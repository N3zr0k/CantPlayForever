-- Kontoübergreifend gespeicherte Charakter-Spielzeiten und Login-Sessions.
-- Der Client liefert /played asynchron per TIME_PLAYED_MSG. /reload löst ebenfalls
-- PLAYER_LOGOUT aus; erst PLAYER_ENTERING_WORLD(isReloadingUi) unterscheidet beides.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

-- Erste stille Abfrage 30 Sekunden nach dem echten Login, danach alle zehn
-- Minuten. Normales Mouseover löst keine Anfrage aus; Shift schon.
-- /played ist asynchron: Beim Logout kann keine Antwort abgewartet werden.
local PLAYED_INITIAL_DELAY = 30
local PLAYED_REFRESH_SECONDS = 10 * 60

local function Uptime()
    return type(_G.GetTime) == 'function' and _G.GetTime() or time()
end

local function Epoch()
    return type(_G.time) == 'function' and _G.time() or 0
end

local function SafeSeconds(value)
    value = tonumber(value)
    if not value or value < 0 then return nil end
    return math.floor(value)
end

-- /played im Tooltip mit ganzen Tagen, Stunden und Minuten anzeigen.
-- Die Session-Dauer nutzt weiterhin Clock:Duration() im Format hh:mm:ss.
function Clock:FormatPlayedDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format('%d %s, %d %s, %d %s',
        days, days == 1 and L.PLAYTIME_DAY_ONE or L.PLAYTIME_DAY_MANY,
        hours, hours == 1 and L.PLAYTIME_HOUR_ONE or L.PLAYTIME_HOUR_MANY,
        minutes, minutes == 1 and L.PLAYTIME_MINUTE_ONE or L.PLAYTIME_MINUTE_MANY)
end

-- Forever hat Vornamen UND Nachnamen. UnitName/UnitFullName koennen je nach
-- Clientbuild nur den Vornamen liefern, waehrend GetUnitName('player') den
-- vollstaendigen Anzeigenamen zurueckgibt. GUID bleibt der stabile DB-Schluessel.
local function ValidPlayerName(value)
    return type(value) == 'string' and value ~= ''
        and value ~= _G.UNKNOWNOBJECT and value ~= _G.UNKNOWN
end

local function HasSurname(value)
    return ValidPlayerName(value) and value:match('^%S+%s+%S') ~= nil
end

local function CharacterDetails()
    local guid = type(_G.UnitGUID) == 'function' and _G.UnitGUID('player')
    if not guid or guid == '' then return end
    local name, realm
    if type(_G.UnitFullName) == 'function' then
        local candidate, candidateRealm = _G.UnitFullName('player')
        if ValidPlayerName(candidate) then name = candidate end
        if type(candidateRealm) == 'string' then realm = candidateRealm end
    end
    -- Besonders wichtig auf WoW Forever: GetUnitName kann den kompletten
    -- 'Vorname Nachname' liefern, obwohl UnitFullName nur 'Vorname' meldet.
    if type(_G.GetUnitName) == 'function' then
        local candidate = _G.GetUnitName('player', false)
        if ValidPlayerName(candidate) and (HasSurname(candidate) or not name) then
            name = candidate
        end
    end
    if not name and type(_G.UnitName) == 'function' then
        local candidate = _G.UnitName('player')
        if ValidPlayerName(candidate) then name = candidate end
    end
    if not realm or realm == '' then
        realm = type(_G.GetNormalizedRealmName) == 'function' and _G.GetNormalizedRealmName()
            or (type(_G.GetRealmName) == 'function' and _G.GetRealmName()) or ''
    end
    local level = type(_G.UnitLevel) == 'function' and _G.UnitLevel('player') or nil
    local classFile
    if type(_G.UnitClass) == 'function' then
        local _, token = _G.UnitClass('player')
        if type(token) == 'string' and token ~= '' then classFile = token end
    end
    -- API liefert 'Alliance' bzw. 'Horde' unabhaengig von der Sprache.
    local faction
    if type(_G.UnitFactionGroup) == 'function' then
        local group = _G.UnitFactionGroup('player')
        if group == 'Alliance' or group == 'Horde' then faction = group end
    end
    return guid, name, realm, level, classFile, faction
