local _, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

-- Alarme im Kalender des Spiels (Blizzard_Calendar): sie erscheinen wie andere Eintraege im Tag und im Tooltip,
-- werden aber nur lokal eingeblendet und nie als Termin an den Server geschickt. Dazu liefern die Abfragen
-- C_Calendar.GetNumDayEvents/GetDayEvent, solange das Kalenderfenster offen ist, hinter den echten Terminen
-- zusaetzliche Eintraege; ein Klick darauf oeffnet die Alarm-Optionen, das Kontextmenue bleibt leer.
-- Alle Uhrzeiten im Kalenderfenster erscheinen in Ortszeit, wenn die Uhr auf Ortszeit steht.
-- Mit Classic Calendar - Revived zeigt dieses Addon die Alarme stattdessen (CalendarLink.lua).

local function Visible()
    local frame = _G.CalendarFrame
    return frame and frame.IsVisible and frame:IsVisible() and Clock.db and not Clock.holidayScanning and not Clock.calRaw
        and not (Clock.CalendarLinkAvailable and Clock:CalendarLinkAvailable())
end

local function LocalOn()
    return Visible() and Clock.db.profile.calLocalTimes ~= false
end

local function Active()
    if not Visible() then return false end
    if not (Clock.db and Clock.db.profile.calLinkShow ~= false and Clock:IsModuleEnabled('alarms')) then return false end
    if Clock.CalendarLinkAvailable and Clock:CalendarLinkAvailable() then return false end
    return ns.AlarmRunsOnDay ~= nil and not Clock.holidayScanning
end

local function DayNumber(year, month, day)
    return math.floor(time({ year = year, month = month, day = day, hour = 12 }) / 86400)
end

-- Alarme eines Kalendertages (Serverzeit) als Kalendereintraege im Format von C_Calendar.GetDayEvent.
function Clock:AlarmCalendarEvents(year, month, day)
    local events = {}
    local _, ty, tm, td = self:GetToday()
    local base = DayNumber(ty, tm, td)
    local target = DayNumber(year, month, day)
    local offset = self:LocalOffset()
    local otherType = _G.Enum and _G.Enum.CalendarEventType and _G.Enum.CalendarEventType.Other or 4
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.enabled ~= false and alarm.inCalendar ~= false and not alarm.calendarKey then
            -- Alarmzeiten sind Ortszeit, der Kalender zeigt Serverzeit: der Tag kann dabei wechseln
            for local_ = target - 1, target + 1 do
                local ahead = local_ - base
                if self:AlarmInRange(alarm, ahead) and ns.AlarmRunsOnDay(alarm, ahead, ty, tm, td) then
                    local at = date('*t', local_ * 86400 + 43200)
                    local start = self:ShiftTime({ year = at.year, month = at.month, monthDay = at.day,
                        hour = alarm.hour or 0, minute = alarm.minute or 0 }, -offset)
                    if start.year == year and start.month == month and start.monthDay == day then
                        local time_ = { year = start.year, month = start.month, monthDay = start.monthDay, hour = start.hour, minute = start.minute }
                        local title = ns.AlarmDisplayName and ns.AlarmDisplayName(alarm) or alarm.name or ''
                        -- gewaehlte Alarmfarbe: im Titel, damit sie in Tageszelle, Liste und Tooltip erscheint
                        local effect = self.GetAlarmEffectOverride and self:GetAlarmEffectOverride(alarm)
                        if effect and self.GetEffectColorHex then title = '|cff' .. self:GetEffectColorHex('alarms', effect) .. title .. '|r' end
                        events[#events + 1] = {
                            title = title,
                            isCustomTitle = true, calendarType = 'SYSTEM', sequenceType = '', eventType = otherType,
                            iconTexture = alarm.calendarIcon == true and ns.AlarmTypeTexture and ns.AlarmTypeTexture(alarm) or nil,
                            startTime = time_, endTime = time_, numSequenceDays = 0, cpfAlarm = true, cpfAlarmId = alarm.id,
                        }
                    end
                end
            end
        end
    end
    table.sort(events, function(a, b)
        return a.startTime.hour * 60 + a.startTime.minute < b.startTime.hour * 60 + b.startTime.minute
    end)
    return events
