-- Test der Strg-Details im Tooltip der Uhr (CalendarTooltip.lua).
local realOs = os
time = realOs.time
date = realOs.date
os = nil
local ctrl = false
IsControlKeyDown = function() return ctrl end
local alarms = {{id = 1, name = 'Raid', hour = 19, minute = 30, armed = true, alarmType = 'alarm'}}
local Clock = {db = {profile = {alarms = alarms}}, CalendarModuleOn = function() return true end,
    AlarmMinutesUntil = function() return 1500 end, DisplayTime = function(_, t) return t end}
local L = setmetatable({HOLIDAY_COUNTDOWN = '%dd %dh %dm', ALARM_TYPE_ALARM = 'Wecker', CALLINK_TYPE_MEETING = 'Treffen', CALLINK_TYPE_OTHER = 'Sonstiges',
    CALTIP_HINT = 'Strg: Details', CALTIP_ALARMS = 'Alarme im Detail', CALTIP_NEXT = 'in %s', CALTIP_CALENDAR = 'Kalender %d', CALTIP_BY = 'Ersteller: %s', CALTIP_MINE = 'Deine Zusage: %s',
    CALTIP_INVITES = '%d/%d/%d/%d', CALTIP_STATUS_AVAILABLE = 'Zugesagt', ALARM_FALLBACK = 'Alarm'}, {__index = function() return '' end})
local ns = {Clock = Clock, L = L, AlarmDisplayName = function(alarm) return alarm.name end}
C_DateAndTime = {GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18, hour = 12, minute = 0} end}
local listener = {RegisterEvent = function() end, SetScript = function(self, _, fn) self.fn = fn end}
function CreateFrame() return listener end
C_Timer = {After = function() end}
local opened
C_Calendar = {
    GetMonthInfo = function() return {year = 2026, month = 10} end, SetAbsMonth = function() end,
    OpenEvent = function(_, day, index) opened = {day, index}; listener.fn() return true end,
    GetEventInfo = function() return {description = 'Wir treffen uns am Eingang', creator = 'Sven'} end,
    GetNumInvites = function() return 3 end,
    EventGetInvite = function(i) return {inviteStatus = ({1, 2, 0})[i]} end,
    CloseEvent = function() end,
}
Clock.CalendarSource = function()
    return {GetDayEvents = function(year, month, day)
        if day ~= 19 then return {} end
        return {{title = 'Baustelle', kind = 'PLAYER', eventID = 9, index = 2, eventType = 'MEETING', inviteStatus = 1, invitedBy = 'Sven',
            start = {year = 2026, month = 10, day = 19, hour = 20, minute = 0}, nativeDate = {year = year, month = month, day = day}}}
    end}
end
assert(loadfile('CantPlayForever/Modules/Calendar/CalendarTooltip.lua'))('CantPlayForever', ns)

local lines = {}
local tip = {AddLine = function(_, text) lines[#lines + 1] = text end, AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. '|' .. b end}
Clock:AddCtrlHint(tip)
assert(lines[1] == '     Strg: Details', 'Hinweiszeile')
assert(Clock.CtrlDown() == false)
ctrl = true
assert(Clock.CtrlDown() == true)
lines = {}
Clock:AddCtrlAlarmDetails(tip, alarms[1])
local text = table.concat(lines, '\n')
assert(text:find('Wecker', 1, true) and text:find('in 1d 1h 0m', 1, true), 'Alarm-Details: ' .. text)
assert(not text:find('Raid', 1, true), 'Alarmzeile selbst bleibt unveraendert')
lines = {}
Clock:AddCtrlDetails(tip)
text = table.concat(lines, '\n')
assert(text:find('19.10. 20:00  Baustelle|Treffen', 1, true), 'Kalendereintrag: ' .. text)
assert(text:find('Ersteller: Sven', 1, true) and text:find('Deine Zusage: Zugesagt', 1, true), 'Ersteller und Zusage')
assert(opened and opened[1] == 19 and opened[2] == 2, 'Termin zum Einlesen geoeffnet')
assert(not Clock.calFetching, 'Einlesen fertig')
lines = {}
Clock:AddCtrlDetails(tip)
text = table.concat(lines, '\n')
assert(text:find('1/1/1/0', 1, true) or text:find('3/1/1/1', 1, true), 'Teilnehmer: ' .. text)
assert(text:find('Wir treffen uns am Eingang', 1, true), 'Beschreibung')
-- importierter Alarm zeigt die Termin-Details darunter
local imported = {id = 2, name = 'Baustelle', calendarKey = 'id:9', calendarEventType = 'MEETING', armed = true}
lines = {}
Clock:AddCtrlAlarmDetails(tip, imported)
text = table.concat(lines, '\n')
assert(text:find('Treffen', 1, true) and text:find('Ersteller: Sven', 1, true) and text:find('Wir treffen uns am Eingang', 1, true), 'Details am importierten Alarm: ' .. text)
print('CalendarTooltip OK')
