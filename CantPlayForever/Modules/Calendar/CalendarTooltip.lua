local _, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

-- Strg am Tooltip der Uhr: Details zu den Alarmen und den naechsten Kalendereintraegen (Typ, Ersteller, eigene
-- Zusage, Beschreibung, Teilnehmer). Beschreibung und Teilnehmer liefert der Spielkalender nur fuer einen
-- geoeffneten Termin; sie werden im Hintergrund eingelesen (nur bei geschlossenem Kalenderfenster) und zwischengespeichert.
local DAYS = 7
local MAX_EVENTS = 6
local DESCRIPTION_LIMIT = 140
local cache = {} -- eventID -> { description, creator, invites = { total, yes, no, open }, at }
local tried = {} -- eventID -> Zeitpunkt des letzten Einleseversuchs (alle 5 Minuten hoechstens einmal)

local function CtrlDown()
    return type(_G.IsControlKeyDown) == 'function' and _G.IsControlKeyDown() or false
end
Clock.CtrlDown = CtrlDown

function Clock:AddCtrlHint(tooltip)
    if not (self:CalendarModuleOn() or #self.db.profile.alarms > 0) then return end
    tooltip:AddLine('     ' .. L.CALTIP_HINT, 0.30, 0.70, 1.00) -- 5 Leerzeichen: Text beginnt dort, wo der Shift-Text nach dem Info-Symbol beginnt
end

local function Duration(minutes)
    return string.format(L.HOLIDAY_COUNTDOWN, math.floor(minutes / 1440), math.floor(minutes % 1440 / 60), minutes % 60)
end

local function Short(text)
    text = tostring(text or ''):gsub('|', ' '):gsub('%s+', ' ')
    if #text > DESCRIPTION_LIMIT then text = text:sub(1, DESCRIPTION_LIMIT - 1) .. '...' end
    return text
end

-- Naechste Kalendereintraege (eigene, Gilde, Community) der naechsten Tage, nach Beginn sortiert.
function Clock:UpcomingCalendarEvents()
    local list = {}
    local source = self.CalendarSource and self.CalendarSource()
    local dateApi = _G.C_DateAndTime
    if not (source and dateApi and dateApi.GetCurrentCalendarTime) then return list end
    local today = dateApi.GetCurrentCalendarTime()
    local noon = time({ year = today.year, month = today.month, day = today.monthDay, hour = 12 })
    local nowStamp = ((((today.year * 100 + today.month) * 100 + today.monthDay) * 100 + (today.hour or 0)) * 100) + (today.minute or 0)
    for ahead = 0, DAYS do
        local at = date('*t', noon + ahead * 86400)
        for _, event in ipairs(source.GetDayEvents(at.year, at.month, at.day)) do
            local start = event.start
            if (event.kind == 'PLAYER' or event.kind == 'GUILD_EVENT' or event.kind == 'COMMUNITY_EVENT' or event.kind == 'GUILD_ANNOUNCEMENT')
                and event.source ~= "Can't play Forever" and start then
                local stamp = ((((start.year * 100 + start.month) * 100 + start.day) * 100 + (start.hour or 0)) * 100) + (start.minute or 0)
                if ahead > 0 or stamp >= nowStamp then list[#list + 1] = { event = event, stamp = stamp } end
            end
        end
    end
    if source.Done then source.Done() end
    table.sort(list, function(a, b) return a.stamp < b.stamp end)
    return list
end

local STATUS_KEYS = { [0] = 'INVITED', 'AVAILABLE', 'DECLINED', 'CONFIRMED', 'OUT', 'STANDBY', 'SIGNEDUP', 'NOTSIGNEDUP', 'TENTATIVE' }

-- Detailzeilen unter einem Alarm der Aktiv-Liste (die Alarmzeile selbst bleibt unveraendert)
function Clock:AddCtrlAlarmDetails(tooltip, alarm)
    local imported = alarm.calendarKey ~= nil
    local kind
    if imported then
        kind = L['CALLINK_TYPE_' .. tostring(alarm.calendarEventType or 'OTHER')]
    else
        kind = L['ALARM_TYPE_' .. string.upper(alarm.alarmType or 'alarm')]
    end
    local parts = { kind }
    local minutes = self:AlarmMinutesUntil(alarm)
    if minutes < 1e8 then parts[#parts + 1] = string.format(L.CALTIP_NEXT, Duration(minutes)) end
    tooltip:AddLine('   ' .. table.concat(parts, '  \194\183  '), 0.65, 0.65, 0.65)
    local detail = imported and cache[tonumber(tostring(alarm.calendarKey):match('^id:(%d+)$'))]
    if detail then
        if detail.creator and detail.creator ~= '' then tooltip:AddLine('   ' .. string.format(L.CALTIP_BY, detail.creator), 0.65, 0.65, 0.65) end
        if detail.invites and detail.invites.total > 0 then
            tooltip:AddLine('   ' .. string.format(L.CALTIP_INVITES, detail.invites.total, detail.invites.yes, detail.invites.no, detail.invites.open), 0.65, 0.65, 0.65)
        end
        if detail.description and detail.description ~= '' then
            tooltip:AddLine('   ' .. Short(detail.description), 0.8, 0.8, 0.8, true)
        end
    end
end

function Clock:AddCtrlDetails(tooltip)
    -- Kalender
    if not self:CalendarModuleOn() then return end
    local upcoming = self:UpcomingCalendarEvents()
    if #upcoming == 0 then return end
    tooltip:AddLine(' ')
    tooltip:AddLine(string.format(L.CALTIP_CALENDAR, DAYS), 1, 0.82, 0)
    local fetch = {}
    for index, entry in ipairs(upcoming) do
        if index > MAX_EVENTS then break end
        local event = entry.event
        local start = event.start
        local shown = self:DisplayTime({ year = start.year, month = start.month, monthDay = start.day, hour = start.hour or 0, minute = start.minute or 0 })
        local kind = L['CALLINK_TYPE_' .. tostring(event.eventType or 'OTHER')] or L.CALLINK_TYPE_OTHER
        tooltip:AddDoubleLine(string.format('%02d.%02d. %02d:%02d  %s', shown.monthDay, shown.month, shown.hour, shown.minute, Short(event.title)),
            kind, 1, 1, 1, 0.75, 0.75, 0.75)
        local detail = event.eventID and cache[event.eventID]
        local creator = detail and detail.creator or event.invitedBy
        if creator and creator ~= '' then tooltip:AddLine('   ' .. string.format(L.CALTIP_BY, creator), 0.65, 0.65, 0.65) end
        if detail and detail.invites and detail.invites.total > 0 then
            tooltip:AddLine('   ' .. string.format(L.CALTIP_INVITES, detail.invites.total, detail.invites.yes, detail.invites.no, detail.invites.open), 0.65, 0.65, 0.65)
        end
        local status = STATUS_KEYS[tonumber(event.inviteStatus)]
        if status then tooltip:AddLine('   ' .. string.format(L.CALTIP_MINE, L['CALTIP_STATUS_' .. status]), 0.65, 0.65, 0.65) end
        if detail then
            if detail.description and detail.description ~= '' then
                tooltip:AddLine('   ' .. Short(detail.description), 0.8, 0.8, 0.8, true)
            end
        elseif event.eventID and event.index and event.nativeDate and (tried[event.eventID] or 0) + 300 < time() then
            tried[event.eventID] = time()
            fetch[#fetch + 1] = event
        end
    end
    if #fetch > 0 then self:FetchCalendarDetails(fetch) end
end

-- Beschreibung und Teilnehmer eines Termins: der Termin wird kurz geoeffnet und wieder geschlossen.
-- Nur bei geschlossenem Kalenderfenster und ausserhalb des Kampfes; das Fenster des Spiels bekommt davon nichts mit.
function Clock:FetchCalendarDetails(events)
    local calendar = _G.C_Calendar
    if self.calFetching or not (calendar and calendar.OpenEvent and calendar.GetEventInfo and calendar.CloseEvent and calendar.SetAbsMonth) then return end
    if (_G.InCombatLockdown and _G.InCombatLockdown()) or (_G.CalendarFrame and _G.CalendarFrame:IsShown()) then return end
    if not (_G.CreateFrame and _G.C_Timer) then return end
    self.calFetching = true
    local queue = {}
    for _, event in ipairs(events) do queue[#queue + 1] = event end
    local blizzard = _G.CalendarFrame
    local viewed = calendar.GetMonthInfo and calendar.GetMonthInfo(0)
    local listener = self.calFetchFrame
    if not listener then
        listener = CreateFrame('Frame')
        listener:RegisterEvent('CALENDAR_OPEN_EVENT')
        self.calFetchFrame = listener
    end
    local current, finished
    local function Finish()
        if finished then return end
        finished = true
        listener:SetScript('OnEvent', nil)
        pcall(calendar.CloseEvent)
        if viewed and viewed.month and viewed.year then
            Clock.holidayScanning = true
            pcall(calendar.SetAbsMonth, viewed.month, viewed.year)
            Clock.holidayScanning = nil
        end
        if blizzard and blizzard.RegisterEvent then pcall(blizzard.RegisterEvent, blizzard, 'CALENDAR_OPEN_EVENT') end
        Clock.calFetching = nil
        if Clock.UpdateHoverTooltip then Clock:UpdateHoverTooltip() end
    end
    local Next
    local function Read()
        local event = current
        current = nil
        if not event then return end
        local info = calendar.GetEventInfo()
        if type(info) == 'table' then
            local invites = { total = 0, yes = 0, no = 0, open = 0 }
            for index = 1, tonumber(calendar.GetNumInvites and calendar.GetNumInvites()) or 0 do
                local invite = calendar.EventGetInvite and calendar.EventGetInvite(index)
                if type(invite) == 'table' then
                    invites.total = invites.total + 1
                    local status = tonumber(invite.inviteStatus)
                    if status == 1 or status == 3 or status == 6 then invites.yes = invites.yes + 1
                    elseif status == 2 or status == 4 then invites.no = invites.no + 1
                    else invites.open = invites.open + 1 end
                end
            end
            cache[event.eventID] = { description = info.description, creator = info.creator, invites = invites, at = time() }
        end
        pcall(calendar.CloseEvent)
        Next()
    end
    function Next()
        local event = table.remove(queue, 1)
        if not event then Finish(); return end
        current = event
        local date_ = event.nativeDate
        Clock.holidayScanning = true
        pcall(calendar.SetAbsMonth, date_.month, date_.year)
        Clock.holidayScanning = nil
        listener:SetScript('OnEvent', function() Read() end)
        local ok = pcall(calendar.OpenEvent, 0, date_.day, event.index)
        -- ohne Rueckmeldung nach kurzer Zeit weiter
        _G.C_Timer.After(1.5, function()
            if current == event then current = nil; pcall(calendar.CloseEvent); Next() end
        end)
        if not ok then current = nil; Next() end
    end
    -- Das Fenster des Spiels soll beim Einlesen nicht aufgehen
    if blizzard and blizzard.UnregisterEvent then pcall(blizzard.UnregisterEvent, blizzard, 'CALENDAR_OPEN_EVENT') end
    Next()
end
