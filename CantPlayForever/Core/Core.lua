
-- CantPlayForever / WoW Forever (Interface 16001)
-- Eigene große Uhr-TGA des Nutzers; kleine Uhr und weitere Grafiken aus dem Spiel.
local ADDON_NAME, ns = ...

local LibStub = _G.LibStub

if not LibStub then
    local locale = (_G.GetLocale and GetLocale()) or 'enUS'
    local message = locale == 'deDE' and 'Bibliothek LibStub fehlt.'
        or locale == 'frFR' and 'Bibliothèque LibStub manquante.'
        or 'LibStub library missing.'
    print("|cffff5555Can't play Forever: " .. message .. '|r')
    return
end

local AceAddon = LibStub('AceAddon-3.0', true)

local AceDB = LibStub('AceDB-3.0', true)

local AceConsole = LibStub('AceConsole-3.0', true)

local Broker = LibStub('LibDataBroker-1.1', true)

local DBIcon = LibStub('LibDBIcon-1.0', true)

local AceConfig = LibStub('AceConfig-3.0', true)

local AceDialog = LibStub('AceConfigDialog-3.0', true)

if not (AceAddon and AceDB and AceConsole and Broker and DBIcon and AceConfig and AceDialog) then
    local locale = (_G.GetLocale and GetLocale()) or 'enUS'
    local message = locale == 'deDE' and 'Eine eingebettete Bibliothek fehlt. Libs/embeds.xml prüfen.'
        or locale == 'frFR' and 'Bibliothèque intégrée manquante. Vérifiez Libs/embeds.xml.'
        or 'Missing embedded library. Check Libs/embeds.xml.'
    print("|cffff5555Can't play Forever: " .. message .. '|r')
    return
end

local L = LibStub('AceLocale-3.0'):GetLocale('CantPlayForever')

ns.L = L

local Clock = AceAddon:NewAddon('CantPlayForever', 'AceConsole-3.0')

ns.Clock = Clock
ns.Broker, ns.DBIcon = Broker, DBIcon

