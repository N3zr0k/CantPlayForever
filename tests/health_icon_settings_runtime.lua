-- Native-Lua smoke test: global Health icon settings, individual override, inheritance.
unpack = unpack or table.unpack
local ns = {L = setmetatable({}, {__index=function(_, key) return key end})}
local faction = 'Alliance'
function UnitFactionGroup() return faction end
local global = {screenGlow = false, spec = '5FFF4F, pulse, 1, 10', glowSpeed = 1,
    iconEnabled = true, iconTransparency = 65, iconOffsetY = 65}
local Clock = {
  db = {global={}, profile = {
    health = {movement={enabled=true,interval=45}, drinking={enabled=true,interval=30},
      eyes={enabled=true,interval=20}, notice='both',sound=false},
    effects = {health=global}, modules={health=true}, alarms={}, nextAlarmID=1,
  }},
  MODULES={},
}
ns.Clock = Clock
function Clock:NotifyOptions() end
function Clock:IsOAPDebugAvailable() return false end
function Clock:IsModuleEnabled() return true end
function Clock:PreviewScreenGlow() end
function Clock:PreviewHealthEffect(category) self.previewCategory = category or "general" end
function Clock:PreviewHealthEffect(category) self.previewCategory=category or 'general' end
function Clock:ParseGlowSpec(spec)
  local color, mode, a, b = spec:match('^(%x%x%x%x%x%x),%s*(%a+),%s*([%d%.]+),%s*([%d%.]+)')
  if not color then
    color, mode, b = spec:match('^(%x%x%x%x%x%x),%s*(%a+),%s*([%d%.]+)')
    a='1'
  end
  assert(color)
  return {color={tonumber(color:sub(1,2),16)/255,tonumber(color:sub(3,4),16)/255,
      tonumber(color:sub(5,6),16)/255}, mode=mode, alpha=tonumber(b)/100,
      period=tonumber(a)}
end
assert(loadfile('CantPlayForever/Core/ScreenGlow.lua'))('CantPlayForever', ns)
assert(loadfile('CantPlayForever/Modules/Health/Options.lua'))('CantPlayForever', ns)

-- Full parent options UI is built via AceConfig's lazy options function.
local buildOptions
Clock.aceConfig = {RegisterOptionsTable = function(_, _, builder) buildOptions = builder end}
Clock.aceDialog = {AddToBlizOptions = function() return nil end}
assert(loadfile('CantPlayForever/Core/Options.lua'))('CantPlayForever', ns)
Clock:InitializeOptions()
assert(type(buildOptions) == 'function')
local allOptions = buildOptions()
local globalUi = allOptions.args.options.args.effects.args.health.args.appearance.args
assert(globalUi.iconEnabled.type == 'toggle')
assert(globalUi.iconTransparency.type == 'range')
assert(globalUi.iconOffsetY.type == 'range')
assert(globalUi.color == nil and globalUi.mode and globalUi.duration and globalUi.opacity)
assert(globalUi.iconEnabled.disabled == nil) -- icons work independently of screen glow
assert(globalUi.iconTransparency.get() == 65)
assert(globalUi.iconOffsetY.get() == 65)
local globalTest = allOptions.args.options.args.effects.args.health.args.test
assert(globalTest.disabled()) -- erst nach aktivem globalem Glow
Clock.db.profile.effects.health.screenGlow = true
assert(not globalTest.disabled())
globalTest.func()
assert(Clock.previewCategory == 'general')
for _, id in ipairs({'movement', 'drinking', 'eyes'}) do
  local ui = ns.HealthOptions().args[id].args
  assert(ui.display == nil and ui.iconEnabled == nil)
  assert(ui.customEffect.type == 'toggle')
  assert(ui.appearance.hidden() == true)
  assert(Clock:GetHealthIconSetting(id, 'iconTransparency') == 65)
end

-- Global adjustments propagate to every category unless custom override is enabled.
globalUi.iconEnabled.set(nil, false)
assert(globalUi.iconTransparency.hidden() and globalUi.iconOffsetY.hidden())
for _, id in ipairs({'movement', 'drinking', 'eyes'}) do
  assert(Clock:GetHealthIconSetting(id, 'iconEnabled') == false)
