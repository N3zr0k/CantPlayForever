-- Test der lokalen Alarm-Anzeige im Spielkalender (CalendarDisplay.lua).
local realOs = os
time = realOs.time
date = realOs.date
os = nil
local settings
local alarms = {
    {id = 1, name = 'Raid', hour = 19, minute = 30, day = 20, month = 10, year = 2026, enabled = true},
    {id = 2, name = 'Imp', hour = 8, minute = 0, day = 20, month = 10, year = 2026, enabled = true, calendarKey = 'x'},
    {id = 3, name = 'Aus', hour = 9, minute = 0, day = 20, month = 10, year = 2026, enabled = true, inCalendar = false},
}
local offset = 3600 -- lokal = Server + 1 Stunde
local Clock = {IsModuleEnabled = function() return true end, db = {profile = {alarms = alarms}},
    GetToday = function() return 1, 2026, 10, 18 end, OpenSettings = function(_, page) settings = page end, LocalOffset = function() return offset end}
function Clock:ShiftTime(t, delta)
    local at = date('*t', time({year = t.year, month = t.month, day = t.monthDay, hour = t.hour, min = t.minute}) + delta)
    return {year = at.year, month = at.month, monthDay = at.day, hour = at.hour, minute = at.min}
end
local edited
SlashCmdList = {}
local ns = {Clock = Clock, EditAlarm = function(id) edited = id end, AlarmRunsOnDay = function(alarm, ahead, year, month, day)
        local at = date('*t', time({year = year, month = month, day = day, hour = 12}) + ahead * 86400)
        return at.day == alarm.day and at.month == alarm.month
    end,
    AlarmTypeTexture = function() return 'tex' end, AlarmDisplayName = function(alarm) return alarm.name end, L = {ALARM_GENERIC = 'Alarm'}}
local visible = true
CalendarFrame = {IsVisible = function() return visible end}
local real = {[20] = {{title = 'Echt', startTime = {year = 2026, month = 10, monthDay = 20, hour = 10, minute = 15}, endTime = {year = 2026, month = 10, monthDay = 20, hour = 0, minute = 0}}}}
local opened
C_Calendar = {
    GetMonthInfo = function() return {year = 2026, month = 10} end,
    GetNumDayEvents = function(_, day) return real[day] and #real[day] or 0 end,
    GetDayEvent = function(_, day, i) return real[day] and real[day][i] end,
    OpenEvent = function(_, _, i) opened = i end,
}
assert(loadfile('CantPlayForever/Modules/Calendar/CalendarRange.lua'))('CantPlayForever', ns)
assert(loadfile('CantPlayForever/Modules/Calendar/CalendarDisplay.lua'))('CantPlayForever', ns)

assert(C_Calendar.GetNumDayEvents(0, 20) == 2, 'echter Termin plus Alarm')
local event = C_Calendar.GetDayEvent(0, 20, 2)
assert(event.title == 'Raid' and event.cpfAlarm and event.calendarType == 'SYSTEM', 'Alarm als Eintrag')
assert(event.startTime.hour == 19 and event.startTime.minute == 30, 'Ortszeit im Kalender: ' .. tostring(event.startTime.hour))
assert(event.iconTexture == nil, 'Symbol standardmaessig aus')
alarms[1].calendarIcon = true
assert(C_Calendar.GetDayEvent(0, 20, 2).iconTexture == 'tex', 'Symbol mit Haken')
alarms[1].calendarIcon = nil
local first = C_Calendar.GetDayEvent(0, 20, 1)
assert(first.title == 'Echt' and first.startTime.hour == 11 and first.startTime.minute == 15 and first.endTime.hour == 0, 'echter Termin in Ortszeit')
assert(real[20][1].startTime.hour == 10, 'Original unveraendert')
offset = 0
assert(C_Calendar.GetDayEvent(0, 20, 1).startTime.hour == 10 and C_Calendar.GetDayEvent(0, 20, 2).startTime.hour == 19, 'Serverzeit-Anzeige: keine Verschiebung')
offset = 3600
assert(C_Calendar.GetNumDayEvents(0, 21) == 0, 'andere Tage leer')
C_Calendar.OpenEvent(0, 20, 2)
assert(opened == nil and settings == 'alarms' and edited == 1, 'Klick oeffnet die Alarm-Optionen')
C_Calendar.OpenEvent(0, 20, 1)
assert(opened == 1, 'echte Termine unveraendert')

