-- Optionaler Eintrag im Blizzard-Addon-Menü (AddonCompartmentFrame).
-- Nicht mit LibDBIcons Compartment-Eintrag verwechseln: ein Klick hier öffnet
-- immer die Optionen, während der Minimap-Button Timer und Alarme bedient.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

local ICON = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\uhr_logo.tga'

local function AddControl(tooltip, label)
    local key, action = tostring(label or ''):match('^(.-)%s*:%s*(.+)$')
    if key then
        tooltip:AddDoubleLine(key, action, 1, 0.82, 0, 0.85, 0.85, 0.85)
    elseif label then
        tooltip:AddLine(label, 0.85, 0.85, 0.85)
    end
end

local function ShowHelp(button)
    local tooltip = _G.GameTooltip
    if not (button and tooltip) then return end
    tooltip:SetOwner(button, 'ANCHOR_LEFT')
    tooltip:ClearLines()
    tooltip:AddLine("Can't play Forever", 1, 0.82, 0)
    tooltip:AddLine(L.COMPARTMENT_CLICK, 0.65, 1, 0.65)
    tooltip:AddLine(' ')
    tooltip:AddLine(L.COMPARTMENT_CONTROLS, 1, 0.82, 0)
    AddControl(tooltip, L.LEFT_CLICK)
    AddControl(tooltip, L.CTRL_LEFT)
    AddControl(tooltip, L.RIGHT_CLICK)
    AddControl(tooltip, L.STOPWATCH_HINT)
    AddControl(tooltip, L.BLIZZARD_CLOCK_HINT)
    AddControl(tooltip, Clock:GetClockDiameter() == 95 and L.DRAG_FREE or L.DRAG_MINIMAP)
    tooltip:Show()
end

local function HideHelp(button)
    local tooltip = _G.GameTooltip
    if tooltip and tooltip.GetOwner and tooltip:GetOwner() == button then
        tooltip:Hide()
    end
end

function Clock:RegisterAddonCompartment()
    local compartment = _G.AddonCompartmentFrame
    if not (compartment and type(compartment.RegisterAddon) == 'function') then
        return -- Ältere Clients ohne Blizzard-Addon-Menü werden unterstützt.
    end

    -- Bei erneuter Aktivierung / Reload keine doppelten Einträge erzeugen.
    if self.compartmentData then return end
    local entry = {
        text = "Can't play Forever",
        icon = ICON,
        notCheckable = true,
        func = function()
            self:OpenSettings('general')
        end,
        funcOnEnter = ShowHelp,
        funcOnLeave = HideHelp,
    }
    compartment:RegisterAddon(entry)
    self.compartmentData = entry
end
