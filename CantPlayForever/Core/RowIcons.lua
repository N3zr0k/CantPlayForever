-- Symbole in den Optionszeilen (Zahnrad, Mülleimer, Sanduhr, Kreis mit Haken). AceConfig kann Bilder
-- weder einfärben noch bei MouseOver wechseln; deshalb wird jedes AceGUI-Icon, dessen Bild eines dieser
-- Symbole ist, beim Setzen des Bildes markiert (SetImage-Wrapper): 'swap'-Symbole sind grau und werden
-- bei MouseOver farbig (zweites Bild <name>_grey), 'plain'-Symbole bleiben, wie sie sind. Bei beiden ist
-- die AceGUI-Hervorhebung (rosa Kasten) abgeschaltet.
local ADDON_NAME, ns = ...

local KINDS = {
    edit_gear = 'swap', delete_bin = 'swap', hourglass = 'swap',
    hourglass_on = 'plain', radio_on = 'plain', radio_off = 'plain',
}
local BADGE_DIR = 'Interface\\AddOns\\CantPlayForever\\Media\\Badges\\'

function ns.RowIcon(name) return BADGE_DIR .. name end

local function KindOf(path)
    local name = type(path) == 'string' and path:match('Badges\\([%w_]+)$')
    return name and KINDS[name]
end

local function SetHover(widget, hover)
    if widget.cpfKind == 'swap' and widget.image then
        widget.image:SetTexture(hover and widget.cpfPath or widget.cpfPath .. '_grey')
    end
end

-- Mouseover-Text: AceConfig zeigt bei Symbolen ohne Beschriftung (name = '') keinen Tooltip; deshalb
-- wird die desc der Option (Text oder Funktion) selbst angezeigt.
local function ShowTip(widget)
    if not widget.cpfKind then return end
    local option = widget.GetUserData and widget:GetUserData('option')
    local desc = option and option.desc
    if type(desc) == 'function' then desc = desc() end
    if type(desc) ~= 'string' or desc == '' then return end
    GameTooltip:SetOwner(widget.frame, 'ANCHOR_TOP')
    GameTooltip:SetText(desc, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

local function HideTip(widget)
    if widget.cpfKind then GameTooltip:Hide() end
end

local AceGUI = LibStub and LibStub('AceGUI-3.0', true)
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
                this.cpfKind, this.cpfPath = KindOf(path), path
                for _, region in ipairs({this.frame:GetRegions()}) do
                    if region.GetDrawLayer and region:GetDrawLayer() == 'HIGHLIGHT' then
                        region:SetAlpha(this.cpfKind and 0 or 1)
                    end
                end
                SetHover(this, false)
            end
            widget.frame:HookScript('OnEnter', function() SetHover(widget, true) ShowTip(widget) end)
            widget.frame:HookScript('OnLeave', function() SetHover(widget, false) HideTip(widget) end)
        end
        return widget
    end
end
