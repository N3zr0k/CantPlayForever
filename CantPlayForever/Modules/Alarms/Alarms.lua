local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L, Now = ns.Clock, ns.L, ns.Now

-- Three built-in alarm categories. Texture paths are standard Blizzard game icons.
local ALARM_TYPE_TEXTURES = {
    alarm = 'Interface\\Icons\\INV_Misc_PocketWatch_01',
    event = 'Interface\\Icons\\INV_Misc_Book_09',
    reminder = 'Interface\\Icons\\INV_Misc_Note_01',
}
function ns.AlarmTypeValues()
    return {
        alarm = ns.AlarmTypeIcon('alarm', 16) .. ' ' .. L.ALARM_TYPE_ALARM,
        event = ns.AlarmTypeIcon('event', 16) .. ' ' .. L.ALARM_TYPE_EVENT,
        reminder = ns.AlarmTypeIcon('reminder', 16) .. ' ' .. L.ALARM_TYPE_REMINDER,
    }
end
function ns.AlarmTypeIcon(alarm, size)
    local kind = type(alarm) == 'table' and alarm.alarmType or alarm
    local texture = ALARM_TYPE_TEXTURES[kind] or ALARM_TYPE_TEXTURES.alarm
    size = tonumber(size) or 16
    return string.format('|T%s:%d:%d:0:0|t', texture, size, size)
end
function ns.AlarmDisplayName(alarm, fallback, size)
    local name = alarm and alarm.name and alarm.name ~= '' and alarm.name or fallback or L.ALARM_GENERIC
    -- Guard tooltip/FontString markup: player-entered messages must not contain
    -- embedded WoW texture or color escape sequences.
    name = tostring(name):gsub('[\r\n\t|]', ' ')
    return ns.AlarmTypeIcon(alarm, size) .. ' ' .. name
end

-- Each selected alarm is armed for its NEXT matching wall-clock minute via
-- Ctrl+LeftClick. Alarms are one-shot unless alarm.repeating or a recurring date is set and are checked in chronological order
-- by the ordinary ticker. They do not fire without explicit arming.
-- Heutiges Datum in der Zeitbasis der Uhr (Realm- oder Ortszeit): Wochentag (1 = Sonntag), Jahr, Monat, Tag.
function Clock:GetToday()
    if not self.db.profile.useLocalTime and _G.C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
        local c = C_DateAndTime.GetCurrentCalendarTime()
        if c and c.weekday then return c.weekday, c.year, c.month, c.monthDay end
    end
    local info = date('*t')
    return info.wday, info.year, info.month, info.day
end

-- Tage im Monat inkl. Schaltjahr (gregorianisch: durch 4, nicht durch 100, außer durch 400).
function ns.DaysInMonth(month, year)
    if month == 2 then
        local leap = year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
        return leap and 29 or 28
    end
    return (month == 4 or month == 6 or month == 9 or month == 11) and 30 or 31
end

local function HasDays(alarm)
    if type(alarm.days) ~= 'table' then return false end
    for wday = 1, 7 do
        if alarm.days[wday] then return true end
    end
    return false
end
ns.AlarmHasDays = HasDays

-- Bleibt der Alarm nach dem Klingeln aktiv? "Wiederholen", oder ein Datum ohne Wochentage mit
-- "jeden Monat"/"jedes Jahr" (das wiederholt sich von selbst).
local function Repeats(alarm)
    return alarm.repeating == true or (not HasDays(alarm) and (alarm.everyMonth or alarm.everyYear) and true or false)
end
ns.AlarmRepeats = Repeats

-- Läuft der Alarm am Tag `offset` (0 = heute)? Wochentage (alarm.days[1..7], 1 = So) ersetzen den
-- Tag der Datumsangabe; Monat und Jahr gelten, sofern nicht "jeden Monat"/"jedes Jahr" gesetzt ist.
local function RunsOnDay(alarm, offset, year, month, day)
    local info = date('*t', time({year = year, month = month, day = day, hour = 12}) + offset * 86400)
    if HasDays(alarm) then
        if not alarm.days[info.wday] then return false end
    elseif info.day ~= math.min(alarm.day or day, ns.DaysInMonth(info.month, info.year)) then
        return false -- kürzere Monate (Feb., 30 Tage): der letzte Tag des Monats
    end
    return (alarm.everyMonth or info.month == (alarm.month or month))
        and (alarm.everyYear or info.year == (alarm.year or year))
end

function Clock:AlarmRunsToday(alarm)
    local _, year, month, day = self:GetToday()
    return RunsOnDay(alarm, 0, year, month, day)
end

-- Minuten bis zum nächsten Auftreten (ab jetzt). justArmed: eine Auslösung in dieser Minute zählt nicht.
-- Nie wieder auftretende Alarme (Datum in der Vergangenheit) liefern eine sehr große Zahl (ganz hinten).
function Clock:AlarmMinutesUntil(alarm, justArmed)
    local hour, minute = self:GetHourMinute()
    local nowOfDay = hour * 60 + minute
    local target = (tonumber(alarm.hour) or 0) * 60 + (tonumber(alarm.minute) or 0)
    local _, year, month, day = self:GetToday()
    local horizon = 400
    if alarm.everyMonth and alarm.everyYear then horizon = HasDays(alarm) and 7 or 31 end
    for offset = 0, horizon do
        if RunsOnDay(alarm, offset, year, month, day) then
            local delta = offset * 1440 + target - nowOfDay
            if delta > 0 or (delta == 0 and not justArmed) then return delta end
        end
    end
    return 1e9
