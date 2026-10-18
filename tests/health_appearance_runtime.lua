-- Native Lua smoke test: category-specific overrides, AceConfig tabs, and weekday/date rows.
unpack = unpack or table.unpack
local ns = {L=setmetatable({}, {__index=function(_, k) return k end})}
local faction = 'Alliance'
function UnitFactionGroup() return faction end
local Clock = {db = {profile = {
    health = {movement={enabled=true,interval=45},drinking={enabled=false,interval=30},
              eyes={enabled=false,interval=20},sleep={enabled=false,interval=60},
              notice='both',sound=false},
    effects={health={screenGlow=true,skipInstances=true,spec='5FFF4F, pulse, 1, 10',periodSeconds=1},
             alarms={screenGlow=true,skipInstances=true,spec='FF2619, pulse, 1, 30',periodSeconds=1}},
    alarms={}, nextAlarmID=1,
}}}
ns.Clock=Clock
function Clock:NotifyOptions() end
function Clock:GetToday() return 1,2026,10,17 end
function Clock:PreviewScreenGlow(source, override) self.previewSource=source;self.previewOverride=override end
function Clock:IsModuleEnabled() return true end
function Clock:ParseGlowSpec(spec)
  local color,mode,a,b=spec:match('^(%x%x%x%x%x%x),%s*(%a+),%s*([%d%.]+),%s*([%d%.]+)')
  if not color then
    color,mode,b=spec:match('^(%x%x%x%x%x%x),%s*(%a+),%s*([%d%.]+)')
    a='1'
  end
  if not color then return nil end
  return {color={tonumber(color:sub(1,2),16)/255,tonumber(color:sub(3,4),16)/255,
    tonumber(color:sub(5,6),16)/255},mode=mode,alpha=tonumber(b)/100,period=tonumber(a)}
end
ns.AlarmHasDays=function(target)
  for i=1,7 do if target.days and target.days[i] then return true end end
  return false
end
ns.AlarmRepeats=function() return false end
ns.DaysInMonth=function() return 30 end
ns.AlarmTypeValues={alarm='Alarm',event='Event',reminder='Reminder'}
ns.RowIcon=function() return '' end
ns.AlarmDisplayName=function() return '' end
ns.ConfirmDelete=function() return false end
assert(loadfile('CantPlayForever/Core/ScreenGlow.lua'))('CantPlayForever',ns)
function Clock:PreviewScreenGlow(source, override) self.previewSource=source;self.previewOverride=override end
function Clock:PreviewHealthEffect(category)
  self.previewSource = 'health'
  self.previewCategory = category
  self.previewOverride = self:GetHealthEffectOverride(category)
end
assert(loadfile('CantPlayForever/Modules/Health/Options.lua'))('CantPlayForever',ns)
assert(loadfile('CantPlayForever/Modules/Alarms/Options.lua'))('CantPlayForever',ns)

local tabs=ns.HealthOptions()
assert(tabs.childGroups=='tab')
local globalspec=Clock.db.profile.effects.health.spec
-- Kategorie-Farbvorgaben richten sich nach dem Motiv und der Spielerfraktion.
for _, entry in ipairs({
  {'movement', '5FFF4F', 'F4A34C'},
  {'drinking', '3399FF', 'FF5844'},
  {'eyes', 'FFFFFF', 'FFFFFF'},
}) do
  faction='Alliance'
  assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride(entry[1])) == entry[2])
  faction='Horde'
  assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride(entry[1])) == entry[3])
end
faction='Alliance'
for _, category in ipairs({'movement','drinking','eyes'}) do
  local tab=tabs.args[category]
  assert(tab and tab.name and tab.args.interval.type=='range')
  local ui=tab.args
  assert(ui.customEffect.get()==false and ui.appearance.hidden()==true)
  ui.customEffect.set(nil,true)
  assert(ui.customEffect.get() and not ui.appearance.hidden())
  local effect=Clock.db.profile.health[category].effect
  assert(effect.spec==Clock:GetScreenGlowSpec('health', effect))
  assert(Clock:GetEffectColorHex('health', effect) == ({movement='5FFF4F', drinking='3399FF', eyes='FFFFFF'})[category])
  ui.appearance.args.color.set(nil, 0, 0.5, 1)
  ui.appearance.args.mode.set(nil,'blink')
  ui.appearance.args.duration.set(nil,2.5)
  ui.appearance.args.opacity.set(nil,70)
  assert(effect.spec:find('0080FF, blink, 2.5, 70',1,true))
  assert(Clock.db.profile.effects.health.spec==globalspec)
  ui.appearance.args.preview.func()
  assert(Clock.previewSource=='health' and Clock.previewCategory==category and Clock.previewOverride==effect)
  ui.customEffect.set(nil,false)
  assert(ui.appearance.hidden() and Clock:GetHealthEffectOverride(category) ~= effect)
  assert(effect.spec:find('0080FF, blink, 2.5, 70',1,true))
  ui.customEffect.set(nil,true)
  assert(Clock:GetHealthEffectOverride(category)==effect)
  -- Preview from next category must not mutate this category.
end
assert(tabs.args.general.args.notice.type=='select' and tabs.args.general.args.tone == nil)
-- Avoid reusing one instance's values for all three components.
assert(Clock.db.profile.health.movement.effect ~= Clock.db.profile.health.drinking.effect)
Clock.db.profile.effects.health.spec = 'ABCDEF, pulse, 1, 10'
assert(Clock:GetHealthEffectOverride('movement') == Clock.db.profile.health.movement.effect)
assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride('drinking')) == '0080FF')
Clock.db.profile.health.drinking.customEffect = false
assert(Clock:GetEffectColorHex('health', Clock:GetHealthEffectOverride('drinking')) == '3399FF')
assert(Clock:GetEffectColorHex('health') == '5FFF4F')
local newAlarm=ns.AlarmOptions().args
newAlarm.newAlarm.func()
local draft=newAlarm.newBox.args
assert(draft.alarmType.width==1)
assert(draft.draft_allDays.order < draft.draft_day2.order)
assert(draft.draft_allDays.width + 7*draft.draft_day2.width < 3)
assert(draft.draft_day.width+draft.draft_month.width+draft.draft_year.width < 3)
-- Alle Tage schaltet die sieben Wochentage einheitlich ein/aus.
draft.draft_allDays.func()
for _, index in ipairs({1,2,3,4,5,6,7}) do
  assert(draft['draft_day'..index].get() == false)
end
draft.draft_allDays.func()
for _, index in ipairs({1,2,3,4,5,6,7}) do
  assert(draft['draft_day'..index].get() == true)
end
assert(draft.draft_day.order < draft.draft_month.order)
assert(draft.draft_month.order < draft.draft_year.order)
print('Health custom effect tabs, persistence, isolation, alarms layout: OK')
