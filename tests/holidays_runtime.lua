-- Test des Fest-Abgleichs (Holidays.lua) mit gemocktem Kalender.
local updates = 0
local registered, notified = {}, 0
local moduleOn = true
local Clock = {IsModuleEnabled = function() return moduleOn end, db = {profile = {}, global = {}}, RegisterModule = function(_, def) registered[#registered + 1] = def end,
    NotifyOptions = function() notified = notified + 1 end, GuardedTick = function(_, _, fn) fn() end, UpdateBadges = function() updates = updates + 1 end}
local ns = {Clock = Clock, T = {HOLIDAY_TIP_ICON_SIZE = 24, HOLIDAY_TIP_ICON_Y = 0, HOLIDAY_GENERIC_ICON = 'generic', HOLIDAY_ICON_SIZE = 28},
    HOLIDAY_STYLES = {[123] = {HOLIDAY_ICON_SIZE = 30}}, L = {HOLIDAYS_TAB = 'Feste', CALENDAR_TAB = 'Kalender'}}
function CreateFrame() return {RegisterEvent = function() end, SetScript = function() end} end
function GetLocale() return 'deDE' end
local setCalls = 0
local events = {
    {calendarType = 'PLAYER', title = 'Gilde'},
    {calendarType = 'HOLIDAY', eventID = 324, title = 'Schlotternächte', iconTexture = 123,
     startTime = {year = 2026, month = 10, monthDay = 18}, endTime = {year = 2026, month = 11, monthDay = 1}},
}
C_DateAndTime = {GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18} end}
C_Calendar = {
    GetNumDayEvents = function() return #events end,
    GetDayEvent = function(_, _, i) return events[i] end,
    SetAbsMonth = function() setCalls = setCalls + 1; if setCalls < 50 then Clock:ScanHolidays() end end,
    GetMonthInfo = function() return {month = 9, year = 2026} end,
}
assert(loadfile('CantPlayForever/Modules/Clock/Holidays.lua'))('CantPlayForever', ns)
assert(#Clock:GetActiveHolidays() == 0)
Clock:ScanHolidays()
assert(setCalls == 1, 'SetAbsMonth loest keine Rekursion aus: ' .. setCalls)
local list = Clock:GetActiveHolidays()
assert(#list == 1 and list[1].title == 'Schlotternächte' and list[1].icon == 123, 'nur HOLIDAY-Eintraege')
assert(updates == 1)
Clock:ScanHolidays()
assert(updates == 1, 'unveraenderte Liste loest kein Update aus')
assert(Clock:FormatHolidayDate(list[1].endTime) == '01.11.2026')
local lines = {}
local tip = {AddLine = function(_, t) lines[#lines + 1] = t end, AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. '=' .. b end}
events[3] = {calendarType = 'HOLIDAY', title = 'Zu den Waffen'}
Clock:ScanHolidays()
assert(#Clock:GetActiveHolidays() == 1 and Clock:GetBadgeIcon() == 123, 'Fest ohne Symbol zaehlt nicht')
-- Anzeige: Overlay / beides / Symbol
ns.HOLIDAY_OVERLAYS = {[123] = 'overlay'}
Clock.db.profile.holidayDisplay = 'both'
assert(Clock:GetBadgeIcon() == 123 and Clock:GetOverlayIcon() == 123)
Clock.db.profile.holidayDisplay = 'overlay'
assert(Clock:GetBadgeIcon() == nil and Clock:GetOverlayIcon() == 123, 'nur Overlay: kein Symbol')
Clock.db.profile.holidayDisplay = 'icon'
assert(Clock:GetBadgeIcon() == 123 and Clock:GetOverlayIcon() == nil, 'nur Symbol: kein Overlay')
-- zwei laufende Feste: das erste ohne, das zweite mit Overlay -> kein Symbol bei "Nur Overlay"
local savedThird, updatesBeforeSecond = events[3], updates
events[3] = {calendarType = 'HOLIDAY', eventID = 11, title = 'Zweites Fest', iconTexture = 125,
    startTime = {year = 2026, month = 10, monthDay = 18}, endTime = {year = 2026, month = 11, monthDay = 1}}
ns.HOLIDAY_OVERLAYS = {[125] = 'overlay2'}
Clock.db.profile.holidayDisplay = 'overlay'
Clock:ScanHolidays()
assert(#Clock:GetActiveHolidays() == 2 and Clock:GetOverlayIcon() == 125 and Clock:GetBadgeIcon() == nil,
    'Overlay des zweiten Festes ersetzt das Symbol')
events[3] = savedThird
Clock.db.global.holidayCatalog[11] = nil
Clock:ScanHolidays()
updates = updatesBeforeSecond
ns.HOLIDAY_OVERLAYS = {}
Clock.db.profile.holidayDisplay = 'overlay'
assert(Clock:GetBadgeIcon() == 123, 'ohne Overlay fuer das Fest bleibt das Symbol')
Clock.db.profile.holidayDisplay = nil
-- Countdown: Winterhauchfest im Katalog, 'jetzt' = 18.10.2026 04:00
Clock.db.global.holidayCatalog[141] = {title = 'Winterhauchfest', icon = 456,
    startTime = {year = 2026, month = 12, monthDay = 23, hour = 4, minute = 0}}
ns.L.CALENDAR_TAB, ns.L.HOLIDAY_COUNTDOWN = 'Kalender', '%d Tage %d Stunden %d Minuten'
C_DateAndTime.GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18, hour = 4, minute = 0} end
local nextEntry, secs = Clock:GetNextHoliday()
assert(nextEntry.title == 'Winterhauchfest' and secs == 66 * 86400, secs)
lines = {}
Clock:AddCalendarLines(tip)
assert(lines[1] == ' ' and lines[2] == 'Kalender' and lines[3]:find('Schlotternächte', 1, true)
    and lines[3]:find('=18.10.2026 - 01.11.2026', 1, true), lines[3]) -- Datum rechts neben dem Namen
assert(lines[4]:find('Winterhauchfest', 1, true) and lines[4]:find('=23.12.2026 04:00', 1, true), lines[4]) -- ohne Enddatum nur der Beginn
assert(lines[5]:find('66 Tage 0 Stunden 0 Minuten', 1, true) and not lines[5]:find('Winterhauchfest', 1, true), lines[5]) -- Countdown in der zweiten Zeile
assert(Clock:FormatHolidayRange({year = 2026, month = 10, monthDay = 18, hour = 4, minute = 0},
    {year = 2026, month = 11, monthDay = 2, hour = 4, minute = 0}) == '18.10.2026 - 02.11.2026', 'mehrtaegig ohne Uhrzeit')
assert(Clock:FormatHolidayRange({year = 2026, month = 10, monthDay = 18, hour = 14, minute = 0},
    {year = 2026, month = 10, monthDay = 18, hour = 16, minute = 30}) == '18.10.2026 14:00 - 16:30')
assert(Clock:FormatHolidayRange({year = 2026, month = 10, monthDay = 18, hour = 0, minute = 0},
    {year = 2026, month = 10, monthDay = 18, hour = 0, minute = 0}) == '18.10.2026')
ns.L.HOLIDAY_UNTIL, ns.L.HOLIDAY_OCLOCK = 'bis', ' Uhr'
assert(Clock:FormatHolidayGameRange({year = 2026, month = 10, monthDay = 18, hour = 4, minute = 0},
    {year = 2026, month = 10, monthDay = 20, hour = 4, minute = 0}) == '18.10.2026 - 4:00 Uhr bis 20.10.2026 - 4:00 Uhr')
Clock.db.profile.holidayHidden = {[141] = true}
assert(Clock:GetNextHoliday() == nil)
Clock.db.profile.holidayHidden = nil
lines = {}
-- Einstellungen je Symbol: Symbolwerte vor allgemeinen; in der Vorschau gelten die allgemeinen
assert(Clock:HolidayValue(123, 'HOLIDAY_ICON_SIZE') == 30 and Clock:HolidayValue(999, 'HOLIDAY_ICON_SIZE') == 28)
Clock.holidayPreview = true
assert(Clock:HolidayValue(123, 'HOLIDAY_ICON_SIZE') == 28)
Clock.holidayPreview = nil
-- Katalog und Optionen
assert(Clock.db.global.holidayCatalog[324].title == 'Schlotternächte' and not Clock.db.global.holidayCatalog[1841])
assert(registered[1].id == 'calendar' and not registered[1].locked and not registered[1].hidden)
local group = registered[1].GetOptions()
local toggle = group.args.holidays.args.h324
assert(group.args.enabled and toggle and toggle.image == 123 and toggle.get() == true)
-- AceConfigRegistry erlaubt bei toggle nur diese Felder (kein imageWidth/imageHeight)
local allowed = {type = 1, name = 1, desc = 1, order = 1, width = 1, get = 1, set = 1, image = 1, imageCoords = 1,
    disabled = 1, hidden = 1, tristate = 1}
for key in pairs(toggle) do assert(allowed[key], 'unbekannter toggle-Parameter: ' .. key) end
toggle.set(nil, false)
assert(#Clock:GetActiveHolidays() == 0 and toggle.get() == false, 'abgehakt = ausgeblendet')
toggle.set(nil, true)
assert(#Clock:GetActiveHolidays() == 1)
-- Fest ohne Symbol: nicht in der Uhr, aber im Tooltip am Ingame-Kalender (alle Eintraege)
events[3] = {calendarType = 'HOLIDAY', eventID = 9, title = 'Zu den Waffen',
    startTime = {year = 2026, month = 10, monthDay = 17}, endTime = {year = 2026, month = 10, monthDay = 19}}
Clock:ScanHolidays()
assert(#Clock.todayAll == 2 and #Clock:GetActiveHolidays() == 1)
-- Dunkelmond-Jahrmarkt: kein Kalendersymbol, wird an ID/Name erkannt und bekommt sein Overlay
local updatesBeforeDmf, savedOverlays = updates, ns.HOLIDAY_OVERLAYS
ns.HOLIDAY_OVERLAYS = {darkmoon = 'dmf'}
ns.HOLIDAY_OVERLAY_MATCH = {darkmoon = {ids = {[479] = true}, names = {'dunkelmond', 'darkmoon'}}}
local savedGeneric = ns.T.HOLIDAY_GENERIC_ICON
ns.T.HOLIDAY_GENERIC_ICON = 'Interface\\Icons\\Generic'
events[4] = {calendarType = 'HOLIDAY', eventID = 479, title = 'Dunkelmond-Jahrmarkt',
    startTime = {year = 2026, month = 10, monthDay = 18}, endTime = {year = 2026, month = 10, monthDay = 25}}
Clock:ScanHolidays()
local dmf
for _, holiday in ipairs(Clock:GetActiveHolidays()) do if holiday.title == 'Dunkelmond-Jahrmarkt' then dmf = holiday end end
assert(dmf and dmf.overlay == 'darkmoon' and Clock:GetOverlayIcon() == 'darkmoon', 'Dunkelmond erkannt')
assert(Clock:IconTexture(dmf.icon) == 'Interface\\Icons\\Generic', 'Symbol ohne Kalendersymbol: allgemeines Symbol')
events[4] = nil
ns.T.HOLIDAY_GENERIC_ICON = savedGeneric
ns.HOLIDAY_OVERLAYS = savedOverlays
Clock:ScanHolidays()
updates = updatesBeforeDmf
local updatesBeforeTimed = updates
-- Termin mit Uhrzeit (14-16 Uhr): nach dem Ende nicht mehr anzeigen
events[4] = {calendarType = 'HOLIDAY', eventID = 10, title = 'Anglerwettbewerb', iconTexture = 124,
    startTime = {year = 2026, month = 10, monthDay = 18, hour = 14, minute = 0},
    endTime = {year = 2026, month = 10, monthDay = 18, hour = 16, minute = 0}}
local realTime = C_DateAndTime.GetCurrentCalendarTime
C_DateAndTime.GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18, hour = 15, minute = 0} end
Clock:ScanHolidays()
assert(#Clock.todayAll == 3, 'laeuft noch um 15 Uhr')
C_DateAndTime.GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18, hour = 16, minute = 1} end
Clock:ScanHolidays()
assert(#Clock.todayAll == 2 and #Clock:GetActiveHolidays() == 1, 'nach 16 Uhr nicht mehr angezeigt')
events[4] = nil
Clock.db.global.holidayCatalog[10] = nil
C_DateAndTime.GetCurrentCalendarTime = realTime
Clock:ScanHolidays()
updates = updatesBeforeTimed -- Zaehler der Zeitprobe nicht mitrechnen
local gameLines = {}
local gameTip = {AddLine = function(_, t) gameLines[#gameLines + 1] = t end, AddDoubleLine = function(_, a, b) gameLines[#gameLines + 1] = a .. '=' .. b end}
Clock:AddCalendarLines(gameTip, 'game')
assert(gameLines[1] == ' ' and gameLines[2] == 'Kalender' and gameLines[3]:find('Schlotternächte', 1, true)
    and gameLines[5] == 'Zu den Waffen', 'Ingame-Tooltip: alle heutigen Eintraege')
-- unabhaengig von den Uhr-Einstellungen, aber nicht bei ausgeschaltetem Modul
Clock.db.profile.holidaySymbol = false
gameLines = {}
Clock:AddCalendarLines(gameTip, 'game')
assert(#gameLines > 0, 'Ingame-Tooltip gilt auch bei ausgeschaltetem Kalender-Symbol')
gameLines = {}
Clock:AddCalendarLines(gameTip)
assert(#gameLines == 0, 'Uhr-Tooltip folgt dem Schalter')
assert(Clock:GetBadgeIcon() == nil, 'Symbol aus')
Clock.db.profile.holidaySymbol = nil
moduleOn = false
gameLines = {}
Clock:AddCalendarLines(gameTip, 'game')
assert(#gameLines == 0 and Clock:GetBadgeIcon() == nil, 'Modul aus: kein Tooltip, kein Symbol')
moduleOn = true
-- Symbol-Regeln: laeuft ein angehaktes Fest -> dessen Symbol; keins, aber sichtbare Feste -> allgemein;
-- alle abgehakt -> kein Symbol
Clock.db.profile.holidayHidden = {[324] = true}
assert(Clock:GetBadgeIcon() == 'generic', 'laufendes Fest abgehakt: allgemeines Symbol')
Clock.db.global.holidayCatalog[141] = nil
assert(Clock:GetBadgeIcon() == nil, 'alle bekannten Feste abgehakt: kein Symbol')
Clock.db.profile.holidayHidden = nil
events[3] = nil
events[2] = nil
Clock:ScanHolidays()
assert(#Clock:GetActiveHolidays() == 0 and updates == 4)
CalendarFrame = {IsShown = function() return true end}
events[1] = {calendarType = 'HOLIDAY', title = 'X'}
Clock:ScanHolidays()
assert(#Clock:GetActiveHolidays() == 0, 'bei offenem Kalender unveraendert')
C_Calendar = nil
Clock:ScanHolidays()
print('Holidays OK')