-- Alle Geometriewerte liegen in einer veränderbaren Tabelle (Standardwerte unten); das
-- Werte können über einen externen Debug-Inspector wie OAP Debug betrachtet werden.
local TUNE_DEFAULTS = {
    RING_X0 = 3, RING_Y0 = 6, RING_SIZE = 67,   -- Ausschnitt im Atlas (Atlas-Pixel)
    RING_MASK = 60.3, RING_MASK_H = 60.8,       -- Durchmesser der Kreismaske des Rings (B/H)
    RING_MASK_DX = 1.4, RING_MASK_DY = 1.65,    -- Maskenmitte relativ zur Ausschnittmitte
    GLOBE_MASK = 57,                            -- Kreismaske für den Globus (Durchmesser)
    GLOBE_MASK_DX = -1.1, GLOBE_MASK_DY = 1.4,  -- Mitte relativ zur Buttonmitte (= Ringmitte)
    GLOW_SHAPE = 0, GLOW_RING_SIZE = 64, GLOW_RING_DX = 0, GLOW_RING_DY = 0, -- Form: 0 gefüllt, 1 Ring (wie Mouseover), 2 beides
    GLOW_DISC = 52, GLOW_DX = -1.1, GLOW_DY = 1.4, -- Leuchtfläche: Durchmesser, Mitte relativ zum Button
    SHADOW_SIZE = 62, SHADOW_ALPHA = 0.7, SHADOW_DROP = 0.25, -- Schatten um den Ring
    RING_OFFSET = 7,                            -- Ecke relativ zum 64-px-Globus
    BADGE_SIZE = 18, BADGE_DISC = 14.5, BADGE_ICON = 12, BADGE_RING_SCALE = 0.3,
    TEXT_SIZE = 25, TEXT_SIZE_CD = 14.1, TEXT_MAXW = 45, -- Uhrzeit: Schrift ohne/mit Timer, max. Breite
    TEXT_X = -1, TEXT_Y = 1, TEXT_Y_CD = 4.9,              -- Uhrzeit: Position (Y mit Timer = höher)
    CD_SIZE = 11.4, CD_MAXW = 34, CD_X = 0, CD_Y = -9, -- Timer-Zahl: Schrift, max. Breite, Position
    CD_SUFFIX_MIN = '', CD_SUFFIX_SEC = '', CD_SUFFIX_HRS = '',                -- Text hinter der Timer-Zahl; leer = Einheit der Spielsprache (L.UNIT_*)
    STAGE_ZOOM = 5, STAGE_GRID = 1, STAGE_BADGES = 1, STAGE_TEXT = 1, STAGE_TIMER = 1, STAGE_TIMER_SEC = 0, -- Testbühne: Vergrößerung, Mittelkreuz, Symbole (1/0)
    BADGE_R = 0.80, BADGE_G = 0.55, BADGE_B = 0.26, BADGE_RING = 1, -- Symbolfarbe, Ring an/aus (1/0)
    TIMER_WARN_SEC = 10, TIMER_WARN_GLOW = '3399FF, pulse, 1, 90, ring, 95px, native', TIMER_WARN_GLOW_SMALL = '3399FF, pulse, 1, 90, fill', -- Timer: Warn-Leuchten in den letzten Sekunden
    SMALL_DX = 0, SMALL_DY = 0.5, -- Kleine Uhr (Standardrahmen): Mitte auf der Scheibe
    SMALL_DOTS = 26, -- Punkte: Größe des Punktebilds (größer = weiter außen)
    SMALL_HOUR_LEN = 5, SMALL_HOUR_W = 1.5, SMALL_MIN_LEN = 10, SMALL_MIN_W = 0.75, -- Zeiger: Länge und Dicke (Pixel)
    TIMER_ICON_SIZE = 28, TIMER_FRAME_SIZE = 53, ALARM_ICON_SIZE = 28, ALARM_FRAME_SIZE = 53, -- Symbol und Rahmen einzeln (Bibliothekseinheiten)
    BADGE_FRAME_R = 1.1, BADGE_FRAME_G = 1.1, BADGE_FRAME_B = 0.95, BADGE_FRAME_DESAT = 0, -- Timer-/Alarm-Symbol: Rahmenfarbe (Standardrahmen der Bibliothek)
    TIMER_ICON_R = 0.25, TIMER_ICON_G = 1, TIMER_ICON_B = 0.25, TIMER_ICON_DESAT = 0, -- Timer-Symbol: Farbe (1/1/1 = Original)
    ALARM_ARMED_R = 0.25, ALARM_ARMED_G = 1, ALARM_ARMED_B = 0.25, -- Alarm-Symbol bei aktivierten Weckern (grünlich)
    ALARM_ICON_R = 1, ALARM_ICON_G = 1, ALARM_ICON_B = 1, ALARM_ICON_DESAT = 1, -- Alarm-Symbol: Farbe
    LOGO_X = 0, LOGO_Y = 25, -- Optionen-Logo: Lage relativ zur Oberkante des Fensters
    DIAMOND_X = 28.5, DIAMOND_Y = 0, DIAMOND_SIZE = 34, DIAMOND_R = 1.1, DIAMOND_G = 1.1, DIAMOND_B = 0.95, DIAMOND_DESAT = 1, -- Optionen-Logo: Rauten (Mitte relativ zum Logo, Größe, Farbe)
    -- Optionsfenster im Blizzard-Uhrenrahmen (Lage relativ zu Rahmenecke bzw. Fensterrand)
    OPT_CLOCK_DX = -11, OPT_CLOCK_DY = 11, OPT_CLOCK_SIZE = 52.5, -- Uhrenkreis in der Ecke: Versatz zur Eckenmitte, Durchmesser
    OPT_TIME_SIZE = 18, OPT_TIME_DX = 0, OPT_TIME_DY = 0,       -- Uhrzeit im Kreis
    OPT_CLOSE_X = 1.5, OPT_CLOSE_Y = 3.5, OPT_CLOSE_SIZE = 28.5,     -- rotes X (Versatz zur Fensterecke oben rechts)
    OPT_TITLE_X = 63, OPT_TITLE_Y = -33, OPT_TAGLINE_DY = -2,    -- Name und Untertitel (links oben)
    OPT_CONTENT_TOP = 60,                                       -- Beginn des Inhalts (Abstand zur Oberkante)
    ROW_PLAY_SIZE = 18, ROW_PLAY_X = 0, ROW_PLAY_Y = 0,         -- Listen-Symbole: Start/Stopp-Pfeil (Größe, Versatz rechts/oben)
    ROW_EDIT_SIZE = 22, ROW_EDIT_X = 0, ROW_EDIT_Y = 0,         -- Zahnrad (Bearbeiten)
    ROW_DEL_SIZE = 18, ROW_DEL_X = 0, ROW_DEL_Y = 0,            -- Papierkorb
    ALARM_SCALE = 1, TIMER_SCALE = 1,                              -- Einzelgrößen (Faktor)
    ALARM_X = -24, ALARM_Y = 25, TIMER_X = -30.5, TIMER_Y = 12, -- Statussymbole (Mitte relativ zum Button)
}