alarms[1].customEffect = true
Clock.GetAlarmEffectOverride = function(_, alarm) return alarm.customEffect and {} or nil end
Clock.GetEffectColorHex = function() return 'ff8000' end
assert(C_Calendar.GetDayEvent(0, 20, 2).title == '|cffff8000Raid|r', 'Alarmfarbe im Titel')
alarms[1].customEffect = nil

-- Tageswechsel durch die Zeitzone: 00:30 Ortszeit am 20.10. ist 23:30 Serverzeit am 19.10.
alarms[1].hour, alarms[1].minute = 0, 30
assert(C_Calendar.GetNumDayEvents(0, 19) == 1 and C_Calendar.GetNumDayEvents(0, 20) == 1, 'Tag wechselt')
alarms[1].hour, alarms[1].minute = 19, 30

-- Importierter Alarm: der echte Termin wird gekennzeichnet und zeigt zusaetzlich die Alarmzeit
real[20][1].eventID = 5
alarms[2].calendarKey = 'id:5'
alarms[2].hour, alarms[2].minute = 10, 45
local tagged = C_Calendar.GetDayEvent(0, 20, 1)
assert(tagged.title == 'Echt |cff63c9ff[Alarm 10:45]|r' and tagged.startTime.hour == 11, 'importierter Alarm gekennzeichnet: ' .. tagged.title)
alarms[2].calendarKey = 'x'
alarms[2].hour, alarms[2].minute = 8, 0
real[20][1].eventID = nil

-- Zeitraum: Einzelalarme immer, wiederholende nur so viele Tage im Voraus
Clock.db.profile.calLinkShowDays = 1
assert(C_Calendar.GetNumDayEvents(0, 20) == 2, 'Einzelalarm immer')
alarms[1].everyYear = true
assert(C_Calendar.GetNumDayEvents(0, 20) == 1, 'wiederholend ausserhalb des Zeitraums')
Clock.db.profile.calLinkShowDays = 2
assert(C_Calendar.GetNumDayEvents(0, 20) == 2, 'wiederholend innerhalb des Zeitraums')
Clock.db.profile.calLinkShowDays = nil
alarms[1].everyYear = nil
alarms[1].day = 10
assert(C_Calendar.GetNumDayEvents(0, 10) == 0, 'Vergangenheit ohne Alarm')
alarms[1].day = 20

-- Option Zeiten in Ortszeit aus: keine Verschiebung
Clock.db.profile.calLocalTimes = false
assert(C_Calendar.GetDayEvent(0, 20, 1).startTime.hour == 10, 'Option Ortszeit aus')
Clock.db.profile.calLocalTimes = nil

-- Aus: Fenster zu, Option aus, Classic Calendar da
visible = false
assert(C_Calendar.GetNumDayEvents(0, 20) == 1, 'Fenster zu')
visible = true
Clock.db.profile.calLinkShow = false
assert(C_Calendar.GetNumDayEvents(0, 20) == 1, 'Option aus')
Clock.db.profile.calLinkShow = nil
Clock.CalendarLinkAvailable = function() return true end
assert(C_Calendar.GetNumDayEvents(0, 20) == 1, 'mit Classic Calendar nicht doppelt')
Clock.CalendarLinkAvailable = nil
Clock.holidayScanning = true
assert(C_Calendar.GetNumDayEvents(0, 20) == 1, 'nicht beim Fest-Abgleich')
print('CalendarDisplay OK')