end

function Clock:EnsurePlaytimeCharacter()
    if not (self.db and self.db.global) then return end
    local guid, name, realm, level, classFile, faction = CharacterDetails()
    if not guid then return end
    local global = self.db.global
    if type(global.playtime) ~= 'table' then global.playtime = {} end
    if type(global.playtime.characters) ~= 'table' then global.playtime.characters = {} end
    local chars = global.playtime.characters
    local record = chars[guid]
    if type(record) ~= 'table' then
        record = {}
        chars[guid] = record
    end
    -- Ein schon korrekt gespeicherter Nachname darf niemals durch eine
    -- spaetere unvollstaendige API-Antwort geloescht werden.
    if ValidPlayerName(name) and (HasSurname(name) or not HasSurname(record.name)) then
        record.name = name
    end
    record.name = record.name or guid
    record.realm = realm or record.realm or ''
    record.level = level or record.level
    record.classFile = classFile or record.classFile
    record.faction = faction or record.faction
    self.playtimeCharacterKey = guid
    return record
end

local function FinishSession(record, now)
    local session = record and record.session
    if type(session) ~= 'table' then return end
    local started = SafeSeconds(session.startedAt)
    local ended = SafeSeconds(session.pendingExitAt) or SafeSeconds(session.lastSeenAt)
        or now
    if started then
        -- Eine vorzeitig beendete Sitzung zählt keine Offlinezeit mit.
        ended = math.max(started, math.min(now, ended))
        record.lastSessionSeconds = ended - started
        record.lastSessionEndedAt = ended
    end
    record.session = nil
end

function Clock:InitializePlaytime()
    if self.playtimeMutedChatFrames then self:RestorePlayedChat() end
    self.playtimeRestoreChatSoon = nil
    self.sessionStartedAt = nil
    self.playtimeWorldEntered = false
    self.playtimeReceived = false
    self.playtimePending = false
    self.playtimeRequestAllowedAt = nil
    self.playtimeHoverRequested = false
    self.playtimeShiftRequested = false
    self.playtimeFreshForHover = false
    self.playtimeLastServerUptime = nil
    self.playtimeNextRequest = nil -- Erst nach PLAYER_ENTERING_WORLD/echtem Login planen.
    self:EnsurePlaytimeCharacter()
end

function Clock:PlaytimeEnteringWorld(isInitialLogin, isReloadingUi)
    local record = self:EnsurePlaytimeCharacter()
    if not record then return end
    if self.playtimeWorldEntered then return end -- nicht bei jedem Zonenwechsel neu beginnen
    self.playtimeWorldEntered = true
    -- Beim Login aktuelle Klasse und Fraktion mit dem Char-Datensatz verknüpfen.
    -- Fehlt eines der Felder anfangs noch, wird es beim nächsten /played erneut
    -- eingelesen. Bereits erfasste andere Charaktere bleiben unverändert.
    local now = Epoch()
    local session = record.session
    local started = type(session) == 'table' and SafeSeconds(session.startedAt)

    -- Forever liefert isReloadingUi als zweiten Parameter von PLAYER_ENTERING_WORLD.
    -- Ist der Parameter in einem abweichenden Client nicht vorhanden, ist eine sehr
    -- kurze Unterbrechung ein konservativer Fallback (mit dokumentierter Unschärfe).
    local isReload = isReloadingUi == true
    if isReloadingUi == nil and started and type(session) == 'table' then
        local exitAt = SafeSeconds(session.pendingExitAt)
        isReload = exitAt ~= nil and now - exitAt >= 0 and now - exitAt <= 15
    end
    if isReload and started and started <= now then
        session.pendingExitAt = nil
        session.lastSeenAt = now
        self.sessionStartedAt = started
    else
        -- Vorherige Sitzung aller Charaktere abschließen, auch nach einem Absturz.
        local store = self.db.global.playtime
        for _, oldRecord in pairs(store.characters) do FinishSession(oldRecord, now) end
        record.session = {startedAt = now, lastSeenAt = now}
        self.sessionStartedAt = now
        record.nextAutoPlayedAt = now + PLAYED_INITIAL_DELAY
    end
    -- Anstehende automatische Anfrage auch bei /reload beibehalten.
    local nextAt = SafeSeconds(record.nextAutoPlayedAt)
    if not nextAt then
        nextAt = now + PLAYED_INITIAL_DELAY
        record.nextAutoPlayedAt = nextAt
    end
    self.playtimeNextRequest = nextAt