local T = {}

ns.T = T

for key, value in pairs(TUNE_DEFAULTS) do T[key] = value end

Clock.tune, Clock.tuneDefaults = T, TUNE_DEFAULTS

Clock.L = L

_G.CantPlayForever = Clock

Clock.iconLibrary = DBIcon

Clock.aceConfig = AceConfig

Clock.aceDialog = AceDialog

local DEFAULTS = {
    global = { scope = 'account', oapLevel = 'metrics', playtime = {characters = {}} }, -- technisches Logging nur über optionales OAP Debug
    profile = {
        minimap = { hide = false, minimapPos = 90 },
        useLocalTime = true,
        hideBlizzardClock = true, -- Blizzard-Uhr ausblenden, solange unsere Uhr sichtbar ist
        clockStyle = 'digital', -- 'digital' | 'analog' (für alle Größen)
        use24Hour = true,
        -- Größe in UI-Pixeln. Alte Profile mit smallClock=true starten bei 32px.
        -- clockSize bleibt ohne Default, damit alte smallClock-Profile migriert werden.
        smallClock = false, -- Nur zur Migration alter BetterClock-/CPF-Einstellungen
        blizzardLook = true, -- 64 px: Original-Blizzard-Globus samt Ring (Ingame-Texturen)
        playSound = true,
        screenGlow = false,
        screenGlowSkipInstances = true,
        screenGlowSpec = 'FF2619, pulse, 1, 30',
        -- Pro Modul getrennte visuelle Effekte; kuenftig pro Alarm ueberschreibbar.
        effects = {
            timer = {screenGlow = false, glowSpeed = 1, skipInstances = true,
                     spec = '3399FF, pulse, 1, 30'},
            alarms = {screenGlow = false, glowSpeed = 1, skipInstances = true,
                      spec = 'FF2619, pulse, 1, 30'},
            health = {screenGlow = false, glowSpeed = 1, skipInstances = true,
                      spec = '5FFF4F, pulse, 1, 10',
                      iconEnabled = true, iconTransparency = 65, iconOffsetY = 65},
        },
        alarmSound = 'alarm2',
        alarmRepeats = 2,
        alarmDisarmOrder = 'farthest', -- Strg+Linksklick: 'farthest' = entferntester zuerst, 'nearest' = nächster zuerst
        alarms = {},
        -- Keine vorbelegten Listen als AceDB-Defaults: sonst können gelöschte
        -- Vorgaben nach /reload wieder aus den Defaults auftauchen.
        presets = {},
        nextAlarmID = 1,
        nextPresetID = 4,
        activeTimer = nil,
        selectedPresetID = 1,
        modules = { clock = true, timer = true, alarms = true, health = false, stats = false, events = false },
        health = {
            movement = { customEffect = false, enabled = true, interval = 45,
                customMessagesEnabled = false, mixWithDefault = false },
            drinking = { customEffect = false, enabled = true, interval = 30,
                customMessagesEnabled = false, mixWithDefault = false },
            eyes = { customEffect = false, enabled = true, interval = 20,
                customMessagesEnabled = false, mixWithDefault = false },
            notice = 'screen', -- screen | chat | both
            sound = false,
            -- Im Kampf und in Instanzen: automatisch nur Chat (keine optischen Effekte).
        },
    },
}

