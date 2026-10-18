-- Health text form regression: same row structure as alarms, draft-only editing,
-- no hidden third accept action, and live options regeneration after mutations.
local changes = 0
local health = { movement = {}, drinking = {}, eyes = {} }
local Clock = {db = {profile = {health = health}}}
function Clock:NotifyOptions() changes = changes + 1 end
local L = setmetatable({}, {__index = function(_, key) return key end})
local ns = {Clock = Clock, L = L,
    RowIcon = function(name) return 'Interface\\AddOns\\CantPlayForever\\Media\\Badges\\' .. name end,
    EffectAppearanceArgs = function() return {} end,
    HealthIconAppearanceArgs = function() return {} end}
assert(loadfile('CantPlayForever/Modules/Health/Options.lua'))('CantPlayForever', ns)
local function Args(category)
    return ns.HealthOptions().args[category].args.customTexts.args
end
local function Row(args, number)
    for key in pairs(args) do
        if key:match('^text_.*_summary$') then
            local index = tonumber(key:match('_(%d+)_summary$'))
            if index == number then return key:gsub('_summary$', '') end
        end
    end
end
local initial = Args('movement')
assert(initial.savedHeader.type == 'header' and initial.savedHeader.name == L.HEALTH_SAVED_TEXTS)
assert(initial.savedHeader.order > initial.new.order)
assert(initial.new.width ~= 'full', 'Keep the add button compact like Alarms')
assert(initial.empty and initial.empty.order > initial.savedHeader.order)
initial.new.func()
local form = Args('movement')
assert(not form.newBox.hidden())
local input = form.newBox.args.message
assert(input.dialogControl == 'CPFHealthTextEditor')
assert(input.multiline == 4)
input.set(nil, '  Meine erste Erinnerung  ')
assert(not health.movement.customMessages, 'Typing must not save')
form.newBox.args.save.func()
assert(#health.movement.customMessages == 1 and health.movement.customMessages[1].text == 'Meine erste Erinnerung')
assert(Args('movement').newBox.hidden())
local list = Args('movement')
local key = assert(Row(list, 1), 'First item missing')
assert(list[key..'_enabled'].order < list[key..'_edit'].order)
assert(list[key..'_edit'].order < list[key..'_delete'].order)
assert(list[key..'_delete'].order < list[key..'_summary'].order)
assert(list[key..'_edit'].image:find('edit_gear'))
assert(list[key..'_delete'].image:find('delete_bin'))
assert(list[key..'_summary'].name():find('Meine erste Erinnerung', 1, true))
list[key..'_edit'].func()
local edit = Args('movement')[key..'_mask']
assert(not edit.hidden())
edit.args.message.set(nil, 'Neuer Entwurf')
assert(health.movement.customMessages[1].text == 'Meine erste Erinnerung')
edit.args.cancel.func()
assert(health.movement.customMessages[1].text == 'Meine erste Erinnerung')
Args('movement')[key..'_edit'].func()
Args('movement')[key..'_mask'].args.message.set(nil, 'Bearbeitet')
Args('movement')[key..'_mask'].args.save.func()
assert(health.movement.customMessages[1].text == 'Bearbeitet')
Args('movement')[key..'_enabled'].set(nil, false)
assert(health.movement.customMessages[1].enabled == false)
assert(Args('movement')[key..'_summary'].name():find('888888'))
Args('movement')[key..'_delete'].func()
assert(#health.movement.customMessages == 0 and Args('movement').empty)
assert(changes >= 6)

-- The multiline widget reuses the game's scrollable text box but hides the
-- builtin accept button and updates only the form draft during typing.
local registry = {}
local AceGUI = {}
function AceGUI:GetWidgetVersion() return nil end
function AceGUI:RegisterWidgetType(kind, ctor) registry[kind] = ctor end
function AceGUI:Create(kind)
    assert(kind == 'MultiLineEditBox')
    local widget = {type = kind, userdata = {}}
    function widget:OnAcquire() self.nativeAcquire = true end
    function widget:DisableButton(value) self.buttonDisabled = value end
    function widget:SetCallback(event, callback) self[event] = callback end
    function widget:GetUserData(key) return self.userdata[key] end
    widget:OnAcquire()
    return widget
end
LibStub = function() return AceGUI end
assert(loadfile('CantPlayForever/Modules/Health/TextEditor.lua'))('CantPlayForever', ns)
local editor = registry.CPFHealthTextEditor()
editor:OnAcquire()
assert(editor.nativeAcquire and editor.buttonDisabled == true, 'Built-in accept button must be hidden')
local edited = nil
editor.userdata.option = {set = function(_, text) edited = text end}
editor.OnTextChanged(editor, 'OnTextChanged', 'Dieser Text wird nur Entwurf')
assert(edited == 'Dieser Text wird nur Entwurf')
print('Health text list, save/cancel, dynamic rebuild, custom editor: OK')
