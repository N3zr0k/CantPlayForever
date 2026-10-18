-- Standalone Lua 5.1 test double for Health. No WoW client required.
local path = (arg and arg[1]) or 'CantPlayForever/Modules/Health'
local ns, locales = {}, {}
function LibStub(_)
    return {NewLocale = function(_, addon, loc)
        locales[loc] = locales[loc] or {}
        return locales[loc]
    end}
end
for _, loc in ipairs({'enUS', 'deDE', 'frFR'}) do
    assert(loadfile(path .. '/Locales/' .. loc .. '.lua'))('CantPlayForever', ns)
end
ns.L = locales.deDE
-- The full Core/ScreenGlow.lua API is separately exercised in health_appearance_runtime.lua.
ns.EffectAppearanceArgs = function() return {} end
ns.RowIcon = function(name) return 'test_media/' .. name end
-- A separate native test exercises the actual icon option callbacks end-to-end.
ns.HealthIconAppearanceArgs = function()
    return {iconEnabled={type='toggle'}, iconTransparency={type='range',min=0,max=100},
            iconOffsetY={type='range',min=-120,max=120}}
end
local now, combat, instance, faction = 0, false, false, 'Alliance'
local sounds, glows = 0, 0
ns.Now = function() return now end
local clock = {
    MODULES = {},
    sessionStartedAt = 0,
    db = { profile = {
        modules = { health = false },
        effects = {health={iconEnabled=true,iconTransparency=65,iconOffsetY=65}},
        health = {
            movement = {enabled = true, interval = 45, iconEnabled = true, iconTransparency = 65},
            drinking = {enabled = true, interval = 30, iconEnabled = true, iconTransparency = 65},
            eyes = {enabled = true, interval = 20, iconEnabled = true, iconTransparency = 65},
            notice = 'screen', sound = true,
            -- Old saved values must not defer chat-only reminders.
            deferInCombat = true, deferInInstances = true,
        },
    } },
    chat = {},
}
function clock:RegisterModule(def) self.MODULES[def.id] = def; return def end
function clock:IsModuleEnabled(id) return self.db.profile.modules[id] == true end
function clock:Print(message) self.chat[#self.chat + 1] = message end
function clock:Debug() end
function clock:OAPCounter() end
function clock:NotifyOptions() self.MODULES.health.OnChanged(self) end
function clock:GetSessionSeconds() return now - self.sessionStartedAt end
function clock:ShowScreenGlow(source)
    assert(source == 'health')
    assert(not self:IsHealthRestricted(), 'Glow leaked into combat/instance')
    glows = glows + 1
    self.activeScreenGlowSource = source
end
function clock:GetHealthEffectOverride(category)
    local setting = self.db.profile.health[category]
    return setting and setting.customEffect and setting.effect or nil
end
function clock:GetEffectConfig() return { screenGlow = true } end
function clock:GetHealthIconSetting(category, field)
    local cat = self.db.profile.health[category]
    if cat and cat.customEffect and cat.effect and cat.effect[field] ~= nil then
        return cat.effect[field]
    end
    return self.db.profile.effects.health[field]
end
function clock:GetEffectStyle() return {color={0.36,1,0.31}} end
function clock:SetHealthCustomEffect(category, enabled)
    local setting = self.db.profile.health[category]
    setting.customEffect = enabled
    if enabled and not setting.effect then setting.effect = {spec = '5FFF4F, pulse, 1, 10'} end
end
function clock:HideScreenGlow() self.activeScreenGlowSource = nil end
ns.Clock = clock
function GetTime() return now end
function UnitAffectingCombat() return combat end
function InCombatLockdown() return combat end
function IsInInstance() return instance, instance and 'party' or 'none' end
function UnitFactionGroup() return faction end
SOUNDKIT = {IG_MAINMENU_OPTION_CHECKBOX_ON = 123}
function PlaySound() sounds = sounds + 1 end
local frame = {}
for _, method in ipairs({'SetFrameStrata', 'SetWidth', 'SetJustifyH',
    'SetTextColor', 'SetShadowColor', 'SetShadowOffset', 'SetFont'}) do
    frame[method] = function() end
end
function frame:SetText(value) self.text = value end
function frame:SetSize(width, height) self.size = {width, height} end
function frame:SetPoint(...) self.anchor = {...} end
function frame:SetAlpha(alpha) self.alpha = alpha end
function frame:SetTexture(texture) self.texture = texture end
function frame:SetTexCoord(...) self.texCoord = {...} end
function frame:ClearAllPoints() self.anchor = nil end
function frame:CreateTexture(_, layer)
    local texture = setmetatable({layer = layer}, {__index = frame})
    self.icon = texture
    return texture
end
function frame:Show() self.visible = true end
function frame:Hide() self.visible = false end
function frame:SetScript(event, callback) self[event] = callback end
function frame:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
end
function frame:UnregisterAllEvents() self.events = {} end
function frame:CreateFontString(_, layer)
    return setmetatable({layer = layer}, {__index = frame})
end
function CreateFrame() return setmetatable({}, {__index = frame}) end
UIParent = {}
for _, file in ipairs({'Messages.lua', 'Notice.lua', 'Reminders.lua', 'Health.lua', 'Options.lua'}) do
    assert(loadfile(path .. '/' .. file))('CantPlayForever', ns)
end
local health = clock.MODULES.health
assert(health and health.available ~= false)
assert(not clock:IsModuleEnabled('health'))
clock.db.profile.modules.health = true
health.OnChanged(clock)
assert(clock.healthMovement.nextAt == 2700)
assert(clock.healthSchedules.drinking.nextAt == 1800)
assert(clock.healthSchedules.eyes.nextAt == 1200)
assert(clock.healthSafetyMonitoring)

-- Icon-Auswahl: automatische Allianz/Horde-Erkennung, echter transparenter Pfad.
clock:ShowHealthNotice('drinking', 'Titel', 'Wasser trinken')
assert(clock.healthNoticeIcon.texture:find('drink_alliance', 1, true))
assert(math.abs(clock.healthNoticeIcon.alpha - 0.35) < 0.001)
assert(clock.healthNoticeLabel.text == 'Titel\nWasser trinken')
assert(clock.healthNoticeLabel.layer == 'OVERLAY')
assert(clock.healthNoticeIcon.layer == 'ARTWORK')
assert(clock.healthNotice.anchor[1] == 'CENTER')
faction = 'Horde'
clock:ShowHealthNotice('drinking', 'Titel', 'Wasser trinken')
assert(clock.healthNoticeIcon.texture:find('drink_horde', 1, true))
clock:ShowHealthNotice('movement', 'Titel', 'Aufstehen')
assert(clock.healthNoticeIcon.texture:find('movement_horde', 1, true))
clock:ShowHealthNotice('eyes', 'Titel', 'Blinzeln')
assert(clock.healthNoticeIcon.texture:find('eye_horde', 1, true))
clock.db.profile.effects.health.iconEnabled = false
clock:ShowHealthNotice('eyes', 'Titel', 'Blinzeln')
assert(not clock.healthNoticeIcon.visible)
clock.db.profile.effects.health.iconEnabled = true
clock.db.profile.effects.health.iconTransparency = 80
clock:ShowHealthNotice('eyes', 'Titel', 'Blinzeln')
assert(math.abs(clock.healthNoticeIcon.alpha - 0.2) < 0.001)
clock:HideHealthNotice()
clock.db.profile.effects.health.iconTransparency = 65

-- Health-Effekttests zeigen eine Nachricht und ein Icon. Sie duerfen keine
-- Erinnerungen ausloesen oder deren Session-Plan veraendern.
local callbacks, previews = {}, {}
C_Timer = {After = function(seconds, fn)
    assert(seconds == 9)
    callbacks[#callbacks + 1] = fn
end}
function clock:PreviewScreenGlow(source, override)
    assert(source == 'health')
    previews[#previews + 1] = {override = override}
end
local scheduleBefore = clock.healthSchedules.drinking.nextAt
local messagesBefore, soundsBefore, glowsBefore = #clock.chat, sounds, glows
faction = 'Alliance'
clock:PreviewHealthEffect()
assert(clock.healthNotice.visible and clock.healthNoticePreviewActive)
assert(clock.healthNoticeLabel.text == ns.L.HEALTH_PREVIEW_TITLE .. '\n' .. ns.L.HEALTH_PREVIEW_MESSAGE)
assert(clock.healthNoticeIcon.texture:find('faction_alliance', 1, true))
assert(previews[#previews].override == nil)
assert(#clock.chat == messagesBefore and glows == glowsBefore)
assert(sounds == soundsBefore + 1) -- Der Effekt-Test spielt den Hinweiston immer
assert(clock.healthSchedules.drinking.nextAt == scheduleBefore)
-- Wiederholte Klicks verlaengern die Vorschau; veraltete Timer ignorieren.
faction = 'Horde'
clock:PreviewHealthEffect()
assert(clock.healthNoticeIcon.texture:find('faction_horde', 1, true))
callbacks[1]()
assert(clock.healthNotice.visible)
callbacks[2]()
assert(not clock.healthNotice.visible)
-- Individuelle Vorschau verwendet echten Titel/Text, Kategorie-Icon und Override.
local custom = {spec = '123456, pulse, 1, 80', iconEnabled = true,
    iconTransparency = 25, iconOffsetY = -24}
clock.db.profile.health.drinking.customEffect = true
clock.db.profile.health.drinking.effect = custom
clock:PreviewHealthEffect('drinking')
do
    local shown = clock.healthNoticeLabel.text
    local ok = false
    for i = 1, 10 do
        if shown == ns.L['HEALTH_DRINK_TITLE_' .. i] .. '\n' .. ns.L['HEALTH_DRINK_MESSAGE_' .. i] then ok = true end
    end
    assert(ok, shown)
end
assert(clock.healthNoticeIcon.texture:find('drink_horde', 1, true))
assert(math.abs(clock.healthNoticeIcon.alpha - 0.75) < 0.001)
assert(clock.healthNoticeIcon.anchor[5] == -24)
assert(previews[#previews].override == custom)
assert(clock.healthSchedules.drinking.nextAt == scheduleBefore)
assert(#clock.chat == messagesBefore and glows == glowsBefore)
-- Ein regulaerer Hinweis darf nicht durch einen alten Vorschau-Timer verschwinden.
clock:ShowHealthNotice('movement', 'Echte Erinnerung', 'Jetzt bewegen')
callbacks[3]()
assert(clock.healthNotice.visible and not clock.healthNoticePreviewActive)
clock:HideHealthNotice()
clock.db.profile.health.drinking.customEffect = false
combat = true
clock:PreviewHealthEffect()
assert(not clock.healthNotice.visible)
combat = false

-- Alle drei Kategorien erinnern im Core-Takt; Kampf/Instanz bleibt Chat-only.
sounds = 0
now, combat = 1200, true
health.OnTick(clock)
assert(not clock.healthNotice.visible and #clock.chat == 1 and sounds == 0 and glows == 0)
assert(clock.healthSchedules.eyes.shown == 1)
now, combat, instance = 1800, false, true
health.OnTick(clock)
assert(#clock.chat == 2 and clock.healthSchedules.drinking.shown == 1)
now, instance = 2700, false
health.OnTick(clock)
assert(clock.healthSchedules.movement.shown == 1)
assert(clock.healthNotice.visible and sounds >= 1 and glows == 1)
assert(clock.healthNoticeIcon.texture:find('movement_horde', 1, true))

-- Bei +/-5 Minuten wird die niedriger priorisierte Erinnerung verworfen.
assert(clock.healthSchedules.eyes.shown == 1 and clock.healthSchedules.eyes.suppressed == 1)
now = 3600
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 2 and clock.healthSchedules.eyes.shown == 1)
assert(clock.healthSchedules.eyes.suppressed == 2)
assert(not clock.healthVisualQueue)
assert(clock.healthNoticeIcon.texture:find('drink_horde', 1, true))
now = 3609
health.OnTick(clock)
assert(not clock.healthNotice.visible and not clock.healthVisualQueue)

now, combat = 3610, true
clock.healthSafetyFrame.OnEvent(clock.healthSafetyFrame, 'PLAYER_REGEN_DISABLED')
assert(not clock.healthNotice.visible and not clock.healthVisualQueue)
clock:ShowHealthNotice('eyes', 'Titel', 'Gesperrt')
assert(not clock.healthNotice.visible)
combat = false

local opts=ns.HealthOptions()
assert(opts.childGroups=='tab' and not opts.args.sleep)
for _, category in ipairs({'movement', 'drinking', 'eyes'}) do
    local setting = opts.args[category].args
    assert(setting[category].type == 'toggle')
    assert(setting.interval.type == 'range')
    assert(setting.iconEnabled == nil and setting.display == nil)
    assert(setting.customEffect.type == 'toggle')
    assert(setting.appearance.hidden())
    setting.customEffect.set(nil, true)
    assert(not setting.appearance.hidden())
    assert(setting.appearance.args.iconEnabled.type == 'toggle')
    assert(setting.appearance.args.iconTransparency.type == 'range')
    assert(setting.appearance.args.iconOffsetY.type == 'range')
end
clock.db.profile.modules.health = false
health.OnChanged(clock)
assert(not clock.healthSchedules and not clock.healthSafetyMonitoring)
health.OnRefresh(clock)
for _, category in ipairs({'movement', 'drinking', 'eyes'}) do
    for _ = 1, 40 do
        local title, message = ns.HealthReminderEntry(category)
        assert(type(title) == 'string' and title ~= '' and not title:find('HEALTH_', 1, true), title)
        assert(type(message) == 'string' and message ~= '' and not message:find('HEALTH_', 1, true), message)
    end
end
-- Augenpause: Uebungstitel gehoert zum Text derselben Uebung.
for _ = 1, 60 do
    local title, message = ns.HealthReminderEntry('eyes')
    local found = false
    for i = 1, 6 do
        for j = 1, 2 do
            if message == ns.L['HEALTH_EYES_MESSAGE_' .. i .. '_' .. j] then
                assert(title == ns.L['HEALTH_EYES_NAME_' .. i], title)
                found = true
            end
        end
    end
    assert(found, message)
end
assert(ns.HealthReminderEntry('unknown') == nil)
-- Quellenangabe steht im Optionsmenue der jeweiligen Kategorie.
assert(ns.HealthSourceText('eyes'):find('dak.de', 1, true))
assert(ns.HealthSourceText('drinking'):find('dge.de', 1, true) and ns.HealthSourceText('drinking'):find('bzfe.de', 1, true))
assert(ns.HealthSourceText('movement'):find('gesund.bund.de', 1, true))
do
    local _, _, source = clock:GetHealthReminderText('eyes')
    assert(source == nil, 'Quelle gehoert ins Menue, nicht in die Meldung')
    local group = ns.HealthOptions().args.eyes.args.sourceInfo
    assert(group and group.name:find('dak.de', 1, true) and group.order >= 90)
end
-- Prioritaetsfaelle unabhaengig von echten WoW-Frames abdecken.
local function ResetPriority(drinking, movement, eyes)
    clock.db.profile.modules.health = true
    for id, interval in pairs({drinking = drinking or false, movement = movement or false, eyes = eyes or false}) do
        local c = clock.db.profile.health[id]
        c.enabled, c.interval = interval ~= false, interval or c.interval
    end
    now, combat, instance, faction = 0, false, false, 'Horde'
    sounds, glows = 0, 0
    clock.chat = {}
    clock:ResetHealthMovement()
    health.OnChanged(clock)
end

-- Genau 5 Minuten vorher: Bewegung faellt zugunsten von Trinken weg.
ResetPriority(10, 5, nil)
now = 300
health.OnTick(clock)
assert(clock.healthSchedules.movement.suppressed == 1)
assert(clock.healthSchedules.movement.shown == 0)
assert(sounds == 0 and glows == 0 and #clock.chat == 0)
now = 600
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 1)
assert(clock.healthSchedules.movement.suppressed == 2)
assert(not clock.healthVisualQueue)

-- Vier Minuten vor dem Trinken: Bewegung entfaellt.
ResetPriority(15, 11, nil)
now = 660
health.OnTick(clock)
assert(clock.healthSchedules.movement.suppressed == 1 and glows == 0)
now = 900
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 1)

-- Sechs Minuten davor: Beide Erinnerungen duerfen erscheinen.
ResetPriority(15, 9, nil)
now = 540
health.OnTick(clock)
assert(clock.healthSchedules.movement.shown == 1)
assert(clock.healthSchedules.movement.suppressed == 0)

-- Drei exakt zeitgleiche Kategorien: genau eine Bildschirmanzeige,
-- genau ein Ton und kein weiterer Warteschlangen-Eintrag.
ResetPriority(10, 10, 10)
now = 600
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 1)
assert(clock.healthSchedules.movement.suppressed == 1)
assert(clock.healthSchedules.eyes.suppressed == 1)
assert(sounds == 1 and glows == 1 and not clock.healthVisualQueue)
assert(clock.healthNoticeIcon.texture:find('drink_horde', 1, true))

-- Eine Minute nach einem hoeherwertigen Termin ebenso unterdruecken.
ResetPriority(10, 11, nil)
now = 600
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 1)
now = 660
health.OnTick(clock)
assert(clock.healthSchedules.movement.suppressed == 1)
assert(clock.healthSchedules.movement.shown == 0)

-- Verkettung: Trinken > Bewegung > Augen, obwohl Trinken und Augen
-- acht Minuten auseinanderliegen (beide vier Minuten von Bewegung).
ResetPriority(20, 24, 28)
now = 1200
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 1)
now = 1440
health.OnTick(clock)
assert(clock.healthSchedules.movement.suppressed == 1)
now = 1680
health.OnTick(clock)
assert(clock.healthSchedules.eyes.suppressed == 1)
assert(clock.healthSchedules.eyes.shown == 0)

-- Deaktivierte Kategorien duerfen keine niedrigere Kategorie blockieren.
ResetPriority(nil, 5, nil)
now = 300
health.OnTick(clock)
assert(clock.healthSchedules.movement.shown == 1)

-- Kampf: nur ein priorisierter Chat-Eintrag ohne visuelle Ausgabe/Ton.
ResetPriority(10, 5, nil)
now, combat = 600, true
health.OnTick(clock)
assert(clock.healthSchedules.drinking.shown == 1)
assert(clock.healthSchedules.movement.suppressed == 1)
assert(#clock.chat == 2 and sounds == 0 and glows == 0)



-- Benutzerdefinierte Health-Texte: Aktivierung, Mischen, Textverwaltung und
-- Vorschau/Reminder teilen sich denselben Textgenerator.
local function TextArgs(cat)
    local group = ns.HealthOptions().args[cat].args
    local args = {customMessagesEnabled = group.customMessagesEnabled}
    for key, value in pairs(group.customTexts.args) do args[key] = value end
    return args
end
local drinkingTexts = TextArgs('drinking')
assert(drinkingTexts.customMessagesEnabled.type == 'toggle')
assert(drinkingTexts.mixWithDefault.hidden())
assert(not clock.db.profile.health.drinking.customMessages)
assert(type(clock:GetHealthReminderText('drinking')) == 'string')
-- Neuen Text ohne sofortige Profilspeicherung bearbeiten, erst Speichern legt ihn an.
drinkingTexts.new.func()
drinkingTexts = TextArgs('drinking')
drinkingTexts.newBox.args.message.set(nil, '  Zeit für einen Schluck Wasser!  ')
drinkingTexts.newBox.args.save.func()
local first = clock.db.profile.health.drinking.customMessages[1]
assert(first.id == 1 and first.text == 'Zeit für einen Schluck Wasser!' and first.enabled)
assert(not clock.db.profile.health.drinking.customMessagesEnabled)
-- Zweiter Text, mit stabilen IDs.
TextArgs('drinking').new.func()
drinkingTexts = TextArgs('drinking')
drinkingTexts.newBox.args.message.set(nil, 'Auf zum Krug!')
drinkingTexts.newBox.args.save.func()
assert(clock.db.profile.health.drinking.customMessages[2].id == 2)
assert(clock.db.profile.health.drinking.nextCustomMessageID == 3)
-- Eigene Texte einschalten: Nur Eigene ohne Mischen.
drinkingTexts = TextArgs('drinking')
drinkingTexts.customMessagesEnabled.set(nil, true)
assert(not TextArgs('drinking').mixWithDefault.hidden())
local originalRandom = math.random
math.random = function(max) return max end
assert(select(2, clock:GetHealthReminderText('drinking')) == 'Auf zum Krug!')
-- Einzelhaken deaktiviert den zweiten Text.
local row2
for key, val in pairs(TextArgs('drinking')) do
    if key:find('text_2_2_enabled', 1, true) then row2 = val end
end
assert(row2 ~= nil)
row2.set(nil, false)
assert(select(2, clock:GetHealthReminderText('drinking')) == 'Zeit für einen Schluck Wasser!')
-- Gemischte Auswahl: Quelle 1 gibt eigenem Text Vorrang.
TextArgs('drinking').mixWithDefault.set(nil, true)
math.random = function(max) return 1 end
assert(select(2, clock:GetHealthReminderText('drinking')) == first.text)
-- Quelle 2 liefert den eingebauten, lokalisierten Text.
math.random = function(max) return max end
local mixed = select(2, clock:GetHealthReminderText('drinking'))
assert(mixed ~= first.text and type(mixed) == 'string' and #mixed > 0)
math.random = originalRandom
-- Editor-Zahnrad mit urspruenglichem Alarmsymbol; explizites Speichern.
local editor, deletion
for key, val in pairs(TextArgs('drinking')) do
    if key:find('text_1_1_edit', 1, true) then editor = val end
    if key:find('text_1_1_delete', 1, true) then deletion = val end
end
assert(editor.image:find('edit_gear') and deletion.image:find('delete_bin'))
assert(type(deletion.confirm()) == 'string')
editor.func()
local mask
for key, val in pairs(TextArgs('drinking')) do
    if key:find('text_1_1_mask', 1, true) then mask = val end
end
assert(not mask.hidden())
mask.args.message.set(nil, '  Neues Wasser! ')
assert(first.text == 'Zeit für einen Schluck Wasser!')
mask.args.save.func()
assert(first.text == 'Neues Wasser!')
-- Einzeltext löschen ohne Wiedererscheinen durch Defaults.
deletion.func()
assert(#clock.db.profile.health.drinking.customMessages == 1)
assert(clock.db.profile.health.drinking.customMessages[1].id == 2)
-- Kein aktiver Text mehr: Sicherer Fallback trotz Nur-eigene-Texte.
assert(select(2, clock:GetHealthReminderText('drinking')) ~= '')
-- Der Hauptschalter deaktiviert die eigene Textquelle vollständig.
TextArgs('drinking').customMessagesEnabled.set(nil, false)
assert(TextArgs('drinking').mixWithDefault.hidden())
assert(select(2, clock:GetHealthReminderText('drinking')) ~= 'Neues Wasser!')
-- Kategorie-isolierte Daten (auch nach Add, Edit und Delete).
assert(not clock.db.profile.health.eyes.customMessages)
assert(not clock.db.profile.health.movement.customMessages)
print('Health custom texts: options, selectors, per-entry toggles, edit/delete: OK')

print('Health runtime: three categories, icons, priority +/-5min, combat, options: OK')