-- Modulsystem: jedes Modul (Modules/<Name>/) meldet sich mit RegisterModule an.
--   id, locked (Kernmodul, immer aktiv), available = false (geplant, Schalter gesperrt),
--   hidden (kein Schalter in den Optionen, z. B. Entwicklungswerkzeuge)
--   Haken: OnInitialize, OnEnable, OnTick (jede Sekunde), OnChanged (Einstellung/Zustand geändert),
--          OnRefresh (Profilwechsel), OnSlash(input) -> true wenn behandelt,
--          GetOptions() -> {key, name, order, args}
Clock.MODULES = {}

-- Clock:Debug/Clock:OAPLog werden zentral in Core/OAPDebug.lua definiert.

local moduleIndex = {}

function Clock:RegisterModule(def)
    table.insert(self.MODULES, def)
    if def.id then moduleIndex[def.id] = def end
    self:Debug('Module registered: %s', tostring(def.id))
    self:OAPCounter('modules.registered')
    return def
end

function Clock:IsModuleEnabled(id)
    local module = moduleIndex[id]
    if not module then return false end
    if module.locked then return true end
    if module.available == false then return false end
    local modules = self.db and self.db.profile.modules
    return not (modules and modules[id] == false)
end

-- Ruft den Haken in allen aktiven Modulen auf (always = true: auch in ausgeschalteten).
function Clock:RunHook(name, always, ...)
    for _, module in ipairs(self.MODULES) do
        local hook = module[name]
        if hook and (always or self:IsModuleEnabled(module.id)) then
            if name == 'OnTick' then
                -- A broken module must not prevent the other modules from ticking.
                local key = module.tickKey
                if not key then key = 'module.' .. module.id; module.tickKey = key end
                self:GuardedTick(key, hook)
            else
                hook(self, ...)
            end
        end
    end
end

local function Between(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(maximum, math.floor(value)))
end

ns.Between = Between

local function Now()
    if type(_G.GetServerTime) == 'function' then
        return _G.GetServerTime()
    end
    return time()
end

ns.Now = Now

function Clock:ProfileName()
    if self.db.global.scope == 'character' then
        return 'Character: ' .. self.db.keys.char
    end
    return 'Account'
end

local STARTER_PRESETS = {
    { id = 1, name = L.STARTER_5, seconds = 300 },
    { id = 2, name = L.STARTER_15, seconds = 900 },
    { id = 3, name = L.STARTER_60, seconds = 3600 },
}

