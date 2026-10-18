local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, T = ns.Clock, ns.T

-- Kleine Statussymbole oben links am Ring (im Stil des Tag/Nacht-Symbols, nur kleiner):
-- Glocke = mindestens ein Wecker scharf, Sanduhr = Timer läuft. Unauffällig im Rington.
local BADGE_TONE = {0.80, 0.55, 0.26}

local PREVIEW_HOLIDAY_ICON = 235462 -- Beispielsymbol (Schlotternaechte) fuer die Vorschau im Frame Debugger

local BADGES = {
    { key = 'alarm', icon = 'Interface\\Icons\\INV_Misc_Bell_01',     xKey = 'ALARM_X', yKey = 'ALARM_Y', sKey = 'ALARM_SCALE' },
    { key = 'timer', icon = 'Interface\\Icons\\INV_Misc_PocketWatch_01', xKey = 'TIMER_X', yKey = 'TIMER_Y', sKey = 'TIMER_SCALE' },
    { key = 'holiday', xKey = 'HOLIDAY_X', yKey = 'HOLIDAY_Y', sKey = 'HOLIDAY_SCALE' },
}

-- Timer- und Alarm-Symbol: fertige Bilder (Media/Badges/timer_icon.tga, alarm_icon.tga) im
-- Standardrahmen der Bibliothek (MiniMap-TrackingBorder, Maße wie bei LibDBIcon), Rahmenfarbe
-- über BADGE_FRAME_R/G/B/DESAT an den Uhrrahmen angepasst.
local BADGE_ICONS = {
    timer = 'Interface\\AddOns\\CantPlayForever\\Media\\Badges\\timer_icon',
    alarm = 'Interface\\AddOns\\CantPlayForever\\Media\\Badges\\alarm_icon',
    holiday = 'Interface\\Icons\\INV_Misc_QuestionMark', -- wird mit dem Symbol des Festes ersetzt
}
local LIB_BORDER = 136430 -- Interface\Minimap\MiniMap-TrackingBorder

function Clock:CreateTimerBadge(key, parent)
    local frame = CreateFrame('Frame', nil, parent or self.iconButton)
    frame.timerStyle = true
    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetTexture(BADGE_ICONS[key])
    frame.icon = icon
    local border = frame:CreateTexture(nil, 'OVERLAY')
    border:SetTexture(LIB_BORDER)
    frame.border = border
    if key == 'holiday' then
        -- Runde Maske: manche Fest-Symbole sind eckig
        if type(frame.CreateMaskTexture) == 'function' and type(icon.AddMaskTexture) == 'function' then
            local mask = frame:CreateMaskTexture()
            mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
            frame.roundMask = mask
        end
        frame:EnableMouse(true)
        frame:SetScript('OnEnter', function(badge)
            if not _G.GameTooltip then return end
            GameTooltip:SetOwner(badge, 'ANCHOR_BOTTOMLEFT')
            Clock:AddCalendarLines(GameTooltip, 'badge')
            GameTooltip:Show()
        end)
        frame:SetScript('OnLeave', function() if _G.GameTooltip then GameTooltip:Hide() end end)
    end
    frame:Hide()
    return frame
end

