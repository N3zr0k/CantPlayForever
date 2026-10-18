-- Testbühne: vergrößerter Nachbau der Uhr (Schatten, Globus mit Maske, Ring mit Maske, Glow,
-- Symbole) auf dunklem Grund. Liest dieselben Werte (Clock.tune) wie die echte Uhr, die
-- Tuning-Änderungen wirken aber nur hier, bis "Auf Uhr anwenden" gedrückt wird.
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
if not (Clock and Clock.tune and _G.FrameDebugger) then return end
local T = Clock.tune

local MASK = 'Interface\\CharacterFrame\\TempPortraitAlphaMask'
local GLOBE = 'Interface\\TimeManager\\GlobeIcon'
local TONE = { 0.80, 0.55, 0.26 }
local BADGE_DEFS = {
    { key = 'alarm', icon = 'Interface\\Icons\\INV_Misc_Bell_01', xKey = 'ALARM_X', yKey = 'ALARM_Y', sKey = 'ALARM_SCALE' },
    { key = 'timer', icon = 'Interface\\Icons\\INV_Misc_PocketWatch_01', xKey = 'TIMER_X', yKey = 'TIMER_Y', sKey = 'TIMER_SCALE' },
}

local function NewMask(parent)
    local mask = parent:CreateMaskTexture()
    mask:SetTexture(MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    return mask
end

local function StageGlowAlpha(style, now)
    if style.mode == 'static' then return style.alpha end
    local phase = (now % style.period) / style.period
    if style.mode == 'blink' then return phase < 0.5 and style.alpha or 0 end
    return style.alpha * (0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)))
end

function Clock:BuildStage()
    local stage = CreateFrame('Frame', 'CPFTuneStage', UIParent)
    stage:SetSize(420, 420)
    stage:SetPoint('RIGHT', UIParent, 'RIGHT', -40, 0)
    stage:SetFrameStrata('DIALOG')
    stage:SetMovable(true)
    stage:EnableMouse(true)
    stage:RegisterForDrag('LeftButton')
    stage:SetScript('OnDragStart', stage.StartMoving)
    stage:SetScript('OnDragStop', stage.StopMovingOrSizing)
    local bg = stage:CreateTexture(nil, 'BACKGROUND', nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.13, 0.20, 1)
    local title = stage:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    title:SetPoint('TOPLEFT', 8, -6)
    title:SetText('Testbühne (Ziehen verschiebt)')

    -- Mittelkreuz als Orientierung
    stage.hline = stage:CreateTexture(nil, 'BACKGROUND', nil, -7)
    stage.hline:SetColorTexture(1, 1, 1, 0.12)
    stage.hline:SetSize(420, 1)
    stage.hline:SetPoint('CENTER')
    stage.vline = stage:CreateTexture(nil, 'BACKGROUND', nil, -7)
    stage.vline:SetColorTexture(1, 1, 1, 0.12)
    stage.vline:SetSize(1, 420)
    stage.vline:SetPoint('CENTER')

    local box = CreateFrame('Frame', nil, stage)
    box:SetPoint('CENTER')
    stage.box = box

    stage.shadow = box:CreateTexture(nil, 'BACKGROUND', nil, -6)
    stage.shadowMask = NewMask(box)
    stage.shadow:AddMaskTexture(stage.shadowMask)
    stage.globe = box:CreateTexture(nil, 'BACKGROUND', nil, -4)
    stage.globe:SetTexture(GLOBE)
    stage.globeMask = NewMask(box)
    stage.globe:AddMaskTexture(stage.globeMask)

    stage.glowFrame = CreateFrame('Frame', nil, box)
    stage.glowFrame:SetAllPoints(box)
    stage.glowTex = stage.glowFrame:CreateTexture(nil, 'OVERLAY')
    stage.glowTex:SetBlendMode('ADD')
    stage.glowTex:SetAllPoints(box)
    stage.glowFrame.layers = { stage.glowTex }
    stage.glowMask = NewMask(stage.glowFrame)
    stage.glowTex:AddMaskTexture(stage.glowMask)

    stage.ring = Clock:CreateRing(box, true)

    stage.badges = {}
    for _, def in ipairs(BADGE_DEFS) do
        local frame = CreateFrame('Frame', nil, box)
        local disc = frame:CreateTexture(nil, 'BACKGROUND')
        disc:SetColorTexture(0.03, 0.03, 0.05, 0.9)
        disc:SetAllPoints(frame)
        frame.mask = NewMask(frame)
        disc:AddMaskTexture(frame.mask)
        frame.icon = frame:CreateTexture(nil, 'ARTWORK')
        frame.icon:SetTexture(def.icon)
        frame.icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
        frame.icon:SetDesaturated(true)
        frame.icon:SetVertexColor(TONE[1], TONE[2], TONE[3], 1)
        frame.ring = Clock:CreateRing(frame, true)
        stage.badges[def.key] = frame
    end
    stage.textFrame = CreateFrame('Frame', nil, box)
    stage.textFrame:SetAllPoints(box)
    stage.time = stage.textFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    stage.time:SetTextColor(1, 1, 1, 1)
    stage.time:SetShadowColor(0, 0, 0, 1)
    stage.time:SetShadowOffset(1, -1)
    stage.cd = stage.textFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    stage.cd:SetTextColor(0.39, 0.79, 1.0, 1)
    stage.cd:SetShadowColor(0, 0, 0, 1)
    stage.cd:SetShadowOffset(1, -1)
    stage:Hide()
    self.stage = stage
    return stage
