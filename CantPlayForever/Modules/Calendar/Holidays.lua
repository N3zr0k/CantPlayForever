local _, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

-- Laufende Feste aus dem WoW-Kalender (nur Anzeige): Symbol oben rechts an der Uhr
-- (mittel/gross) und Eintrag im Tooltip. Der Kalender laedt nach OpenCalendar()
-- verzoegert; CALENDAR_UPDATE_EVENT_LIST loest dann den Abgleich aus. Ohne
-- C_Calendar im Client tut dieses Modul nichts.
local SCAN_SECONDS = 60

local function CalendarApi()
    local api = _G.C_Calendar
    if type(api) == 'table' and api.GetNumDayEvents and api.GetDayEvent then return api end
end

-- Heutiges Datum: der Forever-Client hat C_DateAndTime, C_Calendar.GetDate ist nicht garantiert.
local function Today(api)
    local dateApi = _G.C_DateAndTime
    if type(dateApi) == 'table' and dateApi.GetCurrentCalendarTime then return dateApi.GetCurrentCalendarTime() end
    if api.GetDate then return api.GetDate() end
end

-- Kalenderzeit (Realmzeit) als Sekunden seit 1970 ohne Zeitzone/Sommerzeit (reine Datumsrechnung),
-- damit Differenzen ueber eine Zeitumstellung hinweg stimmen.
local function Seconds(calendarTime)
    if type(calendarTime) ~= 'table' or not calendarTime.year then return nil end
    local year, month, day = calendarTime.year, calendarTime.month, calendarTime.monthDay
    if month <= 2 then year = year - 1 end
    local era = math.floor(year / 400)
    local yearOfEra = year - era * 400
    local dayOfYear = math.floor((153 * (month + (month > 2 and -3 or 9)) + 2) / 5) + day - 1
    local dayOfEra = yearOfEra * 365 + math.floor(yearOfEra / 4) - math.floor(yearOfEra / 100) + dayOfYear
    local days = era * 146097 + dayOfEra - 719468
    return days * 86400 + (calendarTime.hour or 0) * 3600 + (calendarTime.minute or 0) * 60
end

-- Termin mit Uhrzeit am Ende (z. B. 14-16 Uhr), das schon vorbei ist: nicht mehr anzeigen.
-- Enden ohne Uhrzeit (00:00) zaehlen als ganztaegig.
local function HasEnded(event, now)
    local finish = event.endTime
    if not (now and type(finish) == 'table') or ((finish.hour or 0) == 0 and (finish.minute or 0) == 0) then return false end
    local finishAt = Seconds(finish)
    return finishAt ~= nil and finishAt <= now
end

-- Unterschied Ortszeit - Serverzeit in Sekunden (auf Viertelstunden gerundet), 0 bei Serverzeit-Anzeige (force: immer).
function Clock:LocalOffset(force)
    if not (self.db and (force or self.db.profile.useLocalTime)) then return 0 end
    local dateApi = _G.C_DateAndTime
    local server = dateApi and dateApi.GetCurrentCalendarTime and Seconds(dateApi.GetCurrentCalendarTime())
    local info = type(_G.date) == 'function' and _G.date('*t')
    local localNow = info and Seconds({ year = info.year, month = info.month, monthDay = info.day, hour = info.hour, minute = info.min })
    if not (server and localNow) then return 0 end
    return math.floor((localNow - server) / 900 + 0.5) * 900
end

-- Kalenderzeit um delta Sekunden verschoben: { year, month, monthDay, hour, minute }.
function Clock:ShiftTime(time, delta)
    local total = Seconds(time) + delta
    local days = math.floor(total / 86400)
    local rest = total - days * 86400
    local z = days + 719468
    local era = math.floor(z / 146097)
    local doe = z - era * 146097
    local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
    local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
    local mp = math.floor((5 * doy + 2) / 153)
    local day = doy - math.floor((153 * mp + 2) / 5) + 1
    local month = mp < 10 and mp + 3 or mp - 9
    local year = yoe + era * 400 + (month <= 2 and 1 or 0)
    return { year = year, month = month, monthDay = day, hour = math.floor(rest / 3600), minute = math.floor(rest % 3600 / 60) }
