-- Jahres-Einlesen: rollierende 12 Monate, naechster Termin je Fest, Schutz vor Dazwischenfunken.
local ns = {T = {HOLIDAY_TIP_ICON_SIZE = 24, HOLIDAY_TIP_ICON_Y = 0}, Clock = {IsModuleEnabled = function() return true end, db = {profile = {}, global = {}}, RegisterModule = function() end,
    NotifyOptions = function() end, GuardedTick = function(_, _, fn) fn() end, UpdateBadges = function() end}, L = {}}
local Clock = ns.Clock
function CreateFrame() return {RegisterEvent = function() end, SetScript = function() end} end
function GetLocale() return 'deDE' end
C_Timer = {After = function(_, fn) fn() end}
local viewed = {}
local current
local function Ev(id, title, icon, sy, sm, sd, ey, em, ed)
    return {calendarType = 'HOLIDAY', eventID = id, title = title, iconTexture = icon,
        startTime = {year = sy, month = sm, monthDay = sd, hour = 4, minute = 0},
        endTime = {year = ey, month = em, monthDay = ed, hour = 4, minute = 0}}
end
local function Start(e) e.sequenceType = 'START'; return e end
-- Monat (yyyy*100+mm) -> Tag -> Eintraege
local calendar = {
    [202610] = {[10] = {Start(Ev(324, 'Schlotternaechte', 1, 2026, 10, 10, 2026, 11, 2))},
        [18] = {Ev(324, 'Schlotternaechte', 9, 2026, 10, 10, 2026, 11, 2), Ev(1841, 'Zu den Waffen', nil, 2026, 10, 17, 2026, 10, 20)}},
    [202612] = {[16] = {Ev(141, 'Winterhauchfest', 2, 2026, 12, 16, 2027, 1, 2)}, [23] = {Ev(141, 'Winterhauchfest', 2, 2026, 12, 16, 2027, 1, 2)}},
    [202701] = {[1] = {Ev(141, 'Winterhauchfest', 2, 2026, 12, 16, 2027, 1, 2)}},
    [202706] = {[21] = {Ev(327, 'Sonnenwende', 3, 2027, 6, 21, 2027, 7, 5)}},
    [202710] = {[18] = {Ev(324, 'Schlotternaechte', 1, 2027, 10, 18, 2027, 11, 2)}},
}
C_DateAndTime = {GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18, hour = 4, minute = 0} end}
C_Calendar = {
    OpenCalendar = function() end,
    SetAbsMonth = function(m, y) current = y * 100 + m; viewed[#viewed + 1] = current end,
    GetMonthInfo = function() return {numDays = 31} end,
    GetNumDayEvents = function(_, day) return #((calendar[current] or {})[day] or {}) end,
    GetDayEvent = function(_, day, i) return calendar[current][day][i] end,
}
assert(loadfile('CantPlayForever/Modules/Clock/Holidays.lua'))('CantPlayForever', ns)
Clock:ScanHolidayYear()
assert(viewed[1] == 202609 and viewed[14] == 202710, 'rollierend: ab Vormonat bis Okt 2027')
assert(viewed[#viewed] == 202610, 'Ansicht zurueck auf den aktuellen Monat')
local catalog = Clock.db.global.holidayCatalog
assert(catalog[141].startTime.monthDay == 16 and catalog[327] and catalog[324].startTime.year == 2026,
    'naechster Termin je Fest, nicht der spaetere')
ns.L.CALENDAR_TAB, ns.L.HOLIDAY_COUNTDOWN = 'Kalender', '%d Tage %d Stunden %d Minuten'
local nextHoliday, seconds = Clock:GetNextHoliday()
assert(nextHoliday.title == 'Winterhauchfest' and seconds == 59 * 86400, 'naechstes Fest im Jahr, nicht das heutige: ' .. tostring(seconds))
assert(catalog[324].icon == 1 and catalog[324].iconFromStart, 'Symbol vom Starttag, nicht vom Folgetag')
Clock:ScanHolidays()
local running = Clock:GetActiveHolidays()
assert(#running == 1 and running[1].icon == 1, 'laufendes Fest zeigt das Startsymbol: ' .. tostring(running[1] and running[1].icon))
assert(Clock:GetBadgeIcon() == 1)
assert(Clock:AutoScanHolidayYear() == nil)
print('Holidays year OK')
