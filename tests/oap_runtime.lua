-- Lua 5.1 standalone OAP bridge test. Run from Python when Lua is available.
local file = assert(arg[1], 'Path to Core/OAPDebug.lua needed')
time = time or function() return 1000 end
local messages = {}
local registers = {}
local perf = { counts = {}, gauges = {}, timings = {}, inspections = {}, watched = {}, opened = {}, chats = {} }
local oap = {
    Register = function(name, options)
        registers[#registers + 1] = {name, options}
    end,
    Log = function(name, fmt, level, ...)
        messages[#messages + 1] = {name, fmt, level, {...}}
    end,
    API_VERSION = 2,
    Count = function(_, key, delta) perf.counts[key] = (perf.counts[key] or 0) + (delta or 1) end,
    Gauge = function(_, key, v) perf.gauges[key] = v end,
    StartTimer = function(_, key) perf.timings[key] = (perf.timings[key] or 0) + 1 end,
    StopTimer = function(_, key) return 5 end,
    Watch = function(_, name, fn) perf.watched[name] = fn; return 1 end,
    Unwatch = function(_, name) perf.watched[name] = nil end,
    Inspect = function(_, name, value) perf.inspections[name] = value end,
    Show = function(_, tab) perf.opened[#perf.opened+1] = tab end,
    Chat = function(_, value) perf.chats[#perf.chats+1] = value end,
}
local printed = {}
local clock = { db = {global = {oapLevel = 'normal'} }, Print = function(self, message) printed[#printed+1] = message end }
local ns = { Clock = clock }
OAPDebug = oap
assert(loadfile(file))('CantPlayForever', ns)
assert(clock:IsOAPDebugAvailable())
assert(#registers == 1)
assert(registers[1][1] == 'CantPlayForever')
assert(registers[1][2].folder == 'CantPlayForever')
clock:OAPLog('info', 'Hello {1}', 42)
assert(#messages == 1 and messages[1][3] == 'info' and messages[1][4][1] == 42)
clock:Print('player-facing message')
assert(#printed == 1 and printed[1] == 'player-facing message')
assert(#perf.chats == 1 and perf.chats[1] == 'player-facing message')
clock:Debug('Value: %s', 'test')
assert(#messages == 1, 'debug level accidentally sent on normal mode')
clock.db.global.oapLevel = 'detailed'
clock:Debug('Value: %s', 'test')
assert(#messages == 2 and messages[2][2] == 'Value: test' and messages[2][3] == 'debug')
clock.db.global.oapLevel = 'errors'
clock:OAPLog('warn', 'Ignored warning')
clock:OAPLog('error', 'A problem: {1}', 'failed')
assert(#messages == 3 and messages[3][3] == 'error')
local failed = function() error('intentionally broken') end
clock:GuardedTick('notice', failed)
assert(#messages == 4 and messages[4][3] == 'error')
clock:GuardedTick('notice', failed)
assert(#messages == 4, 'Identical tick errors should be deduplicated')
clock:GuardedTick('notice', function() end)
clock:GuardedTick('notice', failed)
assert(#messages == 5, 'Error should be logged again after success')
clock.db.profile = {
    modules = {clock = true, timer = true, alarms = true},
    alarms = {{armed = true}, {armed = false}},
    activeTimer = {expiresAt = 1300},
}
clock.MODULES = {{id = 'clock'}, {id = 'timer'}, {id = 'alarms'}}
clock.IsModuleEnabled = function(_, id) return id ~= 'alarms' end
clock.CountArmedAlarms = function() return 1 end
GetServerTime = function() return 1000 end
GetTime = function() return 20 end
clock.healthMovement = {pending = true, nextAt = 50}
clock.db.global.oapLevel = 'metrics'
clock:OAPCounter('timer.started')
clock:OAPCounter('timer.started', 2)
clock:OAPGauge('testValue', 42)
clock:OAPObserve('core.tick', 4)
clock:OAPObserve('core.tick', 10)
clock:OAPSnapshot()
local telemetry = clock.oapTelemetry
assert(telemetry.counters['timer.started'] == 3)
assert(telemetry.gauges.testValue == 42)
assert(telemetry.gauges.moduleCount == 2)
assert(telemetry.gauges.timerRemainingSec == 300)
assert(telemetry.gauges.alarmsArmed == 1)
assert(telemetry.gauges.movementPending == 1)
assert(telemetry.timings['core.tick'].peakMs == 10)
assert(telemetry.timings['core.tick'].averageMs == 7)
assert(perf.counts['timer.started'] == 3)
assert(perf.gauges.moduleCount == 2)
assert(clock:OAPWatchPreset('timer') == 1)
assert(type(perf.watched.Timer) == 'function')
assert(perf.watched.Timer().remaining == 300)
clock:OAPUnwatchPreset('timer')
assert(perf.watched.Timer == nil)
clock:OAPInspectPreset('core')
assert(perf.inspections.Modules == clock.MODULES)
assert(perf.opened[#perf.opened] == 'inspect')
clock:OAPShow('metrics')
assert(perf.opened[#perf.opened] == 'metrics')
clock:OAPStartTimer('core.tick')
assert(clock:OAPStopTimer('core.tick') == 5)
assert(telemetry.timings['core.tick'].peakMs == 10)
clock.db.global.oapLevel = 'errors'
clock:OAPCounter('not recorded')
assert(perf.counts['not recorded'] == nil)
assert(not clock:OAPWatchPreset('timer'))
clock.db.global.oapLevel = 'metrics'
OAPDebug = nil
assert(not clock:IsOAPDebugAvailable())
clock:Print('still visible to the player')
assert(#printed == 2 and #perf.chats == 1)
assert(clock.oapTelemetry == nil)
clock:OAPCounter('must.not.exist')
assert(clock.oapTelemetry == nil)
clock:OAPLog('error', 'Hidden if addon is missing')
assert(#messages == 5)
OAPDebug = {Log = function() end}
assert(not clock:IsOAPDebugAvailable())
print('OAP runtime tests passed')
