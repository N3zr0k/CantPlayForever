-- Leuchtender Bildschirmrand bei Alarm (wie bei wenig Leben). Vier Farbverlauf-Streifen an den
-- Rändern von UIParent, ohne Bilddatei. Farbe, Art und Stärke kommen aus derselben
-- Leuchtzeile wie alle Glows ("FARBCODE, static|pulse|blink, [Sekunden,] Prozent").
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

local DEFAULT_SPEC = 'FF2619, pulse, 1, 30'
local EDGE_WIDTH, EDGE_HEIGHT = 0.12, 0.20 -- Anteil der Bildschirmbreite/-höhe

function Clock:GetScreenGlowSpec()
    local spec = self.db and self.db.profile.screenGlowSpec
    if spec and self:ParseGlowSpec(spec) then return spec end
    return DEFAULT_SPEC
end

-- Farbverlauf von a1 (Seite „min“: unten bzw. links) nach a2; Neu- und Altclient-Aufruf.
local function Gradient(tex, orientation, color, a1, a2)
    local r, g, b = color[1], color[2], color[3]
    if tex.SetGradient and _G.CreateColor then
        local ok = pcall(tex.SetGradient, tex, orientation,
            CreateColor(r, g, b, a1), CreateColor(r, g, b, a2))
        if ok then return end
    end
    if tex.SetGradientAlpha then
        tex:SetGradientAlpha(orientation, r, g, b, a1, r, g, b, a2)
    end
end

local function Create()
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata('FULLSCREEN')
    frame:EnableMouse(false)
    local function Strip()
        local tex = frame:CreateTexture(nil, 'BACKGROUND')
        tex:SetColorTexture(1, 1, 1, 1)
        tex:SetBlendMode('ADD')
        return tex
    end
    frame.top, frame.bottom, frame.left, frame.right = Strip(), Strip(), Strip(), Strip()
    frame:Hide()
    return frame
end

local function Layout(frame, color)
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local sideWidth, sideHeight = width * EDGE_WIDTH, height * EDGE_HEIGHT
    frame.top:ClearAllPoints()
    frame.top:SetPoint('TOPLEFT'); frame.top:SetPoint('TOPRIGHT'); frame.top:SetHeight(sideHeight)
    frame.bottom:ClearAllPoints()
    frame.bottom:SetPoint('BOTTOMLEFT'); frame.bottom:SetPoint('BOTTOMRIGHT'); frame.bottom:SetHeight(sideHeight)
    frame.left:ClearAllPoints()
    frame.left:SetPoint('TOPLEFT'); frame.left:SetPoint('BOTTOMLEFT'); frame.left:SetWidth(sideWidth)
    frame.right:ClearAllPoints()
    frame.right:SetPoint('TOPRIGHT'); frame.right:SetPoint('BOTTOMRIGHT'); frame.right:SetWidth(sideWidth)
    -- VERTICAL: min = unten, max = oben; HORIZONTAL: min = links, max = rechts.
    Gradient(frame.top, 'VERTICAL', color, 0, 1)
    Gradient(frame.bottom, 'VERTICAL', color, 1, 0)
    Gradient(frame.left, 'HORIZONTAL', color, 1, 0)
    Gradient(frame.right, 'HORIZONTAL', color, 0, 1)
end

function Clock:ShowScreenGlow()
    if not (self.db and self.db.profile.screenGlow) then return end
    -- In Instanzen und Schlachtfeldern (Dungeon, Raid, PvP) bleibt der Rand dunkel.
    if self.db.profile.screenGlowSkipInstances ~= false and type(_G.IsInInstance) == 'function' then
        local inInstance = _G.IsInInstance()
        if inInstance then return end
    end
    local style = self:ParseGlowSpec(self:GetScreenGlowSpec())
    if not style then return end
    -- Gleicher Takt wie der Alarm-Glow der Uhr: Art und Periode kommen vom Uhr-Glow,
    -- Farbe und Stärke bleiben die des Bildschirmrands. Beide rechnen mit GetTime(),
    -- pulsieren also in derselben Phase.
    local alert = self.glows and self.glows.alert
    if alert and alert.style.mode ~= 'static' and alert.style.period then
        style.mode, style.period = alert.style.mode, alert.style.period
    end
    if not self.screenGlow then self.screenGlow = Create() end
    local frame = self.screenGlow
    Layout(frame, style.color)
    if style.mode == 'static' then
        frame:SetScript('OnUpdate', nil)
        frame:SetAlpha(style.alpha)
    else
        frame:SetScript('OnUpdate', function(f)
            local now = (type(_G.GetTime) == 'function' and _G.GetTime()) or ns.Now()
            f:SetAlpha(Clock.GlowAlpha(style, now))
        end)
    end
    frame:Show()
end

function Clock:HideScreenGlow()
    local frame = self.screenGlow
    if frame then
        frame:SetScript('OnUpdate', nil)
        frame:Hide()
    end
end