end

function Clock:GetSessionSeconds()
    local started = self.sessionStartedAt
    if not started then return 0 end
    return math.max(0, Epoch() - started)
end

function Clock:GetLastSessionSeconds()
    local record = self:GetPlaytimeCharacter()
    return record and SafeSeconds(record.lastSessionSeconds)
end

function Clock:GetPlaytimeCharacter()
    if not self.playtimeCharacterKey then self:EnsurePlaytimeCharacter() end
    local store = self.db and self.db.global and self.db.global.playtime
    return store and store.characters and store.characters[self.playtimeCharacterKey]
end

local function SampleDelta(record, sessionStartedAt, useLogoutEstimate)
    local sampleAt = SafeSeconds(useLogoutEstimate and record.logoutSavedAt or record.updatedAt)
    if not sessionStartedAt then return 0 end
    -- Daten vom letzten Logout enthalten bereits die frühere Spielzeit:
    -- nach echtem Login nur seit diesem Login addieren, nie Offlinezeit.
    local from = sampleAt and math.max(sampleAt, sessionStartedAt) or sessionStartedAt
    return math.max(0, Epoch() - from)
end

function Clock:GetCharacterPlayedSeconds(record)
    record = record or self:GetPlaytimeCharacter()
    if not record then return end
    local confirmed = SafeSeconds(record.totalPlayed)
    local logoutEstimate = SafeSeconds(record.logoutTotalPlayed)
    local base = logoutEstimate and math.max(confirmed or 0, logoutEstimate) or confirmed
    if not base then return end
    if record ~= self:GetPlaytimeCharacter() then return base end
    return base + SampleDelta(record, self.sessionStartedAt, logoutEstimate ~= nil)
end

function Clock:GetLevelPlayedSeconds()
    local record = self:GetPlaytimeCharacter()
    if not record then return end
    local confirmed = SafeSeconds(record.levelPlayed)
    local logoutEstimate = SafeSeconds(record.logoutLevelPlayed)
    local base = logoutEstimate and math.max(confirmed or 0, logoutEstimate) or confirmed
    if not base then return end
    local currentLevel = type(_G.UnitLevel) == 'function' and _G.UnitLevel('player') or nil
    if currentLevel and record.playedLevel and currentLevel ~= record.playedLevel then return end
    return base + SampleDelta(record, self.sessionStartedAt, logoutEstimate ~= nil)
end

-- Nur vom Spiel bestaetigte Werte fuer die Shift-Anzeige des aktiven Charakters.
-- Keine lokale Hochrechnung: TIME_PLAYED_MSG ist die einzige Quelle.
function Clock:GetServerPlayedSeconds()
    if not self.playtimeFreshForHover then return nil end
    local record = self:GetPlaytimeCharacter()
    return record and SafeSeconds(record.totalPlayed)
end

function Clock:GetServerLevelSeconds()
    if not self.playtimeFreshForHover then return nil end
    local record = self:GetPlaytimeCharacter()
    if not record then return nil end
    local level = type(_G.UnitLevel) == 'function' and _G.UnitLevel('player') or nil
    if level and record.playedLevel and level ~= record.playedLevel then return nil end
    return SafeSeconds(record.levelPlayed)
end