-- Alle Listen sind echte, gespeicherte Profildaten, keine mit AceDB
-- automatisch wiederhergestellten Vorgaben. Ein Initialisierungsmarker
-- bleibt auch dann gespeichert, wenn alle Vorgaben gelöscht wurden.
function Clock:MigrateProfile(isNewProfile)
    local p = self.db.profile
    -- Alter Modulname Wellness wird bei vorhandenen Profilen einmalig übernommen.
    -- AceDB-Defaults liefern health=false, ohne einen neuen Wert zu speichern.
    if type(p.modules) ~= 'table' then p.modules = {} end
    local savedModules = self.db.sv and self.db.sv.profiles
        and self.db.sv.profiles[self.db:GetCurrentProfile()]
        and self.db.sv.profiles[self.db:GetCurrentProfile()].modules
    if type(savedModules) == 'table' and savedModules.wellness ~= nil and savedModules.health == nil then
        p.modules.health = savedModules.wellness == true
    end
    -- Altes stufenloses Größenfeld auf drei feste Stufen migrieren.
    -- Die alte Standardgröße 84 wird zu 64 (Mittel).
    local oldSize = tonumber(p.clockSize)
    if oldSize == nil then
        p.clockSize = p.smallClock and 32 or 64
    elseif oldSize < 48 then
        p.clockSize = 32
    elseif oldSize < 80 then
        p.clockSize = 64
    else
        p.clockSize = 95
    end
    -- Eigene Minimap-Winkel pro Größe. LibDBIcon misst ab Osten gegen
    -- den Uhrzeigersinn: 270° = Süden, 90° = Norden.
    -- Die gewünschten Standard-Winkel werden hier von Norden aus angegeben:
    -- 32px = 180° (Süden), 64px = 0° (Norden).
    if type(p.minimapPositions) ~= 'table' then
        p.minimapPositions = { [32] = 270, [64] = 90 }
        -- Bei einer Aktualisierung nur die bisher aktive Position erhalten.
        -- Andere Größe bekommt ihre neu definierte Standardposition.
        if not isNewProfile and (p.clockSize == 32 or p.clockSize == 64) then
            local saved = p.minimap and tonumber(p.minimap.minimapPos)
            if saved then p.minimapPositions[p.clockSize] = saved % 360 end
        end
    end
    if type(p.minimap) ~= 'table' then p.minimap = {} end
    if p.clockSize == 32 or p.clockSize == 64 then
        p.minimap.minimapPos = p.minimapPositions[p.clockSize]
    end
    -- Vorhandene allgemeine Effekte einmalig als Alarmeffekte uebernehmen.
    if not p.effectsMigrated then
        local alarmsEffect = p.effects.alarms
        alarmsEffect.screenGlow = p.screenGlow == true
        alarmsEffect.glowSpeed = tonumber(p.glowSpeed) or 1
        alarmsEffect.skipInstances = p.screenGlowSkipInstances ~= false
        alarmsEffect.spec = p.screenGlowSpec or 'FF2619, pulse, 1, 30'
        p.effectsMigrated = true
    end
    p.alarmRepeats = math.max(1, math.min(10, math.floor(tonumber(p.alarmRepeats) or 2)))
    if not ({alarm1=true, alarm2=true, alarm3=true, ready=true})[p.alarmSound] then
        p.alarmSound = 'alarm2'
    end
    if type(p.alarms) ~= 'table' then p.alarms = {} end
    if type(p.presets) ~= 'table' then p.presets = {} end
    if not p.presetsInitialized then
        if isNewProfile and #p.presets == 0 then
            local starter = {}
            for i, item in ipairs(STARTER_PRESETS) do
                starter[i] = { id = item.id, name = item.name, seconds = item.seconds }
            end
            p.presets = starter
        end
        p.presetsInitialized = true
    end
    local maxAlarmID = 0
    for _, alarm in ipairs(p.alarms) do
        ns.MigrateAlarm(alarm)
        -- Alarm-Kategorie erstmals speichern; alte Alarme sind weiterhin Wecker.
        if alarm.alarmType ~= 'alarm' and alarm.alarmType ~= 'event'
            and alarm.alarmType ~= 'reminder' then
            alarm.alarmType = 'alarm'
        end
        if type(alarm.effect) ~= 'table' then alarm.customEffect = false end
        if alarm.selected == nil then alarm.selected = alarm.enabled ~= false end
        if alarm.armed == nil then alarm.armed = false end
        maxAlarmID = math.max(maxAlarmID, tonumber(alarm.id) or 0)
    end
    local maxPresetID = 0
    for _, preset in ipairs(p.presets) do
        maxPresetID = math.max(maxPresetID, tonumber(preset.id) or 0)
    end
    p.nextAlarmID = math.max(tonumber(p.nextAlarmID) or 1, maxAlarmID + 1)
    p.nextPresetID = math.max(tonumber(p.nextPresetID) or 4, maxPresetID + 1)