end

-- Termin mit Uhrzeit (Serverzeit) in die angezeigte Zeit umrechnen. Ganztaegige Angaben (00:00) bleiben.
function Clock:DisplayTime(time)
    if type(time) ~= 'table' or not time.year or ((time.hour or 0) == 0 and (time.minute or 0) == 0) then return time end
    local offset = self:LocalOffset()
    if offset == 0 then return time end
    return self:ShiftTime(time, offset)
end

function Clock:CalendarMinute()
    local dateApi = _G.C_DateAndTime
    local now = dateApi and dateApi.GetCurrentCalendarTime and Seconds(dateApi.GetCurrentCalendarTime())
    return now and math.floor(now / 60) or 0
end

-- Datum eines Kalendereintrags ({year, month, monthDay}) im Format der Spielsprache.
function Clock:FormatHolidayDate(time)
    if type(time) ~= 'table' or not time.year or not time.month or not time.monthDay then return '?' end
    local locale = type(_G.GetLocale) == 'function' and _G.GetLocale() or 'enUS'
    if locale == 'enUS' then return string.format('%02d/%02d/%04d', time.month, time.monthDay, time.year) end
    if locale == 'deDE' then return string.format('%02d.%02d.%04d', time.monthDay, time.month, time.year) end
    return string.format('%02d/%02d/%04d', time.monthDay, time.month, time.year)
end

-- Einstellungen je Fest-Symbol: Werte des Symbols (ns.HOLIDAY_STYLES) vor den allgemeinen (ns.T).
-- Waehrend der Vorschau im Frame Debugger gelten die allgemeinen Werte, damit Aenderungen sichtbar sind.
Clock.HOLIDAY_STYLE_KEYS = { 'HOLIDAY_ICON_SIZE', 'HOLIDAY_ICON_X', 'HOLIDAY_ICON_Y', 'HOLIDAY_ICON_CROP', 'HOLIDAY_CROP_X', 'HOLIDAY_CROP_Y', 'HOLIDAY_MASK_SIZE',
    'HOLIDAY_OVERLAY_SIZE', 'HOLIDAY_OVERLAY_X', 'HOLIDAY_OVERLAY_Y', 'HOLIDAY_OVERLAY_ALPHA' }
function Clock:HolidayValue(icon, key)
    if not self.holidayPreview then
        local style = ns.HOLIDAY_STYLES and ns.HOLIDAY_STYLES[icon]
        if style and style[key] ~= nil then return style[key] end
    end
    return ns.T[key]
end

-- Ausschnitt aus der Textur: Rand beschneiden (CROP) und Fenster verschieben (CROP_X/CROP_Y, Texturanteil).
function Clock:HolidayTexCoord(icon)
    local crop = self:HolidayValue(icon, 'HOLIDAY_ICON_CROP') or 0
    local dx = self:HolidayValue(icon, 'HOLIDAY_CROP_X') or 0
    local dy = self:HolidayValue(icon, 'HOLIDAY_CROP_Y') or 0
    return crop + dx, 1 - crop + dx, crop + dy, 1 - crop + dy
end

-- Schluessel eines Overlays fuer Feste ohne Kalendersymbol (z. B. 'darkmoon'), erkannt an ID oder Name.
function Clock:OverlayKeyForEvent(event)
    local lowered = type(event.title) == 'string' and event.title:lower() or ''
    for key, match in pairs(ns.HOLIDAY_OVERLAY_MATCH or {}) do
        if event.eventID and match.ids and match.ids[event.eventID] then return key end
        for _, part in ipairs(match.names or {}) do
            if lowered:find(part, 1, true) then return key end
        end
    end
end

-- Textur zu einem Symbolschluessel: Schluessel ohne Pfad (z. B. 'darkmoon') zeigen das allgemeine Symbol.
function Clock:IconTexture(icon)
    if type(icon) == 'string' and not icon:find('\\', 1, true) then
        local generic = ns.T.HOLIDAY_GENERIC_ICON
        return tonumber(generic) or generic
    end
    return icon
end

