local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, T = ns.Clock, ns.T

-- Original-Uhrfenster (Blizzard_TimeManager): Globus 64x64 plus Bronzering aus dem
-- Portraitrahmen der ButtonFrameTemplate. Der Ring ist ein Atlas (95x95) mit Rahmenleisten
-- rechts und unten; vermessen an der Vorschau (/cpf ring) liegt der Ring im Bereich
-- x 3..66, y 6..69 des Atlas. Im Original sitzt die Atlas-Ecke 7 px links und oben vom Globus.
local GLOBE_TEXTURE = 'Interface\\TimeManager\\GlobeIcon'

ns.GLOBE_TEXTURE = GLOBE_TEXTURE

local RING_ATLAS = 'UI-Frame-PortraitMetal-CornerTopLeft'

ns.RING_ATLAS = RING_ATLAS

local RING_ATLAS_SIZE = 95

local function RingAtlasInfo()
    local api = _G.C_Texture
    if api and type(api.GetAtlasInfo) == 'function' then
        return api.GetAtlasInfo(RING_ATLAS)
    end
end

ns.RingAtlasInfo = RingAtlasInfo

-- Der Ring-Atlas wird in voller Größe in einen Rahmen gelegt, der nur den Ringbereich
-- zeigt (SetClipsChildren). Das vermeidet SetTexCoord auf Atlas-Texturen, dessen
-- Koordinaten je nach Client relativ zum Atlas gelten.
function Clock:CreateRing(parent, withMask)
    local clip = CreateFrame('Frame', nil, parent)
    clip:SetClipsChildren(true)
    local tex = clip:CreateTexture(nil, 'ARTWORK')
    tex:SetAtlas(RING_ATLAS, false)
    clip.tex = tex
    -- Kreisförmige Maske: schneidet die Rahmenleiste rechts und die Linie links unten
    -- ab, die im Atlas an den Ring anschließen.
    if withMask and type(clip.CreateMaskTexture) == 'function'
        and type(tex.AddMaskTexture) == 'function' then
        local mask = clip:CreateMaskTexture()
        mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask',
            'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        tex:AddMaskTexture(mask)
        clip.mask = mask
    end
    return clip
end

-- Größe und Atlas-Ausschnitt des Rings; Ausschnittecke liegt bei (x, y) relativ zu point.
function Clock:LayoutRing(clip, scale, relativeTo, point, x, y)
    clip:SetSize(T.RING_SIZE * scale, T.RING_SIZE * scale)
    clip:ClearAllPoints()
    clip:SetPoint('TOPLEFT', relativeTo, point, x, y)
    if clip.mask then
        clip.mask:SetSize(T.RING_MASK * scale, T.RING_MASK_H * scale)
        clip.mask:ClearAllPoints()
        clip.mask:SetPoint('CENTER', clip, 'CENTER', T.RING_MASK_DX * scale, T.RING_MASK_DY * scale)
    end
    clip.tex:SetSize(RING_ATLAS_SIZE * scale, RING_ATLAS_SIZE * scale)
    clip.tex:ClearAllPoints()
    clip.tex:SetPoint('TOPLEFT', clip, 'TOPLEFT', -T.RING_X0 * scale, T.RING_Y0 * scale)
end

-- Die Globus-Textur ist ein abgerundetes Quadrat; ihre dunklen Ecken ragen sonst
-- hinter dem Ring heraus. Eine Kreismaske beschneidet sie auf die Fläche unter dem Ring.
function Clock:ApplyGlobeMask(enabled, diameter)
    local face = self.clockFace
    if not (face and self.iconButton) then return end
    local canMask = type(self.iconButton.CreateMaskTexture) == 'function'
        and type(face.AddMaskTexture) == 'function'
    if not canMask then return end
    if enabled then
        if not self.globeMask then
            local mask = self.iconButton:CreateMaskTexture()
            mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask',
                'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
            self.globeMask = mask
        end
        local scale = diameter / 64
        self.globeMask:SetSize(T.GLOBE_MASK * scale, T.GLOBE_MASK * scale)
        self.globeMask:ClearAllPoints()
        self.globeMask:SetPoint('CENTER', self.iconButton, 'CENTER',
            T.GLOBE_MASK_DX * scale, T.GLOBE_MASK_DY * scale)
        if not self.globeMaskApplied then
            face:AddMaskTexture(self.globeMask)
            self.globeMaskApplied = true
        end
        -- Leichter schwarzer Schatten um den Ring, wie bei den Blizzard-Minimapsymbolen:
        -- eine weiche, kreisförmig maskierte schwarze Fläche hinter dem Ring.
        if not self.ringShadow then
            local shadow = self.iconButton:CreateTexture(nil, 'BACKGROUND', nil, -8)
            shadow:SetColorTexture(0, 0, 0, T.SHADOW_ALPHA)
            local smask = self.iconButton:CreateMaskTexture()
            smask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask',
                'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
            shadow:AddMaskTexture(smask)
            self.ringShadow, self.ringShadowMask = shadow, smask
        end
        self.ringShadow:SetAllPoints(self.iconButton)
        self.ringShadowMask:SetSize(T.SHADOW_SIZE * scale, T.SHADOW_SIZE * scale)
        self.ringShadowMask:ClearAllPoints()
        self.ringShadowMask:SetPoint('CENTER', self.iconButton, 'CENTER',
            T.GLOBE_MASK_DX * scale, (T.GLOBE_MASK_DY - 0.25 - T.SHADOW_DROP) * scale)
        self.ringShadow:Show()
    else
        if self.globeMask and self.globeMaskApplied then
            face:RemoveMaskTexture(self.globeMask)
            self.globeMaskApplied = false
        end
        if self.ringShadow then self.ringShadow:Hide() end
    end
end

function Clock:ApplyRing(diameter)
    local scale = diameter / 64
    if not self.clockRing then
        self.clockRing = self:CreateRing(self.iconButton, true)
    end
    local clip = self.clockRing
    clip:SetFrameLevel(self.iconButton:GetFrameLevel() + 2)
    self:LayoutRing(clip, scale, self.iconButton, 'TOPLEFT',
        (-T.RING_OFFSET + T.RING_X0) * scale, (T.RING_OFFSET - T.RING_Y0) * scale)
    clip:Show()
end

-- Öffentlich für externe Werkzeuge (z. B. Frame_Debugger).
Clock.GLOBE_TEXTURE = GLOBE_TEXTURE
Clock.RingAtlasInfo = RingAtlasInfo
Clock.RING_ATLAS = RING_ATLAS
