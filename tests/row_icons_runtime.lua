-- Test des tatsachlichen RowIcons-Lua-Codes mit einem minimalen AceGUI/WoW-Mock.
local ns = {}
local availableAtlas = false
C_Texture = { GetAtlasInfo = function(name)
    if availableAtlas and name == 'common-icon-delete' then return {width = 16, height = 16} end
end }

local tipCalls = 0
GameTooltip = {
    SetOwner = function() end, SetText = function(self, value) assert(value == 'Bearbeiten') end,
    Show = function() tipCalls = tipCalls + 1 end, Hide = function() end,
}
local AceGUI = {}
AceGUI.Create = function(self, kind)
    assert(kind == 'Icon')
    local image = {}
    function image:SetTexture(path) self.path = path; self.atlas = nil end
    function image:SetAtlas(atlas) self.atlas = atlas; self.path = nil end
    function image:SetTexCoord() end
    function image:SetDesaturated(value) self.desaturated = value end
    function image:SetVertexColor(...) self.color = {...} end
    local highlight = {alpha = 1}
    function highlight:GetDrawLayer() return 'HIGHLIGHT' end
    function highlight:SetAlpha(alpha) self.alpha = alpha end
    local frame = {handlers = {}}
    function frame:GetRegions() return highlight end
    function frame:HookScript(event, handler) self.handlers[event] = handler end
    local widget = {image = image, frame = frame, type = kind}
    function widget:SetImage(path) self.image:SetTexture(path) end
    function widget:SetDisabled(value)
        self.disabled = value
        self.image:SetVertexColor(1, 1, 1, value and .5 or 1)
    end
    function widget:GetUserData(key)
        if key == 'option' then return {desc = 'Bearbeiten'} end
    end
    return widget
end
LibStub = function(name) assert(name == 'AceGUI-3.0'); return AceGUI end

assert(loadfile('CantPlayForever/Core/RowIcons.lua'))('CantPlayForever', ns)
local gear = AceGUI:Create('Icon')
gear:SetImage(ns.RowIcon('edit_gear'))
assert(gear.image.path == 'Interface\\Buttons\\UI-OptionsButton')
assert(gear.image.desaturated == false, 'Idle gear must retain its original colors')
assert(gear.image.color[1] == 1 and gear.image.color[3] == 1, 'Idle gear must have no tint')
gear.frame.handlers.OnEnter()
assert(gear.image.desaturated == true, 'Hover gear must be desaturated before tinting')
assert(gear.image.color[3] == 1 and gear.image.color[1] < .3, 'Gear must turn blue')
assert(tipCalls == 1, 'Tooltip must work without label')
gear.frame.handlers.OnLeave()
assert(gear.image.desaturated == false, 'Gear must return to original colors')
assert(gear.image.color[1] == 1, 'Gear must return to untinted white vertex color')
gear:SetDisabled(true)
gear.frame.handlers.OnEnter()
assert(gear.image.desaturated == false and gear.image.color[1] == 1 and gear.image.color[4] == .45, 'Disabled gear must remain original, dimmed')
gear:SetDisabled(false)

local delete = AceGUI:Create('Icon')
delete:SetImage(ns.RowIcon('delete_bin'))
assert(delete.image.path:find('delete_bin'), 'Forever fallback must be provided')
assert(not delete.image.desaturated, 'Idle delete icon keeps its gold colors')
delete.frame.handlers.OnEnter()
assert(delete.image.color[1] == 1 and delete.image.color[2] < .3, 'Delete must turn red')
delete.frame.handlers.OnLeave()
assert(delete.image.color[1] == 1 and delete.image.color[2] == 1, 'Delete must return to untinted gold')

-- Bereits genutzte AceGUI-Widgets verlieren ihre Markierung beim Recycling.
gear:SetImage('Interface\\Icons\\INV_Misc_Note_01')
assert(gear.image.desaturated == false, 'Recycled widget must be normal')
assert(gear.image.color[1] == 1, 'Recycled widget must be white')
gear.frame.handlers.OnEnter()
assert(gear.image.color[1] == 1, 'Hover must not tint an unrelated widget')
gear:SetImage(nil)
assert(gear.image.desaturated == false)
print('RowIcons Blizzard gear, trash fallback/atlas, tint, tooltip and reuse: OK')
