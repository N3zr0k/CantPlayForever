-- Leuchtender Bildschirmrand bei Alarm (wie bei wenig Leben). Vier Farbverlauf-Streifen an den
-- Rändern von UIParent, ohne Bilddatei. Farbe, Art und Stärke kommen aus derselben
-- Leuchtzeile wie alle Glows ("FARBCODE, static|pulse|blink, [Sekunden,] Prozent").
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

-- Dieselben Standardwerte wie in Core.DEFAULTS.profile.effects.
-- Getrennte Fallbacks verhindern, dass ein ungueltiger Health-Wert rot (Alarm) wird.
local EFFECT_DEFAULT_SPECS = {
    timer = '3399FF, pulse, 1, 30',
    alarms = 'FF2619, pulse, 1, 30',
    health = '5FFF4F, pulse, 1, 10',
}
local EDGE_WIDTH, EDGE_HEIGHT = 0.12, 0.20 -- Anteil der Bildschirmbreite/-höhe

local EFFECT_SOURCES = { timer = true, alarms = true, health = true }

function Clock:GetEffectConfig(source)
    source = EFFECT_SOURCES[source] and source or 'alarms'
    local profile = self.db and self.db.profile
    local effects = profile and profile.effects
    local config = effects and effects[source]
    if config then return config end
    -- Falls ein aelterer Charakter-Profilstand noch nicht migriert wurde.
    return {screenGlow = source == 'alarms' and profile and profile.screenGlow == true,
        glowSpeed = profile and profile.glowSpeed or 1,
        skipInstances = profile and profile.screenGlowSkipInstances ~= false,
        spec = source == 'alarms'
            and (profile and profile.screenGlowSpec or EFFECT_DEFAULT_SPECS.alarms)
            or EFFECT_DEFAULT_SPECS[source]}
end

-- Overrides dürfen pro Alarm oder Health-Kategorie Farben enthalten.
-- Die globale Health-Farbe ist dagegen immer fest: alte gespeicherte Farben
-- beeinflussen weder Kategorien noch die neutrale Health-Testmeldung.
-- Effektart, Dauer, Deckkraft und optionale Spec-Teile bleiben erhalten.
function Clock:GetScreenGlowSpec(source, override)
    local isOverride = type(override) == 'table' and type(override.spec) == 'string'
    local spec = isOverride and override.spec or self:GetEffectConfig(source).spec
    if spec and self:ParseGlowSpec(spec) then
        if source == 'health' and not isOverride then
            -- Erst nach erfolgreicher Validierung die erste HEX-Angabe ersetzen.
            return (spec:gsub('^(%s*#?)%x%x%x%x%x%x(%s*,)', '%1' .. '5FFF4F' .. '%2', 1))
        end
        return spec
    end
    source = EFFECT_SOURCES[source] and source or 'alarms'
    return EFFECT_DEFAULT_SPECS[source]
end

-- Die Einstellungen werden weiterhin im bisherigen Spec-Format gespeichert.
-- Damit bleiben alte SavedVariables und optionale Form-/Groessenangaben kompatibel.
local function Clamp(number, low, high)
    return math.max(low, math.min(high, tonumber(number) or low))
end

local function ColorHex(color)
    local values = {}
    for index = 1, 3 do
        values[index] = math.floor(Clamp(color[index], 0, 1) * 255 + 0.5)
    end
    return string.format('%02X%02X%02X', values[1], values[2], values[3])
end

function Clock:GetEffectStyle(source, override)
    return self:ParseGlowSpec(self:GetScreenGlowSpec(source, override))
end

function Clock:GetEffectPeriod(source, override)
    local config = type(override) == 'table' and override or self:GetEffectConfig(source)
    if tonumber(config.periodSeconds) then
        return Clamp(config.periodSeconds, 0.2, 10)
    end
    -- Vor dem neuen Regler war glowSpeed (Pulse pro Sekunde) ausschlaggebend.
    -- Fuer bestehende Profile mit angepasster Geschwindigkeit diese uebernehmen.
    local speed = tonumber(config.glowSpeed)
    if speed and speed > 0 and math.abs(speed - 1) > 0.001 then
        return Clamp(1 / speed, 0.2, 10)
    end
    local style = self:GetEffectStyle(source, override)
    return Clamp(style and style.period or 1, 0.2, 10)