-- Die Werte der Shift-Übersicht stammen ausschließlich aus TIME_PLAYED_MSG.
-- Für ausgeloggte Charaktere wird der zuletzt bestätigte WoW-Wert verwendet,
-- keine beim Logout lokal hochgerechnete Spielzeit.
function Clock:GetAccountPlayedSeconds()
    local store = self.db and self.db.global and self.db.global.playtime
    local records = store and store.characters or {}
    local total, count, list = 0, 0, {}
    for guid, record in pairs(records) do
        -- Jeder einmal erfasste Charakter erscheint in der Liste. Ohne bestätigten
        -- /played-Wert steht dort "Noch keine Daten"; Summe und Anzahl zählen nur
        -- Charaktere mit bestätigtem Wert.
        if type(record) == 'table' and record.name then
            local played = SafeSeconds(record.totalPlayed)
            if played then
                total = total + played
                count = count + 1
            end
            list[#list + 1] = {
                guid = guid,
                name = record.name,
                realm = record.realm or '',
                classFile = record.classFile,
                faction = record.faction,
                played = played,
                -- Im Shift-Tooltip erst nach TIME_PLAYED_MSG den aktiven
                -- Charakter als aktuellen Serverstand ausgeben.
                isCurrent = guid == self.playtimeCharacterKey,
            }
        end
    end
    table.sort(list, function(a, b)
        if a.played ~= b.played then
            if a.played == nil then return false end
            if b.played == nil then return true end
            return a.played > b.played
        end
        if a.name == b.name then return a.guid < b.guid end
        return a.name < b.name
    end)
    return total, count, list
end

function Clock:StorePlayedTime(totalPlayed, levelPlayed)
    local record = self:EnsurePlaytimeCharacter()
    local total = SafeSeconds(totalPlayed)
    if not record or not total then return end
    record.totalPlayed = total
    record.levelPlayed = SafeSeconds(levelPlayed)
    record.playedLevel = type(_G.UnitLevel) == 'function' and _G.UnitLevel('player') or nil
    record.updatedAt = Epoch()
    record.logoutTotalPlayed = nil  -- Neuer Serverstand ersetzt alte Logout-Hochrechnung.
    record.logoutLevelPlayed = nil
    self.playtimeLastServerUptime = Uptime()
    self.playtimeFreshForHover = self.playtimeShiftRequested == true
    self.playtimeReceived = true
    self.playtimePending = false
    -- Der bestätigte /played-Wert ist sofort in SavedVariables aktuell.
    -- Manuelles /played und Shift ändern die festgelegte 10-Minuten-Kadenz nicht.
    -- Auch eine von uns ausgelöste Antwort wird wie jede andere Serverantwort gespeichert.
    self:RestorePlayedChatNextFrame()
    if self.UpdateHoverTooltip then self:UpdateHoverTooltip() end
end

-- Beim PLAYER_LOGOUT (auch /reload) alle aktuellen Daten sofort im
-- accountweiten Charakter-Datensatz sichern. Exakte /played-Werte bleiben
-- unveraendert; eine Hochrechnung wird SEPARAT als Logout-Stand abgelegt,
-- weil RequestTimePlayed() beim Logout keine synchrone Antwort garantiert.
function Clock:SavePlaytimeEstimate()
    local record = self:GetPlaytimeCharacter()
    if not record then return end
    local now = Epoch()
    -- Snapshot des letzten von WoW bestätigten Stands je Charakter.
    -- Nur TIME_PLAYED_MSG aktualisiert totalPlayed/levelPlayed; die Logout-Speicherung
    -- darf diese Serverdaten niemals durch eine Hochrechnung überschreiben.
    record.logoutConfirmedTotalPlayed = SafeSeconds(record.totalPlayed)
    record.logoutConfirmedLevelPlayed = SafeSeconds(record.levelPlayed)
    record.logoutConfirmedAt = SafeSeconds(record.updatedAt)
    record.logoutSnapshotAt = now
    local total = self:GetCharacterPlayedSeconds(record)
    local level = self:GetLevelPlayedSeconds()
    if total then
        record.logoutTotalPlayed = math.max(total, SafeSeconds(record.totalPlayed) or 0)
    end
    if level then record.logoutLevelPlayed = level end
    record.logoutSavedAt = now
    local session = record.session
    if type(session) == 'table' then
        session.lastSeenAt = now
        -- /reload und echter Logout sind hier nicht unterscheidbar.
        -- Erst beim naechsten Login die letzte Session finalisieren.
        session.pendingExitAt = now
    end
end

