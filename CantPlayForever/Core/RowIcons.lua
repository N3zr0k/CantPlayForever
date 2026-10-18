-- Gemeinsame kleine Bedienelemente in Alarm-, Timer- und Health-Listen.
-- Blizzard-Zahnrad sowie eigenes Loeschen-Symbol.
-- Zahnrad: unveraenderte Blizzard-Originalfarbe, beim Hover zuerst
-- entsaettigen, danach blau faerben. Muelleimer: Gold, beim Hover rot.
-- Dadurch braucht das Zahnrad kein kuenstliches zweites Hover-Bild.
local ADDON_NAME, ns = ...

local BADGE_DIR = 'Interface\\AddOns\\CantPlayForever\\Media\\Badges\\'
local NATIVE_GEAR = 'Interface\\Buttons\\UI-OptionsButton'
local TYPES = {
    edit_gear = 'tint', delete_bin = 'tint',
    hourglass = 'swap', hourglass_on = 'plain',
    radio_on = 'plain', radio_off = 'plain',
}
local EDIT_HOVER = {0.26, 0.69, 1.00}
local DELETE_HOVER = {1.00, 0.28, 0.25}

-- Beibehaltene AceConfig-Pfade: Alarme, Timer und Health nutzen dieselben Icons.
function ns.RowIcon(name) return BADGE_DIR .. name end

local function IconName(path)
    if type(path) ~= 'string' then return nil end
    return path:match('Badges\\([%w_]+)$')
end

local function ApplyStyle(widget, hovered)
    local icon = widget.image
    if not icon then return end
    local kind, name = widget.cpfKind, widget.cpfName
    if kind == 'swap' then
        -- Bestehendes Sanduhr-Verhalten beibehalten.
        icon:SetTexture(hovered and widget.cpfPath or widget.cpfPath .. '_grey')
    elseif kind == 'tint' then
        if name == 'edit_gear' then
            -- Im Ruhezustand die originalen WoW-Farben behalten. Erst fuer
            -- den blauen Hover die goldene/originale Farbe entfernen.
            local highlight = hovered and not widget.disabled
            if icon.SetDesaturated then icon:SetDesaturated(highlight) end
            local color = highlight and EDIT_HOVER or {1, 1, 1}
            icon:SetVertexColor(color[1], color[2], color[3], widget.disabled and 0.45 or 1)
        else
            -- Neue goldene Muelleimer-Grafik unverfaelscht lassen; beim Hover rot.
            local highlight = hovered and not widget.disabled
            if icon.SetDesaturated then icon:SetDesaturated(highlight) end
            local color = highlight and DELETE_HOVER or {1, 1, 1}
            icon:SetVertexColor(color[1], color[2], color[3], widget.disabled and 0.45 or 1)
        end
    end
end

local function SetImageStyle(widget, path)
    widget.cpfPath = path
    widget.cpfName = IconName(path)
    widget.cpfKind = TYPES[widget.cpfName]
    -- Alle angepassten Regionen zuruecksetzen, wenn AceGUI das Widget recycelt.
    if widget.image then
        if widget.image.SetDesaturated then widget.image:SetDesaturated(false) end
        widget.image:SetVertexColor(1, 1, 1, widget.disabled and 0.5 or 1)
    end
    if widget.cpfName == 'edit_gear' then
        -- Diese Blizzard-Textur ist auch im Forever-/Classic-Client vorhanden.
        widget.image:SetTexture(NATIVE_GEAR)
        widget.image:SetTexCoord(0, 1, 0, 1)
    elseif widget.cpfName == 'delete_bin' then
        -- Immer das eigene Symbol verwenden, auch wenn ein Blizzard-Atlas vorhanden ist.
        widget.image:SetTexture(BADGE_DIR .. 'delete_bin')
        widget.image:SetTexCoord(0, 1, 0, 1)
    end
    for _, region in ipairs({widget.frame:GetRegions()}) do
        if region.GetDrawLayer and region:GetDrawLayer() == 'HIGHLIGHT' then
            region:SetAlpha(widget.cpfKind and 0 or 1)
        end
    end
    ApplyStyle(widget, false)
end

-- Bei namenlosen Icon-Buttons muss der Options-Tooltip explizit aufgebaut werden.
local function ShowTip(widget)
    if not widget.cpfKind then return end
    local option = widget.GetUserData and widget:GetUserData('option')
    local description = option and option.desc
    if type(description) == 'function' then description = description() end
    if type(description) ~= 'string' or description == '' or not _G.GameTooltip then return end
    GameTooltip:SetOwner(widget.frame, 'ANCHOR_TOP')
    GameTooltip:SetText(description, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

local function HideTip(widget)
    if widget.cpfKind and _G.GameTooltip then GameTooltip:Hide() end
end

local AceGUI = _G.LibStub and _G.LibStub('AceGUI-3.0', true)
if AceGUI and not AceGUI.cpfIconWrapped then
    AceGUI.cpfIconWrapped = true
    local create = AceGUI.Create
    AceGUI.Create = function(self, widgetType, ...)
        local widget = create(self, widgetType, ...)
        if widgetType == 'Icon' and widget and not widget.cpfWrapped then
            widget.cpfWrapped = true
            local setImage = widget.SetImage
            widget.SetImage = function(this, path, ...)
                setImage(this, path, ...)
                SetImageStyle(this, path)
            end
            local setDisabled = widget.SetDisabled
            if setDisabled then
                widget.SetDisabled = function(this, disabled)
                    setDisabled(this, disabled)
                    ApplyStyle(this, false)
                end
            end
            widget.frame:HookScript('OnEnter', function()
                ApplyStyle(widget, true)
                ShowTip(widget)
            end)
            widget.frame:HookScript('OnLeave', function()
                ApplyStyle(widget, false)
                HideTip(widget)
            end)
        end
        return widget
    end
end