end

local function DayEvents(offsetMonths, day)
    local calendar = _G.C_Calendar
    local info = calendar.GetMonthInfo and calendar.GetMonthInfo(offsetMonths)
    if not (type(info) == 'table' and info.year and info.month and day) then return nil end
    local ok, list = pcall(Clock.AlarmCalendarEvents, Clock, info.year, info.month, day)
    if not ok then Clock.calDisplayError = tostring(list) end
    return ok and list or nil
end

-- Alarm, der aus diesem Kalendertermin importiert wurde (Schluessel wie beim Import: eventID, sonst Datum + Titel)
local function ImportedAlarm(event)
    local start = event.startTime
    if not (start and Clock.db) then return nil end
    local key = event.eventID ~= nil and ('id:' .. tostring(event.eventID))
        or string.format('%04d%02d%02d|%s', start.year or 0, start.month or 0, start.monthDay or 0, tostring(event.title))
    for _, alarm in ipairs(Clock.db.profile.alarms) do
        if alarm.calendarKey == key then return alarm end
    end
end

-- Eintrag fuer die Anzeige: Uhrzeiten in Ortszeit (wenn die Uhr auf Ortszeit steht; Datum und ganztaegige
-- Eintraege bleiben) und ein Hinweis, wenn aus dem Termin ein Alarm importiert wurde.
local function Decorate(event)
    if type(event) ~= 'table' or not event.startTime or not Visible() then return event end
    local minutes = LocalOn() and math.floor(Clock:LocalOffset() / 60) or 0
    local alarm = not event.cpfAlarm and ImportedAlarm(event) or nil
    if minutes == 0 and not alarm then return event end
    local function Shift(t)
        if minutes == 0 or type(t) ~= 'table' or ((t.hour or 0) == 0 and (t.minute or 0) == 0) then return t end
        local total = ((t.hour or 0) * 60 + (t.minute or 0) + minutes) % 1440
        local copy = {}
        for key, value in pairs(t) do copy[key] = value end
        copy.hour, copy.minute = math.floor(total / 60), total % 60
        return copy
    end
    local copy = {}
    for key, value in pairs(event) do copy[key] = value end
    copy.startTime, copy.endTime = Shift(event.startTime), Shift(event.endTime)
    if alarm then
        copy.title = tostring(event.title) .. string.format(' |cff63c9ff[%s %02d:%02d]|r', ns.L.ALARM_GENERIC or 'Alarm', alarm.hour or 0, alarm.minute or 0)
        copy.isCustomTitle = true
    end
    return copy
end
local LocalTimes = Decorate

local installed
function Clock:InstallCalendarDisplay()
    local calendar = _G.C_Calendar
    if installed or type(calendar) ~= 'table' or not (calendar.GetNumDayEvents and calendar.GetDayEvent) then return end
    installed = true
    local numEvents, dayEvent = calendar.GetNumDayEvents, calendar.GetDayEvent
    calendar.GetNumDayEvents = function(offsetMonths, day)
        local count = numEvents(offsetMonths, day)
        if Active() then
            local extra = DayEvents(offsetMonths, day)
            if extra then return (count or 0) + #extra end
        end
        return count
    end
    calendar.GetDayEvent = function(offsetMonths, day, index)
        if Active() then
            local real = numEvents(offsetMonths, day) or 0
            if index and index > real then
                local extra = DayEvents(offsetMonths, day)
                return extra and LocalTimes(extra[index - real]) or nil
            end
        end
        return LocalTimes(dayEvent(offsetMonths, day, index))
    end
    -- Klick auf einen eigenen Eintrag (Index hinter den echten Terminen): Optionen der Alarme oeffnen
    local openEvent = calendar.OpenEvent
    if openEvent then
        calendar.OpenEvent = function(offsetMonths, day, index, ...)
            if type(index) == 'number' and (numEvents(offsetMonths, day) or 0) < index then
                if Active() then
                    local real = numEvents(offsetMonths, day) or 0
                    local extra = DayEvents(offsetMonths, day)
                    local event = extra and extra[index - real]
                    if _G.CalendarFrame_CloseEvent then pcall(_G.CalendarFrame_CloseEvent) end
                    if event and ns.EditAlarm then ns.EditAlarm(event.cpfAlarmId) end
                    Clock:OpenSettings('alarms')
                end
                return nil
            end
            return openEvent(offsetMonths, day, index, ...)
        end
    end
    -- Weitere Aktionen auf einem eigenen Eintrag ins Leere laufen lassen
    for _, name in ipairs({ 'ContextMenuSelectEvent', 'ContextMenuEventCanEdit', 'ContextMenuEventCanRemove',
        'ContextMenuEventCanComplain' }) do
        local original = calendar[name]
        if original then
            calendar[name] = function(offsetMonths, day, index, ...)
                if type(index) == 'number' and (numEvents(offsetMonths, day) or 0) < index then return nil end
                return original(offsetMonths, day, index, ...)
            end
        end
    end