-- Blizzard schickt TIME_PLAYED_MSG direkt an registrierte ChatFrames.
-- Es ist KEINE CHAT_MSG_SYSTEM-Nachricht, weshalb ChatFrame_AddMessageEventFilter
-- hier nicht greift. Für addoninterne Abfragen pausieren wir NUR dieses eine
-- Event auf den bereits registrierten Chatfenstern und stellen den Zustand
-- sofort nach der Antwort wieder her (ohne andere Systemmeldungen anzufassen).
function Clock:MutePlayedChat()
    if self.playtimeMutedChatFrames then return end
    local saved, seen = {}, {}
    local function TryMute(frame)
        if not frame or seen[frame] then return end
        seen[frame] = true
        if type(frame.IsEventRegistered) == 'function'
            and frame:IsEventRegistered('TIME_PLAYED_MSG')
            and type(frame.UnregisterEvent) == 'function'
            and type(frame.RegisterEvent) == 'function' then
            local ok = pcall(frame.UnregisterEvent, frame, 'TIME_PLAYED_MSG')
            if ok then saved[#saved + 1] = frame end
        end
    end
    if type(_G.CHAT_FRAMES) == 'table' then
        for _, name in ipairs(_G.CHAT_FRAMES) do
            TryMute(type(name) == 'string' and _G[name] or name)
        end
    end
    local count = tonumber(_G.NUM_CHAT_WINDOWS) or 10
    for i = 1, math.min(count, 50) do
        TryMute(_G['ChatFrame' .. i])
    end
    self.playtimeMutedChatFrames = saved
end

function Clock:RestorePlayedChat()
    local saved = self.playtimeMutedChatFrames
    self.playtimeMutedChatFrames = nil
    self.playtimeRestoreChatSoon = nil
    if not saved then return end
    for _, frame in ipairs(saved) do
        -- Only re-enable registrations that were active before OUR request.
        if type(frame.IsEventRegistered) == 'function'
            and not frame:IsEventRegistered('TIME_PLAYED_MSG') then
            pcall(frame.RegisterEvent, frame, 'TIME_PLAYED_MSG')
        end
    end
end

-- Nicht innerhalb des TIME_PLAYED_MSG-Dispatch wieder registrieren: Bei manchen
-- Clientversionen könnte sonst dieselbe Antwort doch noch im Chat erscheinen.
function Clock:RestorePlayedChatNextFrame()
    if not self.playtimeMutedChatFrames then return end
    if _G.C_Timer and type(_G.C_Timer.After) == 'function' then
        local mutedFrames = self.playtimeMutedChatFrames
        _G.C_Timer.After(0, function()
            -- Eine inzwischen gestartete neue Abfrage nicht versehentlich entstummen.
            if self.playtimeMutedChatFrames == mutedFrames then
                self:RestorePlayedChat()
            end
        end)
    else
        -- Fallback: PlaytimeOnTick() stellt spätestens im nächsten Tick wieder her.
        self.playtimeRestoreChatSoon = true
    end
end

-- Automatische und Shift-Anfragen teilen denselben Request-Weg. Manuelles
-- /played benutzt Blizzards Befehl und wird über TIME_PLAYED_MSG mitgespeichert.
-- Ein noch laufender Request wird gemeinsam benutzt statt doppelt gestartet.
function Clock:RequestPlayedTime(force)
    if not self.playtimeEvents then return false end
    if self.playtimePending then return true end
    local now = Uptime()
    if not force and self.playtimeRequestAllowedAt
        and now < self.playtimeRequestAllowedAt then return false end
    if type(_G.RequestTimePlayed) ~= 'function' then return false end
    -- Falls die letzte Antwort und der nächste Mouseover unmittelbar aufeinander
    -- folgen, alte Listener zuerst ordnungsgemäß wieder aktivieren.
    if self.playtimeMutedChatFrames then self:RestorePlayedChat() end
    self:MutePlayedChat()
    local ok = pcall(_G.RequestTimePlayed)
    if not ok then self:RestorePlayedChat() end
    if ok then
        self.playtimePending = true
        self.playtimeRequestSentAt = now
        self.playtimeRequestAllowedAt = now + PLAYED_REFRESH_SECONDS -- weitere optionale Anfragen
    end
    return ok
end

-- Ein normales Mouseover zeigt nur Uhrzeit und Sessions und fragt nichts ab.
function Clock:RequestPlayedOnHover()
    if self.playtimeHoverRequested then return end
    self.playtimeHoverRequested = true
    self.playtimeShiftRequested = false
    self.playtimeFreshForHover = false
    -- Wird Shift bereits vor dem Mouseover gehalten, direkt neue Werte anfordern.
    if type(_G.IsShiftKeyDown) == 'function' and _G.IsShiftKeyDown() then
        self:RequestPlayedOnShift()
    end
end

function Clock:RequestPlayedOnShift()
    if not self.playtimeHoverRequested or self.playtimeShiftRequested then return end
    self.playtimeShiftRequested = true
    self.playtimeFreshForHover = false
    -- Stille Anfrage. Eine laufende Hintergrundanfrage wird mitverwendet.
    self:RequestPlayedTime(true)
end

function Clock:EndPlayedHover()
    self.playtimeHoverRequested = false
    self.playtimeShiftRequested = false
    self.playtimeFreshForHover = false
end

function Clock:EnablePlaytime()
    if self.playtimeEvents then return end
    local frame = CreateFrame('Frame')
    frame:RegisterEvent('TIME_PLAYED_MSG')
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')
    frame:RegisterEvent('PLAYER_LOGOUT')
    frame:RegisterEvent('MODIFIER_STATE_CHANGED')
    frame:RegisterEvent('PLAYER_LEVEL_UP')
    frame:SetScript('OnEvent', function(_, event, ...)
        if event == 'TIME_PLAYED_MSG' then
            self:StorePlayedTime(...)
        elseif event == 'PLAYER_ENTERING_WORLD' then
            self:PlaytimeEnteringWorld(...)
        elseif event == 'PLAYER_LOGOUT' then
            self:SavePlaytimeEstimate()
        elseif event == 'MODIFIER_STATE_CHANGED' then
            local key, pressed = ...
            if type(key) == 'string' and key:find('SHIFT', 1, true) then
                if pressed == 1 or pressed == true then
                    -- Nur Shift beim tatsächlichen Uhr-Mouseover löst /played aus.
                    self:RequestPlayedOnShift()
                elseif not (type(_G.IsShiftKeyDown) == 'function' and _G.IsShiftKeyDown()) then
                    -- Nächstes Drücken, auch während desselben Mouseovers, neu abfragen.
                    self.playtimeShiftRequested = false
                    self.playtimeFreshForHover = false
                end
                if self.UpdateHoverTooltip then self:UpdateHoverTooltip() end
            end
        elseif event == 'PLAYER_LEVEL_UP' then
            -- Keine Extra-Abfrage beim Level-Up: nur Shift oder der nächste
            -- reguläre Zehn-Minuten-Request holt einen aktualisierten Serverwert.
            self.playtimeReceived = false
        end
    end)
    self.playtimeEvents = frame
end

function Clock:PlaytimeOnTick()
    if self.playtimeRestoreChatSoon then
        self.playtimeRestoreChatSoon = nil
        self:RestorePlayedChat()
    end
    if self.playtimePending and self.playtimeRequestSentAt
        and Uptime() - self.playtimeRequestSentAt > 20 then
        self.playtimePending = false -- Keine Serverantwort: nächster regulärer Termin.
        self:RestorePlayedChat()
    end
    local record = self:GetPlaytimeCharacter()
    local now = Epoch()
    if record and type(record.session) == 'table' and not record.session.pendingExitAt then
        record.session.lastSeenAt = now
    end
    if self.playtimeNextRequest and now >= self.playtimeNextRequest then
        local recordForSchedule = self:EnsurePlaytimeCharacter()
        if not recordForSchedule then
            self.playtimeNextRequest = now + 5 -- Charakter-ID noch nicht verfügbar.
        else
            -- Der nächste Termin wird unabhängig von Shift oder /played gespeichert.
            local nextAt = now + PLAYED_REFRESH_SECONDS
            recordForSchedule.nextAutoPlayedAt = nextAt
            self.playtimeNextRequest = nextAt
            self:RequestPlayedTime(true)
        end
    end
end
