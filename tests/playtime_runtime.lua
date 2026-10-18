-- Ohne WoW/Libs ausführbare Ablaufprüfung: Login, Reload, Logout, /played, Shift.
local source = assert(arg[1], 'Core/Playtime.lua erforderlich')
local epoch, uptime = 100000, 1000
local userGuid = 'Player-123'
local frames, calls = {}, 0
_G.time = function() return epoch end
_G.GetTime = function() return uptime end
_G.UnitGUID = function() return userGuid end
-- Forever kann in UnitFullName nur den Vornamen liefern. GetUnitName
-- gibt den vollstaendigen Anzeigenamen mit Nachnamen zurueck.
_G.UnitFullName = function()
    if userGuid == 'Player-456' then return 'OtherChar', 'ForeverRealm' end
    return 'TestChar', 'ForeverRealm'
end
local returnShortName = false
_G.GetUnitName = function()
    if userGuid == 'Player-456' then
        return returnShortName and 'OtherChar' or 'OtherChar Bearsoul'
    end
    return returnShortName and 'TestChar' or 'TestChar Moonlight'
end
_G.UnitFactionGroup = function()
    return userGuid == 'Player-456' and 'Horde' or 'Alliance'
end
_G.UnitClass = function()
    if userGuid == 'Player-456' then return 'Druid', 'DRUID' end
    return 'Mage', 'MAGE'
end
_G.RAID_CLASS_COLORS = {
    MAGE = {r = 0.25, g = 0.78, b = 0.92},
    DRUID = {r = 1.00, g = 0.49, b = 0.04},
}
_G.C_ClassColor = { GetClassColor = function(token)
    return _G.RAID_CLASS_COLORS[token]
end }

