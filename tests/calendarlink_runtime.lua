-- Test der Verbindung zu Classic Calendar (CalendarLink.lua) mit gemockter API.
local realOs = os
time = realOs.time
date = realOs.date
unpack = unpack or table.unpack
os = nil -- im Spiel gibt es kein os; nur time/date
local registered, notified = {}, 0
local Clock = {IsModuleEnabled = function() return true end, db = {profile = {alarms = {}, nextAlarmID = 5, useLocalTime = false}, global = {}},
    RegisterModule = function(_, def) registered[#registered + 1] = def end, NotifyOptions = function() notified = notified + 1 end,
    GuardedTick = function(_, _, fn) fn() end, GetToday = function() return 1, 2026, 10, 18 end,
    SetAlarmCustomEffect = function(_, alarm, on) alarm.customEffect = on; alarm.effect = {} end,
    SetEffectSettingForConfig = function(_, _, config, field, r, g, b) config[field] = {r, g, b} end,
    AlarmRunsToday = function(_, alarm) return alarm.day == 18 end, Print = function() end}
local ns = {Clock = Clock, T = {}, L = {ALARM_GENERIC = 'Alarm', CALLINK_TAB = 'CC', CALENDAR_TAB = 'Kalender', CALLINK_IMPORTED = '%d', CALLINK_REMOVED_TAG = 'Im Kalender gelöscht', CALLINK_REMOVED_ALARM = 'Alarm wird gelöscht', CALLINK_REMOVED_DONE = '%d', CALLINK_INSTALLED = 'CC installiert', CALLINK_INFO = 'Text', CALLINK_SERVER_TIME = 'Serverzeit', CALLINK_LOCAL_TIME = 'Ortszeit', CALLINK_ALARM_AT = 'Alarm am', CALLINK_TYPE_OTHER = 'Sonstiges', CALLINK_TYPE_RAID = 'Raid', CALLINK_UPDATE = 'Aktualisierung', CALLINK_CHANGE_START = 'Beginn', CALLINK_CHANGE_END = 'Ende', CALLINK_CHANGE_KIND = 'Art', CALLINK_TYPE_MEETING = 'Treffen'},
    Now = function() return 1800000000 end,
    AlarmRunsOnDay = function(alarm, ahead, year, month, day)
        local at = date('*t', time({year = year, month = month, day = day, hour = 12}) + ahead * 86400)
        return at.day == alarm.day and at.month == alarm.month
    end,
    AlarmTypeTexture = function(alarm) return 'tex-' .. tostring(alarm.alarmType or 'alarm') end,
    AlarmDisplayName = function(alarm) return alarm.name end}
function CreateFrame() return {RegisterEvent = function() end, SetScript = function() end} end
function GetLocale() return 'deDE' end
C_DateAndTime = {GetCurrentCalendarTime = function() return {year = 2026, month = 10, monthDay = 18, hour = 12, minute = 0} end}
assert(loadfile('CantPlayForever/Modules/Calendar/CalendarRange.lua'))('CantPlayForever', ns)
assert(loadfile('CantPlayForever/Modules/Calendar/Holidays.lua'))('CantPlayForever', ns)
assert(loadfile('CantPlayForever/Modules/Calendar/CalendarLink.lua'))('CantPlayForever', ns)

assert(not Clock:CalendarLinkAvailable(), 'ohne Classic Calendar nicht verfuegbar')
local alarms = Clock.db.profile.alarms
alarms[1] = {id = 1, uid = 'abc', name = 'Raid', hour = 19, minute = 30, day = 20, month = 10, year = 2026, enabled = true}
alarms[2] = {id = 2, name = 'Heute', hour = 8, minute = 15, day = 18, month = 10, year = 2026, enabled = true}

-- Alarme im Kalender
local added, cleared, dayEvents, store = {}, 0, {}, {}
local function Snapshot()
    added = {}
    for _, event in pairs(store) do added[#added + 1] = event end
end
ClassicCalendar = {API = {
    AddEvents = function(_, list) cleared = cleared + 1; for _, event in ipairs(list) do store[event.key] = event end; Snapshot(); return {}, {} end,
    RemoveEvent = function(_, key) cleared = cleared + 1; store[key] = nil; Snapshot() end,
    ClearEvents = function() cleared = cleared + 1; store = {}; Snapshot() end,
    GetEvents = function() local out = {}; for key, event in pairs(store) do out[#out + 1] = {key = key, title = event.title, icon = event.icon, start = event.start} end; return out end,
    GetDayEvents = function(y, m, d) return dayEvents[y * 10000 + m * 100 + d] or {} end,
}}
assert(Clock:CalendarLinkAvailable())
Clock:SyncCalendarLink(true)
assert(#added == 2, 'zwei Alarme, je ein Termin im Horizont: ' .. #added)
local raid
for _, event in ipairs(added) do if event.title == 'Raid' then raid = event end end
assert(raid.icon == nil, 'Symbol ist standardmaessig aus')
alarms[1].calendarIcon = true
Clock:SyncCalendarLink(true)
for _, event in ipairs(added) do if event.title == 'Raid' then raid = event end end
assert(raid.icon == 'tex-alarm', 'Alarmtyp-Symbol am Kalendertermin')
alarms[1].calendarIcon = nil
Clock:SyncCalendarLink(true)
assert(raid and raid.key == 'abc#20261020' and raid.start.day == 20 and raid.start.hour == 19 and raid.start.minute == 30)
local before = cleared
Clock:SyncCalendarLink()
assert(cleared == before, 'unveraendert: kein erneutes Schreiben')
alarms[1].hour = 20
Clock:SyncCalendarLink()
assert(cleared == before + 1, 'geaendert: nur dieser Termin neu geschrieben, kein Neuaufbau')
assert(Clock:AlarmFromCalendarKey('abc#20261020') == alarms[1] and Clock:AlarmFromCalendarKey('zzz#20261020') == nil, 'Rueckwaerts: Alarm zur Kennung')
local removedAlarm = table.remove(alarms, 1)
Clock:SyncCalendarLink()
assert(store['abc#20261020'] == nil and #added == 1, 'geloeschter Alarm: Termin verwaist und entfernt')
table.insert(alarms, 1, removedAlarm)
alarms[1].hour = 19
Clock:SyncCalendarLink()
-- Ortszeit +2 h: Kalender (Server) 17:30 fuer Alarm 19:30
Clock.db.profile.useLocalTime = true
local realDate = date
date = function(fmt, at) if at then return realDate(fmt, at) end return {year = 2026, month = 10, day = 18, hour = 14, min = 0} end
alarms[1].hour = 19
Clock:SyncCalendarLink(true)
for _, event in ipairs(added) do if event.title == 'Raid' then raid = event end end
assert(raid.start.hour == 17 and raid.start.minute == 30, 'Server = Ortszeit - 2 h: ' .. raid.start.hour)
Clock.db.profile.useLocalTime = false
Clock.db.profile.calLinkShow = false
Clock:SyncCalendarLink()
assert(cleared >= before + 3, 'Option aus: Termine entfernt')
Clock.db.profile.calLinkShow = true

-- Einzelner Alarm vom Kalender ausgenommen
alarms[1].inCalendar = false
Clock:SyncCalendarLink()
for _, event in ipairs(added) do assert(event.title ~= 'Raid', 'Alarm ohne Haken nicht im Kalender') end
alarms[2].inCalendar = false
alarms[1].inCalendar, alarms[2].inCalendar = nil, nil
Clock:SyncCalendarLink()

-- Symbol je Alarm abschaltbar
alarms[1].calendarIcon = false
Clock:SyncCalendarLink()
for _, event in ipairs(added) do if event.title == 'Raid' then assert(event.icon == nil, 'ohne Haken kein Symbol am Termin') end end
alarms[1].calendarIcon = true
Clock:SyncCalendarLink()
for _, event in ipairs(added) do if event.title == 'Raid' then assert(event.icon == 'tex-alarm', 'Symbol wieder da') end end

-- Neuer Alarm: gebuendelter Abgleich kurz nach NotifyOptions
local queued = {}
C_Timer = {After = function(_, fn) queued[#queued + 1] = fn end}
alarms[#alarms + 1] = {id = 9, name = 'Neu', hour = 7, minute = 0, day = 21, month = 10, year = 2026, enabled = true}
Clock:QueueCalendarLinkSync(); Clock:QueueCalendarLinkSync()
assert(#queued == 1, 'mehrere Aenderungen: ein Abgleich')
queued[1]()
local found
for _, event in ipairs(added) do if event.title == 'Neu' then found = true end end
assert(found, 'neuer Alarm steht sofort im Kalender')
C_Timer = nil
alarms[#alarms] = nil
Clock:SyncCalendarLink(true)

-- Import: nur auf Knopfdruck, nicht doppelt, nur Spieler-Termine mit Uhrzeit
dayEvents[20261019] = {
    {title = 'Gildenraid', kind = 'GUILD_EVENT', eventType = 'RAID', start = {year = 2026, month = 10, day = 19, hour = 20, minute = 0}},
    {title = 'Fest', kind = 'HOLIDAY', start = {year = 2026, month = 10, day = 19, hour = 0, minute = 0}},
    {title = 'Eigen', kind = 'SYSTEM', source = "Can't play Forever", start = {year = 2026, month = 10, day = 19, hour = 9, minute = 0}},
}
-- Frage nach der Anmeldung: einmalig, nur bei neuen/geaenderten Terminen
local shown, opened = {}, nil
StaticPopupDialogs = {}
StaticPopup_Show = function(name, text) shown[#shown + 1] = {name = name, text = text} end
Clock.OpenSettings = function(_, ...) opened = {...} end
ns.L.CALLINK_PROMPT, ns.L.CALLINK_PROMPT_YES, ns.L.CALLINK_PROMPT_LATER = '%d Termine', 'Ja', 'Spaeter'
InCombatLockdown = function() return true end
assert(Clock:AskCalendarImport() == false and #shown == 0 and not Clock.calLinkAsked, 'im Kampf: spaeter erneut')
InCombatLockdown = function() return false end
assert(Clock:AskCalendarImport() == true and #shown == 1 and shown[1].name == 'CPF_CALENDAR_IMPORT', 'Frage erscheint')
assert(Clock:AskCalendarImport() == nil and #shown == 1, 'nur einmal pro Anmeldung')
StaticPopupDialogs.CPF_CALENDAR_IMPORT.OnAccept()
assert(opened[1] == 'calendar' and opened[2] == 'calendarLink' and Clock.calLinkChecked and #Clock.calLinkCandidates > 0, 'Ja oeffnet die Auswahl')
Clock.calLinkChecked, Clock.calLinkCandidates = nil, nil

local count = #alarms
local candidates = Clock:CollectCalendarEvents()
assert(#candidates == 1 and candidates[1].title == 'Gildenraid' and candidates[1].when.minute == 45, 'ein Kandidat, Vorlauf 15 min')
assert(#alarms == count, 'Sammeln legt nichts an')
assert(Clock:ImportCalendarAlarms({}) == 0 and #alarms == count, 'nichts gewaehlt, nichts angelegt')
assert(Clock:ImportCalendarAlarms(candidates) == 1, 'gewaehlter Termin wird Alarm')
local made = alarms[count + 1]
assert(made.customEffect == true and made.effect.color[1] == 1 and made.effect.color[3] < 0.2, 'Raid: orange Alarmfarbe')
assert(made.name == 'Gildenraid' and made.hour == 19 and made.minute == 45 and made.day == 19 and made.month == 10 and made.armed and not made.repeating and made.alarmType == 'calendar')
assert(#Clock:CollectCalendarEvents() == 0 and #alarms == count + 1, 'nicht doppelt')
Clock:SyncCalendarLink(true)
for _, event in ipairs(added) do assert(event.title ~= 'Gildenraid', 'importierter Alarm wird nicht zurueckgespiegelt') end
-- Auswahl-Maske in den Optionen
dayEvents[20261019][#dayEvents[20261019] + 1] = {title = 'Zweiter', kind = 'PLAYER', start = {year = 2026, month = 10, day = 19, hour = 21, minute = 0}}
local options = Clock:CalendarLinkOptions()
assert(options.hidden() == false, 'Reiter sichtbar mit API')
C_AddOns = {GetAddOnMetadata = function() return 'ClassicCalendar-v1.8.0' end}
assert(options.args.installed.name() == 'CC installiert  |cff33ff33v1.8.0|r', 'Version in Gruen: ' .. options.args.installed.name())
assert(options.args.info.order < options.args.import.order and options.args.import.order < options.args.lead.order, 'Reihenfolge')
local choose = options.args.choose
assert(choose.hidden() == true, 'Maske zu bis zum Knopf')
options.args.import.func()
assert(choose.hidden() == false and choose.args.e1.hidden() == false and choose.args.e2.hidden() == true, 'ein neuer Termin (Gildenraid ist schon Alarm)')
assert(choose.args.e1.name() == 'Zweiter' and choose.args.e1.get() == true, 'Zeile 1: Haken und Name, vorgewaehlt')
local label = choose.args.d1.name()
assert(label:find('[Sonstiges]', 1, true) and label:find('19.10.2026 21:00 (Serverzeit)', 1, true), label)
assert(label:find('|cffffd100Alarm am: 19.10.2026 20:45 (Serverzeit)|r', 1, true), 'Zeile 2: Alarm in Alarmfarbe: ' .. label)
choose.args.none.func()
assert(choose.args.run.disabled() == true, 'nichts gewaehlt: Knopf aus')
choose.args.all.func()
local countNow = #alarms
choose.args.run.func()
assert(#alarms == countNow + 1 and alarms[#alarms].name == 'Zweiter' and choose.hidden() == true, 'Auswahl uebernommen, Maske zu')
-- Termin mit eventID: Verschiebung und Umbenennung aktualisieren denselben Alarm
dayEvents[20261019][#dayEvents[20261019] + 1] = {title = 'Baustelle', kind = 'PLAYER', eventID = 77, eventType = 'MEETING',
    start = {year = 2026, month = 10, day = 19, hour = 10, minute = 0}}
Clock:CollectCalendarEvents()
local fresh = Clock:CollectCalendarEvents()
local baustelle
for _, item in ipairs(fresh) do if item.key == 'id:77' then baustelle = item end end
assert(baustelle and not baustelle.update, 'neuer Termin mit eventID')
Clock:ImportCalendarAlarms({baustelle})
local total = #alarms
for _, item in ipairs(Clock:CollectCalendarEvents()) do assert(item.key ~= 'id:77', 'unveraendert: nicht erneut angeboten') end
local ev = dayEvents[20261019][#dayEvents[20261019]]
ev.title, ev.start.hour = 'Baustelle Nord', 11
local changed
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.key == 'id:77' then changed = item end end
assert(changed and changed.update, 'Aenderung wird als Aktualisierung angeboten')
Clock.calLinkCandidates = {changed}
local info = Clock:CalendarLinkOptions().args.choose.args.e1.name()
assert(info:find('Baustelle Nord', 1, true) and info:find('|cff63c9ff[Aktualisierung: Baustelle -> Baustelle Nord, Beginn 19.10. 10:00 -> 19.10. 11:00]|r', 1, true), 'blaue Aenderungsinfo: ' .. info)
Clock.calLinkCandidates = nil
assert(Clock:ImportCalendarAlarms({changed}) == 1 and #alarms == total, 'derselbe Alarm, kein neuer')
local alarm77
for _, a in ipairs(alarms) do if a.calendarKey == 'id:77' then alarm77 = a end end
assert(alarm77.name == 'Baustelle Nord' and alarm77.hour == 10 and alarm77.minute == 45 and alarm77.armed, 'Alarm aktualisiert: ' .. alarm77.hour)
-- Auch die Terminart (oder Ende/Art) loest eine Aktualisierung aus; die Alarmfarbe folgt der Terminart
ev.eventType = 'RAID'
local typed
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.key == 'id:77' then typed = item end end
assert(typed and typed.update and typed.changes[1] == 'type' and #typed.changes == 1, 'Typ-Aenderung erkannt')
Clock:ImportCalendarAlarms({typed})
assert(alarm77.calendarEventType == 'RAID' and alarm77.effect.color[1] == 1 and alarm77.effect.color[3] < 0.2, 'Alarmfarbe folgt dem Typ')
for _, item in ipairs(Clock:CollectCalendarEvents()) do assert(item.key ~= 'id:77', 'danach unveraendert') end
ev.finish = {year = 2026, month = 10, day = 19, hour = 12, minute = 30}
typed = nil
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.key == 'id:77' then typed = item end end
assert(typed and typed.changes[1] == 'finish', 'geaendertes Ende erkannt')
Clock:ImportCalendarAlarms({typed})

-- Tooltip der Uhr: importierter Alarm zeigt den Termin in Orts- und Serverzeit
ns.L.CALLINK_TOOLTIP_EVENT = '%02d.%02d. %02d:%02d lokal (%02d:%02d Server)'
local eventLine = Clock:ImportedAlarmEventText(alarm77)
assert(eventLine and eventLine:find('Server)', 1, true), 'Terminzeile fuer importierten Alarm: ' .. tostring(eventLine))
assert(Clock:ImportedAlarmEventText(alarms[1]) == nil, 'normaler Alarm: keine Terminzeile')

-- Geloeschter Termin: der Alarm wird zum Loeschen angeboten und beim Import entfernt
table.remove(dayEvents[20261019], #dayEvents[20261019])
local gone
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.removed and item.key == 'id:77' then gone = item end end
assert(gone and gone.remove == alarm77, 'geloeschter Termin erkannt')
Clock.calLinkCandidates = {gone}
local removedText = Clock:CalendarLinkOptions().args.choose.args.e1.name()
assert(removedText:find('Im Kalender', 1, true) or removedText:find('Baustelle', 1, true), 'Zeile fuer geloeschten Termin')
Clock.calLinkCandidates = nil
local countBefore = #alarms
local createdCount, dropped = Clock:ImportCalendarAlarms({gone})
assert(createdCount == 0 and dropped == 1 and #alarms == countBefore - 1, 'Alarm entfernt')
for _, item in ipairs(Clock:CollectCalendarEvents()) do assert(not item.removed or item.key ~= 'id:77', 'danach nichts mehr') end

-- Aelterer Alarm ohne gespeicherte Terminart: sie wird aus der Alarmfarbe erkannt
local legacy = {id = 50, uid = 'leg', name = 'Alt', hour = 9, minute = 0, day = 19, month = 10, year = 2026, enabled = true,
    calendarKey = 'id:88', calendarStamp = 202610191000, calendarTitle = 'Alt', customEffect = true, effect = {spec = '#66E666, pulse, 1, 100, fill'}}
alarms[#alarms + 1] = legacy
dayEvents[20261019][#dayEvents[20261019] + 1] = {title = 'Alt', kind = 'PLAYER', eventID = 88, eventType = 'RAID',
    start = {year = 2026, month = 10, day = 19, hour = 10, minute = 0}}
assert(Clock:AlarmCalendarType(legacy) == 'MEETING', 'Art aus Alarmfarbe')
local legacyItem
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.key == 'id:88' then legacyItem = item end end
assert(legacyItem and legacyItem.update == legacy and legacyItem.changes[1] == 'type', 'Typ-Aenderung auch bei aelterem Alarm')
alarms[#alarms] = nil
dayEvents[20261019][#dayEvents[20261019]] = nil

-- Ohne eventID: gleicher Tag und Name, andere Uhrzeit aktualisiert den gefundenen Alarm
dayEvents[20261019][#dayEvents[20261019] + 1] = {title = 'Ohne ID', kind = 'PLAYER', eventType = 'OTHER',
    start = {year = 2026, month = 10, day = 19, hour = 12, minute = 0}}
local noId
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.title == 'Ohne ID' then noId = item end end
assert(noId and not noId.update and noId.key == '20261019|Ohne ID')
Clock:ImportCalendarAlarms({noId})
total = #alarms
local ev2 = dayEvents[20261019][#dayEvents[20261019]]
ev2.start.hour = 13
noId = nil
for _, item in ipairs(Clock:CollectCalendarEvents()) do if item.title == 'Ohne ID' then noId = item end end
assert(noId and noId.update, 'andere Uhrzeit: Aktualisierung des vorhandenen Alarms')
Clock:ImportCalendarAlarms({noId})
assert(#alarms == total, 'kein zweiter Alarm')
for _, a in ipairs(alarms) do if a.calendarKey == '20261019|Ohne ID' then assert(a.hour == 12 and a.minute == 45, 'Alarm 13:00 - 15 min') end end
-- Ohne Classic Calendar: Import aus dem Kalender des Spiels (C_Calendar)
ClassicCalendar = nil
local viewed, setCalls = {month = 10, year = 2026}, {}
local gameEvents = {[19] = {{title = 'Gildenabend', calendarType = 'GUILD_EVENT', eventID = 501, eventType = 3,
    startTime = {year = 2026, month = 10, monthDay = 19, hour = 20, minute = 0}, endTime = {year = 2026, month = 10, monthDay = 19, hour = 22, minute = 0}},
    {title = 'Fest', calendarType = 'HOLIDAY', startTime = {year = 2026, month = 10, monthDay = 19, hour = 0, minute = 0}}}}
C_Calendar = {
    GetMonthInfo = function() return {month = viewed.month, year = viewed.year, numDays = 31} end,
    SetAbsMonth = function(month, year) setCalls[#setCalls + 1] = month; viewed = {month = month, year = year} end,
    GetNumDayEvents = function(_, day) return (gameEvents[day] and viewed.month == 10) and #gameEvents[day] or 0 end,
    GetDayEvent = function(_, day, index) return gameEvents[day][index] end,
}
assert(not Clock:CalendarLinkAvailable() and Clock:CalendarImportAvailable(), 'Import ohne Addon moeglich, Export nicht')
local nativeList = Clock:CollectCalendarEvents()
local guild
for _, item in ipairs(nativeList) do if item.key == 'id:501' then guild = item end end
assert(guild and guild.native and guild.eventType == 'MEETING' and guild.kind == 'GUILD_EVENT', 'Spielkalender: Termin gelesen')
for _, item in ipairs(nativeList) do assert(item.title ~= 'Fest', 'Feste sind keine Termine') end
Clock:ImportCalendarAlarms({guild})
local nativeAlarm
for _, a in ipairs(alarms) do if a.calendarKey == 'id:501' then nativeAlarm = a end end
assert(nativeAlarm and nativeAlarm.calendarSource == 'game' and nativeAlarm.alarmType == 'event', 'Alarm aus dem Spielkalender')
assert(viewed.month == 10, 'angezeigter Monat wiederhergestellt')
print('CalendarLink OK')