-- Datum mit Uhrzeit, wenn der Termin eine bestimmte Uhrzeit hat (nicht 00:00).
local function DateTimeText(self, time)
    local text = self:FormatHolidayDate(time)
    if type(time) == 'table' and ((time.hour or 0) ~= 0 or (time.minute or 0) ~= 0) then
        text = string.format('%s %02d:%02d', text, time.hour or 0, time.minute or 0)
    end
    return text
end

-- Ingame-Kalender: "18.10.2026 - 4:00 Uhr bis 20.10.2026 - 4:00 Uhr" (Uhrzeit nur wenn vorhanden)
function Clock:FormatHolidayGameRange(startTime, endTime)
    startTime, endTime = self:DisplayTime(startTime), self:DisplayTime(endTime)
    local L = ns.L
    local function Part(time)
        local text = self:FormatHolidayDate(time)
        if type(time) == 'table' and ((time.hour or 0) ~= 0 or (time.minute or 0) ~= 0) then
            text = string.format('%s - %d:%02d%s', text, time.hour or 0, time.minute or 0, L.HOLIDAY_OCLOCK or '')
        end
        return text
    end
    if type(endTime) ~= 'table' then return Part(startTime) end
    return Part(startTime) .. ' ' .. (L.HOLIDAY_UNTIL or '-') .. ' ' .. Part(endTime)
end

-- "18.10.2026 04:00 - 02.11.2026 04:00"; am selben Tag "18.10.2026 14:00 - 16:00".
function Clock:FormatHolidayRange(startTime, endTime)
    startTime, endTime = self:DisplayTime(startTime), self:DisplayTime(endTime)
    local first = DateTimeText(self, startTime)
    if type(startTime) == 'table' and type(endTime) == 'table' and startTime.year == endTime.year
        and startTime.month == endTime.month and startTime.monthDay == endTime.monthDay then
        if (endTime.hour or 0) ~= 0 or (endTime.minute or 0) ~= 0 then
            return string.format('%s - %02d:%02d', first, endTime.hour or 0, endTime.minute or 0)
        end
        return first
    end
    if type(endTime) ~= 'table' then return first end
    -- Mehrtaegig: nur Datum, keine Uhrzeit
    return self:FormatHolidayDate(startTime) .. ' - ' .. self:FormatHolidayDate(endTime)
end

-- Naechstes kommendes Fest (nicht schon laufend) aus dem Katalog. all = true: auch abgehakte Feste.
function Clock:GetNextHoliday(all)
    local dateApi = _G.C_DateAndTime
    local now = dateApi and dateApi.GetCurrentCalendarTime and Seconds(dateApi.GetCurrentCalendarTime())
    if not (now and self.db) then return end
    local hidden = not all and self.db.profile.holidayHidden or {}
    local running = {}
    for _, holiday in ipairs(self.holidays or {}) do running[holiday.id] = true end
    local best, bestStart
    for id, entry in pairs(self.db.global.holidayCatalog or {}) do
        local start = Seconds(entry.startTime)
        if start and start > now and not hidden[id] and not running[id] and (not bestStart or start < bestStart) then
            best, bestStart = entry, start
        end
    end
    if best then return best, bestStart - now end
end

-- Ist das Modul "Kalender" in Can't play Forever eingeschaltet?
function Clock:CalendarModuleOn()
    return self:IsModuleEnabled('calendar')
end

