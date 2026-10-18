-- Health: Bewegung, Trinken und Augenpausen auf Basis der bestehenden Login-Session.
-- Alle Kategorien nutzen ausschliesslich den zentralen Core-Tick (kein neuer Ticker).
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L
local NOTICE_SECONDS = 9
-- Reihenfolge ist gleichzeitig die feste Prioritaet (hoch -> niedrig).
local CATEGORIES = { 'drinking', 'movement', 'eyes' }
local COLLISION_WINDOW_SECONDS = 5 * 60
local INTERVAL_MAX = { movement = 180, drinking = 120, eyes = 60 }
local DEFAULT_INTERVAL = { movement = 45, drinking = 30, eyes = 20 }

local function SessionTime()
    if type(_G.GetTime) == 'function' then return _G.GetTime() end
    return ns.Now()
end

local function SessionElapsed(self)
    if type(self.GetSessionSeconds) == 'function' and self.sessionStartedAt then
        return math.max(0, self:GetSessionSeconds())
    end
    return 0
end

local function NextBoundary(elapsed, seconds)
    return (math.floor(elapsed / seconds) + 1) * seconds
end

-- Eine faellige Erinnerung unterdruecken, wenn eine hoeher priorisierte
-- Kategorie innerhalb +/-5 Minuten einen geplanten Termin hat. Es zaehlt
-- die Session-Zeit, nicht der Tick-Zeitpunkt; dadurch werden auch noch
-- bevorstehende Termine erkannt und es entstehen keine Warteschlangen.
-- Die Pruefung funktioniert ebenso, wenn ein Client-Tick spaet eintrifft.
local function HigherPriorityNearby(schedules, category, scheduledAt, dueNow)
    for _, higher in ipairs(CATEGORIES) do
        if higher == category then break end
        local other = schedules[higher]
        if other then
            -- Wenn beide im selben Tick faellig sind (z.B. nach einem Lag),
            -- erhaelt ebenfalls nur die hoeher priorisierte Kategorie Vorrang.
            if dueNow[higher] then return higher end
            local interval = other.minutes * 60
            local previous = math.floor(scheduledAt / interval) * interval
            local following = previous + interval
            if (previous > 0 and scheduledAt - previous <= COLLISION_WINDOW_SECONDS)
                or following - scheduledAt <= COLLISION_WINDOW_SECONDS then
                return higher
            end
        end
    end
    return nil
end

function Clock:IsHealthRestricted()
    if type(_G.UnitAffectingCombat) == 'function' and _G.UnitAffectingCombat('player') then return true end
    if type(_G.InCombatLockdown) == 'function' and _G.InCombatLockdown() then return true end
    if type(_G.IsInInstance) == 'function' then
        local inside = _G.IsInInstance()
        if inside then return true end
    end
    return false
end

function Clock:StartHealthSafetyMonitor()
    if self.healthSafetyMonitoring then return end
    if not self.healthSafetyFrame then
        local frame = CreateFrame('Frame')
        frame:SetScript('OnEvent', function(_, event)
            if event == 'PLAYER_REGEN_DISABLED' or Clock:IsHealthRestricted() then
                Clock:HideHealthNotice()
                Clock.healthVisualQueue = nil
            end
        end)
        self.healthSafetyFrame = frame
    end
    self.healthSafetyFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
    self.healthSafetyFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    self.healthSafetyFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
    self.healthSafetyMonitoring = true
end

function Clock:StopHealthSafetyMonitor()
    if self.healthSafetyFrame and self.healthSafetyMonitoring then
        self.healthSafetyFrame:UnregisterAllEvents()
    end
    self.healthSafetyMonitoring = false
end

function Clock:ResetHealthMovement()
    self.healthSchedules = nil
    self.healthMovement = nil -- bisheriger Debug- und Test-Vertrag
    self.healthVisualQueue = nil
    self:HideHealthNotice()
    self:StopHealthSafetyMonitor()
end

function Clock:SyncHealthMovement()
    local h = self.db and self.db.profile and self.db.profile.health
    if not self:IsModuleEnabled('health') or not h then
        self:ResetHealthMovement()
        return
    end
    if not self.sessionStartedAt then return end -- Loginzeit erst initialisieren
    self:StartHealthSafetyMonitor()
    self.healthSchedules = self.healthSchedules or {}
    local elapsed = SessionElapsed(self)
    for _, category in ipairs(CATEGORIES) do
        local config = h[category]
        local runtime = self.healthSchedules[category]
        if config and config.enabled == true then
            local minutes = math.max(5, math.min(INTERVAL_MAX[category],
                math.floor(tonumber(config.interval) or DEFAULT_INTERVAL[category])))
            if not runtime or runtime.minutes ~= minutes then
                self.healthSchedules[category] = {
                    minutes = minutes,
                    nextAt = NextBoundary(elapsed, minutes * 60),
                    pending = false, lastAt = nil, shown = 0, deferred = 0,
                    suppressed = 0, lastSuppressedAt = nil,
                }
            end
        else
            self.healthSchedules[category] = nil
        end
    end
    self.healthMovement = self.healthSchedules.movement
end