-- anchor: Bezugsframe (Standard: Minimap-Knopf; die Testbühne des Frame Debuggers uebergibt ihre Box)
function Clock:LayoutTimerBadge(frame, spec, scale, anchor)
    anchor = anchor or self.iconButton
    -- Maße der Bibliothek: Knopf 31, Rahmen 53 oben links, Symbol 17/20 bei (7|-6)/(7|-5).
    local f = T.BADGE_SIZE * scale * T[spec.sKey] / 31
    frame:SetFrameLevel(anchor:GetFrameLevel() + 4)
    frame:ClearAllPoints()
    frame:SetPoint('CENTER', anchor, 'CENTER', T[spec.xKey] * scale, T[spec.yKey] * scale)
    frame:SetSize(31 * f, 31 * f)
    -- Symbol und Rahmen einzeln einstellbar (TIMER_/ALARM_ICON_SIZE und _FRAME_SIZE, Bibliothekseinheiten)
    local prefix = (spec.key == 'timer' and 'TIMER_') or (spec.key == 'holiday' and 'HOLIDAY_') or 'ALARM_'
    -- Fest-Symbol: Werte je Symbol (frame.styleIcon), sonst allgemein
    local function value(key)
        if spec.key == 'holiday' then return self:HolidayValue(frame.styleIcon, key) end
        return T[key]
    end
    local iconSize, frameSize = value(prefix .. 'ICON_SIZE') * f, T[prefix .. 'FRAME_SIZE'] * f
    local k = frameSize / (53 * f) -- Rahmen-Skalierung gegenüber den Maßen der Bibliothek
    frame.icon:SetSize(iconSize, iconSize)
    frame.icon:ClearAllPoints()
    -- Bildposition im Rahmen (nur Fest-Symbol einstellbar, sonst 0)
    frame.icon:SetPoint('CENTER', frame, 'CENTER', (value(prefix .. 'ICON_X') or 0) * f, (value(prefix .. 'ICON_Y') or 0) * f)
    local mask = frame.roundMask
    if mask and type(frame.icon.AddMaskTexture) == 'function' then
        -- Kreis fester Groesse um das Bild: alles ausserhalb ist weg (kleiner als die Rahmenoeffnung waehlen)
        local maskSize = value('HOLIDAY_MASK_SIZE') * f
        mask:ClearAllPoints()
        mask:SetPoint('CENTER', frame.icon, 'CENTER', 0, 0)
        mask:SetSize(maskSize, maskSize)
        local round = T.HOLIDAY_ICON_ROUND == 1 and maskSize > 0 -- Kreisgroesse 0 = nicht beschneiden
        if round and not frame.roundApplied then
            frame.icon:AddMaskTexture(mask); frame.roundApplied = true
        elseif not round and frame.roundApplied then
            frame.icon:RemoveMaskTexture(mask); frame.roundApplied = nil
        end
    end
    frame.border:SetSize(frameSize, frameSize)
    frame.border:ClearAllPoints()
    frame.border:SetPoint('TOPLEFT', frame, 'CENTER', -15.5 * f * k, 14.5 * f * k)
    -- Symbolfarbe je Symbol (TIMER_ICON_* bzw. ALARM_ICON_*; 1/1/1 = Originalfarbe)
    prefix = prefix .. 'ICON_'
    if spec.key == 'alarm' and self:CountArmedAlarms() > 0 then
        -- Wecker aktiviert: grünlich; nur konfiguriert: normale Symbolfarbe
        frame.icon:SetDesaturated(false)
        frame.icon:SetVertexColor(T.ALARM_ARMED_R, T.ALARM_ARMED_G, T.ALARM_ARMED_B, 1)
    else
        frame.icon:SetDesaturated(T[prefix .. 'DESAT'] == 1)
        frame.icon:SetVertexColor(T[prefix .. 'R'], T[prefix .. 'G'], T[prefix .. 'B'], 1)
    end
    frame.border:SetDesaturated(T.BADGE_FRAME_DESAT == 1)
    frame.border:SetVertexColor(T.BADGE_FRAME_R, T.BADGE_FRAME_G, T.BADGE_FRAME_B, 1)
end

function Clock:CreateBadge(spec)
    if BADGE_ICONS[spec.key] then return self:CreateTimerBadge(spec.key) end
    local frame = CreateFrame('Frame', nil, self.iconButton)
    local disc = frame:CreateTexture(nil, 'BACKGROUND')
    disc:SetColorTexture(0.03, 0.03, 0.05, 0.9)
    disc:SetAllPoints(frame)
    if type(frame.CreateMaskTexture) == 'function' and type(disc.AddMaskTexture) == 'function' then
        local mask = frame:CreateMaskTexture()
        mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask',
            'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        disc:AddMaskTexture(mask)
        frame.mask = mask
    end
    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetTexture(spec.icon)
    icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    icon:SetDesaturated(true)
    icon:SetVertexColor(BADGE_TONE[1], BADGE_TONE[2], BADGE_TONE[3], 1)
    frame.icon = icon
    frame.ring = self:CreateRing(frame, true)
    frame:Hide()
    return frame
end

function Clock:LayoutBadge(frame, spec, scale)
    if frame.timerStyle then return self:LayoutTimerBadge(frame, spec, scale) end
    frame:SetFrameLevel(self.iconButton:GetFrameLevel() + 4)
    frame:ClearAllPoints()
    frame:SetPoint('CENTER', self.iconButton, 'CENTER', T[spec.xKey] * scale, T[spec.yKey] * scale)
    scale = scale * T[spec.sKey]
    frame:SetSize(T.BADGE_SIZE * scale, T.BADGE_SIZE * scale)
    if frame.mask then
        frame.mask:SetSize(T.BADGE_DISC * scale, T.BADGE_DISC * scale)
        frame.mask:ClearAllPoints()
        frame.mask:SetPoint('CENTER', frame, 'CENTER')
    end
    frame.icon:SetSize(T.BADGE_ICON * scale, T.BADGE_ICON * scale)
    frame.icon:ClearAllPoints()
    frame.icon:SetPoint('CENTER', frame, 'CENTER')
    frame.icon:SetVertexColor(T.BADGE_R, T.BADGE_G, T.BADGE_B, 1)
    frame.ring:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.ring:SetShown(T.BADGE_RING ~= 0)
    local ringScale = T.BADGE_RING_SCALE * scale
    -- Ringmitte liegt im Ausschnitt bei (34,9 / 31,85) von links oben.
    self:LayoutRing(frame.ring, ringScale, frame, 'CENTER',
        -(T.RING_SIZE / 2 + T.RING_MASK_DX) * ringScale, (T.RING_SIZE / 2 - T.RING_MASK_DY) * ringScale)