_G.UnitLevel = function() return 21 end
_G.RequestTimePlayed = function() calls = calls + 1 end
local shift = false
_G.IsShiftKeyDown = function() return shift end
_G.CreateFrame = function()
    local frame = {events = {}}
    function frame:RegisterEvent(name) self.events[name] = true end
    function frame:SetScript(name, fn) self[name] = fn end
    function frame:Emit(event, ...)
        assert(self.events[event], 'Event nicht registriert: '..event)
        self.OnEvent(self, event, ...)
    end
    frames[#frames + 1] = frame
    return frame
end
-- Blizzard-Chatframes erhalten TIME_PLAYED_MSG nur dann, wenn wir sie nicht
-- für eine eigene /played-Abfrage temporär abgemeldet haben.
local chat = {events = {TIME_PLAYED_MSG = true}}
function chat:IsEventRegistered(name) return self.events[name] == true end
function chat:RegisterEvent(name) self.events[name] = true end
function chat:UnregisterEvent(name) self.events[name] = nil end
_G.ChatFrame1 = chat
_G.CHAT_FRAMES = {'ChatFrame1'}
_G.NUM_CHAT_WINDOWS = 1
local scheduled = {}
_G.C_Timer = {After = function(delay, fn)
    assert(delay == 0)
    scheduled[#scheduled + 1] = fn
end}
local function FlushTimers()
    local tasks = scheduled
    scheduled = {}
    for _, fn in ipairs(tasks) do fn() end
end
local global = {}
local function NewClient()
    local clock = {db = {global = global}}
    local ns = {Clock = clock, L = {
        CLOCK_LABEL = 'Clock', PLAYTIME_SESSION = 'Current session',
        PLAYTIME_SESSION_HEADER = 'Game session',
        PLAYTIME_TOTAL_HEADER = 'Playtime', PLAYTIME_SHIFT_HINT = 'Hold Shift to show playtime',
        PLAYTIME_CHARACTERS_HEADER = 'Tracked characters',
        PLAYTIME_LAST_SESSION = 'Last session', PLAYTIME_CHARACTER = 'Character total',
        PLAYTIME_LEVEL = 'Current level', PLAYTIME_ACCOUNT = 'Account total',
        PLAYTIME_UNAVAILABLE = 'Not available yet', PLAYTIME_LOADING = 'Loading',
        PLAYTIME_DAY_ONE = 'day', PLAYTIME_DAY_MANY = 'days',
        PLAYTIME_HOUR_ONE = 'hour', PLAYTIME_HOUR_MANY = 'hours',
        PLAYTIME_MINUTE_ONE = 'minute', PLAYTIME_MINUTE_MANY = 'minutes',
        TIMER_LABEL = 'Timer', ARMED_HEADER = 'Alarms', ALARM_FALLBACK = 'Alarm',
        LEFT_CLICK = 'Left: Start', RIGHT_CLICK = 'Right: Options',
        CTRL_LEFT = 'Ctrl: Alarms', STOPWATCH_HINT = 'Control: Stopwatch',
        BLIZZARD_CLOCK_HINT = 'Alt: Clock', DRAG_FREE = 'Drag: Move',
        DRAG_MINIMAP = 'Drag: Move', COVERS_ICON = 'Covers %s',
    }}
    assert(loadfile(source))('CantPlayForever', ns)
    assert(loadfile('CantPlayForever/Modules/Clock/Tooltip.lua'))('CantPlayForever', ns)
    clock.db.profile = {alarms = {}, activeTimer = nil}
    clock.FormatTooltipTime = function() return '12:34:56' end
    clock.Duration = function(_, seconds) return tostring(seconds) .. 's' end
    clock.RemainingTimer = function() return nil end
    clock.GetClockDiameter = function() return 64 end
    clock:InitializePlaytime()
    clock:EnablePlaytime()
    return clock, frames[#frames]
end
local function Advance(seconds)
    epoch, uptime = epoch + seconds, uptime + seconds
end
local first, f1 = NewClient()
f1:Emit('PLAYER_ENTERING_WORLD', true, false)
assert(global.playtime.characters[userGuid].name == 'TestChar Moonlight',
    'Vor- und Nachname muessen beim Login erfasst werden')
assert(global.playtime.characters[userGuid].classFile == 'MAGE',
    'Klasse muss beim Login gespeichert werden')
assert(global.playtime.characters[userGuid].faction == 'Alliance',
    'Fraktion muss beim Login gespeichert werden')
-- Ein aus alten Addonversionen importierter Datensatz wird ohne Verlust
-- der /played-Werte vervollstaendigt, sobald der Char wieder eingeloggt ist.
local oldRecord = global.playtime.characters[userGuid]
oldRecord.name = 'TestChar'
oldRecord.classFile = nil
oldRecord.faction = nil
oldRecord.totalPlayed = 1100
first:EnsurePlaytimeCharacter()
assert(oldRecord.name == 'TestChar Moonlight' and oldRecord.classFile == 'MAGE'
    and oldRecord.faction == 'Alliance' and oldRecord.totalPlayed == 1100,
    'Alte Charakterdaten muessen beim Login nachgeruestet werden')
-- Unvollstaendige API-Namensantwort darf den vollen gespeicherten Namen
-- auch nach einem /played-Event nicht zerstoeren.
returnShortName = true
first:EnsurePlaytimeCharacter()
assert(global.playtime.characters[userGuid].name == 'TestChar Moonlight',
    'Ein spaeterer Vorname darf den gespeicherten Nachnamen nicht ueberschreiben')
returnShortName = false
assert(first:GetSessionSeconds() == 0)
assert(first:FormatPlayedDuration(90061) == '1 day, 1 hour, 1 minute')
assert(first:FormatPlayedDuration(172860) == '2 days, 0 hours, 1 minute')
assert(first:FormatPlayedDuration(59) == '0 days, 0 hours, 0 minutes')
Advance(7)
first:PlaytimeOnTick()
assert(calls == 0, 'Keine automatische /played-Anfrage vor 30 Sekunden')
-- Normales Mouseover löst keine Anfrage aus; erst gedrücktes Shift.
first:RequestPlayedOnHover()
assert(calls == 0, 'Mouseover ohne Shift darf /played nicht anfragen')
shift = true
first:RequestPlayedOnShift()
assert(calls == 1, 'Shift muss /played anfragen')
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Addon-Request darf nicht im Chat erscheinen')
f1:Emit('TIME_PLAYED_MSG', 2200, 800)
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Blizzard darf dieselbe Antwort nicht erhalten')
FlushTimers()
shift = false
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Blizzard-Chat-Registrierung muss wiederhergestellt sein')
assert(first.playtimeNextRequest == 100030, 'Erster automatischer Termin ist Login + 30 s und nicht Shift + 10 min')
Advance(120)
assert(first:GetSessionSeconds() == 127)
assert(first:GetCharacterPlayedSeconds() == 2320)
assert(first:GetLevelPlayedSeconds() == 920)
assert(first:GetAccountPlayedSeconds() == 2200, 'Account-Summe darf keinen hochgerechneten /played-Wert anzeigen')
first:SavePlaytimeEstimate() -- derselbe Pfad wie PLAYER_LOGOUT bei /reload
assert(first:GetCharacterPlayedSeconds() == 2320)
assert(global.playtime.characters[userGuid].totalPlayed == 2200, 'Serverantwort darf nicht ueberschrieben werden')
assert(global.playtime.characters[userGuid].logoutConfirmedTotalPlayed == 2200, 'Logout muss letzten WoW-Serverstand sichern')
assert(global.playtime.characters[userGuid].logoutConfirmedLevelPlayed == 800, 'Logout muss letzte serverbestaetigte Stufenzeit sichern')
assert(global.playtime.characters[userGuid].logoutConfirmedAt == 100007, 'Zeitstempel des letzten WoW-Serverstands fehlt')
assert(global.playtime.characters[userGuid].logoutSnapshotAt == epoch, 'Logout-Snapshot-Zeitpunkt fehlt')
assert(global.playtime.characters[userGuid].logoutTotalPlayed == 2320, 'Logout-Stand muss gesondert gespeichert werden')
-- GetTime kann nach /reload zurückspringen, die Session zählt über time().
uptime = 4
local second, f2 = NewClient()
f2:Emit('PLAYER_ENTERING_WORLD', false, true)
Advance(15)
assert(second:GetSessionSeconds() == 142, 'Reload hat Session zurückgesetzt')
assert(second:GetCharacterPlayedSeconds() == 2335, 'Reload hat /played doppelt gezählt')
assert(second:GetLevelPlayedSeconds() == 935)
assert(second:GetLastSessionSeconds() == nil, 'Reload darf nicht letzte Session überschreiben')
f2:Emit('PLAYER_LOGOUT')
local third, f3 = NewClient()
Advance(600) -- Offlinezeit darf in keiner Statistik enthalten sein.
f3:Emit('PLAYER_ENTERING_WORLD', true, false)
assert(third:GetSessionSeconds() == 0, 'echter Login muss neue Session starten')
assert(third:GetLastSessionSeconds() == 142, 'vorherige Session nicht abgeschlossen')
assert(third:GetCharacterPlayedSeconds() == 2335, 'Offlinezeit fälschlich addiert')
Advance(5)
assert(third:GetCharacterPlayedSeconds() == 2340)
-- Shift-Mouseover: ausbleibende TIME_PLAYED_MSG-Antwort erneut anfragen.
local hover = {lines = {}, IsShown = function() return true end}
function hover:GetOwner() return third.iconButton end
function hover:GetName() return nil end -- Spiel-Client ohne benannte FontStrings
function hover:ClearLines() self.lines = {} end
function hover:NumLines() return #self.lines end
function hover:AddLine(a) self.lines[#self.lines+1] = {a} end
function hover:AddDoubleLine(a, b, ...) self.lines[#self.lines+1] = {a, b, ...} end
function hover:GetWidth() return 240 end
function hover:AddTexture(path, settings)
    local line = self.lines[#self.lines]
    assert(line, 'Divider muss an eine Tooltip-Zeile angehaengt werden')
    line.texture = path
    line.textureSettings = settings
end

function hover:Show() end
third.iconButton = {}
third.hoverTooltip = hover
third:BuildHoverTooltip(hover)
third.RemainingTimer = function() return 77 end
hover:ClearLines()
third:BuildHoverTooltip(hover)
assert(hover.lines[3][1] == 'Timer' and hover.lines[3][2] == '77s',
    'Timer muss unmittelbar unter der Uhrzeit stehen')
third.RemainingTimer = function() return nil end
hover:ClearLines()
third:BuildHoverTooltip(hover)
local function Row(name)
    for _, row in ipairs(hover.lines) do if row[1] == name or (type(row[1]) == 'string' and row[1]:find(name, 1, true)) then return row[2] end end
end
assert(Row('Current session') == '5s', 'normale Session-Zeile fehlt')
assert(hover.lines[2][1] == 'Clock' and hover.lines[3][1] == ' ', 'Uhrzeit oben getrennt vom Sessionblock')
assert(Row('Game session') == nil, 'Session-Überschrift ist eine Einzelzeile')
assert(hover.lines[4][1] == 'Game session', 'Session-Überschrift fehlt')
assert(Row('Last session') == '142s', 'letzte Session fehlt')
assert(not Row('Character total'), 'Shift-Zeilen ungewollt dauerhaft sichtbar')
local function DividerLine()
    for _, row in ipairs(hover.lines) do
        if row.texture then return row end
    end
end
assert(DividerLine() == nil, 'Divider darf ohne Shift nicht sichtbar sein')
local function HintIndex()
    for i, row in ipairs(hover.lines) do
        if type(row[1]) == 'string' and row[1]:find('Hold Shift to show playtime', 1, true) then
            return i
        end
    end
end
local hintIndex = HintIndex()
assert(hintIndex and hover.lines[hintIndex][1]:find('|cff4db3ff(i)|r ', 1, true),
    'Blauer Fallback fuer das Info-Symbol vor dem Shift-Hinweis fehlt')
assert(hover.lines[hintIndex-1][1] == ' ' and hover.lines[hintIndex+1][1] == ' ',
    'Info-Hinweis muss eine Leerzeile vor und hinter sich haben')
assert(hover.lines[hintIndex][2] == nil, 'Hinweis darf keine zweite Tooltip-Spalte verwenden')

shift = true
third.playtimeReceived = false
third.playtimeRequestAllowedAt = nil
local before = calls
third:RequestPlayedOnHover() -- OnTooltipShow mit bereits gedrücktem Shift
assert(calls == before + 1, 'Ein neuer Shift-Mouseover startet eine /played-Abfrage')
f3:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 1)
assert(Row('Character total') == 'Loading', 'Shift darf keinen lokalen Schätzwert zeigen')
assert(Row('Current level') == 'Loading', 'Shift muss auf Serverwerte warten')
assert(Row('TestChar Moonlight') == 'Loading', 'aktiver Char darf keinen alten Serverwert anzeigen')
assert(hover.lines[8][1] == 'Playtime', 'Die Shift-Überschrift muss Spielzeit heißen')
assert(HintIndex() == nil, 'Der Shift-Hinweis muss beim Drücken verschwinden')
assert(hover.lines[7][1] == ' ' and hover.lines[9][1] == 'Character total',
    'Spielzeit-Werte muessen ohne Leerzeile direkt nach der Überschrift stehen')
assert(Row('Account total') == 'Loading', 'Accountanzeige muss auf neue Serverantwort warten')
local divider = DividerLine()
assert(divider == nil, 'Nach den Spielzeitdaten ist keine Trennlinie mehr gewuenscht')

assert(hover.lines[#hover.lines][1] ~= nil, 'Tooltip unvollständig')
assert(calls == before+1, 'Zweites Shift-Event ohne Loslassen darf keine zweite Anfrage starten')
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Shift-Request darf nicht im Chat erscheinen')
f3:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 1)
assert(calls == before+1, 'Shift darf keine Anfrageschleife auslösen')
f3:Emit('TIME_PLAYED_MSG', 2340, 940)
FlushTimers()
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Chat muss nach Shift wieder /played anzeigen')
assert(Row('Character total') == '0 days, 0 hours, 39 minutes', 'Serverwert muss in Tagen, Stunden, Minuten stehen')
assert(Row('Current level') == '0 days, 0 hours, 15 minutes', 'Server-Stufenzeit muss in Minuten erscheinen')
assert(Row('Account total') == '0 days, 0 hours, 39 minutes')
assert(Row('TestChar Moonlight') == '0 days, 0 hours, 39 minutes', 'einzelne Char-Spielzeit fehlt')
local function ColorFor(label)
    for _, row in ipairs(hover.lines) do
        if row[1] == label or (type(row[1]) == 'string' and row[1]:find(label, 1, true)) then return row[3], row[4], row[5] end
    end
end
local red, green, blue = ColorFor('TestChar Moonlight')
assert(red == 0.25 and green == 0.78 and blue == 0.92,
    'Class-MAGE-Farbe muss direkt auf dem Char-Namen liegen')
local function CharacterLabel(name)
    for _, row in ipairs(hover.lines) do
        if type(row[1]) == 'string' and row[1]:find(name, 1, true) then
            return row[1]
        end
    end
end
local allianceLabel = CharacterLabel('TestChar Moonlight')
assert(allianceLabel and allianceLabel:find('PVP-Currency-Alliance', 1, true),
    'Allianz-Symbol muss vor dem Char erscheinen')
assert(allianceLabel:find('|cff40c7eb', 1, true),
    'Charname muss mit Klassenfarbcode eingebettet sein')
assert(third:GetCharacterPlayedSeconds() == 2340)
shift = false
f3:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 0)
assert(Row('Character total') == nil, 'Shift-Zeilen nicht wieder entfernt')
assert(DividerLine() == nil, 'Divider nach Shift loslassen nicht entfernt')
local hintAfterShift = HintIndex()
assert(hintAfterShift and hover.lines[hintAfterShift-1][1] == ' '
    and hover.lines[hintAfterShift+1][1] == ' ',
    'Nach dem Loslassen von Shift muss die blaue Infozeile wieder erscheinen')
assert(third.playtimePending == false)
assert(third.playtimeHoverRequested, 'Shift loslassen darf Mouseover nicht beenden')
-- Ein neuer echter Mouseover holt erneut Werte aus dem Spiel, selbst bei altem Cache.
third:EndPlayedHover() -- tatsächliches OnLeave
Advance(6)
shift = true
local beforeNewHover = calls
third:RequestPlayedOnHover() -- tatsächliches OnTooltipShow
f3:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 1)
assert(calls == beforeNewHover + 1, 'Neuer Mouseover mit Shift soll erneut vom Server abfragen')
assert(Row('Character total') == 'Loading')
f3:Emit('TIME_PLAYED_MSG', 2350, 950)
FlushTimers()
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'))
assert(Row('Character total') == '0 days, 0 hours, 39 minutes')
shift = false
f3:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 0)
-- Charakterwechsel: Accountsumme und Sessionhistory pro GUID.
f3:Emit('PLAYER_LOGOUT')
assert(global.playtime.characters['Player-123'].totalPlayed == 2350, 'letzter bestaetigter Wert erhalten')
assert(global.playtime.characters['Player-123'].logoutConfirmedTotalPlayed == 2350, 'Logout-Snapshot muss aktuellsten bestaetigten Wert besitzen')
assert(global.playtime.characters['Player-123'].logoutConfirmedLevelPlayed == 950, 'Logout-Snapshot der Stufenzeit fehlt')
assert(global.playtime.characters['Player-123'].logoutTotalPlayed == 2350, 'Logout schreibt Endstand pro Charakter')
userGuid = 'Player-456'
Advance(3)
local fourth, f4 = NewClient()
f4:Emit('PLAYER_ENTERING_WORLD', true, false)
assert(fourth:GetLastSessionSeconds() == nil)
assert(global.playtime.characters['Player-123'].lastSessionSeconds == 11, 'letzte Session muss bis zum tatsächlichen Logout laufen')
fourth:RequestPlayedOnHover()
local beforeManual = calls
assert(calls == beforeManual, 'Ein normaler Mouseover darf keine Anfrage senden')
-- Simuliertes manuelles /played aus dem Blizzard-Chat: nur TIME_PLAYED_MSG.
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Manuelles /played muss im Chat sichtbar bleiben')
f4:Emit('TIME_PLAYED_MSG', 500, 100)
assert(calls == beforeManual, 'Manuelles /played darf nicht nochmals RequestTimePlayed aufrufen')
assert(global.playtime.characters[userGuid].totalPlayed == 500,
    'Manuelles /played muss wie eine eigene Anfrage gespeichert werden')
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Manuelles /played darf nicht stummgeschaltet werden')
assert(fourth:GetAccountPlayedSeconds() == 2850,
    'Accountsumme muss den letzten von WoW bestaetigten Wert verwenden')
assert(global.playtime.characters[userGuid].classFile == 'DRUID',
    'Klassentoken muss fuer spätere Sessions gespeichert bleiben')
local total, count, list = fourth:GetAccountPlayedSeconds()
assert(count == 2 and list[1].name == 'TestChar Moonlight' and list[2].name == 'OtherChar Bearsoul',
    'Characterliste muss alle erfassten Spieler sortiert enthalten')
-- Charaktere ohne bestätigten /played-Wert bleiben sichtbar, zählen aber nicht in Summe/Anzahl.
global.playtime.characters['Player-NOPLAYED'] = {name = 'Neuling Frischling', realm = 'R', classFile = 'ROGUE'}
local totalWithNew, countWithNew, listWithNew = fourth:GetAccountPlayedSeconds()
assert(totalWithNew == total and countWithNew == count and #listWithNew == #list + 1
    and listWithNew[#listWithNew].guid == 'Player-NOPLAYED' and listWithNew[#listWithNew].played == nil,
    'Charakter ohne /played-Wert muss am Listenende ohne Zeit erscheinen')
global.playtime.characters['Player-NOPLAYED'] = nil
assert(list[1].classFile == 'MAGE' and list[2].classFile == 'DRUID',
    'Klassentoken muss in der Charakterliste enthalten sein')
assert(list[1].faction == 'Alliance' and list[2].faction == 'Horde',
    'Fraktion muss in der Charakterliste enthalten sein')
assert(global.playtime.characters['Player-456'].name == 'OtherChar Bearsoul'
    and global.playtime.characters['Player-456'].faction == 'Horde',
    'Klasse, Fraktion und Nachname muessen am zweiten Char schon beim Login vorliegen')
fourth.iconButton = {}
function hover:GetOwner() return fourth.iconButton end
shift = true
fourth:RequestPlayedOnShift()
assert(calls == beforeManual + 1, 'Shift nach Mouseover muss neue Werte anfragen')
f4:Emit('TIME_PLAYED_MSG', 500, 100)
FlushTimers()
hover:ClearLines()
fourth:BuildHoverTooltip(hover)
assert(Row('TestChar Moonlight') == '0 days, 0 hours, 39 minutes',
    'Offline-Char muss mit gespeicherter WoW-Zeit erscheinen')
assert(Row('OtherChar Bearsoul') == '0 days, 0 hours, 8 minutes',
    'Aktiver Char muss mit frischem WoW-Wert erscheinen')
local cr, cg, cb = ColorFor('OtherChar Bearsoul')
assert(cr == 1 and cg == 0.49 and cb == 0.04, 'DRUID-Klassenfarbe fehlt')
local hordeLabel = CharacterLabel('OtherChar Bearsoul')
assert(hordeLabel and hordeLabel:find('PVP-Currency-Horde', 1, true),
    'Horde-Symbol muss vor dem Char erscheinen')
-- Shift loslassen und erneut drücken muss während desselben Mouseovers
-- eine neue Anfrage erzeugen. Mouseover selbst darf das nicht tun.
shift = false
f4:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 0)
local callsBeforeSecondShift = calls
assert(fourth.playtimeHoverRequested, 'Shift loslassen darf den Hover nicht beenden')
shift = true
f4:Emit('MODIFIER_STATE_CHANGED', 'LSHIFT', 1)
assert(calls == callsBeforeSecondShift + 1, 'Erneutes Shift drücken muss neu abfragen')
f4:Emit('TIME_PLAYED_MSG', 500, 100)
FlushTimers()
-- Auch wenn eine alte Offline-Logout-Schaetzung hoeher ist, bleibt der
-- /played-Wert unter Shift der serverseitig bestaetigte Wert.
global.playtime.characters['Player-123'].logoutTotalPlayed = 9999
assert(fourth:GetAccountPlayedSeconds() == 2850,
    'Offline-Schätzwert darf die WoW-Zeiten der Accountliste nicht verfälschen')
-- Zwei kurze Anfragen direkt hintereinander: verspäteter Restore-Callback
-- darf die neue Abfrage nicht ungewollt wieder in den Chat durchlassen.
FlushTimers()
fourth.playtimePending = false
assert(fourth:RequestPlayedTime(true))
f4:Emit('TIME_PLAYED_MSG', 500, 100)
assert(fourth:RequestPlayedTime(true))
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'))
FlushTimers() -- alte Restore-Funktion von voriger Anfrage
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Alt-Callback darf neue Anfrage nicht entstummen')
-- Timeout ohne Serverantwort: chat event muss garantiert wieder aktiv werden.
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'))
Advance(21)
fourth:PlaytimeOnTick()
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Timeout darf Chat nie stumm lassen')
assert(fourth.playtimePending == false)
-- Fehler bei RequestTimePlayed: das Event muss sofort wiederhergestellt werden.
local originalRequest = _G.RequestTimePlayed
_G.RequestTimePlayed = function() error('simulierte Serveranfrage-Exception') end
assert(fourth:RequestPlayedTime(true) == false)
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Request-Fehler darf Chat nicht stumm lassen')
_G.RequestTimePlayed = originalRequest
-- Separater Login überprüft feste 30s-Start- und 10min-Folgeintervalle.
f4:Emit('PLAYER_LOGOUT')
userGuid = 'Player-789'
shift = false
local fifth, f5 = NewClient()
f5:Emit('PLAYER_ENTERING_WORLD', true, false)
local firstDue = epoch + 30
local previousCalls = calls
Advance(29)
fifth:PlaytimeOnTick()
assert(calls == previousCalls, 'Vor 30 Sekunden nach Login keine Hintergrundabfrage')
Advance(1)
fifth:PlaytimeOnTick()
assert(calls == previousCalls + 1, 'Erste automatische /played-Anfrage nach 30 Sekunden fehlt')
assert(not chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Hintergrundabfrage darf nicht im Chat landen')
f5:Emit('TIME_PLAYED_MSG', 650, 150)
FlushTimers()
assert(chat:IsEventRegistered('TIME_PLAYED_MSG'), 'Chatlistener nach Hintergrundantwort nicht restauriert')
assert(global.playtime.characters[userGuid].totalPlayed == 650, 'Serverstand nicht am Charakter gespeichert')
assert(global.playtime.characters[userGuid].updatedAt == epoch, 'Serverzeitpunkt nicht aktualisiert')
assert(fifth.playtimeNextRequest == firstDue + 600, 'Regelmäßiger Termin muss 10 Minuten später liegen')
-- Manuelles /played aktualisiert Daten, aber verändert den Auto-Termin nicht.
f5:Emit('TIME_PLAYED_MSG', 670, 155)
assert(global.playtime.characters[userGuid].totalPlayed == 670, 'Manuelle Serverantwort wurde nicht gespeichert')
assert(fifth.playtimeNextRequest == firstDue + 600, 'Manuelles /played darf Auto-Termin nicht verschieben')
Advance(599)
local callsBeforeInterval = calls
fifth:PlaytimeOnTick()
assert(calls == callsBeforeInterval, 'Vor Ablauf der 10 Minuten keine zweite Hintergrundabfrage')
Advance(1)
fifth:PlaytimeOnTick()
assert(calls == callsBeforeInterval + 1, 'Zweite automatische Abfrage nach 10 Minuten fehlt')
f5:Emit('TIME_PLAYED_MSG', 700, 175)
FlushTimers()
assert(global.playtime.characters[userGuid].totalPlayed == 700, 'Zweiter Serverstand wurde nicht gespeichert')
-- /reload darf die regelmäßig nächste Fälligkeit nicht umplanen.
local nextDue = fifth.playtimeNextRequest
f5:Emit('PLAYER_LOGOUT')
local reloaded, f6 = NewClient()
f6:Emit('PLAYER_ENTERING_WORLD', false, true)
assert(reloaded.playtimeNextRequest == nextDue, '/reload darf den 10-Minuten-Termin nicht neu starten')
assert(global.playtime.characters[userGuid].logoutConfirmedTotalPlayed == 700, 'Letzter Stand nicht bei Reload/Logout gespeichert')
assert(global.playtime.characters[userGuid].logoutConfirmedLevelPlayed == 175, 'Stufenzeit nicht bei Reload/Logout gespeichert')
print('OK playtime: 30s + 10min, Shift, manual /played, chat suppression, reload and logout')