-- Abschnitt "Kalender": laufende Feste und das naechste kommende mit Countdown.
--   mode nil: Uhr-Tooltip (nur angehakte Feste, nur bei aktivem Kalender-Symbol)
--   mode 'badge': Tooltip am Fest-Symbol (wie nil, ohne fuehrende Leerzeile)
--   mode 'game': Tooltip am Ingame-Kalendersymbol (alle Eintraege, unabhaengig von Uhr-Einstellungen)
function Clock:AddCalendarLines(tooltip, mode)
    if not self.db or not self:CalendarModuleOn() then return end
    if mode ~= 'game' and self.db.profile.holidaySymbol == false then return end
    local L = ns.L
    local dateApi = _G.C_DateAndTime
    local now = dateApi and dateApi.GetCurrentCalendarTime and Seconds(dateApi.GetCurrentCalendarTime())
    -- Beendete Termine des Tages (z. B. Anglerwettbewerb nach 16 Uhr) auch zwischen zwei Abfragen ausblenden
    local running = {}
    for _, holiday in ipairs(mode == 'game' and (self.todayAll or {}) or self:GetActiveHolidays()) do
        if not HasEnded(holiday, now) then running[#running + 1] = holiday end
    end
    local nextHoliday, seconds = self:GetNextHoliday(mode == 'game')
    if #running == 0 and not nextHoliday then return end
    if mode ~= 'badge' then tooltip:AddLine(' ') end
    tooltip:AddLine(L.CALENDAR_TAB, 1, 0.82, 0)
    local function Icon(entry)
        if not entry.icon then return '' end
        return '|T' .. tostring(self:IconTexture(entry.icon)) .. ':' .. ns.T.HOLIDAY_TIP_ICON_SIZE .. ':' .. ns.T.HOLIDAY_TIP_ICON_SIZE
            .. ':0:' .. ns.T.HOLIDAY_TIP_ICON_Y .. '|t '
    end
    local game = mode == 'game'
    local DOT = '   \194\183 '
    for _, holiday in ipairs(running) do
        if game then
            tooltip:AddLine(Icon(holiday) .. holiday.title, 1, 1, 1)
            tooltip:AddLine(DOT .. self:FormatHolidayGameRange(holiday.startTime, holiday.endTime), 0.65, 0.65, 0.65) -- Datum grau, Fest weiss
        else
        -- laufendes Fest und Datum weiss, Datum rechtsbuendig daneben
        tooltip:AddDoubleLine(Icon(holiday) .. holiday.title, self:FormatHolidayRange(holiday.startTime, holiday.endTime),
            1, 1, 1, 1, 1, 1)
        end
    end
    if nextHoliday and game then
        local minutes = math.floor(seconds / 60)
        local countdown = string.format(L.HOLIDAY_COUNTDOWN, math.floor(minutes / 1440),
            math.floor(minutes % 1440 / 60), minutes % 60)
        tooltip:AddLine(Icon(nextHoliday) .. nextHoliday.title .. ' \194\183 |cff63c9ff' .. countdown .. '|r', 0.65, 0.65, 0.65)
        tooltip:AddLine(DOT .. self:FormatHolidayGameRange(nextHoliday.startTime, nextHoliday.endTime), 0.65, 0.65, 0.65)
    elseif nextHoliday then
        local minutes = math.floor(seconds / 60)
        local countdown = string.format(L.HOLIDAY_COUNTDOWN, math.floor(minutes / 1440),
            math.floor(minutes % 1440 / 60), minutes % 60)
        -- Fest grau mit Datum rechts, darunter der Countdown in Blau
        tooltip:AddDoubleLine(Icon(nextHoliday) .. nextHoliday.title,
            self:FormatHolidayRange(nextHoliday.startTime, nextHoliday.endTime), 0.65, 0.65, 0.65, 0.65, 0.65, 0.65)
        tooltip:AddLine(DOT .. '|cff63c9ff' .. countdown .. '|r', 0.65, 0.65, 0.65)
    end
end

-- Symbol fuer die Uhr: Fest-Symbol des ersten laufenden Festes; laeuft keines, das allgemeine
-- Kalender-Symbol. Sind alle bekannten Feste abgehakt, gibt es kein Symbol.
-- Symbol des laufenden Festes, zu dem es eine Dekoration gibt (Overlay um die Uhr), sonst nil.
function Clock:GetOverlayIcon()
    if not (self.db and self:CalendarModuleOn()) or self.db.profile.holidaySymbol == false
        or self.db.profile.holidayDisplay == 'icon' then return nil end
    for _, holiday in ipairs(self:GetActiveHolidays()) do
        local key = holiday.overlay or holiday.icon
        if ns.HOLIDAY_OVERLAYS and ns.HOLIDAY_OVERLAYS[key] then return key end
    end
end

function Clock:GetBadgeIcon()
    if not (self.db and self:CalendarModuleOn()) or self.db.profile.holidaySymbol == false then return nil end
    local first = self:GetActiveHolidays()[1]
    -- "Nur Overlay": Symbol entfaellt, sobald ein laufendes Fest ein Overlay zeigt (sonst bliebe nichts).
    -- Laufen mehrere Feste, zaehlt jedes mit Overlay, nicht nur das erste.
    local onlyOverlay = self.db.profile.holidayDisplay == 'overlay'
    if onlyOverlay and self:GetOverlayIcon() then return nil end
    if first then return first.icon end
    if onlyOverlay then return nil end
    local hidden, known, visible = self.db.profile.holidayHidden or {}, 0, 0
    for id in pairs(self.db.global.holidayCatalog or {}) do
        known = known + 1
        if not hidden[id] then visible = visible + 1 end
    end
    if known > 0 and visible == 0 then return nil end
    return tonumber(ns.T.HOLIDAY_GENERIC_ICON) or ns.T.HOLIDAY_GENERIC_ICON
end

-- Liste der heute laufenden Feste: { {title = ..., icon = ...}, ... }
function Clock:GetActiveHolidays()
    local hidden = self.db and self.db.profile.holidayHidden or {}
    local list = {}
    for _, holiday in ipairs(self.holidays or {}) do
        if not hidden[holiday.id] then list[#list + 1] = holiday end
    end
    return list
end

-- Gleicht die Festliste mit dem Kalender ab. Ist das Kalenderfenster offen, bleibt
-- die Liste unveraendert (der Spieler blaettert dort evtl. in einem anderen Monat).
function Clock:ScanHolidays()
    local api = CalendarApi()
    -- Nicht waehrend des Jahres-Einlesens und nicht aus dem eigenen SetAbsMonth heraus (loest
    -- CALENDAR_UPDATE_EVENT_LIST synchron aus).
    if not api or self.holidayYearScan or self.holidayScanning or not self:CalendarModuleOn() then return end
    local calendarFrame = _G.CalendarFrame
    if calendarFrame and calendarFrame.IsShown and calendarFrame:IsShown() then return end
    local today = Today(api)
    if type(today) ~= 'table' or not today.monthDay then return end
    if api.SetAbsMonth then
        local viewed = api.GetMonthInfo and api.GetMonthInfo(0)
        if not (type(viewed) == 'table' and viewed.month == today.month and viewed.year == today.year) then
            self.holidayScanning = true
            pcall(api.SetAbsMonth, today.month, today.year)
            self.holidayScanning = nil
        end
    end
    local list, seen, signature = {}, {}, {}
    local all, seenAll = {}, {}
    local count = api.GetNumDayEvents(0, today.monthDay) or 0
    local now = Seconds(today)
    for index = 1, count do
        local event = api.GetDayEvent(0, today.monthDay, index)
        if type(event) == 'table' and HasEnded(event, now) then event = nil end
        -- Alle heutigen Feste (auch ohne Symbol) fuer den Tooltip am Ingame-Kalender
        if type(event) == 'table' and event.calendarType == 'HOLIDAY' and type(event.title) == 'string'
            and event.title ~= '' and not seenAll[event.title] then
            seenAll[event.title] = true
            all[#all + 1] = { id = event.eventID or event.title, title = event.title,
                icon = (event.sequenceType == 'START' and event.iconTexture) or (event.eventID and self.db
                    and self.db.global.holidayCatalog and self.db.global.holidayCatalog[event.eventID]
                    and self.db.global.holidayCatalog[event.eventID].iconFromStart
                    and self.db.global.holidayCatalog[event.eventID].icon) or event.iconTexture
                    or Clock:OverlayKeyForEvent(event),
                startTime = event.startTime, endTime = event.endTime }
        end
        -- Nur die grossen Feste: Eintraege wie Schlachtfeld-Wochenenden haben kein eigenes Symbol.
        local known = type(event) == 'table' and event.eventID and self.db and self.db.global.holidayCatalog
            and self.db.global.holidayCatalog[event.eventID]
        local startIcon = known and known.iconFromStart and known.icon or nil
        local overlayKey = type(event) == 'table' and event.calendarType == 'HOLIDAY' and Clock:OverlayKeyForEvent(event) or nil
        if type(event) == 'table' and event.calendarType == 'HOLIDAY' and (event.iconTexture or startIcon or overlayKey)
            and type(event.title) == 'string' and event.title ~= '' and not seen[event.title] then
            seen[event.title] = true
            -- Symbol vom Starttag des Festes (Folgetage koennen ein anderes/keins liefern)
            local icon = event.sequenceType == 'START' and event.iconTexture or startIcon or event.iconTexture or overlayKey
            local startTime, endTime = event.startTime, event.endTime
            list[#list + 1] = { id = event.eventID or event.title, title = event.title, icon = icon, overlay = overlayKey,
                startTime = startTime, endTime = endTime }
            Clock:RememberHoliday(event)
            signature[#signature + 1] = event.title .. '|' .. tostring(icon) .. '|' .. Clock:FormatHolidayDate(startTime)
                .. '|' .. Clock:FormatHolidayDate(endTime)
        end
    end
    self.todayAll = all
    signature = table.concat(signature, ';')
    if signature == self.holidaySignature then return end
    self.holidaySignature = signature
    self.holidays = list
    if self.UpdateBadges then self:UpdateBadges() end
end

-- Katalog aller je gesehenen Feste (accountweit), Grundlage der Liste in den Optionen.
-- Je Fest wird der naechste noch nicht beendete Termin gemerkt.
function Clock:RememberHoliday(event)
    if not (self.db and event.eventID and event.iconTexture) then return end
    local catalog = self.db.global.holidayCatalog
    if not catalog then catalog = {}; self.db.global.holidayCatalog = catalog end
    local entry = catalog[event.eventID]
    local dateApi = _G.C_DateAndTime
    local now = dateApi and dateApi.GetCurrentCalendarTime and Seconds(dateApi.GetCurrentCalendarTime()) or 0
    local newStart, newEnd = Seconds(event.startTime) or 0, Seconds(event.endTime) or 0
    if newEnd < now then return end -- Termin schon vorbei
    local isStart = event.sequenceType == 'START'
    -- Das Symbol ist immer das vom Starttag; Folgetage ueberschreiben ein bekanntes Startsymbol nicht
    local icon = event.iconTexture
    local fromStart = isStart
    if entry and entry.iconFromStart and not isStart then icon = entry.icon; fromStart = true end
    local changed = not entry or entry.title ~= event.title or entry.icon ~= icon or entry.iconFromStart ~= fromStart
    local better = not entry
    if entry then
        local oldEnd = Seconds(entry.endTime) or 0
        local oldStart = Seconds(entry.startTime) or 0
        better = oldEnd < now or (newStart < oldStart and newEnd >= now)
    end
    if better or changed then
        catalog[event.eventID] = { title = event.title, icon = icon, iconFromStart = fromStart,
            startTime = better and event.startTime or entry.startTime,
            endTime = better and event.endTime or entry.endTime }
        if self.NotifyOptions then self:NotifyOptions() end
    end
end

-- Liest die Feste der naechsten 12 Monate Monat fuer Monat in den Katalog ein.
function Clock:ScanHolidayYear()
    local api = CalendarApi()
    local dateApi = _G.C_DateAndTime
    if not (api and api.SetAbsMonth and api.GetMonthInfo and dateApi and _G.C_Timer) or self.holidayYearScan or not self:CalendarModuleOn() then return end
    local calendarFrame = _G.CalendarFrame
    if calendarFrame and calendarFrame.IsShown and calendarFrame:IsShown() then return end
    local today = dateApi.GetCurrentCalendarTime()
    self.holidayYearScan = true
    self.holidayYearScanDay = today.monthDay
    pcall(api.OpenCalendar)
    local offset = -1 -- ab Vormonat, damit der Starttag laufender Feste (und sein Symbol) erfasst wird
    local function Step()
        local absolute = today.month + offset
        api.SetAbsMonth((absolute - 1) % 12 + 1, today.year + math.floor((absolute - 1) / 12))
        local info = api.GetMonthInfo(0)
        for day = 1, (info and info.numDays or 31) do
            for index = 1, api.GetNumDayEvents(0, day) or 0 do
                local event = api.GetDayEvent(0, day, index)
                if type(event) == 'table' and event.calendarType == 'HOLIDAY' then Clock:RememberHoliday(event) end
            end
        end
        offset = offset + 1
        if offset <= 12 then
            _G.C_Timer.After(0.7, Step)
        else
            api.SetAbsMonth(today.month, today.year)
            Clock.holidayYearScan = nil
            Clock.holidaySignature = nil
            Clock:ScanHolidays()
            if Clock.NotifyOptions then Clock:NotifyOptions() end
        end
    end
    Step()
    if self.NotifyOptions then self:NotifyOptions() end
end

-- Reiter "Kalender" in den Optionen: Schalter, darunter der Unter-Reiter "Feste" mit Haken je Fest.
function Clock:HolidayOptions()
    local L = ns.L
    local function Off() return self.db.profile.holidaySymbol == false end
    local holidays = { type = 'group', name = L.HOLIDAYS_TAB, order = 1, disabled = Off, args = {
        info = { type = 'description', order = 1, width = 'full', name = L.HOLIDAYS_INFO },
        read = { type = 'execute', order = 2, name = L.HOLIDAYS_READ_YEAR, desc = L.HOLIDAYS_READ_YEAR_DESC,
            disabled = function() return Off() or self.holidayYearScan == true end,
            func = function() self:ScanHolidayYear() end },
        reading = { type = 'description', order = 3, width = 'full',
            name = function() return self.holidayYearScan and ('|cffffd100' .. L.HOLIDAYS_READING .. '|r') or '' end },
    } }
    local entries = {}
    for id, entry in pairs(self.db.global.holidayCatalog or {}) do entries[#entries + 1] = { id = id, entry = entry } end
    table.sort(entries, function(a, b)
        local x, y = a.entry.startTime, b.entry.startTime
        local kx = x and (x.month * 100 + x.monthDay) or 0
        local ky = y and (y.month * 100 + y.monthDay) or 0
        if kx ~= ky then return kx < ky end
        return a.id < b.id
    end)
    if #entries == 0 then
        holidays.args.empty = { type = 'description', order = 10, width = 'full', name = L.HOLIDAYS_EMPTY }
    end
    for index, item in ipairs(entries) do
        local id, entry = item.id, item.entry
        holidays.args['h' .. id] = {
            type = 'toggle', order = 10 + index, width = 'full',
            name = entry.title .. '  |cff999999' .. self:FormatHolidayDate(entry.startTime) .. ' - '
                .. self:FormatHolidayDate(entry.endTime) .. '|r',
            image = entry.icon,
            get = function() return not (self.db.profile.holidayHidden or {})[id] end,
            set = function(_, value)
                local hidden = self.db.profile.holidayHidden
                if not hidden then hidden = {}; self.db.profile.holidayHidden = hidden end
                hidden[id] = (not value) or nil
                if self.UpdateBadges then self:UpdateBadges() end
            end,
        }
    end
    return {
        type = 'group', name = L.CALENDAR_TAB, order = 5, childGroups = 'tab',
        args = {
            enabled = { type = 'toggle', order = 0, width = 'full', name = L.CALENDAR_SHOW, desc = L.CALENDAR_SHOW_DESC,
                get = function() return not Off() end,
                set = function(_, value)
                    self.db.profile.holidaySymbol = value
                    if self.UpdateBadges then self:UpdateBadges() end
                end },
            alarms = { type = 'toggle', order = 2, width = 'full', name = L.CALLINK_SHOW, desc = L.CALLINK_SHOW_DESC,
                get = function() return self.db.profile.calLinkShow ~= false end,
                set = function(_, value)
                    self.db.profile.calLinkShow = value
                    if self.SyncAlarmsToCalendar then self:SyncAlarmsToCalendar(true) end
                end },
            showDays = { type = 'range', order = 2.2, width = 'double', name = L.CALENDAR_SHOW_DAYS, desc = L.CALENDAR_SHOW_DAYS_DESC,
                min = 7, max = 365, step = 1,
                get = function() return self.db.profile.calLinkShowDays or 60 end,
                set = function(_, value)
                    self.db.profile.calLinkShowDays = value
                    if self.SyncAlarmsToCalendar then self:SyncAlarmsToCalendar(true) end
                end },
            localTimes = { type = 'toggle', order = 2.5, width = 'full', name = L.CALENDAR_LOCAL_TIMES, desc = L.CALENDAR_LOCAL_TIMES_DESC,
                get = function() return self.db.profile.calLocalTimes ~= false end,
                set = function(_, value) self.db.profile.calLocalTimes = value end },
            display = { type = 'select', order = 1, width = 'double', name = L.CALENDAR_DISPLAY, desc = L.CALENDAR_DISPLAY_DESC,
                disabled = Off,
                values = { overlay = L.DISPLAY_OVERLAY, both = L.DISPLAY_BOTH, icon = L.DISPLAY_ICON },
                sorting = { 'overlay', 'both', 'icon' },
                get = function() return self.db.profile.holidayDisplay or 'both' end,
                set = function(_, value)
                    self.db.profile.holidayDisplay = value
                    if self.UpdateBadges then self:UpdateBadges() end
                end },
            holidays = holidays,
            calendarLink = self.CalendarLinkOptions and self:CalendarLinkOptions() or nil,
        },
    }
end

Clock:RegisterModule({ id = 'calendar',
    GetOptions = function() return Clock:HolidayOptions() end })

-- Tooltip am Ingame-Kalendersymbol (Minimap): wird nur erweitert, nie ersetzt. Zeigt immer alle
-- heutigen Eintraege und das naechste Fest, unabhaengig von den Einstellungen an der Uhr;
-- nur das Modul Kalender muss eingeschaltet sein.
local function ExtendGameCalendarTooltip()
    local tip, button = _G.GameTooltip, _G.GameTimeFrame
    if not (tip and button and tip.GetOwner and tip:GetOwner() == button and Clock:CalendarModuleOn()) then return end
    for index = 1, tip:NumLines() do
        local line = _G['GameTooltipTextLeft' .. index]
        if line and line:GetText() == ns.L.CALENDAR_TAB then return end -- schon ergaenzt
    end
    Clock:AddCalendarLines(tip, 'game')
    tip:Show() -- Groesse an die neuen Zeilen anpassen
end

function Clock:HookGameCalendar()
    local button = _G.GameTimeFrame
    if self.gameCalendarHooked or not button or not button.HookScript then return end
    self.gameCalendarHooked = true
    button:HookScript('OnEnter', ExtendGameCalendarTooltip)
    -- Blizzard baut den Tooltip bei OnUpdate/OnEvent neu auf: unsere Zeilen danach wieder anhaengen
    button:HookScript('OnUpdate', ExtendGameCalendarTooltip)
    button:HookScript('OnEvent', ExtendGameCalendarTooltip)
    if type(_G.GameTime_UpdateTooltip) == 'function' and _G.hooksecurefunc then
        _G.hooksecurefunc('GameTime_UpdateTooltip', ExtendGameCalendarTooltip)
    end
end

-- Einmal pro Spieltag (und nach dem Anmelden) die naechsten 12 Monate einlesen, damit das
-- naechste kommende Fest bekannt ist. Nicht bei geoeffnetem Kalender.
function Clock:AutoScanHolidayYear()
    local dateApi = _G.C_DateAndTime
    if not (self.db and dateApi and dateApi.GetCurrentCalendarTime) or not self:CalendarModuleOn() then return end
    if self.holidayYearScanDay == dateApi.GetCurrentCalendarTime().monthDay then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then return end
    self:ScanHolidayYear()
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:RegisterEvent('CALENDAR_UPDATE_EVENT_LIST')
frame:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_ENTERING_WORLD' then
        Clock:HookGameCalendar()
        local api = CalendarApi()
        if not api then return end
        if _G.C_Timer then
            if api.OpenCalendar then _G.C_Timer.After(3, function() pcall(api.OpenCalendar) end) end
            _G.C_Timer.After(15, function() Clock:GuardedTick('holidays', function() Clock:AutoScanHolidayYear() end) end)
            if not Clock.holidayTicker and _G.C_Timer.NewTicker then
                Clock.holidayTicker = _G.C_Timer.NewTicker(SCAN_SECONDS, function()
                    Clock:GuardedTick('holidays', function()
                        Clock:ScanHolidays()
                        Clock:AutoScanHolidayYear()
                    end)
                end)
            end
        end
    end
    Clock:GuardedTick('holidays', function() Clock:ScanHolidays() end)
end)