end

-- Alarm-Zeitplan (Version 2): Wochentage (days), Datum (day/month/year) mit "jeden Monat"/"jedes
-- Jahr". Ältere Alarme hatten mode = daily/weekdays/date.
function ns.MigrateAlarm(alarm)
    if alarm.sched == 2 then return end
    local today = date('*t')
    alarm.days = type(alarm.days) == 'table' and alarm.days or {}
    alarm.day, alarm.month, alarm.year = alarm.day or today.day, alarm.month or today.month, alarm.year or today.year
    if alarm.mode == 'date' then
        alarm.days = {}
        alarm.everyMonth, alarm.everyYear = false, alarm.repeating == true
        alarm.repeating = false
    else
        if alarm.mode ~= 'weekdays' then
            for wday = 1, 7 do alarm.days[wday] = true end
        end
        alarm.everyMonth, alarm.everyYear = true, true
    end
    alarm.mode, alarm.sched = nil, 2
end

function Clock:SwitchProfile(scope)
    if scope ~= 'account' and scope ~= 'character' then return end
    self.db.global.scope = scope
    self:OAPLog('info', 'Save scope: {1}', scope)
    local name = self:ProfileName()
    local isNew = not (self.db.sv and self.db.sv.profiles
        and self.db.sv.profiles[name] ~= nil)
    self.db:SetProfile(name)
    self:MigrateProfile(isNew)
    self:RunHook('OnRefresh', true)
    self:OAPCounter('profiles.changed')
    self:NotifyOptions()
end

function Clock:NotifyOptions()
    if LibStub('AceConfigRegistry-3.0', true) then
        LibStub('AceConfigRegistry-3.0'):NotifyChange('CantPlayForever')
    end
    self:RunHook('OnChanged', true)
end

-- An explicit page opens that page even when the window is already visible.
-- Without a page this behaves as a toggle for /bc.
function Clock:OpenSettings(page)
    self:Debug('Opening options: %s', tostring(page))
    if page then
        self.aceDialog:Open('CantPlayForever')
        self.aceDialog:SelectGroup('CantPlayForever', page)
    elseif self.aceDialog.OpenFrames and self.aceDialog.OpenFrames.CantPlayForever then
        self.aceDialog:Close('CantPlayForever')
        return
    else
        self.aceDialog:Open('CantPlayForever')
    end
    if self.StyleOptionsFrame then self:GuardedTick('options.style', self.StyleOptionsFrame) end
end

function Clock:OnInitialize()
    -- Erkennen, ob das Profil schon in der SavedVariables-Datei existierte.
    -- Gelöschte Einträge älterer Versionen dürfen nicht neu erzeugt werden.
    local existing = {}
    -- Migration: Einstellungen der alten SavedVariables (BetterClockSettings) einmalig
    -- in CantPlayForeverSettings übernehmen. Die alte Tabelle bleibt unverändert als Sicherung.
    local old = _G.BetterClockSettings
    local current = _G.CantPlayForeverSettings
    if type(old) == 'table' and not (type(current) == 'table' and current.profiles) then
        local function Copy(value)
            if type(value) ~= 'table' then return value end
            local result = {}
            for key, entry in pairs(value) do result[key] = Copy(entry) end
            return result
        end
        _G.CantPlayForeverSettings = Copy(old)
    end
    local saved = _G.CantPlayForeverSettings
    if type(saved) == 'table' and type(saved.profiles) == 'table' then
        for profileName in pairs(saved.profiles) do existing[profileName] = true end
    end
    self.db = AceDB:New('CantPlayForeverSettings', DEFAULTS, true)
    -- Alten Chat-Debug-Schalter nur einmal übernehmen und danach entfernen.
    -- Ein deaktivierter alter Schalter wird nicht automatisch zu OAP-Debug-Detail.
    local storedGlobal = self.db.sv and self.db.sv.global
    if type(storedGlobal) == 'table' then
        if storedGlobal.oapLevel == nil and storedGlobal.debug == true then
            self.db.global.oapLevel = 'detailed'
        end
        storedGlobal.debug = nil
    end
    self:RegisterOAPDebug()
    local name = self:ProfileName()
    self.db:SetProfile(name)
    self:MigrateProfile(not existing[name])
    -- Spielzeit darf weder die Module noch das Optionsmenue am Start blockieren.
    self:GuardedTick('playtime.initialize', self.InitializePlaytime)

    self:InitializeAlarmNotice()
    self:RegisterChatCommand('bc', 'SlashCommand')
    self:RegisterChatCommand('betterclock', 'SlashCommand')
    self:RegisterChatCommand('cpf', 'SlashCommand')
    self:RegisterChatCommand('cantplayforever', 'SlashCommand')
    self:RunHook('OnInitialize', true)
    self:InitializeOptions()