-- Einzelnes Visual startet erst, wenn das vorherige fertig ist. Der Chat wird
-- dennoch zum faelligen Zeitpunkt ausgeliefert (auch bei gleichzeitigem Termin).
function Clock:StartHealthVisual(entry)
    self:HideHealthNotice()
    if self:IsHealthRestricted() then return end
    local start = SessionTime()
    if entry.method == 'screen' or entry.method == 'both' then
        self:ShowHealthNotice(entry.category, entry.title, entry.message)
        self.healthNoticeUntil = start + NOTICE_SECONDS
    end
    if self.ShowScreenGlow then
        self:ShowScreenGlow('health', false, self:GetHealthEffectOverride(entry.category))
        if self.activeScreenGlowSource == 'health' then
            self.healthGlowUntil = start + NOTICE_SECONDS
        end
    end
    if self.healthNoticeUntil or self.healthGlowUntil then
        self.healthVisualUntil = start + NOTICE_SECONDS
    end
end

function Clock:GetHealthReminderText(category)
    local h = self.db.profile.health
    local message, title = ns.HealthChooseMessage(category, h[category])
    if not title then
        title = category == 'movement' and L.HEALTH_NOTICE_TITLE
            or category == 'drinking' and L.HEALTH_DRINK_TITLE or L.HEALTH_EYES_TITLE_CUSTOM
    end
    return title, message
end

function Clock:AnnounceHealthChat(category, message)
    self:Print(L.HEALTH_CHAT_PREFIX .. ' ' .. message)
    self:OAPCounter('health.' .. category .. '.chat')
end

function Clock:ShowHealthReminder(category)
    local h = self.db.profile.health
    local title, message = self:GetHealthReminderText(category)
    self:Debug('Health %s reminder: %s', category, message)
    self:OAPCounter('health.' .. category .. '.shown')
    if self:IsHealthRestricted() then
        self:HideHealthNotice()
        self.healthVisualQueue = nil
        self:AnnounceHealthChat(category, message)
        self:OAPCounter('health.' .. category .. '.chat_only')
        return
    end
    local method = h.notice or 'screen'
    if method == 'chat' or method == 'both' then
        self:AnnounceHealthChat(category, message)
    end
    if h.sound == true and type(_G.PlaySound) == 'function' then
        local kit = _G.SOUNDKIT
        if kit and kit.IG_MAINMENU_OPTION_CHECKBOX_ON then
            _G.PlaySound(kit.IG_MAINMENU_OPTION_CHECKBOX_ON, 'Master')
        end
    end
    local entry = {category = category, title = title, message = message, method = method}
    if self.healthVisualUntil then
        self.healthVisualQueue = self.healthVisualQueue or {}
        table.insert(self.healthVisualQueue, entry)
    else
        self:StartHealthVisual(entry)
    end
end

function Clock:ShowHealthMovement() self:ShowHealthReminder('movement') end

function Clock:TickHealthMovement()
    self:SyncHealthMovement()
    local schedules = self.healthSchedules
    if not schedules then return end
    local now = SessionTime()
    local elapsed = SessionElapsed(self)
    if self:IsHealthRestricted() then
        if self.healthVisualUntil or self.healthNoticeUntil or self.healthGlowUntil then
            self:HideHealthNotice()
        end
        self.healthVisualQueue = nil
    elseif self.healthVisualUntil and now >= self.healthVisualUntil then
        self:HideHealthNotice()
        local queue = self.healthVisualQueue
        if queue and #queue > 0 then
            self:StartHealthVisual(table.remove(queue, 1))
        end
    end
    -- Zunaechst alle Faelligkeiten erfassen, bevor sich ein nextAt aendert.
    local dueNow = {}
    for _, category in ipairs(CATEGORIES) do
        local runtime = schedules[category]
        if runtime and elapsed >= runtime.nextAt and not runtime.pending then
            runtime.pending = true
            self:OAPCounter('health.' .. category .. '.due')
        end
        if runtime and runtime.pending then dueNow[category] = true end
    end
    for _, category in ipairs(CATEGORIES) do
        local runtime = schedules[category]
        if runtime and runtime.pending then
            local scheduledAt = runtime.nextAt
            local winner = HigherPriorityNearby(schedules, category, scheduledAt, dueNow)
            runtime.pending = false
            runtime.nextAt = NextBoundary(elapsed, runtime.minutes * 60)
            if winner then
                runtime.suppressed = (runtime.suppressed or 0) + 1
                runtime.lastSuppressedAt = scheduledAt
                self:OAPCounter('health.' .. category .. '.suppressed')
                self:Debug('Health %s visuals suppressed by %s (within 5 min)', category, winner)
                local h = self.db.profile.health
                local _, message = self:GetHealthReminderText(category)
                if self:IsHealthRestricted() then
                    self:AnnounceHealthChat(category, message)
                else
                    local method = h.notice or 'screen'
                    if method == 'chat' or method == 'both' then
                        self:AnnounceHealthChat(category, message)
                    end
                end
            else
                runtime.lastAt = now
                runtime.shown = runtime.shown + 1
                self:ShowHealthReminder(category)
            end
        end
    end
end