end

-- Termin ansehen/bearbeiten: hinter der Serverzeit steht die Ortszeit (wenn die Uhr auf Ortszeit steht)
local function LocalSuffix(hour, minute)
    if not LocalOn() or hour == nil or minute == nil then return nil end
    local minutes = math.floor(Clock:LocalOffset() / 60)
    if minutes == 0 then return nil end
    local total = (hour * 60 + minute + minutes) % 1440
    return string.format('(%02d:%02d %s)', math.floor(total / 60), total % 60, ns.L.CALLINK_LOCAL_TIME or '')
end

local function UpdateEditLocalTime()
    local edit = _G.CalendarCreateEventFrame
    if not (edit and edit.MinuteDropdown) then return end
    if not edit.cpfLocalTime then
        edit.cpfLocalTime = edit:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    end
    local label = edit.cpfLocalTime
    local hour, minute = edit.selectedHour, edit.selectedMinute
    if hour and not (_G.CalendarFrame and _G.CalendarFrame.militaryTime) and _G.GameTime_ComputeMilitaryTime then
        hour = _G.GameTime_ComputeMilitaryTime(hour, edit.selectedAM)
    end
    local text = LocalSuffix(hour, minute)
    if not text then label:Hide(); return end
    local last = edit.AMPMDropdown and edit.AMPMDropdown:IsShown() and edit.AMPMDropdown or edit.MinuteDropdown
    label:ClearAllPoints()
    label:SetPoint('LEFT', last, 'RIGHT', 8, 0)
    label:SetText(text)
    label:Show()
end

local function UpdateViewLocalTime()
    local label = _G.CalendarViewEventTimeLabel
    local info = _G.C_Calendar and _G.C_Calendar.GetEventInfo and _G.C_Calendar.GetEventInfo()
    if not (label and info and info.time) then return end
    local text = LocalSuffix(info.time.hour, info.time.minute)
    if text then label:SetText((label:GetText() or '') .. '  ' .. text) end
end

local function HookEventFrames()
    if not _G.hooksecurefunc or Clock.calEventHooks or not _G.CalendarCreateEventFrame then return end
    Clock.calEventHooks = true
    for _, name in ipairs({ 'CalendarCreateEvent_SetEventTime', 'CalendarCreateEvent_UpdateEventTime',
        'CalendarCreateEvent_UpdateTimeFormat', 'CalendarCreateEventFrame_Update' }) do
        if _G[name] then _G.hooksecurefunc(name, function() pcall(UpdateEditLocalTime) end) end
    end
    if _G.CalendarViewEventFrame_Update then _G.hooksecurefunc('CalendarViewEventFrame_Update', function() pcall(UpdateViewLocalTime) end) end
end
-- Blizzard_Calendar wird erst beim ersten Oeffnen geladen
do
    local loader = _G.CreateFrame and _G.CreateFrame('Frame')
    if loader then
        loader:RegisterEvent('ADDON_LOADED')
        loader:SetScript('OnEvent', function(_, _, name)
            if name == 'Blizzard_Calendar' then HookEventFrames() end
        end)
        HookEventFrames()
    end
end

-- Tooltip am Kalendertag: hinter der (Orts-)Uhrzeit steht in Klammern die Serverzeit
local function FormatClock(hour, minute)
    if _G.GameTime_GetFormattedTime then return (_G.GameTime_GetFormattedTime(hour, minute, true)) end
    return string.format('%02d:%02d', hour, minute)
