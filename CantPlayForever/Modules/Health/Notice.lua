-- Gemeinsamer Health-Hinweis mit fraktionsspezifischen, transparenten TGA-Motiven.
-- Text, Icon und Effektfarbe werden pro Kategorie konfiguriert.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock
local MEDIA = 'Interface\\AddOns\\CantPlayForever\\Media\\Health\\'
local CATEGORY_ICONS = {
    movement = { Alliance = MEDIA .. 'movement_alliance', Horde = MEDIA .. 'movement_horde' },
    drinking = { Alliance = MEDIA .. 'drink_alliance', Horde = MEDIA .. 'drink_horde' },
    eyes = { Alliance = MEDIA .. 'eye_alliance', Horde = MEDIA .. 'eye_horde' },
}
-- Eigene transparente Health-Testwappen, entsprechend der Spielerfraktion.
-- Kategorie-Erinnerungen verwenden weiterhin ihre eigenen Hintergrund-Icons.
local FACTION_ICONS = {
    Alliance = MEDIA .. 'faction_alliance',
    Horde = MEDIA .. 'faction_horde',
}
local ICON_SIZE = 200
local DEFAULT_ICON_OFFSET_Y = 65

function Clock:GetHealthNoticeIcon(category)
    local faction = type(_G.UnitFactionGroup) == 'function' and _G.UnitFactionGroup('player') or 'Alliance'
    if faction ~= 'Horde' then faction = 'Alliance' end
    local icons = CATEGORY_ICONS[category]
    if not icons then return FACTION_ICONS[faction] end -- allgemeine Vorschau
    return icons[faction] or icons.Alliance
end

local function EnsureNotice(self)
    if self.healthNotice then return end
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetSize(800, 220)
    frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    frame:SetFrameStrata('HIGH')

    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    -- Aus PNG erzeugte TGAs besitzen transparenten Rand; kein Icon-Ausschnitt.
    icon:SetTexCoord(0, 1, 0, 1)

    local label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    label:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    label:SetWidth(760)
    label:SetJustifyH('CENTER')
    -- Wie der WoW-Zonenwechsel: dicke dunkle Kontur plus Schlagschatten.
    local fontPath = _G.STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF'
    label:SetFont(fontPath, 24, 'THICKOUTLINE')
    label:SetShadowColor(0, 0, 0, 1)
    label:SetShadowOffset(2, -2)
    frame:Hide()
    self.healthNotice = frame
    self.healthNoticeIcon = icon
    self.healthNoticeLabel = label
end

function Clock:ShowHealthNotice(category, title, message)
    if self:IsHealthRestricted() then
        self:HideHealthNotice()
        return
    end
    EnsureNotice(self)
    -- Eine reguläre Meldung übersteuert eine laufende Vorschau und schützt
    -- sie vor deren verzögertem Ausblenden.
    self.healthNoticePreviewActive = false
    local iconEnabled = self:GetHealthIconSetting(category, 'iconEnabled') ~= false
    local iconOffsetY = tonumber(self:GetHealthIconSetting(category, 'iconOffsetY')) or DEFAULT_ICON_OFFSET_Y
    self.healthNoticeIcon:ClearAllPoints()
    self.healthNoticeIcon:SetPoint('CENTER', self.healthNotice, 'CENTER', 0, iconOffsetY)
    if iconEnabled then
        local transparency = tonumber(self:GetHealthIconSetting(category, 'iconTransparency')) or 65
        transparency = math.max(0, math.min(100, transparency))
        self.healthNoticeIcon:SetTexture(self:GetHealthNoticeIcon(category))
        self.healthNoticeIcon:SetAlpha(1 - transparency / 100)
        self.healthNoticeIcon:Show()
    else
        self.healthNoticeIcon:Hide()
    end
    local effect = self:GetHealthEffectOverride(category)
    local style = self:GetEffectStyle('health', effect)
    local color = style and style.color or {1, 1, 1}
    self.healthNoticeLabel:SetTextColor(color[1], color[2], color[3], 1)
    self.healthNoticeLabel:SetText(tostring(title or '') .. '\n' .. tostring(message or ''))
    self.healthNotice:Show()
end

-- Vorschau mit derselben Schrift, Icon-Transparenz, Position und Effektfarbe
-- wie eine echte Health-Erinnerung, inklusive Hinweiston (immer). Keine Chatnachricht und keine
-- Veraenderung von Sessionzeit, Prioritaeten oder Wiederholungsintervallen.
function Clock:PreviewHealthEffect(category)
    if self:IsHealthRestricted() then return end
    -- Auch bei ausgeschaltetem Health-Modul kann der Test geöffnet werden.
    -- Der vorhandene Event-Monitor beendet Vorschauen beim Kampfbeginn;
    -- dafür ist kein zusätzlicher Ticker erforderlich.
    if self.StartHealthSafetyMonitor then self:StartHealthSafetyMonitor() end
    local title, message
    local override
    if CATEGORY_ICONS[category] then
        if type(self.GetHealthReminderText) ~= 'function' then return end
        title, message = self:GetHealthReminderText(category)
        override = self:GetHealthEffectOverride(category)
    else
        category = nil -- allgemeine Health-Vorschau mit Fraktionswappen
        local L = ns.L
        title, message = L.HEALTH_PREVIEW_TITLE, L.HEALTH_PREVIEW_MESSAGE
    end
    self.healthNoticePreviewToken = (self.healthNoticePreviewToken or 0) + 1
    local token = self.healthNoticePreviewToken
    self:ShowHealthNotice(category, title, message)
    self.healthNoticePreviewActive = true
    self:PreviewScreenGlow('health', override)
    self:PlayHealthSound(true)
    -- Der Glow hat seinen eigenen Token/Timeout. Nur die eigene Vorschau
    -- verbergen: echte, zwischenzeitlich gestartete Meldungen bleiben stehen.
    if _G.C_Timer and type(_G.C_Timer.After) == 'function' then
        _G.C_Timer.After(9, function()
            if self.healthNoticePreviewActive and self.healthNoticePreviewToken == token then
                self.healthNoticePreviewActive = false
                if self.healthNotice then self.healthNotice:Hide() end
            end
        end)
    end
end

function Clock:HideHealthNotice()
    self.healthNoticePreviewActive = false
    if self.healthNotice then self.healthNotice:Hide() end
    self.healthNoticeUntil = nil
    self.healthGlowUntil = nil
    self.healthVisualUntil = nil
    if self.activeScreenGlowSource == 'health' and self.HideScreenGlow then
        self:HideScreenGlow()
    end
end
