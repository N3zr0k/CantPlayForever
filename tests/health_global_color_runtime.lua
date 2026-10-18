-- Regression: keine globale Health-Farbe; feste Standardfarben und optionale Einzel-Overrides.
unpack = unpack or table.unpack
local ns = {L = setmetatable({}, {__index = function(_, k) return k end}), T = {}, Now = function() return 1 end}
local faction = 'Alliance'
function UnitFactionGroup() return faction end
local Clock = {db = {profile = {
    -- Benutzerdefinierte globale Farbe aus aelterer Version muss ignoriert werden.
    effects = {health = {screenGlow = true, spec = 'A1B2C3, blink, 2.5, 48',
        periodSeconds = 2.5, colorCustomized = true}},
    health = {movement = {customEffect = false}, drinking = {customEffect = false},
        eyes = {customEffect = false}},
}}}
ns.Clock = Clock
assert(loadfile('CantPlayForever/Modules/Clock/Glow.lua'))('CantPlayForever', ns)
assert(loadfile('CantPlayForever/Core/ScreenGlow.lua'))('CantPlayForever', ns)

local function Expected(category, alliance, horde)
    faction = 'Alliance'
    assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride(category)) == alliance, category)
    faction = 'Horde'
    assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride(category)) == horde, category)
end

-- Alte globale Farben dürfen keine Kategorie mehr beeinflussen.
Expected('movement', '5FFF4F', 'F4A34C')
Expected('drinking', '3399FF', 'FF5844')
Expected('eyes', 'FFFFFF', 'FFFFFF')
assert(Clock:GetScreenGlowSpec('health') == '5FFF4F, blink, 2.5, 48')
assert(Clock:GetEffectColorHex('health') == '5FFF4F') -- neutrale Health-Testvorschau
assert(Clock:GetEffectStyle('health').mode == 'blink')
assert(Clock:GetEffectPeriod('health') == 2.5)
assert(Clock:GetEffectStyle('health').alpha == 0.48)

local legacy = Clock.db.profile.effects.health
assert(not Clock:SetEffectSetting('health', 'color', 1, 0, 0))
assert(legacy.spec == 'A1B2C3, blink, 2.5, 48')
assert(Clock:SetEffectSetting('health', 'percent', 36))
assert(Clock:GetEffectStyle('health').alpha == 0.36)
assert(Clock:GetEffectColorHex('health') == '5FFF4F')
assert(Clock:GetEffectStyle('health', Clock:GetHealthEffectOverride('eyes')).alpha == 0.36)
assert(Clock:GetEffectPeriod('health', Clock:GetHealthEffectOverride('movement')) == 2.5)
assert(Clock:SetEffectSetting('health', 'mode', 'pulse'))
assert(Clock:GetEffectStyle('health', Clock:GetHealthEffectOverride('drinking')).mode == 'pulse')

-- Nur der Kategorie-Schalter ermoeglicht eine abweichende Farbe.
faction = 'Alliance'
Clock:SetHealthCustomEffect('drinking', true)
local own = Clock.db.profile.health.drinking.effect
assert(own and own.spec and Clock:GetHealthEffectOverride('drinking') == own)
assert(Clock:GetEffectColorHex('health', own) == '3399FF')
assert(Clock:SetEffectSettingForConfig('health', own, 'color', 1, 0.5, 0))
assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride('drinking')) == 'FF8000')
faction = 'Horde'
assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride('drinking')) == 'FF8000')
Expected('movement', '5FFF4F', 'F4A34C')
Clock:SetHealthCustomEffect('drinking', false)
Expected('drinking', '3399FF', 'FF5844')
Clock:SetHealthCustomEffect('drinking', true)
assert(Clock:GetHealthEffectOverride('drinking') == own)
assert(Clock:GetEffectColorHex('health', own) == 'FF8000')

-- Migration auch fuer alte globale Farbe ohne colorCustomized-Flag.
Clock.db.profile.effects.health = {screenGlow = true, spec = 'ABCDEF, static, 28'}
assert(Clock:GetScreenGlowSpec('health') == '5FFF4F, static, 28')
assert(Clock:GetEffectColorHex('health') == '5FFF4F')
Expected('eyes', 'FFFFFF', 'FFFFFF')
assert(Clock:GetEffectStyle('health', Clock:GetHealthEffectOverride('eyes')).alpha == 0.28)
print('OK health fixed category colors and individual overrides')
