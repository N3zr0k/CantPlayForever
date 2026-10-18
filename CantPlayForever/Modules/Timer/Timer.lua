local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L, T, Between, Now = ns.Clock, ns.L, ns.T, ns.Between, ns.Now

function Clock:ToggleSelectedTimer()
    if self.db.profile.activeTimer then
        self:StopTimer()
    else
        self:StartSelectedTimer()
    end
end

function Clock:CheckTimer()
    local timer = self.db.profile.activeTimer
    if not timer or not self:IsModuleEnabled('timer') then return end
    -- Die letzten Sekunden zeigt UpdateTimerWarnGlow (blauer Ring); beim Ablauf folgt der Alarm.
    if Now() >= timer.expiresAt then
        self.db.profile.activeTimer = nil
        self:OAPCounter('timer.expired')
        self:OAPLog('info', 'Timer expired: {1}', timer.name or '')
        self:Alert(timer.name or L.TIMER_FINISHED, 'timer')
        self:NotifyOptions()
        self:UpdateClock()
    end
end

function Clock:StartTimer(seconds, name, presetID)
    seconds = Between(seconds, 1, 7 * 24 * 3600)
    self:Debug('Timer started: %d s (%s)', seconds, tostring(name))
    self:OAPCounter('timer.started')
    self:OAPLog('info', 'Timer started: {1} seconds, {2}', seconds, name or '')
    self.db.profile.activeTimer = {
        expiresAt = Now() + seconds,
        name = name or L.TIMER_FINISHED,
        presetID = presetID,
    }
    self:Print(string.format(L.TIMER_STARTED, self:Duration(seconds)))
    self:NotifyOptions()
    self:UpdateClock()
end

-- Laufenden Timer auf eine neue Restzeit setzen (Name bleibt erhalten).
function Clock:SetTimerRemaining(seconds)
    local timer = self.db.profile.activeTimer
    if not timer then return false end
    seconds = Between(seconds, 1, 7 * 24 * 3600)
    timer.expiresAt = Now() + seconds
    self:Print(string.format(L.TIMER_STARTED, self:Duration(seconds)))
    self:NotifyOptions()
    self:UpdateClock()
    return true
end

function Clock:StopTimer()
    self:Debug('Timer stopped')
    self:OAPCounter('timer.stopped')
    self:OAPLog('info', 'Timer stopped')
    self.db.profile.activeTimer = nil
    self:Print(L.TIMER_STOPPED)
    self:NotifyOptions()
    self:UpdateClock()
end

function Clock:Duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format('%02d:%02d:%02d', h, m, s)
end

-- One blue number beneath the time: ceil(minutes) until 60 seconds,
-- then integer seconds. Hours are always folded into minutes.
-- Einheit hinter der Timer-Zahl: eigener Text aus dem Tuning, sonst die lokalisierte Einheit.
function Clock:CountdownSuffix(unit)
    local custom = T['CD_SUFFIX_' .. unit]
    if custom and custom ~= '' then return custom end
    return L['UNIT_' .. unit]
end

-- Zahl samt anhängbarem Text (CD_SUFFIX_MIN / CD_SUFFIX_SEC), z. B. "25 min".
function Clock:CountdownText()
    if not self:IsModuleEnabled('timer') then return nil end
    local remaining = self:RemainingTimer()
    if remaining == nil then return nil end
    if remaining > 3600 then
        -- Stunden mit zwei Nachkommastellen (1 h 5 min = 1,08), abgerundet; Komma in de/fr.
        local hours = string.format('%.2f', math.floor(remaining / 36) / 100)
        local locale = (_G.GetLocale and GetLocale()) or 'enUS'
        if locale == 'deDE' or locale == 'frFR' then hours = hours:gsub('%.', ',') end
        return hours .. self:CountdownSuffix('HRS')
    end
    if remaining > 60 then return tostring(math.ceil(remaining / 60)) .. self:CountdownSuffix('MIN') end
    return tostring(math.ceil(remaining)) .. self:CountdownSuffix('SEC')
end

function Clock:CountdownNumber()
    local remaining = self:RemainingTimer()
    if remaining == nil then return nil end
    if remaining > 60 then return tostring(math.ceil(remaining / 60)) end
    return tostring(math.ceil(remaining))
end

function Clock:StartSelectedTimer()
    local selected = self.db.profile.selectedPresetID
    for _, preset in ipairs(self.db.profile.presets) do
        if selected and preset.id == selected then
            self:StartTimer(preset.seconds, preset.name, preset.id)
            return true
        end
    end
    self:Print(L.PRESET_MISSING)
    return false
end

function Clock:RemainingTimer()
    local timer = self.db.profile.activeTimer
    if not timer then return nil end
    return math.max(0, timer.expiresAt - Now())
end

-- Verdeckt die Uhr ein anderes Minimap-Element? Rot, dauerhaft, 80 % (Priorität 20).
function Clock:UpdateTimerWarnGlow()
    local remaining = self:IsModuleEnabled('timer') and self:RemainingTimer() or nil
    -- Klein: der ganze Kreis leuchtet blau; alle anderen Größen: Ring.
    local spec = self:GetClockDiameter() == ns.SMALL_DIAMETER
        and T.TIMER_WARN_GLOW_SMALL or T.TIMER_WARN_GLOW
    if remaining and remaining > 0 and remaining <= T.TIMER_WARN_SEC
        and self:SetGlow('timerWarn', spec, 25) then
        return
    end
    self:ClearGlow('timerWarn')
end

Clock:RegisterModule({
    id = 'timer',
    logo = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\timer_logo',
    OnEnable = function(self) self:CheckTimer() end,
    OnTick = function(self)
        self:CheckTimer()
        self:UpdateTimerWarnGlow()
    end,
    OnChanged = function(self) self:UpdateTimerWarnGlow() end,
    OnSlash = function(self, input)
        if input == 'stop' then
            self:StopTimer()
            return true
        end
        local minutes = tonumber(input:match('^timer%s+(%d+)$'))
        if minutes then
            self:StartTimer(minutes * 60, string.format(L.CMD_TIMER_NAME, minutes))
            return true
        end
    end,
    GetOptions = function() return ns.TimerOptions() end,
})
