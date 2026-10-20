-- Can't Play Forever: optional OAP Debug 1.1 API bridge (API_VERSION 2).
-- Source of truth: OAPDebug/Core.lua and HelpUsage.lua, not internal OAP state.
-- Never write technical/debug messages to the normal WoW chat.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock
local SOURCE = 'CantPlayForever'
local registeredWith

-- OAP is optional. Without it all the integration methods below are silent.
local function OAP()
    local api = _G.OAPDebug
    if type(api) ~= 'table' or type(api.Register) ~= 'function'
        or type(api.Log) ~= 'function' then
        registeredWith = nil
        Clock.oapTelemetry = nil
        return nil
    end
    if registeredWith ~= api then
        -- Register maps errors to our folder in OAP's Errors tab.
        local ok = pcall(api.Register, SOURCE, {
            title = "Can't play Forever", folder = ADDON_NAME,
            icon = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\allgemein_logo.tga',
            color = '3987e5',
        })
        if not ok then return nil end
        registeredWith = api
    end
    return api
end

local LEVEL = { errors = 1, normal = 2, metrics = 3, detailed = 4 }
local LOG_LEVEL = { error = 1, warn = 2, info = 2, debug = 4 }

local function CurrentLevel()
    local global = Clock.db and Clock.db.global
    return LEVEL[global and global.oapLevel] or LEVEL.metrics
end

local function Enabled(minimum)
    if CurrentLevel() < minimum then return nil end
    return OAP()
end

function Clock:RegisterOAPDebug() return OAP() ~= nil end
function Clock:IsOAPDebugAvailable() return OAP() ~= nil end

-- BugLab (optional, Console API): every technical message goes to one logger "CantPlayForever",
-- regardless of the OAP level; BugLab filters (SetLevel), rate-limits and keeps the history itself.
local unpack = unpack or table.unpack
local BUGLAB_METHOD = { debug = 'Debug', info = 'Info', warn = 'Warn', error = 'Error' }
local bugApi, bugLogger

local function BugLabLogger()
    local api = _G.BugLab
    if type(api) ~= 'table' or type(api.GetLogger) ~= 'function' then
        bugApi, bugLogger = nil, nil
        return nil
    end
    if bugApi ~= api then
        local ok, logger = pcall(api.GetLogger, api, SOURCE)
        if not (ok and type(logger) == 'table') then return nil end
        bugApi, bugLogger = api, logger
    end
    return bugLogger
end

function Clock:IsBugLabAvailable() return BugLabLogger() ~= nil end