end
globalUi.iconEnabled.set(nil, true)
globalUi.iconTransparency.set(nil, 42)
globalUi.iconOffsetY.set(nil, 18)
for _, id in ipairs({'movement', 'drinking', 'eyes'}) do
  assert(Clock:GetHealthIconSetting(id, 'iconTransparency') == 42)
  assert(Clock:GetHealthIconSetting(id, 'iconOffsetY') == 18)
end
local tab = ns.HealthOptions().args.movement.args
tab.customEffect.set(nil, true)
assert(not tab.appearance.hidden())
local individualUi = tab.appearance.args
assert(individualUi.color.type == 'color') -- per-category editor still offers color
assert(individualUi.iconEnabled.type == 'toggle')
assert(individualUi.iconTransparency.type == 'range')
assert(individualUi.iconOffsetY.type == 'range')
assert(individualUi.iconTransparency.get() == 42)
assert(individualUi.iconOffsetY.get() == 18)
individualUi.iconEnabled.set(nil, false)
assert(individualUi.iconTransparency.hidden() and individualUi.iconOffsetY.hidden())
assert(Clock:GetHealthIconSetting('movement', 'iconEnabled') == false)
individualUi.iconEnabled.set(nil, true)
individualUi.iconTransparency.set(nil, 75)
individualUi.iconOffsetY.set(nil, -40)
assert(Clock:GetHealthIconSetting('movement', 'iconTransparency') == 75)
assert(Clock:GetHealthIconSetting('movement', 'iconOffsetY') == -40)
assert(Clock:GetHealthIconSetting('drinking', 'iconTransparency') == 42)
assert(global.iconTransparency == 42 and global.iconOffsetY == 18)
globalUi.iconTransparency.set(nil, 25)
assert(Clock:GetHealthIconSetting('movement', 'iconTransparency') == 75)
assert(Clock:GetHealthIconSetting('drinking', 'iconTransparency') == 25)
tab.customEffect.set(nil, false)
assert(tab.appearance.hidden() and Clock:GetHealthIconSetting('movement', 'iconTransparency') == 25)
tab.customEffect.set(nil, true)
assert(Clock:GetHealthIconSetting('movement', 'iconTransparency') == 75)
assert(Clock:GetHealthIconSetting('movement', 'iconOffsetY') == -40)

-- A pre-0.3.16 profile stored icon values under health.<category>.
local eyes = Clock.db.profile.health.eyes
eyes.iconEnabled, eyes.iconTransparency, eyes.iconOffsetY = false, 80, 33
local eyeUi = ns.HealthOptions().args.eyes.args
eyeUi.customEffect.set(nil, true)
assert(Clock:GetHealthIconSetting('eyes', 'iconEnabled') == false)
assert(Clock:GetHealthIconSetting('eyes', 'iconTransparency') == 80)
assert(Clock:GetHealthIconSetting('eyes', 'iconOffsetY') == 33)
eyeUi.customEffect.set(nil, false)
assert(Clock:GetHealthIconSetting('eyes', 'iconEnabled') == true)
assert(Clock:GetHealthIconSetting('eyes', 'iconTransparency') == 25)

-- If a legacy custom effect table exists, the icon preferences are still migrated.
local drinking = Clock.db.profile.health.drinking
drinking.customEffect = true
drinking.effect = {spec='3399FF, pulse, 1, 10'}
drinking.iconEnabled = false
drinking.iconTransparency = 92
assert(Clock:GetHealthIconSetting('drinking', 'iconEnabled') == false)
assert(Clock:GetHealthIconSetting('drinking', 'iconTransparency') == 92)
local drinkUi = ns.HealthOptions().args.drinking.args
assert(drinkUi.appearance.args.iconEnabled.get() == false)
drinking.customEffect = false
drinkUi.customEffect.set(nil, true)
assert(drinking.effect.iconEnabled == false)
assert(drinking.effect.iconTransparency == 92)
assert(drinking.effect.iconOffsetY == global.iconOffsetY)
print('Global and individual Health icon appearance inheritance: OK')