end

function Clock:OnEnable()
    -- Optionale /played-Erfassung isolieren; Clock/Timer/Health muessen weiterlaufen.
    self:GuardedTick('playtime.enable', self.EnablePlaytime)
    self:GuardedTick('modules.enable', function(core) core:RunHook('OnEnable') end)
    -- Je nach Forever-Client kann der Blizzard-Compartment-Aufruf scheitern.
    -- Er darf die zentrale Tick-Registrierung niemals verhindern.
    self:GuardedTick('compartment.register', self.RegisterAddonCompartment)
    self:OAPLog('info', 'Addon enabled (profile: {1})', self:ProfileName())
    local function Update()
        self:OAPStartTimer('core.tick')
        -- Alarmmeldung und Leuchten zuerst und einzeln abgesichert: ein Fehler in einem
        -- Modul-Tick darf das Zurücksetzen nach einem Alarm nicht verhindern.
        self:GuardedTick('notice', self.UpdateAlarmNotice)
        self:GuardedTick('sound', self.UpdateAlarmSoundSequence)
        -- Kein ungeschuetzter Aufruf VOR den eigentlichen Modul-Ticks.
        self:GuardedTick('playtime', self.PlaytimeOnTick)
        self:RunHook('OnTick')
        if self:IsOAPDebugAvailable() then
            self:OAPCounter('core.ticks')
            self:GuardedTick('telemetry.snapshot', self.OAPSnapshot)
            self:OAPStopTimer('core.tick')
        end
    end
    if _G.C_Timer and type(C_Timer.NewTicker) == 'function' then
        self.tick = C_Timer.NewTicker(1, Update)
    else
        self.tickFrame = self.tickFrame or CreateFrame('Frame')
        local elapsedTotal = 0
        self.tickFrame:SetScript('OnUpdate', function(_, elapsed)
            elapsedTotal = elapsedTotal + elapsed
            if elapsedTotal >= 1 then
                elapsedTotal = elapsedTotal % 1
                Update()
            end
        end)
    end
    local getMeta = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
    local version = getMeta and getMeta(ADDON_NAME, 'Version') or '?'
    self:Print(string.format(L.VERSION_LOADED, tostring(version)))
end

function Clock:OnDisable()
    if self.SavePlaytimeEstimate then self:GuardedTick('playtime.save', self.SavePlaytimeEstimate) end
    if self.tick then self.tick:Cancel(); self.tick = nil end
    if self.tickFrame then self.tickFrame:SetScript('OnUpdate', nil) end
end

function Clock:SlashCommand(input)
    input = tostring(input or ''):lower():match('^%s*(.-)%s*$')
    for _, module in ipairs(self.MODULES) do
        if module.OnSlash and self:IsModuleEnabled(module.id) and module.OnSlash(self, input) then return end
    end
    if input == 'help' then
        self:Print(L.CMD_HELP)
    elseif input == 'settings' then
        self:OpenSettings('general')
    else
        self:OpenSettings(self:IsModuleEnabled('alarms') and 'alarms' or 'general')
    end
end