end

local function TooltipServerTimes()
    local tip = _G.GameTooltip
    local owner = tip and tip.GetOwner and tip:GetOwner()
    local name = owner and owner.GetName and owner:GetName()
    if not (name and name:find('^CalendarDay') and LocalOn()) then return end
    local minutes = math.floor(Clock:LocalOffset() / 60)
    if minutes == 0 then return end
    local changed
    for line = 1, tip:NumLines() do
        local right = _G['GameTooltipTextRight' .. line]
        local text = right and right:GetText()
        local hour, minute, suffix
        if text then hour, minute, suffix = text:match('^(%d+):(%d+)%s*(%a*)$') end
        if hour then
            hour, minute = tonumber(hour), tonumber(minute)
            local lower = suffix:lower()
            if lower:find('p') and hour < 12 then hour = hour + 12 elseif lower:find('a') and hour == 12 then hour = 0 end
            local total = (hour * 60 + minute - minutes) % 1440
            right:SetText(text .. ' ' .. ns.L.CALLINK_LOCAL_TIME .. ' |cff999999(' .. FormatClock(math.floor(total / 60), total % 60)
                .. ' ' .. ns.L.CALLINK_SERVER_TIME .. ')|r')
            changed = true
        end
    end
    if changed then tip:Show() end
end
do
    local tip = _G.GameTooltip
    if tip and tip.HookScript then tip:HookScript('OnShow', function() pcall(TooltipServerTimes) end) end
end

-- Kalender neu zeichnen, wenn sich Alarme aendern, solange das Fenster offen ist
function Clock:RefreshCalendarDisplay()
    if Active() and _G.CalendarFrame_Update then pcall(_G.CalendarFrame_Update) end
end

Clock:InstallCalendarDisplay()

-- /cpfcalendar: zeigt, warum Alarme im Spielkalender (nicht) erscheinen
_G.SLASH_CPFCALENDAR1 = '/cpfcalendar'
_G.SlashCmdList.CPFCALENDAR = function()
    local frame = _G.CalendarFrame
    local function Say(text) print("Can't play Forever Kalender: " .. text) end
    Say('Fenster ' .. tostring(frame and frame:IsVisible() or false) .. ', Option ' .. tostring(Clock.db.profile.calLinkShow ~= false)
        .. ', Alarme-Modul ' .. tostring(Clock:IsModuleEnabled('alarms')) .. ', Classic Calendar ' .. tostring(Clock.CalendarLinkAvailable and Clock:CalendarLinkAvailable() or false)
        .. ', Abgleich ' .. tostring(Clock.holidayScanning) .. ', Eingehakt ' .. tostring(installed))
    local info = _G.C_DateAndTime and _G.C_DateAndTime.GetCurrentCalendarTime()
    if info then
        local list = Clock:AlarmCalendarEvents(info.year, info.month, info.monthDay)
        Say('heute (' .. info.monthDay .. '.' .. info.month .. '.) ' .. #list .. ' Alarm(e), Tage im Monat mit Alarm:')
        local days = {}
        for day = 1, 31 do
            if #Clock:AlarmCalendarEvents(info.year, info.month, day) > 0 then days[#days + 1] = day end
        end
        Say(#days > 0 and table.concat(days, ',') or 'keine')
    end
    local _, ty, tm, td = Clock:GetToday()
    Say('Alarme gesamt ' .. #Clock.db.profile.alarms .. ', Datum ' .. tostring(td) .. '.' .. tostring(tm) .. '.' .. tostring(ty)
        .. ', Versatz ' .. tostring(Clock:LocalOffset()))
    for _, alarm in ipairs(Clock.db.profile.alarms) do
        Say(string.format('%s: aktiv %s, im Kalender %s, importiert %s, heute %s', tostring(alarm.name), tostring(alarm.enabled),
            tostring(alarm.inCalendar), tostring(alarm.calendarKey), tostring(ns.AlarmRunsOnDay and ns.AlarmRunsOnDay(alarm, 0, ty, tm, td))))
    end
    if Clock.calDisplayError then Say('Fehler: ' .. Clock.calDisplayError) end
end
