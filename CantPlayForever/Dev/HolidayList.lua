-- Clock:CollectHolidays(year, log): liest alle Kalender-Feste eines Jahres aus (Monat fuer Monat) und
-- schreibt sie ins Probe-Log (BugLab-Probe "holidays", siehe Dev/Probes.lua). Grundlage fuer die Liste
-- der grossen Feste.
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
if not (Clock and _G.C_Calendar) then return end

local STEP_SECONDS = 0.7

local function Collect(year, onDone)
    local api = _G.C_Calendar
    if not (api and api.SetAbsMonth and api.GetNumDayEvents and api.GetDayEvent and api.GetMonthInfo) then
        onDone(nil); return
    end
    local found, order = {}, {}
    local current = _G.C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime()
    pcall(api.OpenCalendar)
    local month = 1
    local function Step()
        api.SetAbsMonth(month, year)
        local info = api.GetMonthInfo(0)
        for day = 1, (info and info.numDays or 31) do
            for index = 1, api.GetNumDayEvents(0, day) or 0 do
                local event = api.GetDayEvent(0, day, index)
                if event and event.calendarType == 'HOLIDAY' and not found[event.eventID] then
                    found[event.eventID] = event
                    order[#order + 1] = event.eventID
                end
            end
        end
        month = month + 1
        if month <= 12 then
            C_Timer.After(STEP_SECONDS, Step)
        else
            if current then api.SetAbsMonth(current.month, current.year) end
            onDone(found, order)
        end
    end
    Step()
end

function Clock:CollectHolidays(year, log)
    year = tonumber(year) or (C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime().year) or 2026
    log:Info('Lese Feste %d (ca. 10 Sekunden) ...', year)
    Collect(year, function(found, order)
        if not found then log:Error('C_Calendar unvollstaendig'); return end
        log:Info('-- Feste %d (eventID | Titel | Symbol | Beginn - Ende | Tage)', year)
        table.sort(order, function(a, b)
            local x, y = found[a].startTime, found[b].startTime
            return (x.month * 100 + x.monthDay) < (y.month * 100 + y.monthDay)
        end)
        for _, id in ipairs(order) do
            local e = found[id]
            local s, f = e.startTime, e.endTime
            log:Info('%d | %s | %s | %02d.%02d.%04d - %02d.%02d.%04d | %s', id, e.title,
                tostring(e.iconTexture), s.monthDay, s.month, s.year, f.monthDay, f.month, f.year,
                tostring(e.numSequenceDays))
        end
        -- Heutige Eintraege mit Uhrzeiten (Grundlage fuer das Ausblenden beendeter Termine)
        local today = _G.C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime()
        if today and year == today.year then
            local api = _G.C_Calendar
            api.SetAbsMonth(today.month, today.year)
            log:Info('-- Heute %02d.%02d.%04d, jetzt %02d:%02d (eventID | Titel | Sequenz | Beginn | Ende)',
                today.monthDay, today.month, today.year, today.hour or 0, today.minute or 0)
            for index = 1, api.GetNumDayEvents(0, today.monthDay) or 0 do
                local e = api.GetDayEvent(0, today.monthDay, index)
                if e and e.calendarType == 'HOLIDAY' then
                    local s, f = e.startTime, e.endTime
                    log:Info('%s | %s | %s | %02d.%02d. %02d:%02d | %02d.%02d. %02d:%02d',
                        tostring(e.eventID), e.title, tostring(e.sequenceType), s.monthDay, s.month, s.hour or 0, s.minute or 0,
                        f.monthDay, f.month, f.hour or 0, f.minute or 0)
                end
            end
        end
    end)
end
