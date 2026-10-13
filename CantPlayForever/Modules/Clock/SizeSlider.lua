-- Spezialisierter AceGUI-Slider: drei Rastpunkte, aber lokalisierte Größennamen als Text.
-- Keine Änderungen an der eingebetteten Ace3-Library notwendig.
local ADDON_NAME, ns = ...
local AceGUI = _G.LibStub and _G.LibStub('AceGUI-3.0', true)
if not AceGUI then return end

-- Beschriftung kommt zur Laufzeit aus der Lokalisierung (Klein/Mittel/Groß).
local function Label(index)
    local L = ns.L
    if not L then return '' end
    return index == 1 and L.SIZE_SMALL or index == 2 and L.SIZE_MEDIUM or index == 3 and L.SIZE_LARGE or ''
end
local TYPE = 'CantPlayForeverSizeSlider'

local function Constructor()
    local widget = AceGUI:Create('Slider')
    widget.type = TYPE
    local originalSetValue = widget.SetValue
    local originalSetSliderValues = widget.SetSliderValues
    local originalSetIsPercent = widget.SetIsPercent

    local function UpdateLabel(self)
        local value = self.value and math.floor(self.value + 0.5)
        self.editbox:SetText(Label(value))
    end

    function widget:SetValue(value)
        originalSetValue(self, value)
        UpdateLabel(self)
    end

    function widget:SetSliderValues(minValue, maxValue, step)
        originalSetSliderValues(self, minValue, maxValue, step)
        self.lowtext:SetText(Label(1))
        self.hightext:SetText(Label(3))
        UpdateLabel(self)
    end

    -- AceConfigDialog setzt nach den Slider-Grenzen SetIsPercent(nil);
    -- das Standard-Widget würde sonst die Randlabels auf 1 und 3 zurücksetzen.
    function widget:SetIsPercent(value)
        originalSetIsPercent(self, value)
        self.lowtext:SetText(Label(1))
        self.hightext:SetText(Label(3))
        UpdateLabel(self)
    end

    widget.slider:HookScript('OnValueChanged', function()
        UpdateLabel(widget)
    end)

    widget.editbox:SetScript('OnEnterPressed', function(box)
        local text = (box:GetText() or ''):lower()
        local index
        for i = 1, 3 do
            if text == Label(i):lower() or text == tostring(i) then index = i end
        end
        if index then
            widget.slider:SetValue(index)
            widget:Fire('OnMouseUp', index)
        end
        UpdateLabel(widget)
        box:ClearFocus()
    end)

    return widget
end

AceGUI:RegisterWidgetType(TYPE, Constructor, 1)
