unpack = unpack or table.unpack
date = os.date; time = os.time
local dir = 'CantPlayForever/'
local Clock = {}
local ns = {
    Clock = Clock,
    Now = function() return 1000 end,
    RowIcon = function() return "icon" end,
    Between = function(v,lo,hi) return math.max(lo,math.min(hi,v)) end,
    L = setmetatable({}, {__index = function(_,key) return key end}),
}
Clock.db = {profile = {
    effects = {alarms = {spec = 'FF2619, pulse, 1, 30', periodSeconds=1,
        screenGlow=true, skipInstances=true}},
    alarms = {}, nextAlarmID = 1,
}}
function Clock:NotifyOptions() end
function Clock:Print() end
function Clock:OAPCounter() end
function Clock:OAPLog() end
function Clock:Debug() end
function Clock:RegisterModule() end
function Clock:IsModuleEnabled() return true end
function Clock:ParseGlowSpec(spec)
    local hex, mode, a, b = spec:match('^(%x%x%x%x%x%x),%s*(%a+),%s*([%d%.]+),%s*([%d%.]+)')
    if not hex then
        hex, mode, a = spec:match('^(%x%x%x%x%x%x),%s*(%a+),%s*([%d%.]+)')
        if not hex then return nil end
        a,b = 1,a
    end
    local r=tonumber(hex:sub(1,2),16)/255
    local g=tonumber(hex:sub(3,4),16)/255
    local blue=tonumber(hex:sub(5,6),16)/255
    return {color = {r,g,blue}, mode = mode, period = tonumber(a), alpha=tonumber(b)/100}
end
function Clock:InitializeAlarmNotice()
    self.recentAlerts = self.recentAlerts or {}
end
function Clock:UpdateAlarmNotice() end
function Clock:SetGlow(source,spec) self.lastGlow = spec end
function Clock:ShowScreenGlow(source,prev,config) self.seenScreenConfig = config end
function Clock:StartAlarmSoundSequence() end
function CopyTable(t)
    local out={}
    for k,v in pairs(t) do out[k]=type(v)=='table' and CopyTable(v) or v end
    return out
end
assert(loadfile(dir .. 'Core/ScreenGlow.lua'))('CantPlayForever', ns)
assert(loadfile(dir .. 'Modules/Alarms/Alarms.lua'))('CantPlayForever',ns)
assert(loadfile(dir .. 'Modules/Alarms/Options.lua'))('CantPlayForever',ns)
assert(loadfile(dir .. 'Core/Alert.lua'))('CantPlayForever',ns)
assert(loadfile(dir .. 'Modules/Clock/Tooltip.lua'))('CantPlayForever',ns)
function Clock:InitializeAlarmNotice() self.recentAlerts = self.recentAlerts or {} end
function Clock:UpdateAlarmNotice() end
function Clock:StartAlarmSoundSequence() end
function Clock:ShowScreenGlow(source,preview,override) self.seenScreenConfig = override end
local s = ns.AlarmOptions().args
s.newAlarm.func()
s = ns.AlarmOptions().args
local edit = s.newBox.args
assert(edit.alarmType ~= nil and edit.draft_customEffect ~= nil)
edit.alarmType.set(nil,'event')
edit.message.set(nil,'Mein Event')
edit.draft_customEffect.set(nil,true)
assert(edit.draft_appearance.hidden() == false)
edit.draft_appearance.args.color.set(nil,0,1,0)
edit.draft_appearance.args.mode.set(nil,'blink')
edit.draft_appearance.args.duration.set(nil,2.3)
edit.draft_appearance.args.opacity.set(nil,65)
edit.add.func()
local alarm = Clock.db.profile.alarms[1]
assert(alarm.alarmType == 'event')
assert(alarm.customEffect == true)
assert(alarm.effect.spec:match('00FF00, blink, 2.3, 65'))
assert(Clock.db.profile.effects.alarms.spec == 'FF2619, pulse, 1, 30')
local opts = ns.AlarmOptions().args
local summary = opts['alarm_1_summary'].name()
assert(summary:find('00FF00') and summary:find('INV_Misc_Book_09'))
Clock:Alert(alarm.name, 'alarms', alarm)
assert(Clock.lastGlow:find('00FF00, blink, 2.3, 100'))
assert(Clock.seenScreenConfig == alarm.effect)
assert(Clock.recentAlerts[1].message:find('INV_Misc_Book_09'))
assert(Clock.recentAlerts[1].color[2] == 1)
opts['alarm_1_mask'].args.customEffect.set(nil,false)
assert(Clock:GetAlarmEffectOverride(alarm) == nil)
assert(alarm.effect ~= nil, 'values should survive disable')
Clock:Alert(alarm.name,'alarms',alarm)
assert(Clock.lastGlow:find('FF2619, pulse, 1.0, 100'))
assert(Clock.seenScreenConfig == nil)
print('Lua runtime alarm custom effect, UI, icon and inheritance: OK')
