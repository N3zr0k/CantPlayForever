-- Rahmen-Diagnose und Ring-Vorschau für Can't play Forever (Entwicklung, nur im Repo).
--   /cpf frame        Texturen des Optionsfensters im Chat + 4-fach vergrößerte Ecke
--   /cpf probe ring   Ring-Atlas prüfen und Vorschau ein-/ausblenden
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
if not (Clock and Clock.RegisterModule and _G.FrameDebugger) then return end

-- Diagnose: zeigt den Ring-Atlas ungeschnitten (links) und den Globus (rechts)
-- auf dunklem Grund in Originalgröße. Erneut /cpf probe ring schließt die Vorschau.
function Clock:ToggleRingPreview()
    if self.ringPreview then
        self.ringPreview:SetShown(not self.ringPreview:IsShown())
        return
    end
    local f = CreateFrame('Frame', nil, UIParent)
    f:SetSize(480, 150)
    f:SetPoint('CENTER', UIParent, 'CENTER', 0, -150)
    f:SetFrameStrata('DIALOG')
    local bg = f:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.35, 1)
    -- 1) Atlas ungeschnitten, 2) Ring mit Maske (2x), 3) Ring ohne Maske (2x), 4) Globus
    local atlas = f:CreateTexture(nil, 'ARTWORK')
    atlas:SetPoint('LEFT', f, 'LEFT', 8, 0)
    atlas:SetAtlas(Clock.RING_ATLAS, true)
    local masked = self:CreateRing(f, true)
    self:LayoutRing(masked, 2, f, 'LEFT', 120, 64)
    local plain = self:CreateRing(f, false)
    self:LayoutRing(plain, 2, f, 'LEFT', 255, 64)
    local globe = f:CreateTexture(nil, 'ARTWORK')
    globe:SetSize(64, 64)
    globe:SetPoint('RIGHT', f, 'RIGHT', -12, 0)
    globe:SetTexture(Clock.GLOBE_TEXTURE)
    self.ringPreview = f
end


-- Rahmen-Diagnose: /cpf frame gibt die Texturen der
-- Fensterränder im Chat aus und zeigt die obere linke Ecke 4-fach vergrößert mit 8-px-Raster.
local CANDIDATE_ATLASES = {
    'UI-Frame-DiamondMetal-CornerTopLeft', 'UI-Frame-Metal-CornerTopLeft',
    'UI-Frame-Diamond-CornerTopLeft', 'UI-Frame-SimpleMetal-CornerTopLeft',
    'UI-Frame-PortraitMetal-CornerTopLeft',
}

local function Describe(region)
    local atlas = region.GetAtlas and region:GetAtlas()
    local texture = region.GetTexture and region:GetTexture()
    local w, h = region.GetSize and region:GetSize()
    return string.format('atlas=%s texture=%s size=%sx%s', tostring(atlas), tostring(texture),
        tostring(w and math.floor(w + 0.5)), tostring(h and math.floor(h + 0.5)))
end

function Clock:DumpOptionsFrame()
    local open = self.aceDialog.OpenFrames and self.aceDialog.OpenFrames.CantPlayForever
    if not (open and open.frame) then
        self:Print('Optionsfenster zuerst öffnen (/cpf), dann /cpf frame.')
        return
    end
    local frame = open.frame
    self:Print('Rahmen-Diagnose:')
    local nine = frame.NineSlice
    if nine then
        for _, key in ipairs({'TopLeftCorner', 'TopRightCorner', 'TopEdge', 'LeftEdge', 'BottomLeftCorner'}) do
            if nine[key] then self:Print('  NineSlice.' .. key .. ': ' .. Describe(nine[key])) end
        end
    else
        self:Print('  kein NineSlice am Fenster')
    end
    local n = 0
    for _, region in ipairs({frame:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == 'Texture' then
            n = n + 1
            if n <= 24 then self:Print(string.format('  Region %d: %s', n, Describe(region))) end
        end
    end
    local api = _G.C_Texture
    for _, name in ipairs(CANDIDATE_ATLASES) do
        local info = api and api.GetAtlasInfo and api.GetAtlasInfo(name)
        self:Print(string.format('  Atlas %s: %s', name,
            info and string.format('%sx%s', tostring(info.width), tostring(info.height)) or 'nicht vorhanden'))
    end
    -- Vorschau der Ecke
    local piece = nine and nine.TopLeftCorner
    local atlasName = piece and piece.GetAtlas and piece:GetAtlas()
    if not atlasName then
        for _, name in ipairs(CANDIDATE_ATLASES) do
            if api and api.GetAtlasInfo and api.GetAtlasInfo(name) then atlasName = name break end
        end
    end
    if not atlasName then return end
    if not self.cornerPreview then
        local f = CreateFrame('Frame', nil, UIParent)
        f:SetPoint('CENTER', UIParent, 'CENTER', 0, -200)
        f:SetFrameStrata('FULLSCREEN_DIALOG')
        local bg = f:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints()
        bg:SetColorTexture(0.12, 0.12, 0.2, 1)
        f.tex = f:CreateTexture(nil, 'ARTWORK')
        f.tex:SetPoint('TOPLEFT', f, 'TOPLEFT', 4, -4)
        f.lines = {}
        self.cornerPreview = f
    end
    local f = self.cornerPreview
    f.tex:SetAtlas(atlasName, true)
    local w, h = f.tex:GetSize()
    local zoom = 4
    f.tex:SetSize(w * zoom, h * zoom)
    f:SetSize(w * zoom + 8, h * zoom + 8)
    for i = 1, 2 do
        f.lines[i] = f.lines[i] or {}
    end
    for _, line in ipairs(f.lines[1]) do line:Hide() end
    for i, step in ipairs({8, 16, 24, 32, 40, 48, 56, 64}) do
        if step < math.max(w, h) then
            local v = f.lines[1][i] or f:CreateTexture(nil, 'OVERLAY')
            f.lines[1][i] = v
            v:SetColorTexture(1, 1, 0, 0.35)
            v:SetSize(1, h * zoom)
            v:ClearAllPoints()
            v:SetPoint('TOPLEFT', f.tex, 'TOPLEFT', step * zoom, 0)
            v:Show()
            local hz = f.lines[2][i] or f:CreateTexture(nil, 'OVERLAY')
            f.lines[2][i] = hz
            hz:SetColorTexture(1, 1, 0, 0.35)
            hz:SetSize(w * zoom, 1)
            hz:ClearAllPoints()
            hz:SetPoint('TOPLEFT', f.tex, 'TOPLEFT', 0, -step * zoom)
            hz:Show()
        end
    end
    f:Show()
    self:Print('Vorschau: ' .. tostring(atlasName) .. ' (gelbe Linien alle 8 Pixel). Erneut /cpf frame zum Aktualisieren, /reload zum Schließen.')
end