end

function Clock:SetStageGlow(spec)
    self.stageGlowSpec = spec
    self:RefreshStage()
end

function Clock:RefreshStage()
    local stage = self.stage
    if not stage or not stage:IsShown() then return end
    local Z = T.STAGE_ZOOM
    if not Z or Z < 1 then Z = 1 end
    local box = stage.box
    box:SetSize(64 * Z, 64 * Z)
    stage.hline:SetShown(T.STAGE_GRID ~= 0)
    stage.vline:SetShown(T.STAGE_GRID ~= 0)
    local base = box:GetFrameLevel()

    stage.shadow:SetColorTexture(0, 0, 0, T.SHADOW_ALPHA)
    stage.shadow:SetAllPoints(box)
    stage.shadowMask:SetSize(T.SHADOW_SIZE * Z, T.SHADOW_SIZE * Z)
    stage.shadowMask:ClearAllPoints()
    stage.shadowMask:SetPoint('CENTER', box, 'CENTER', T.GLOBE_MASK_DX * Z, (T.GLOBE_MASK_DY - 0.25 - T.SHADOW_DROP) * Z)

    stage.globe:SetSize(64 * Z, 64 * Z)
    stage.globe:ClearAllPoints()
    stage.globe:SetPoint('CENTER', box, 'CENTER')
    stage.globeMask:SetSize(T.GLOBE_MASK * Z, T.GLOBE_MASK * Z)
    stage.globeMask:ClearAllPoints()
    stage.globeMask:SetPoint('CENTER', box, 'CENTER', T.GLOBE_MASK_DX * Z, T.GLOBE_MASK_DY * Z)

    stage.glowFrame:SetFrameLevel(base + 1)
    stage.glowMask:SetSize(T.GLOW_DISC * Z, T.GLOW_DISC * Z)
    stage.glowMask:ClearAllPoints()
    stage.glowMask:SetPoint('CENTER', box, 'CENTER', T.GLOW_DX * Z, T.GLOW_DY * Z)
    local style = self.stageGlowSpec and self:ParseGlowSpec(self.stageGlowSpec)
    if style then
        stage.glowTex:SetColorTexture(style.color[1], style.color[2], style.color[3], 1)
        Clock:LayoutGlowShape(stage.glowFrame, box, Z, style)
        stage.glowFrame:SetScript('OnUpdate', function(f)
            f:SetAlpha(StageGlowAlpha(style, GetTime()))
        end)
        stage.glowFrame:Show()
    else
        stage.glowFrame:SetScript('OnUpdate', nil)
        stage.glowFrame:Hide()
    end

    stage.ring:SetFrameLevel(base + 2)
    Clock:LayoutRing(stage.ring, Z, box, 'TOPLEFT', (-T.RING_OFFSET + T.RING_X0) * Z, (T.RING_OFFSET - T.RING_Y0) * Z)

    for _, def in ipairs(BADGE_DEFS) do
        local frame = stage.badges[def.key]
        local S = Z * T[def.sKey]
        frame:SetFrameLevel(base + 4)
        frame:SetSize(T.BADGE_SIZE * S, T.BADGE_SIZE * S)
        frame:ClearAllPoints()
        frame:SetPoint('CENTER', box, 'CENTER', T[def.xKey] * Z, T[def.yKey] * Z)
        frame.mask:SetSize(T.BADGE_DISC * S, T.BADGE_DISC * S)
        frame.mask:ClearAllPoints()
        frame.mask:SetPoint('CENTER', frame, 'CENTER')
        frame.icon:SetSize(T.BADGE_ICON * S, T.BADGE_ICON * S)
        frame.icon:ClearAllPoints()
        frame.icon:SetPoint('CENTER', frame, 'CENTER')
        frame.icon:SetVertexColor(T.BADGE_R, T.BADGE_G, T.BADGE_B, 1)
        frame.ring:SetFrameLevel(frame:GetFrameLevel() + 1)
        frame.ring:SetShown(T.BADGE_RING ~= 0)
        local rs = T.BADGE_RING_SCALE * S
        Clock:LayoutRing(frame.ring, rs, frame, 'CENTER',
            -(T.RING_SIZE / 2 + T.RING_MASK_DX) * rs, (T.RING_SIZE / 2 - T.RING_MASK_DY) * rs)
        frame:SetShown(T.STAGE_BADGES ~= 0)
    end

    -- Uhrzeit und Timer-Zahl (Beispieltexte) über allem
    local textFrame = stage.textFrame
    textFrame:SetFrameLevel(base + 6)
    local showTimer = T.STAGE_TIMER ~= 0
    stage.time:SetText('11:19')
    stage.time:ClearAllPoints()
    stage.time:SetPoint('CENTER', box, 'CENTER', T.TEXT_X * Z, (showTimer and T.TEXT_Y_CD or T.TEXT_Y) * Z)
    Clock.ResizeClockFont(stage.time, 'GameFontHighlightLarge',
        (showTimer and T.TEXT_SIZE_CD or T.TEXT_SIZE) * Z, T.TEXT_MAXW * Z)
    stage.time:SetShown(T.STAGE_TEXT ~= 0)
    local sample = '25' .. Clock:CountdownSuffix('MIN')
    if T.STAGE_TIMER_SEC == 1 then sample = '42' .. Clock:CountdownSuffix('SEC')
    elseif T.STAGE_TIMER_SEC == 2 then sample = '1.08' .. Clock:CountdownSuffix('HRS') end
    stage.cd:SetText(sample)
    stage.cd:ClearAllPoints()
    stage.cd:SetPoint('CENTER', box, 'CENTER', T.CD_X * Z, T.CD_Y * Z)
    Clock.ResizeClockFont(stage.cd, 'GameFontHighlightLarge', T.CD_SIZE * Z, T.CD_MAXW * Z)
    stage.cd:SetShown(T.STAGE_TEXT ~= 0 and showTimer)
end

function Clock:ToggleStage(show)
    local stage = self.stage or self:BuildStage()
    if show == nil then show = not stage:IsShown() end
    stage:SetShown(show)
    self:RefreshStage()
end