end

function Clock:GetEffectColorHex(source, override)
    local style = self:GetEffectStyle(source, override)
    return ColorHex(style and style.color or {1, 0.15, 0.10})
end

function Clock:SetEffectSettingForConfig(source, config, field, value, green, blue)
    if type(config) ~= 'table' then return false end
    local style = self:GetEffectStyle(source, config)
    if not style then return false end
    local color = {unpack(style.color)}
    local mode = style.mode
    local percent = math.floor(Clamp(style.alpha * 100, 0, 100) + 0.5)
    local period = self:GetEffectPeriod(source, config)
    if field == 'color' then
        color = {Clamp(value, 0, 1), Clamp(green, 0, 1), Clamp(blue, 0, 1)}
    elseif field == 'mode' then
        if value ~= 'pulse' and value ~= 'static' and value ~= 'blink' then return false end
        mode = value
    elseif field == 'period' then
        period = math.floor(Clamp(value, 0.2, 10) * 10 + 0.5) / 10
    elseif field == 'percent' then
        percent = math.floor(Clamp(value, 0, 100) + 0.5)
    else
        return false
    end
    config.periodSeconds = period -- auch bei static den zuletzt gewaehlten Takt merken
    local parts = {ColorHex(color), mode}
    if mode ~= 'static' then parts[#parts + 1] = string.format('%.1f', period) end
    parts[#parts + 1] = tostring(percent)
    -- Nicht in der UI gezeigte Zusatzdaten der bestehenden Glow-Spezifikation behalten.
    if style.shape ~= nil then
        parts[#parts + 1] = ({[0]='fill', [1]='ring', [2]='both'})[style.shape]
    end
    if style.size then parts[#parts + 1] = tostring(style.size) .. 'px' end
    if style.native then parts[#parts + 1] = 'native' end
    config.spec = table.concat(parts, ', ')
    return true
end

function Clock:SetEffectSetting(source, field, value, green, blue)
    -- Der globale Health-Effekt definiert nur Art, Dauer und Deckkraft.
    -- Nur individuell aktivierte Health-Kategorien dürfen die Farbe ändern.
    if source == 'health' and field == 'color' then return false end
    return self:SetEffectSettingForConfig(source, self:GetEffectConfig(source), field, value, green, blue)
end

-- The alarm owns only an optional appearance. The global enable toggle and
-- instance exclusion retain precedence even if an override is configured.
function Clock:GetAlarmEffectOverride(alarm)
    if alarm and alarm.customEffect == true and type(alarm.effect) == 'table' then
        return alarm.effect
    end
end

function Clock:SetAlarmCustomEffect(alarm, enabled)
    if enabled and type(alarm.effect) ~= 'table' then
        local global = self:GetEffectConfig('alarms')
        alarm.effect = {
            spec = self:GetScreenGlowSpec('alarms'),
            periodSeconds = self:GetEffectPeriod('alarms'),
            glowSpeed = global.glowSpeed,
        }
    end
    alarm.customEffect = enabled == true
end

-- Eigene Darstellung je Health-Kategorie. Ohne Haken gilt die globale Health-Vorgabe.
-- Die globalen Ein-/Ausschalter und Sicherheitsregeln behalten immer Vorrang.
local HEALTH_CATEGORIES = { movement = true, drinking = true, eyes = true }
local HEALTH_ICON_DEFAULTS = {iconEnabled = true, iconTransparency = 65, iconOffsetY = 65}

-- Global settings: effects.health.icon*. Individual settings: health[category].effect.icon*.
-- Legacy versions stored icon values directly under health[category]; read those only
-- when an individual override is active, otherwise global settings must prevail.
function Clock:GetHealthIconSetting(category, field)
    if HEALTH_ICON_DEFAULTS[field] == nil then return nil end
    if HEALTH_CATEGORIES[category] then
        local health = self.db and self.db.profile and self.db.profile.health
        local setting = health and health[category]
        if setting and setting.customEffect == true then
            if type(setting.effect) == 'table' and setting.effect[field] ~= nil then
                return setting.effect[field]
            end
            if setting[field] ~= nil then return setting[field] end -- SavedVariables migration
        end
    end
    local global = self:GetEffectConfig('health')
    if global[field] ~= nil then return global[field] end
    return HEALTH_ICON_DEFAULTS[field]
end

function Clock:SetHealthIconSetting(category, field, value)
    if HEALTH_ICON_DEFAULTS[field] == nil then return end
    local config
    if HEALTH_CATEGORIES[category] then
        local health = self.db and self.db.profile and self.db.profile.health
        local setting = health and health[category]
        if not setting or setting.customEffect ~= true or type(setting.effect) ~= 'table' then return end
        config = setting.effect
    else
        config = self:GetEffectConfig('health')
    end
    if field == 'iconEnabled' then
        config[field] = value == true
    elseif field == 'iconTransparency' then
        config[field] = math.floor(Clamp(value, 0, 100) + 0.5)
    else
        config[field] = math.floor(Clamp(value, -120, 120) + 0.5)
    end
end

-- Same icon controls in Options > Effects > Health > Appearance and in the
-- category editor when the "custom effect appearance" checkbox is active.
function ns.HealthIconAppearanceArgs(category)
    local L = ns.L
    local function Get(field) return Clock:GetHealthIconSetting(category, field) end
    local function Set(field, value)
        Clock:SetHealthIconSetting(category, field, value)
        if Clock.NotifyOptions then Clock:NotifyOptions() end
    end
    return {
        iconEnabled = {
            type = 'toggle', name = L.HEALTH_ICON_ENABLED, order = 10, width = 'full',
            get = function() return Get('iconEnabled') ~= false end,
            set = function(_, enabled) Set('iconEnabled', enabled) end,
        },
        iconTransparency = {
            type = 'range', name = L.HEALTH_ICON_TRANSPARENCY,
            desc = L.HEALTH_ICON_TRANSPARENCY_DESC,
            order = 11, width = 'full', min = 0, max = 100, step = 1,
            hidden = function() return Get('iconEnabled') == false end,
            get = function() return Get('iconTransparency') end,
            set = function(_, value) Set('iconTransparency', value) end,
        },
        iconOffsetY = {
            type = 'range', name = L.HEALTH_ICON_OFFSET_Y,
            desc = L.HEALTH_ICON_OFFSET_Y_DESC,
            order = 12, width = 'full', min = -120, max = 120, step = 1,
            hidden = function() return Get('iconEnabled') == false end,
            get = function() return Get('iconOffsetY') end,
            set = function(_, value) Set('iconOffsetY', value) end,
        },
    }
end

-- Kategorie-Farben entsprechen den Iconmotiven und sind ohne aktivierte
-- individuelle Darstellung immer bindend; auch bei alten globalen Farbwerten.
local HEALTH_ICON_COLORS = {
    movement = { Alliance = '5FFF4F', Horde = 'F4A34C' },
    drinking = { Alliance = '3399FF', Horde = 'FF5844' },
    eyes = { Alliance = 'FFFFFF', Horde = 'FFFFFF' },
}

function Clock:GetHealthEffectOverride(category)
    if not HEALTH_CATEGORIES[category] then return nil end
    local health = self.db and self.db.profile and self.db.profile.health
    local setting = health and health[category]
    if setting and setting.customEffect == true and type(setting.effect) == 'table' then
        return setting.effect
    end
    -- Effektart, Dauer und Deckkraft weiter aus der globalen Health-Konfiguration
    -- übernehmen, aber die Farbe immer aus der jeweiligen Kategorie bestimmen.
    local global = self:GetEffectConfig('health')
    local faction = type(_G.UnitFactionGroup) == 'function' and _G.UnitFactionGroup('player') or 'Alliance'
    if faction ~= 'Horde' then faction = 'Alliance' end
    local color = HEALTH_ICON_COLORS[category][faction]
    local config = {spec = self:GetScreenGlowSpec('health'), periodSeconds = global.periodSeconds,
        glowSpeed = global.glowSpeed}
    self:SetEffectSettingForConfig('health', config, 'color',
        tonumber(color:sub(1, 2), 16) / 255, tonumber(color:sub(3, 4), 16) / 255,
        tonumber(color:sub(5, 6), 16) / 255)
    return config
end

function Clock:SetHealthCustomEffect(category, enabled)
    if not HEALTH_CATEGORIES[category] then return end
    local health = self.db and self.db.profile and self.db.profile.health
    local setting = health and health[category]
    if not setting then return end
    if enabled and type(setting.effect) ~= 'table' then
        local global = self:GetEffectConfig('health')
        -- Erstaktivierung beginnt mit der zur Fraktion passenden Kategorie-Farbe.
        local effective = self:GetHealthEffectOverride(category)
        setting.effect = {
            spec = effective and effective.spec or self:GetScreenGlowSpec('health'),
            periodSeconds = self:GetEffectPeriod('health', effective),
            glowSpeed = global.glowSpeed,
        }
    end
    if enabled then
        -- Save the inherited/legacy icon settings when an individual editor is
        -- first enabled; older category-specific preferences are not discarded.
        for field in pairs(HEALTH_ICON_DEFAULTS) do
            if setting.effect[field] == nil then
                local legacy = setting[field]
                if legacy ~= nil then
                    setting.effect[field] = legacy
                else
                    setting.effect[field] = self:GetHealthIconSetting(nil, field)
                end
            end
        end
    end
    -- Eigene Werte bleiben beim Ausschalten gespeichert.
    setting.customEffect = enabled == true
end

-- Shared AceConfig appearance controls: reused by the module-wide settings
-- and by individual alarms so both editors always offer the same options.
function ns.EffectAppearanceArgs(source, getOverride, disabled)
    local L = ns.L
    local function Override() return getOverride and getOverride() or nil end
    local function Style() return Clock:GetEffectStyle(source, Override()) end
    local function Update(field, value, g, b)
        local override = Override()
        if override then
            Clock:SetEffectSettingForConfig(source, override, field, value, g, b)
        else
            Clock:SetEffectSetting(source, field, value, g, b)
        end
    end
    return {
        color = {type = 'color', name = L.EFFECT_COLOR, order = 1, width = 'full',
            desc = L.EFFECT_COLOR_DESC, hasAlpha = false, disabled = disabled,
            get = function() return unpack(Style().color) end,
            set = function(_, r, g, b) Update('color', r, g, b) end},
        mode = {type = 'select', name = L.EFFECT_MODE, order = 2, width = 'full',
            desc = L.EFFECT_MODE_DESC, values = {
                pulse = L.EFFECT_PULSE, static = L.EFFECT_STATIC, blink = L.EFFECT_BLINK},
            disabled = disabled, get = function() return Style().mode end,
            set = function(_, value) Update('mode', value) end},
        duration = {type = 'range', name = L.EFFECT_SECONDS, order = 3,
            desc = L.EFFECT_SECONDS_DESC, width = 'full', min = 0.2, max = 10, step = 0.1,
            disabled = function() return disabled() or Style().mode == 'static' end,
            get = function() return Clock:GetEffectPeriod(source, Override()) end,
            set = function(_, value) Update('period', value) end},
        opacity = {type = 'range', name = L.EFFECT_PERCENT, order = 4,
            desc = L.EFFECT_PERCENT_DESC, width = 'full', min = 0, max = 100, step = 1,
            disabled = disabled,
            get = function() return math.floor(Style().alpha * 100 + 0.5) end,
            set = function(_, value) Update('percent', value) end},
    }
end

-- Farbverlauf von a1 (Seite „min“: unten bzw. links) nach a2; Neu- und Altclient-Aufruf.
local function Gradient(tex, orientation, color, a1, a2)
    local r, g, b = color[1], color[2], color[3]
    if tex.SetGradient and _G.CreateColor then
        local ok = pcall(tex.SetGradient, tex, orientation,
            CreateColor(r, g, b, a1), CreateColor(r, g, b, a2))
        if ok then return end
    end
    if tex.SetGradientAlpha then
        tex:SetGradientAlpha(orientation, r, g, b, a1, r, g, b, a2)
    end
end

local function Create()
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata('FULLSCREEN')
    frame:EnableMouse(false)
    local function Strip()
        local tex = frame:CreateTexture(nil, 'BACKGROUND')
        tex:SetColorTexture(1, 1, 1, 1)
        tex:SetBlendMode('ADD')
        return tex
    end
    frame.top, frame.bottom, frame.left, frame.right = Strip(), Strip(), Strip(), Strip()
    frame:Hide()
    return frame
end

local function Layout(frame, color)
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local sideWidth, sideHeight = width * EDGE_WIDTH, height * EDGE_HEIGHT
    frame.top:ClearAllPoints()
    frame.top:SetPoint('TOPLEFT'); frame.top:SetPoint('TOPRIGHT'); frame.top:SetHeight(sideHeight)
    frame.bottom:ClearAllPoints()
    frame.bottom:SetPoint('BOTTOMLEFT'); frame.bottom:SetPoint('BOTTOMRIGHT'); frame.bottom:SetHeight(sideHeight)
    frame.left:ClearAllPoints()
    frame.left:SetPoint('TOPLEFT'); frame.left:SetPoint('BOTTOMLEFT'); frame.left:SetWidth(sideWidth)
    frame.right:ClearAllPoints()
    frame.right:SetPoint('TOPRIGHT'); frame.right:SetPoint('BOTTOMRIGHT'); frame.right:SetWidth(sideWidth)
    -- VERTICAL: min = unten, max = oben; HORIZONTAL: min = links, max = rechts.
    Gradient(frame.top, 'VERTICAL', color, 0, 1)
    Gradient(frame.bottom, 'VERTICAL', color, 1, 0)
    Gradient(frame.left, 'HORIZONTAL', color, 1, 0)
    Gradient(frame.right, 'HORIZONTAL', color, 0, 1)
end

function Clock:ShowScreenGlow(source, isPreview, override)
    if not isPreview then self.screenGlowPreviewActive = false end
    source = EFFECT_SOURCES[source] and source or 'alarms'
    local config = self:GetEffectConfig(source)
    -- Health-Effekte sind im Kampf und in jeder Instanz grundsaetzlich gesperrt,
    -- unabhaengig von der konfigurierbaren Instanz-Ausnahme.
    if source == 'health' and self.IsHealthRestricted and self:IsHealthRestricted() then
        if self.activeScreenGlowSource == 'health' then self:HideScreenGlow() end
        return
    end
    if not config.screenGlow then return end
    -- In Instanzen und Schlachtfeldern (Dungeon, Raid, PvP) bleibt der Rand dunkel.
    if config.skipInstances ~= false and type(_G.IsInInstance) == 'function' then
        local inInstance = _G.IsInInstance()
        if inInstance then return end
    end
    local style = self:GetEffectStyle(source, override)
    if not style then return end
    -- Im Normalfall stammt die Periodendauer aus dem Effektreiter. Einmalig
    -- angepasste aeltere glowSpeed-Werte werden bis zur naechsten Bearbeitung
    -- ueber GetEffectPeriod weiterhin wirksam, ohne andere Module zu beeinflussen.
    if style.mode ~= 'static' then style.period = self:GetEffectPeriod(source, override) end
    if not self.screenGlow then self.screenGlow = Create() end
    local frame = self.screenGlow
    Layout(frame, style.color)
    if style.mode == 'static' then
        frame:SetScript('OnUpdate', nil)
        frame:SetAlpha(style.alpha)
    else
        frame:SetScript('OnUpdate', function(f)
            local now = (type(_G.GetTime) == 'function' and _G.GetTime()) or ns.Now()
            f:SetAlpha(Clock.GlowAlpha(style, now))
        end)
    end
    self.activeScreenGlowSource = source
    self.screenGlowPreviewActive = isPreview == true
    frame:Show()
end

-- Testet ausschließlich die Randdarstellung, ohne Sounds oder Meldungen.
-- Die ohnehin verfügbare WoW-C_Timer-API beendet die Vorschau wieder.
function Clock:PreviewScreenGlow(source, override)
    if not (_G.C_Timer and type(_G.C_Timer.After) == 'function') then return end
    self.screenGlowPreviewToken = (self.screenGlowPreviewToken or 0) + 1
    local token = self.screenGlowPreviewToken
    self:ShowScreenGlow(source, true, override)
    if not self.screenGlowPreviewActive then return end
    _G.C_Timer.After(9, function()
        -- Wiederholtes Testen verlängert die Vorschau. Echte Alarme übernehmen
        -- den Bildschirmrand und werden niemals durch einen Test abgeschaltet.
        if self.screenGlowPreviewActive and self.screenGlowPreviewToken == token then
            self:HideScreenGlow()
        end
    end)
end

function Clock:HideScreenGlow()
    self.screenGlowPreviewActive = false
    self.activeScreenGlowSource = nil
    local frame = self.screenGlow
    if frame then
        frame:SetScript('OnUpdate', nil)
        frame:Hide()
    end
end
