local _, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

-- Verbindung zu Classic Calendar - Revived (ClassicCalendar.API, Version 2):
--   * Alarme erscheinen als Termine im Kalender (Quelle "Can't play Forever", nur dieser Charakter)
--   * Termine aus dem Kalender (eigene, Gilde, Community) lassen sich per Knopf zu Alarmen machen (nie automatisch)
-- Ohne das Addon zeigt CalendarDisplay.lua die Alarme im Kalender des Spiels.
local SOURCE = "Can't play Forever"
-- Farbe je Terminart aus Classic Calendar: Auswahl beim Import und Effektfarbe des Alarms.
local EVENT_COLORS = {
    RAID = { 1.00, 0.50, 0.10 }, DUNGEON = { 0.35, 0.60, 1.00 }, PVP = { 1.00, 0.25, 0.25 },
    MEETING = { 0.40, 0.90, 0.40 }, OTHER = { 1.00, 0.82, 0.00 },
}
function Clock:CalendarEventColor(eventType)
    return unpack(EVENT_COLORS[eventType] or EVENT_COLORS.OTHER)
end
local function ColorCode(eventType)
    local r, g, b = Clock:CalendarEventColor(eventType)
    return string.format('|cff%02x%02x%02x', math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
local MADE_BY_PLAYERS = { PLAYER = true, GUILD_EVENT = true, COMMUNITY_EVENT = true }

local function Api()
    local calendar = _G.ClassicCalendar
    local api = type(calendar) == 'table' and calendar.API
    if type(api) == 'table' and api.AddEvents and api.ClearEvents and api.GetDayEvents then return api end
end
function Clock:CalendarLinkAvailable() return Api() ~= nil end

-- Quelle der Kalendertermine fuer den Import: Classic Calendar (alle Termine, auch ferne Monate) oder,
-- ohne das Addon, der Kalender des Spiels selbst (C_Calendar: eigene, Gilden- und Community-Termine).
local NATIVE_TYPES = { [0] = 'RAID', [1] = 'DUNGEON', [2] = 'PVP', [3] = 'MEETING', [4] = 'OTHER' }
local function NativeSource()
    local calendar = _G.C_Calendar
    if not (type(calendar) == 'table' and calendar.GetNumDayEvents and calendar.GetDayEvent
        and calendar.SetAbsMonth and calendar.GetMonthInfo) then return nil end
    local source = { native = true }
    -- Ist der Kalender offen, bleibt der angezeigte Monat der Monat, in dem der Spieler gerade steht
    local viewed = calendar.GetMonthInfo(0)
    local original = type(viewed) == 'table' and viewed.month and viewed.year and viewed
        or _G.C_DateAndTime and _G.C_DateAndTime.GetCurrentCalendarTime and _G.C_DateAndTime.GetCurrentCalendarTime()
    local shown
    function source.GetDayEvents(year, month, day)
        local out = {}
        local info = calendar.GetMonthInfo(0)
        if not (type(info) == 'table' and info.year == year and info.month == month) then
            Clock.holidayScanning = true -- SetAbsMonth loest den Kalenderabgleich synchron aus
            pcall(calendar.SetAbsMonth, month, year)
            Clock.holidayScanning = nil
            shown = true
        end
        Clock.calRaw = true -- echte Termine, ohne die lokal eingeblendeten Alarme und Ortszeiten
        for index = 1, calendar.GetNumDayEvents(0, day) or 0 do
            local event = calendar.GetDayEvent(0, day, index)
            if type(event) == 'table' and event.startTime and not event.cpfAlarm then
                local start, finish = event.startTime, event.endTime
                local function Plain(t)
                    return t and { year = t.year, month = t.month, day = t.monthDay or t.day, hour = t.hour or 0, minute = t.minute or 0 }
                end
                out[#out + 1] = { title = event.title, kind = event.calendarType, eventID = event.eventID,
                    index = index, inviteStatus = event.inviteStatus, invitedBy = event.invitedBy, nativeDate = { year = year, month = month, day = day },
                    eventType = NATIVE_TYPES[tonumber(event.eventType) or 4] or 'OTHER', start = Plain(start), finish = Plain(finish) }
            end
        end
        Clock.calRaw = nil
        return out
    end
    function source.Done()
        if shown and original then
            Clock.holidayScanning = true
            pcall(calendar.SetAbsMonth, original.month, original.year)
            Clock.holidayScanning = nil
        end
    end
    return source
end
local function Source()
    return Api() or NativeSource()
end
Clock.CalendarSource = Source
function Clock:CalendarImportAvailable() return Api() ~= nil or (type(_G.C_Calendar) == 'table' and _G.C_Calendar.GetDayEvent ~= nil) end

local function Stamp(time)
    return (((time.year * 100 + time.month) * 100 + (time.monthDay or time.day)) * 100 + (time.hour or 0)) * 100
        + (time.minute or time.min or 0)
end

-- Alarme -> Kalender: alle Termine der naechsten Tage neu setzen (nur bei geaenderten Alarmen).
function Clock:SyncAlarmsToCalendar(force)
    local api = Api()
    if not (api and self.db and ns.AlarmRunsOnDay) then return end
    local profile = self.db.profile
    if profile.calLinkShow == false or not self:IsModuleEnabled('alarms') then
        if self.calLinkShown then api.ClearEvents(SOURCE); self.calLinkShown = nil; self.calLinkSignature = nil end
        return
    end
    local _, year, month, day = self:GetToday()
    local parts = { year, month, day, self:LocalOffset(), self:CalendarShowDays() }
    for _, alarm in ipairs(profile.alarms) do
        if not alarm.calendarKey and alarm.enabled ~= false and alarm.inCalendar ~= false then
            local days = {}
            for wday = 1, 7 do days[wday] = alarm.days and alarm.days[wday] and 1 or 0 end
            parts[#parts + 1] = table.concat({ alarm.uid or alarm.id or 0, alarm.hour or 0, alarm.minute or 0, alarm.name or '',
                alarm.alarmType or '', tostring(alarm.calendarIcon), alarm.year or 0, alarm.month or 0, alarm.day or 0, tostring(alarm.everyMonth), tostring(alarm.everyYear),
                table.concat(days) }, ',')
        end
    end
    local signature = table.concat(parts, ';')
    if signature == self.calLinkSignature and not force then return end
    self.calLinkSignature = signature
    local offset = self:LocalOffset()
    local events = {}
    for _, alarm in ipairs(profile.alarms) do
        if not alarm.calendarKey and alarm.enabled ~= false and alarm.inCalendar ~= false then
            local title = alarm.name and alarm.name ~= '' and alarm.name or L.ALARM_GENERIC
            for _, ahead in ipairs(self:AlarmAheadDays(alarm, year, month, day)) do
                do
                    local at = date('*t', time({ year = year, month = month, day = day, hour = 12 }) + ahead * 86400)
                    local start = self:ShiftTime({ year = at.year, month = at.month, monthDay = at.day,
                        hour = alarm.hour or 0, minute = alarm.minute or 0 }, -offset)
                    events[#events + 1] = { title = title, eventType = 'OTHER', icon = alarm.calendarIcon == true and ns.AlarmTypeTexture and ns.AlarmTypeTexture(alarm) or nil, description = L.CALLINK_EVENT_DESC,
                        key = string.format('%s#%04d%02d%02d', tostring(alarm.uid or alarm.id or 0), at.year, at.month, at.day),
                        start = { year = start.year, month = start.month, day = start.monthDay, hour = start.hour, minute = start.minute } }
                end
            end
        end
    end
    -- Abgleich ueber die Kennungen: nur Neues/Geaendertes schreiben, Verwaistes (Alarm geloescht) entfernen.
    -- Sind es viele Aenderungen, ist neu aufbauen billiger als einzeln (jede Aenderung zeichnet den Kalender neu).
    local desired = {}
    for _, event in ipairs(events) do desired[event.key] = event end
    local stale, fresh = {}, {}
    if api.GetEvents then
        local existing = {}
        for _, old in ipairs(api.GetEvents(SOURCE)) do
            existing[old.key] = old
            if not desired[old.key] then stale[#stale + 1] = old.key end
        end
        for _, event in ipairs(events) do
            local old = existing[event.key]
            local s, o = event.start, old and old.start
            if not (old and old.title == event.title and old.icon == event.icon and o and o.year == s.year and o.month == s.month
                and o.day == s.day and o.hour == s.hour and o.minute == s.minute) then
                fresh[#fresh + 1] = event
            end
        end
    end
    if not api.GetEvents or #stale + #fresh > 5 then
        api.ClearEvents(SOURCE)
        if #events > 0 then api.AddEvents(SOURCE, events) end
    else
        for _, key in ipairs(stale) do api.RemoveEvent(SOURCE, key) end
        if #fresh > 0 then api.AddEvents(SOURCE, fresh) end
    end
    self.calLinkShown = true
end

-- Zeile fuer den Tooltip der Uhr bei einem importierten Alarm: der eigentliche Termin in Orts- und Serverzeit
function Clock:ImportedAlarmEventText(alarm)
    local stamp = alarm and alarm.calendarKey and alarm.calendarStamp
    if not stamp then return nil end
    local day, clock = math.floor(stamp / 10000), stamp % 10000
    local server = { year = math.floor(day / 10000), month = math.floor(day / 100) % 100, monthDay = day % 100,
        hour = math.floor(clock / 100), minute = clock % 100 }
    local at = self:ShiftTime(server, self:LocalOffset(true))
    return string.format(L.CALLINK_TOOLTIP_EVENT, at.monthDay, at.month, at.hour, at.minute, server.hour, server.minute)
end

-- Rueckwaerts: zu einem Kalendertermin (Schluessel aus API.GetEvents / GetDayEvents) den Alarm finden.
function Clock:AlarmFromCalendarKey(key)
    local uid = type(key) == 'string' and key:match('^(.+)#%d%d%d%d%d%d%d%d$')
    if not (uid and self.db) then return nil end
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.uid == uid then return alarm end
    end
end

-- Welche Bestandteile eines Termins haben sich gegenueber dem Stand beim letzten Import geaendert?
-- Verglichen wird, was der Alarm gespeichert hat (aeltere Alarme kennen nicht alles: das zaehlt nicht als Aenderung).
-- Terminart, mit der der Alarm angelegt wurde: gespeichert, sonst aus der Alarmfarbe (aeltere Staende)
local function AlarmCalendarType(alarm)
    if alarm.calendarEventType then return alarm.calendarEventType end
    local color = type(alarm.effect) == 'table' and alarm.customEffect == true and alarm.effect.spec
    local text = type(color) == 'string' and color:match('^%s*#?(%x%x%x%x%x%x)') or nil
    if text then
        for name, rgb in pairs(EVENT_COLORS) do
            if string.format('%02x%02x%02x', math.floor(rgb[1] * 255 + 0.5), math.floor(rgb[2] * 255 + 0.5),
                math.floor(rgb[3] * 255 + 0.5)) == text:lower() then return name end
        end
    end
end
Clock.AlarmCalendarType = function(_, alarm) return AlarmCalendarType(alarm) end

local function CalendarChanges(alarm, item)
    local changes = {}
    if alarm.calendarTitle and alarm.calendarTitle ~= item.title then changes[#changes + 1] = 'title' end
    if alarm.calendarStamp and alarm.calendarStamp ~= item.stamp then changes[#changes + 1] = 'start' end
    if alarm.calendarFinish and alarm.calendarFinish ~= (item.finishStamp or 0) then changes[#changes + 1] = 'finish' end
    local oldType = AlarmCalendarType(alarm)
    if oldType and oldType ~= (item.eventType or 'OTHER') then changes[#changes + 1] = 'type' end
    if alarm.calendarKind and alarm.calendarKind ~= item.kind then changes[#changes + 1] = 'kind' end
    return changes
end
Clock.CalendarChanges = CalendarChanges

-- Kalender -> Alarme, nur auf Knopfdruck: Termine der naechsten Tage (eigene, Gilde, Community), aus
-- denen noch kein Alarm entstanden ist. Jeder Eintrag: { key, title, start, when } (when = Alarmzeit
-- in der Zeitbasis der Uhr, Vorlauf abgezogen).
function Clock:CollectCalendarEvents()
    local api = Source()
    local dateApi = _G.C_DateAndTime
    local list = {}
    if not (api and self.db and dateApi and dateApi.GetCurrentCalendarTime) then return list end
    local profile = self.db.profile
    local today = dateApi.GetCurrentCalendarTime()
    local nowStamp = Stamp(today)
    local offset, lead = self:LocalOffset(), (tonumber(profile.calLinkLead) or 15) * 60
    -- Bekannte Termine: Alarm je Terminschluessel. Schluessel = eventID des Kalenders (stabil, auch wenn der
    -- Termin verschoben oder umbenannt wird); ohne eventID Datum + Titel (eine geaenderte Uhrzeit aktualisiert den Alarm).
    local known = {}
    for _, alarm in ipairs(profile.alarms) do
        if alarm.calendarKey then
            known[alarm.calendarKey] = alarm
            -- Schluessel aus frueheren Staenden (Datum + Uhrzeit + Titel) auch unter Datum + Titel finden
            local day, name = tostring(alarm.calendarKey):match('^(%d%d%d%d%d%d%d%d)%d%d%d%d|(.*)$')
            if day then known[day .. '|' .. name] = known[day .. '|' .. name] or alarm end
        end
    end
    local noon = time({ year = today.year, month = today.month, day = today.monthDay, hour = 12 })
    local seen, present = {}, {}
    local days = tonumber(profile.calLinkDays) or 14
    for ahead = 0, days do
        local at = date('*t', noon + ahead * 86400)
        for _, event in ipairs(api.GetDayEvents(at.year, at.month, at.day)) do
            local start = event.start
            if MADE_BY_PLAYERS[event.kind] and event.source ~= SOURCE and start
                and ((start.hour or 0) ~= 0 or (start.minute or 0) ~= 0) then
                local stamp = Stamp(start)
                local key = event.eventID ~= nil and ('id:' .. tostring(event.eventID)) or (math.floor(stamp / 10000) .. '|' .. tostring(event.title))
                local title = tostring(event.title)
                local alarm = known[key]
                if alarm then present[alarm] = true end
                local finish = event.finish
                local item = { key = key, title = title, start = start, eventType = event.eventType or 'OTHER', kind = event.kind, native = api.native,
                    stamp = stamp, finishStamp = finish and Stamp(finish) or 0, update = alarm }
                local changes = alarm and CalendarChanges(alarm, item) or {}
                if not seen[key] and stamp > nowStamp and (not alarm or #changes > 0) then
                    seen[key] = true
                    item.changes = changes
                    list[#list + 1] = { key = key, title = title, start = start, eventType = event.eventType or 'OTHER', kind = event.kind, native = api.native,
                        stamp = stamp, finishStamp = item.finishStamp, update = alarm, changes = changes,
                        when = self:ShiftTime({ year = start.year, month = start.month, monthDay = start.day,
                            hour = start.hour, minute = start.minute }, offset - lead) }
                end
            end
        end
    end
    -- Importierte Alarme, deren Termin im Zeitraum nicht mehr im Kalender steht (geloescht), werden zum Loeschen angeboten
    local horizon = Stamp({ year = date('*t', noon + days * 86400).year, month = date('*t', noon + days * 86400).month,
        day = date('*t', noon + days * 86400).day, hour = 23, minute = 59 })
    for _, alarm in ipairs(profile.alarms) do
        local stamp = alarm.calendarKey and alarm.calendarStamp
        if stamp and not present[alarm] and stamp > nowStamp and stamp <= horizon then
            local day, clock = math.floor(stamp / 10000), stamp % 10000
            list[#list + 1] = { removed = true, remove = alarm, key = alarm.calendarKey, title = tostring(alarm.calendarTitle or alarm.name),
                eventType = AlarmCalendarType(alarm) or 'OTHER', stamp = stamp,
                start = { year = math.floor(day / 10000), month = math.floor(day / 100) % 100, day = day % 100,
                    hour = math.floor(clock / 100), minute = clock % 100 } }
        end
    end
    if api.Done then api.Done() end
    return list
end

-- Legt aus den uebergebenen Terminen (Standard: alle) einmalige, scharfe Alarme an.
function Clock:ImportCalendarAlarms(list)
    local profile = self.db and self.db.profile
    if not profile then return 0 end
    list = list or self:CollectCalendarEvents()
    local created, removed = 0, 0
    for _, item in ipairs(list) do
        local when = item.when
        local alarm = item.update
        if item.removed then
            for index, entry in ipairs(profile.alarms) do
                if entry == item.remove then table.remove(profile.alarms, index); removed = removed + 1; break end
            end
        elseif alarm then
            -- Termin hat sich geaendert: derselbe Alarm wird angepasst und wieder scharf gestellt
            alarm.hour, alarm.minute, alarm.name = when.hour, when.minute, item.title
            alarm.year, alarm.month, alarm.day = when.year, when.month, when.monthDay
            alarm.armed, alarm.armedAfterMinute = true, math.floor(ns.Now() / 60)
            alarm.calendarStamp, alarm.calendarTitle = item.stamp, item.title
            alarm.calendarFinish, alarm.calendarEventType, alarm.calendarKind = item.finishStamp, item.eventType or 'OTHER', item.kind
            -- Andere Terminart: die Alarmfarbe folgt
            for _, what in ipairs(item.changes or {}) do
                if what == 'type' and self.SetAlarmCustomEffect and self.SetEffectSettingForConfig then
                    self:SetAlarmCustomEffect(alarm, true)
                    self:SetEffectSettingForConfig('alarms', alarm.effect, 'color', self:CalendarEventColor(item.eventType))
                end
            end
        else
            alarm = {
                id = profile.nextAlarmID, uid = ns.NewAlarmUID and ns.NewAlarmUID(), hour = when.hour, minute = when.minute, name = item.title,
                enabled = true, selected = true, armed = true, armedAfterMinute = math.floor(ns.Now() / 60),
                sched = 2, days = { false, false, false, false, false, false, false },
                year = when.year, month = when.month, day = when.monthDay,
                everyMonth = false, everyYear = false, repeating = false, alarmType = item.native and 'event' or 'calendar',
                calendarSource = item.native and 'game' or 'cc',
                customEffect = false, calendarKey = item.key, calendarStamp = item.stamp, calendarTitle = item.title,
                calendarFinish = item.finishStamp, calendarEventType = item.eventType or 'OTHER', calendarKind = item.kind,
            }
            table.insert(profile.alarms, alarm)
            profile.nextAlarmID = profile.nextAlarmID + 1
            -- Alarmfarbe = Farbe der Terminart
            if self.SetAlarmCustomEffect and self.SetEffectSettingForConfig then
                self:SetAlarmCustomEffect(alarm, true)
                self:SetEffectSettingForConfig('alarms', alarm.effect, 'color', self:CalendarEventColor(item.eventType))
            end
        end
        if not item.removed then created = created + 1 end
    end
    if created + removed > 0 then self:NotifyOptions() end
    return created, removed
end

function Clock:SyncCalendarLink(force)
    if not self.db or not self:CalendarModuleOn() then return end
    self:SyncAlarmsToCalendar(force)
end

-- Auswahl der Termine: je Termin ein Haken, dazu "Alle", "Keine" und "Auswahl uebernehmen".
function Clock.CalendarLinkChoiceArgs(self)
    local function Items() return self.calLinkCandidates or {} end
    local function Selected()
        local list = {}
        for _, item in ipairs(Items()) do
            if item.selected then list[#list + 1] = item end
        end
        return list
    end
    local args = {
        empty = { type = 'description', order = 1, width = 'full', name = L.CALLINK_NONE,
            hidden = function() return #Items() > 0 end },
        all = { type = 'execute', order = 2, width = 'half', name = L.CALLINK_ALL,
            func = function() for _, item in ipairs(Items()) do item.selected = true end end },
        none = { type = 'execute', order = 3, width = 'half', name = L.CALLINK_NONE_BUTTON,
            func = function() for _, item in ipairs(Items()) do item.selected = false end end },
        run = { type = 'execute', order = 4, width = 'double', name = L.CALLINK_RUN,
            disabled = function() return #Selected() == 0 end,
            func = function()
                local count, removed = self:ImportCalendarAlarms(Selected())
                self.calLinkChecked, self.calLinkCandidates = nil, nil
                if count > 0 or removed == 0 then self:Print(string.format(L.CALLINK_IMPORTED, count)) end
                if removed > 0 then self:Print(string.format(L.CALLINK_REMOVED_DONE, removed)) end
                self:NotifyOptions()
            end },
    }
    -- Je Termin zwei Zeilen: (1) Haken, Name, bei Aenderung blau was sich geaendert hat;
    -- (2) [Terminart] Datum mit Terminzeit und der erzeugte Alarm in der Alarmfarbe der Terminart.
    local function StampText(stamp)
        return string.format('%02d.%02d. %02d:%02d', math.floor(stamp / 10000) % 100, math.floor(stamp / 1000000) % 100 % 100,
            math.floor(stamp / 100) % 100, stamp % 100)
    end
    for index = 1, 60 do
        args['e' .. index] = { type = 'toggle', order = 10 + index * 2, width = 'full',
            hidden = function() return Items()[index] == nil end,
            name = function()
                local item = Items()[index]
                if not item then return '' end
                local text = (item.title:gsub('|', ' '))
                if item.removed then return text .. '  |cffff5555[' .. L.CALLINK_REMOVED_TAG .. ']|r' end
                local old = item.update
                if old and item.changes and #item.changes > 0 then
                    local parts = {}
                    for _, what in ipairs(item.changes) do
                        if what == 'title' then
                            parts[#parts + 1] = (old.calendarTitle:gsub('|', ' ')) .. ' -> ' .. text
                        elseif what == 'start' then
                            parts[#parts + 1] = L.CALLINK_CHANGE_START .. ' ' .. StampText(old.calendarStamp) .. ' -> ' .. StampText(item.stamp)
                        elseif what == 'finish' then
                            parts[#parts + 1] = L.CALLINK_CHANGE_END .. ' ' .. StampText(old.calendarFinish) .. ' -> ' .. StampText(item.finishStamp)
                        elseif what == 'type' then
                            local oldType = Clock:AlarmCalendarType(old)
                            parts[#parts + 1] = (L['CALLINK_TYPE_' .. oldType] or oldType) .. ' -> '
                                .. (L['CALLINK_TYPE_' .. tostring(item.eventType)] or tostring(item.eventType))
                        elseif what == 'kind' then
                            parts[#parts + 1] = L.CALLINK_CHANGE_KIND
                        end
                    end
                    text = text .. '  |cff63c9ff[' .. L.CALLINK_UPDATE .. ': ' .. table.concat(parts, ', ') .. ']|r'
                end
                return text
            end,
            get = function() local item = Items()[index]; return item and item.selected == true end,
            set = function(_, value) local item = Items()[index]; if item then item.selected = value end end }
        args['d' .. index] = { type = 'description', order = 11 + index * 2, width = 'full',
            hidden = function() return Items()[index] == nil end,
            name = function()
                local item = Items()[index]
                if not item then return '' end
                local start, when = item.start, item.when
                if item.removed then
                    return string.format('      |cff999999[%s]  %s %02d:%02d (%s)  -|r  |cffff5555%s|r',
                        L['CALLINK_TYPE_' .. tostring(item.eventType)] or L.CALLINK_TYPE_OTHER,
                        Clock:FormatHolidayDate({ year = start.year, month = start.month, monthDay = start.day }),
                        start.hour or 0, start.minute or 0, L.CALLINK_SERVER_TIME, L.CALLINK_REMOVED_ALARM)
                end
                local date = Clock:FormatHolidayDate({ year = start.year, month = start.month, monthDay = start.day })
                local alarmDate = Clock:FormatHolidayDate(when)
                local zone = self.db.profile.useLocalTime and L.CALLINK_LOCAL_TIME or L.CALLINK_SERVER_TIME
                local kind = L['CALLINK_TYPE_' .. tostring(item.eventType or 'OTHER')] or L.CALLINK_TYPE_OTHER
                return string.format('      |cff999999[%s]  %s %02d:%02d (%s)  -|r  %s%s: %s %02d:%02d (%s)|r', kind,
                    date, start.hour or 0, start.minute or 0, L.CALLINK_SERVER_TIME,
                    ColorCode(item.eventType), L.CALLINK_ALARM_AT, alarmDate, when.hour, when.minute, zone)
            end }
    end
    return args
end

function Clock:CalendarLinkOptions()
    local function Profile() return self.db.profile end
    return {
        type = 'group', order = 20,
        name = function() return Api() and L.CALLINK_TAB or L.CALLINK_TAB_GAME end,
        hidden = function() return not self:CalendarImportAvailable() end,
        args = {
            installed = { type = 'description', order = 1, width = 'full', fontSize = 'medium',
                name = function()
                    local get = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
                    local version = get and get('ClassicCalendar', 'Version')
                    version = type(version) == 'string' and version:gsub('^ClassicCalendar%-', '') or nil
                    if not Api() then return '|cff999999' .. L.CALLINK_NO_ADDON .. '|r' end
                    return L.CALLINK_INSTALLED .. (version and ('  |cff33ff33' .. version .. '|r') or '')
                end },
            info = { type = 'description', order = 1.5, width = 'full', name = function() return '|cff999999' .. (Api() and L.CALLINK_INFO or L.CALLINK_INFO_GAME) .. '|r' end },
            lead = { type = 'range', order = 6, width = 1.49, name = L.CALLINK_LEAD, desc = L.CALLINK_LEAD_DESC,
                min = 0, max = 120, step = 5,
                get = function() return Profile().calLinkLead or 15 end,
                set = function(_, value) Profile().calLinkLead = value end },
            days = { type = 'range', order = 6.5, width = 1.49, name = L.CALLINK_DAYS, desc = L.CALLINK_DAYS_DESC,
                min = 7, max = 90, step = 1,
                get = function() return Profile().calLinkDays or 14 end,
                set = function(_, value) Profile().calLinkDays = value end },
            import = { type = 'execute', order = 5, width = 'full', name = L.CALLINK_IMPORT, desc = L.CALLINK_IMPORT_DESC,
                func = function()
                    self.calLinkCandidates = self:CollectCalendarEvents()
                    for _, item in ipairs(self.calLinkCandidates) do item.selected = true end
                    self.calLinkChecked = true
                    self:NotifyOptions()
                end },
            choose = { type = 'group', order = 7, inline = true, name = L.CALLINK_CHOOSE,
                hidden = function() return not self.calLinkChecked end,
                args = Clock.CalendarLinkChoiceArgs(self) },
        },
    }
end

-- Nach einer Aenderung an den Alarmen (Optionen rufen NotifyOptions) kurz gebuendelt abgleichen,
-- damit ein neuer Alarm sofort im Kalender steht; unveraenderte Alarme schreiben nichts.
function Clock:QueueCalendarLinkSync()
    if self.calLinkQueued or not _G.C_Timer then return end
    self.calLinkQueued = true
    _G.C_Timer.After(0.5, function()
        Clock.calLinkQueued = nil
        Clock:GuardedTick('calendarlink', function()
            Clock:SyncCalendarLink()
            if Clock.RefreshCalendarDisplay then Clock:RefreshCalendarDisplay() end
        end)
    end)
end

-- Einmal pro Anmeldung: gibt es neue oder geaenderte Termine, wird gefragt, ob sie als Alarme uebernommen
-- werden sollen. "Ja" oeffnet die Auswahl in den Optionen; importiert wird nie ohne Auswahl.
function Clock:AskCalendarImport()
    if self.calLinkAsked or not (self:CalendarImportAvailable() and self.db and self:CalendarModuleOn()) then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then return false end
    local list = self:CollectCalendarEvents()
    self.calLinkAsked = true
    if #list == 0 or not (_G.StaticPopupDialogs and _G.StaticPopup_Show) then return end
    _G.StaticPopupDialogs['CPF_CALENDAR_IMPORT'] = {
        text = '%s', button1 = L.CALLINK_PROMPT_YES, button2 = L.CALLINK_PROMPT_LATER,
        OnAccept = function()
            Clock.calLinkCandidates = Clock:CollectCalendarEvents()
            for _, item in ipairs(Clock.calLinkCandidates) do item.selected = true end
            Clock.calLinkChecked = true
            Clock:OpenSettings('calendar', 'calendarLink')
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    _G.StaticPopup_Show('CPF_CALENDAR_IMPORT', string.format(L.CALLINK_PROMPT, #list))
    return true
end

-- Abgleich beim Anmelden und danach mit dem Kalender-Takt (nur bei Aenderungen wird neu geschrieben).
local frame = CreateFrame('Frame')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:SetScript('OnEvent', function()
    if _G.C_Timer then
        _G.C_Timer.After(8, function() Clock:GuardedTick('calendarlink', function() Clock:SyncCalendarLink(true) end) end)
        -- Der Kalender braucht einen Moment, bis die Termine geladen sind; im Kampf spaeter erneut versuchen
        local function Ask()
            Clock:GuardedTick('calendarlink', function()
                if Clock:AskCalendarImport() == false then _G.C_Timer.After(30, Ask) end
            end)
        end
        _G.C_Timer.After(25, Ask)
        if not Clock.calLinkTicker and _G.C_Timer.NewTicker then
            Clock.calLinkTicker = _G.C_Timer.NewTicker(60, function()
                Clock:GuardedTick('calendarlink', function() Clock:SyncCalendarLink() end)
            end)
        end
    end
end)