-- BugLab formats like string.format and colours the inserted values blue, so the
-- OAP style template "Tick {1} failed: {2}" becomes "Tick %s failed: %s".
local function BraceToFormat(template, ...)
    local values, args = { ... }, {}
    local text = tostring(template):gsub('%%', '%%%%')
    text = text:gsub('{(%d+)}', function(n)
        args[#args + 1] = tostring(values[math.max(tonumber(n), 1)])
        return '%s'
    end)
    return text, args
end

local function SendBugLab(level, format, ...)
    local logger = BugLabLogger()
    local method = logger and BUGLAB_METHOD[level]
    if not (method and type(logger[method]) == 'function') then return end
    if not pcall(logger[method], logger, format, ...) then
        -- A stray % in a finished text must not swallow the message.
        pcall(logger[method], logger, '%s', tostring(format))
    end
end

-- One login line in BugLab: "Angemeldet, Version X, Debug aktiviert/deaktiviert".
-- Debug counts as active at the detailed OAP level (the addon's only debug mode).
function Clock:AnnounceBugLab()
    local logger = BugLabLogger()
    if not (logger and type(logger.Announce) == 'function') then return end
    local getMeta = _G.C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
    local ok, version = pcall(getMeta or function() end, ADDON_NAME, 'Version')
    pcall(logger.Announce, logger, {
        version = ok and version or nil,
        debug = CurrentLevel() >= LEVEL.detailed,
    })
end

function Clock:OAPLog(level, template, ...)
    if not LOG_LEVEL[level] then return end
    if BugLabLogger() then
        local format, args = BraceToFormat(template, ...)
        SendBugLab(level, format, unpack(args))
    end
    local api = Enabled(LOG_LEVEL[level])
    if api then pcall(api.Log, SOURCE, template, level, ...) end
end

-- Older modules use printf-style debug calls; keep that contract.
function Clock:Debug(template, ...)
    if BugLabLogger() then SendBugLab('debug', tostring(template), ...) end
    if not Enabled(LEVEL.detailed) then return end
    local ok, message = pcall(string.format, tostring(template), ...)
    local api = OAP()
    if api then pcall(api.Log, SOURCE, ok and message or tostring(template), 'debug') end
end

-- Metrics use OAP's *native* API so they appear on its Metrics tab/chart.
function Clock:OAPCounter(name, amount)
    local api = Enabled(LEVEL.metrics)
    if not (api and type(api.Count) == 'function') then return end
    local n = tonumber(amount) or 1
    pcall(api.Count, SOURCE, name, n)
    local data = self.oapTelemetry
    if not data then
        data = { counters = {}, gauges = {}, timings = {} }
        self.oapTelemetry = data
    end
    if data then data.counters[name] = (data.counters[name] or 0) + n end
end

function Clock:OAPGauge(name, value)
    local api = Enabled(LEVEL.metrics)
    if not (api and type(api.Gauge) == 'function') then return end
    pcall(api.Gauge, SOURCE, name, value)
    local data = self.oapTelemetry
    if not data then
        data = { counters = {}, gauges = {}, timings = {} }
        self.oapTelemetry = data
    end
    if data then data.gauges[name] = value end
end

function Clock:OAPStartTimer(name)
    local api = Enabled(LEVEL.metrics)
    if api and type(api.StartTimer) == 'function' then
        pcall(api.StartTimer, SOURCE, name)
    end
end

function Clock:OAPStopTimer(name)
    local api = Enabled(LEVEL.metrics)
    if not (api and type(api.StopTimer) == 'function') then return nil end
    local ok, ms = pcall(api.StopTimer, SOURCE, name)
    if ok and type(ms) == 'number' then self:OAPObserve(name, ms); return ms end
end

-- Timed function wrapper: calls its function unchanged without OAP or below Metrics.
-- OAPDebug.Time preserves return values, records errors and re-raises them.
function Clock:OAPTime(name, fn, ...)
    local api = Enabled(LEVEL.metrics)
    if api and type(api.Time) == 'function' then
        return api.Time(SOURCE, name, fn, ...)
    end
    return fn(...)
end

-- Inspector-only running aggregates complement the native OAP timer metrics.
function Clock:OAPObserve(name, ms)
    local api = Enabled(LEVEL.metrics)
    if not api then return end
    ms = tonumber(ms)
    if not ms or ms < 0 then return end
    local data = self.oapTelemetry
    if not data then
        data = { counters = {}, gauges = {}, timings = {} }
        self.oapTelemetry = data
    end
    local item = data.timings[name]
    if not item then
        item = { count = 0, lastMs = 0, averageMs = 0, peakMs = 0 }
        data.timings[name] = item
    end
    item.count = item.count + 1
    item.lastMs = ms
    item.peakMs = math.max(item.peakMs, ms)
    item.averageMs = item.averageMs + (ms - item.averageMs) / item.count
end

function Clock:OAPInspect(label, value)
    local api = Enabled(LEVEL.normal)
    if api and type(api.Inspect) == 'function' then
        pcall(api.Inspect, SOURCE, label, value)
    end
end

function Clock:OAPShow(tab)
    local api = Enabled(LEVEL.errors)
    if api and type(api.Show) == 'function' then
        pcall(api.Show, SOURCE, tab)
    end
end

function Clock:OAPWatch(label, value)
    local api = Enabled(LEVEL.normal)
    if not (api and tonumber(api.API_VERSION) and tonumber(api.API_VERSION) >= 2
        and type(api.Watch) == 'function') then return end
    local ok, id = pcall(api.Watch, SOURCE, label, value)
    if ok then return id end
end

function Clock:OAPUnwatch(label)
    local api = Enabled(LEVEL.normal)
    if api and tonumber(api.API_VERSION) and tonumber(api.API_VERSION) >= 2 and type(api.Unwatch) == 'function' then
        pcall(api.Unwatch, SOURCE, label)
    end
end

local WATCH_LABELS = {
    core = 'Core / modules', timer = 'Timer', alarms = 'Alarms',
    health = 'Health', settings = 'Profile', diagnostics = 'Metrics snapshot',
}

function Clock:OAPWatchPreset(name)
    if not WATCH_LABELS[name] then return end
    local value
    if name == 'core' then
        value = function()
            local result = {}
            for _, module in ipairs(self.MODULES or {}) do
                result[module.id] = self:IsModuleEnabled(module.id)
            end
            return result
        end
    elseif name == 'timer' then
        value = function()
            local timer = self.db and self.db.profile and self.db.profile.activeTimer
            if not timer then return { active = false } end
            local now = ns.Now and ns.Now() or time()
            return { active = true, name = timer.name,
                remaining = math.max(0, (timer.expiresAt or now) - now) }
        end
    elseif name == 'alarms' then
        value = function()
            return { armed = type(self.CountArmedAlarms) == 'function' and self:CountArmedAlarms() or 0 }
        end
    elseif name == 'health' then
        value = function()
            local h = self.healthMovement
            local config = self.db and self.db.profile and self.db.profile.health or {}
            local sections = {}
            for _, key in ipairs({'movement', 'drinking', 'eyes'}) do
                local entry = config[key] or {}
                sections[key] = { enabled = entry.enabled == true, intervalMin = entry.interval }
            end
            return {
                active = self:IsModuleEnabled('health'), components = sections,
                movementPending = h and h.pending or false,
                movementRemainingSec = h and math.max(0, math.floor(h.nextAt - self:GetSessionSeconds())) or nil,
                chatOnly = type(self.IsHealthRestricted) == 'function' and self:IsHealthRestricted() or false,
                lastReminderUptime = h and h.lastAt or nil,
                reminderCount = h and h.shown or 0,
            }
        end
    elseif name == 'settings' then
        value = function() return self.db and self.db.profile end
    elseif name == 'diagnostics' then
        value = function() return self.oapTelemetry end
    end
    return self:OAPWatch(WATCH_LABELS[name], value)
end

function Clock:OAPUnwatchPreset(name)
    if WATCH_LABELS[name] then self:OAPUnwatch(WATCH_LABELS[name]) end
end

function Clock:OAPInspectPreset(name)
    if name == 'core' then self:OAPInspect('Modules', self.MODULES)
    elseif name == 'settings' then self:OAPInspect('Profile', self.db and self.db.profile)
    elseif name == 'diagnostics' then self:OAPInspect('Telemetry', self.oapTelemetry)
    elseif name == 'health' then self:OAPInspect('Health', self.healthMovement)
    elseif name == 'ui' then self:OAPInspect('Clock frame', self.iconButton or self.button)
    end
    self:OAPShow('inspect')
end

-- OAP.Chat stores *a copy* of an existing player-facing message; it never prints.
-- Wrap AceConsole's Print exactly once, preserving normal in-game output.
local originalPrint = Clock.Print
if type(originalPrint) == 'function' then
    Clock.Print = function(self, ...)
        local result = originalPrint(self, ...)
        local api = Enabled(LEVEL.normal)
        if api and type(api.Chat) == 'function' then
            local count = select('#', ...)
            local parts = {}
            for i = 1, count do parts[i] = tostring(select(i, ...)) end
            pcall(api.Chat, SOURCE, table.concat(parts, ' '))
        end
        return result
    end
end

-- Protected core/module calls: log the first error, retry normally on later ticks.
local tickNames = {}

function Clock:GuardedTick(key, handler)
    if type(handler) ~= 'function' then return end
    -- Timer nur bei Metrics-Stufe: ohne OAP entfallen Stringbau und zwei Aufrufe pro Handler.
    local timed = Enabled(LEVEL.metrics) and true or false
    local name
    if timed then
        name = tickNames[key]
        if not name then name = 'tick.' .. key; tickNames[key] = name end
        self:OAPStartTimer(name)
    end
    local ok, err = pcall(handler, self)
    if timed then self:OAPStopTimer(name) end
    if not ok then
        self.oapTickErrors = self.oapTickErrors or {}
        local message = tostring(err)
        if self.oapTickErrors[key] ~= message then
            self.oapTickErrors[key] = message
            self:OAPLog('error', 'Tick {1} failed: {2}', key, message)
        end
    elseif self.oapTickErrors then
        self.oapTickErrors[key] = nil
    end
end

-- Inspector data is created only at metrics level, and is never saved to disk.
function Clock:OAPSnapshot()
    if not Enabled(LEVEL.metrics) then
        self.oapTelemetry = nil
        return
    end
    if not (self.db and self.db.profile) then return end
    local data = self.oapTelemetry
    if not data then
        data = { counters = {}, gauges = {}, timings = {} }
        self.oapTelemetry = data
    end
    local p = self.db.profile
    local count = 0
    for _, module in ipairs(self.MODULES or {}) do
        local active = self:IsModuleEnabled(module.id)
        self:OAPGauge('module.' .. module.id, active and 1 or 0)
        if active then count = count + 1 end
    end
    self:OAPGauge('moduleCount', count)
    local timer = p.activeTimer
    self:OAPGauge('timerRunning', timer and 1 or 0)
    local now = ns.Now and ns.Now() or time()
    self:OAPGauge('timerRemainingSec', timer and timer.expiresAt
        and math.max(0, timer.expiresAt - now) or 0)
    if type(self.CountArmedAlarms) == 'function' then
        self:OAPGauge('alarmsArmed', self:CountArmedAlarms())
    end
    local health = self.healthMovement
    self:OAPGauge('movementPending', health and health.pending and 1 or 0)
    self:OAPGauge('healthChatOnly', type(self.IsHealthRestricted) == 'function'
        and self:IsHealthRestricted() and 1 or 0)
    self:OAPGauge('movementRemainingSec', health and health.nextAt
        and type(self.GetSessionSeconds) == 'function'
        and math.max(0, health.nextAt - self:GetSessionSeconds()) or 0)
end