end

-- Dekoration (Overlay) um die Uhr waehrend eines Festes: Ebene ueber der Uhr, unter den Symbolen.
function Clock:CreateHolidayOverlay(parent)
    local frame = CreateFrame('Frame', nil, parent or self.iconButton)
    frame.tex = frame:CreateTexture(nil, 'ARTWORK')
    frame.tex:SetAllPoints(frame)
    frame:EnableMouse(false)
    frame:Hide()
    return frame
end

function Clock:LayoutHolidayOverlay(frame, icon, scale, anchor)
    anchor = anchor or self.iconButton
    frame:SetFrameLevel(anchor:GetFrameLevel() + 3)
    frame:ClearAllPoints()
    frame:SetPoint('CENTER', anchor, 'CENTER', self:HolidayValue(icon, 'HOLIDAY_OVERLAY_X') * scale,
        self:HolidayValue(icon, 'HOLIDAY_OVERLAY_Y') * scale)
    local size = self:HolidayValue(icon, 'HOLIDAY_OVERLAY_SIZE') * scale
    frame:SetSize(size, size)
    frame.tex:SetTexture(ns.HOLIDAY_OVERLAYS and ns.HOLIDAY_OVERLAYS[icon])
    frame:SetAlpha(self:HolidayValue(icon, 'HOLIDAY_OVERLAY_ALPHA'))
end

-- Layout nur bei geaenderter Groesse oder Scharf-Zustand neu berechnen: die
-- Eingaben (Durchmesser, Wecker scharf) aendern sich selten, der Tick laeuft jede Sekunde.
function Clock:UpdateBadges()
    local button = self.iconButton
    if not button then return end
    local diameter = self:GetClockDiameter()
    local big = diameter > ns.SMALL_DIAMETER
    local profile = self.db.profile
    -- Symbol sobald mindestens ein Wecker angelegt ist; grünlich, wenn einer aktiviert ist.
    local alarm = big and self:IsModuleEnabled('alarms') and #profile.alarms > 0
    local timer = big and self:IsModuleEnabled('timer') and profile.activeTimer ~= nil
    -- Fest-Symbol: Symbol des ersten heute laufenden Festes aus dem Kalender.
    local holidayIcon = self.holidayPreview and (self.holidayPreviewIcon or PREVIEW_HOLIDAY_ICON) or self:GetBadgeIcon()
    local holiday = big and holidayIcon ~= nil
    local overlayIcon = big and (self.holidayPreview and (self.holidayPreviewIcon or PREVIEW_HOLIDAY_ICON) or self:GetOverlayIcon()) or nil
    if overlayIcon and not (ns.HOLIDAY_OVERLAYS and ns.HOLIDAY_OVERLAYS[overlayIcon]) then overlayIcon = nil end
    if overlayIcon then
        local overlay = self.holidayOverlay
        if not overlay then overlay = self:CreateHolidayOverlay(); self.holidayOverlay = overlay end
        if overlay.cpfDiameter ~= diameter or overlay.cpfIcon ~= overlayIcon then
            overlay.cpfDiameter, overlay.cpfIcon = diameter, overlayIcon
            self:LayoutHolidayOverlay(overlay, overlayIcon, diameter / 64)
        end
        if not overlay:IsShown() then overlay:Show() end
    elseif self.holidayOverlay and self.holidayOverlay:IsShown() then
        self.holidayOverlay:Hide()
    end
    self.badges = self.badges or {}
    for _, spec in ipairs(BADGES) do
        local frame = self.badges[spec.key]
        if (spec.key == 'alarm' and alarm) or (spec.key == 'timer' and timer)
            or (spec.key == 'holiday' and holiday) then
            if not frame then
                frame = self:CreateBadge(spec)
                self.badges[spec.key] = frame
            end
            local armed = spec.key == 'alarm' and self:CountArmedAlarms() > 0
            local iconKey = spec.key == 'holiday' and holidayIcon or nil
            if frame.cpfDiameter ~= diameter or frame.cpfArmed ~= armed or frame.cpfHolidayIcon ~= iconKey then
                frame.cpfDiameter, frame.cpfArmed, frame.cpfHolidayIcon = diameter, armed, iconKey
                if iconKey then
                    frame.styleIcon = iconKey
                    frame.icon:SetTexture(self:IconTexture(iconKey))
                    frame.icon:SetTexCoord(self:HolidayTexCoord(iconKey))
                end
                self:LayoutBadge(frame, spec, diameter / 64)
            end
            if not frame:IsShown() then frame:Show() end
        elseif frame and frame:IsShown() then
            frame:Hide()
        end
    end
end
