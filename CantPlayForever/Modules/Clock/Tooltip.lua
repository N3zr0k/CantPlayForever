local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

-- LibDBIcon nutzt einen eigenen, wiederverwendeten GameTooltip.
-- Die Felder werden während des Mouseovers aktualisiert, ohne ihn
-- bei jeder Sekunde zu schließen oder den Mouseover neu auszulösen.
function Clock:TooltipSignature()
    local fields = {self.db.profile.activeTimer and 'timer' or 'no-timer'}
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed then
            fields[#fields + 1] = tostring(alarm.id) .. ':'
                .. tostring(alarm.hour) .. ':' .. tostring(alarm.minute)
                .. ':' .. tostring(alarm.name)
        end
    end
    return table.concat(fields, ';')
end

-- Hinweiszeile "Taste: Wirkung" als zweispaltige Zeile (Taste gold, Wirkung hell).
local function AddHint(tooltip, text)
    local key, action = tostring(text):match('^(.-)%s*:%s*(.+)$')
    if key then
        tooltip:AddDoubleLine(key, action, 1, 0.82, 0, 0.85, 0.85, 0.85)
    else
        tooltip:AddLine(text, 0.85, 0.85, 0.85)
    end
end

function Clock:BuildHoverTooltip(tooltip)
    self.hoverTooltip = tooltip
    self.hoverSignature = self:TooltipSignature()
    tooltip:AddLine("Can't play Forever", 1, 0.82, 0)
    tooltip:AddLine(' ')
    self.hoverClockLine = tooltip:NumLines() + 1
    tooltip:AddDoubleLine(L.CLOCK_LABEL, self:FormatTooltipTime(), 0.75, 0.75, 0.75, 1, 1, 1)
    self.hoverTimerLine = nil
    local remaining = self:RemainingTimer()
    if remaining then
        self.hoverTimerLine = tooltip:NumLines() + 1
        tooltip:AddDoubleLine(L.TIMER_LABEL, self:Duration(remaining), 0.75, 0.75, 0.75, .39, .79, 1)
    end
    local active = {}
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed then active[#active + 1] = alarm end
    end
    if #active > 0 then
        table.sort(active, function(a,b)
            local minsA = self:AlarmMinutesUntil(a)
            local minsB = self:AlarmMinutesUntil(b)
            if minsA == minsB then return (a.id or 0) < (b.id or 0) end
            return minsA < minsB
        end)
        tooltip:AddLine(' ')
        tooltip:AddLine(L.ARMED_HEADER, .35, 1, .35)
        for _, alarm in ipairs(active) do
            tooltip:AddDoubleLine(string.format('%02d:%02d', alarm.hour, alarm.minute),
                alarm.name and alarm.name ~= '' and alarm.name or L.ALARM_FALLBACK,
                1, 1, 1, .75, 1, .75)
        end
    end
    tooltip:AddLine(' ')
    AddHint(tooltip, L.LEFT_CLICK)
    AddHint(tooltip, L.RIGHT_CLICK)
    AddHint(tooltip, L.SHIFT_LEFT)
    AddHint(tooltip, L.STOPWATCH_HINT)
    AddHint(tooltip, L.BLIZZARD_CLOCK_HINT)
    AddHint(tooltip, self:GetClockDiameter() == 95 and L.DRAG_FREE or L.DRAG_MINIMAP)
end

function Clock:UpdateHoverTooltip()
    local tooltip = self.hoverTooltip
    if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then return end
    -- LibDBIconTooltip ist gemeinsam mit anderen Addons nutzbar.
    if tooltip.GetOwner and tooltip:GetOwner() ~= self.iconButton then return end
    local signature = self:TooltipSignature()
    if signature ~= self.hoverSignature then
        tooltip:ClearLines()
        self:BuildHoverTooltip(tooltip)
        tooltip:Show()
        return
    end
    local name = tooltip.GetName and tooltip:GetName()
    if not name or name == '' then
        -- Fallback für Clients, die FontStrings nicht namentlich exponieren.
        tooltip:ClearLines()
        self:BuildHoverTooltip(tooltip)
        tooltip:Show()
        return
    end
    local timeText = _G[name .. 'TextRight' .. self.hoverClockLine]
    if timeText then
        timeText:SetText(self:FormatTooltipTime())
    end
    if self.hoverTimerLine then
        local timerText = _G[name .. 'TextRight' .. self.hoverTimerLine]
        if timerText then
            timerText:SetText(self:Duration(self:RemainingTimer() or 0))
        end
    end
end