end

function Clock:CountArmedAlarms()
    local count = 0
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed then count = count + 1 end
    end
    return count
end

-- Einzelnen Alarm aktivieren/deaktivieren (Optionen); wie Strg+Klick,
-- aber nur für diesen einen Alarm.
function Clock:SetAlarmArmed(alarm, armed)
    self:Debug('Alarm %s: %s', tostring(alarm.message or '?'), armed and 'armed' or 'off')
    self:OAPCounter(armed and 'alarms.armed' or 'alarms.disarmed')
    if armed then
        alarm.armed = true
        alarm.armedAfterMinute = math.floor(Now() / 60)
    else
        alarm.armed = false
    end
    self:NotifyOptions()
end

function Clock:ArmSelectedAlarms()
    local count = 0
    local nowMinute = math.floor(Now() / 60)
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.selected then
            alarm.armed = true
            -- Arming during the exact target minute must not fire immediately.
            -- The next eligible occurrence is a future matching minute.
            alarm.armedAfterMinute = nowMinute
            count = count + 1
        end
    end
    if count > 0 then self:OAPCounter('alarms.armed', count) end
    if count == 0 then
        self:Print(L.NO_ALARMS)
    else
        self:Print(string.format(count == 1 and L.ALARMS_ARMED_ONE or L.ALARMS_ARMED_MANY, count))
    end
    self:NotifyOptions()
    return count
end

-- Ctrl+click cancels one armed alarm. Default order (option alarmDisarmOrder = 'farthest'): the
-- alarm FARTHEST away first (alarms that only ring tomorrow go first), the one that can still
-- ring soonest today last; 'nearest' reverses that. Repeat to cancel
-- the others. Once none remains, Ctrl+click arms selected ones.
function Clock:DisarmNextAlarm()
    local currentEpochMinute = math.floor(Now() / 60)
    local nearest, nearestDelta, nearestID = nil, nil, nil -- the alarm to cancel (order: option alarmDisarmOrder)
    local nearestFirst = self.db.profile.alarmDisarmOrder == 'nearest'
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed and alarm.selected then -- nicht für Strg+Linksklick ausgewählte bleiben unberührt
            local justArmed = (alarm.armedAfterMinute or -1) >= currentEpochMinute
            local delta = self:AlarmMinutesUntil(alarm, justArmed)
            local id = tonumber(alarm.id) or 0
            local better = nearestDelta and (nearestFirst and delta < nearestDelta or (not nearestFirst and delta > nearestDelta))
            if not nearest or better
                or (delta == nearestDelta and id < nearestID) then
                nearest, nearestDelta, nearestID = alarm, delta, id
            end
        end
    end
    if not nearest then return false end
    nearest.armed = false
    self:OAPCounter('alarms.disarmed')
    self:Print(string.format(L.ALARM_DISARMED, nearest.hour, nearest.minute,
        nearest.name and nearest.name ~= '' and nearest.name or L.ALARM_FALLBACK))
    self:NotifyOptions()
    return true
end

function Clock:ToggleSelectedAlarms()
    local armedSelected = 0
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed and alarm.selected then armedSelected = armedSelected + 1 end
    end
    if armedSelected > 0 then
        self:DisarmNextAlarm()
    else
        self:ArmSelectedAlarms()
    end
end

function Clock:DisarmAlarms()
    for _, alarm in ipairs(self.db.profile.alarms) do
        alarm.armed = false
    end
    self:NotifyOptions()
end

function Clock:CheckAlarms()
    if not self:IsModuleEnabled('alarms') then return end
    local hour, minute = self:GetHourMinute()
    local currentMinute = math.floor(Now() / 60)
    -- Max. one on-screen alarm per tick. Multiple alarms due at the exact
    -- same time are announced on consecutive ticker cycles, not on top of
    -- one another. Ordinary different alarm times ring independently.
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed and alarm.hour == hour and alarm.minute == minute
            and currentMinute > (alarm.armedAfterMinute or -1)
            and alarm.lastTriggeredMinute ~= currentMinute
            and self:AlarmRunsToday(alarm) then
            -- Wiederholende Alarme (Tage/täglich/jährlich) bleiben aktiv; einmalige schalten ab.
            if not Repeats(alarm) then alarm.armed = false end
            alarm.lastTriggeredMinute = currentMinute
            self:OAPCounter('alarms.triggered')
            self:OAPLog('info', 'Alarm triggered: {1}', alarm.name or '')
            local message = alarm.name and alarm.name ~= '' and alarm.name
                or string.format('%s %02d:%02d', L.ALARM_GENERIC, hour, minute)
            self:Alert(message, 'alarms', alarm)
            self:NotifyOptions()
            return
        end
    end
end

Clock:RegisterModule({
    id = 'alarms',
    logo = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\alarm_logo',
    OnEnable = function(self) self:CheckAlarms() end,
    OnTick = function(self) self:CheckAlarms() end,
    GetOptions = function() return ns.AlarmOptions() end,
})
