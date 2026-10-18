local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, T, Now = ns.Clock, ns.T, ns.Now

-- Verdeckt die Uhr ein anderes sichtbares Minimap-Element (Button, Symbol), leuchtet der
-- innere Kreis (Textur des Mouseover-Highlights) dauerhaft gelb.
local COVER_HIGHLIGHT = 136477 -- Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight

local function ScaledRect(frame)
    local left, bottom, width, height = frame:GetRect()
    local scale = frame:GetEffectiveScale()
    if not left or not scale then return end
    return left * scale, bottom * scale, (left + width) * scale, (bottom + height) * scale
end

local function IsMinimapSymbol(name, parent)
    if parent ~= _G.Minimap then return true end
    return name:find('^LibDBIcon') ~= nil or name:find('^MiniMap') ~= nil or name:find('^Minimap') ~= nil
end

-- Kinderlisten der Minimap-Container werden nur neu gelesen, wenn sich deren
-- Anzahl aendert (GetChildren legt bei jedem Aufruf eine neue Tabelle an).
-- Der Symbol-Test haengt nur vom (festen) Frame-Namen ab und wird je Frame gemerkt.
local childLists = {}
local symbolCache = setmetatable({}, {__mode = 'k'})

local function ChildrenOf(parent)
    local count = parent.GetNumChildren and parent:GetNumChildren()
    local entry = childLists[parent]
    if not entry or entry.count ~= count then
        entry = {count = count, parent:GetChildren()}
        childLists[parent] = entry
    end
    return entry
end

local function CoverCandidate(self, child, parent, button)
    if child == button or child == self.clockRing then return false end
    local symbol = symbolCache[child]
    if symbol == nil then
        local name = child.GetName and child:GetName()
        -- Kartenmarkierungen (z. B. GatherMate-Pins) und unbenannte Hilfsframes zaehlen nicht.
        symbol = (name and IsMinimapSymbol(name, parent)) and true or false
        symbolCache[child] = symbol
    end
    return symbol
end

function Clock:IsCoveringSomething()
    local button = self.iconButton
    if not (button and button:IsShown()) then return false end
    local l1, b1, r1, t1 = ScaledRect(button)
    if not l1 then return false end
    local limit = (r1 - l1) * 1.2
    for index = 1, 2 do
        local parent = index == 1 and _G.Minimap or _G.MinimapCluster
        if parent and parent.GetChildren then
            local children = ChildrenOf(parent)
            for i = 1, #children do
                local child = children[i]
                -- Nur Minimap-Symbole zählen: Knöpfe (LibDBIcon, Blizzard) und Frames der Minimap-Leiste.
                if CoverCandidate(self, child, parent, button) and child:IsShown()
                    and child:GetAlpha() > 0.1 and child.GetRect then
                    local l2, b2, r2, t2 = ScaledRect(child)
                    -- Nur kleine, klickbare Elemente zählen (keine Karte, keine Zonenleiste).
                    if l2 and (r2 - l2) <= limit and (t2 - b2) <= limit
                        and (child.IsMouseEnabled and child:IsMouseEnabled()) then
                        local overlapW = math.min(r1, r2) - math.max(l1, l2)
                        local overlapH = math.min(t1, t2) - math.max(b1, b2)
                        if overlapW > 4 and overlapH > 4 then return true, child:GetName() end
                    end
                end
            end
        end
    end
    return false
end

-- Wandelt eine Leuchtzeile in {color={r,g,b}, mode, period, alpha} um (nil bei Fehlern).
function Clock:ParseGlowSpec(spec)
    local parts = {}
    for part in tostring(spec or ''):gmatch('[^,]+') do
        parts[#parts + 1] = part:match('^%s*(.-)%s*$')
    end
    local hex = ((parts[1] or ''):gsub('^#', ''))
    if #hex ~= 6 or not hex:match('^%x+$') then return nil end
    local mode = (parts[2] or ''):lower()
    local style = {
        color = {
            tonumber(hex:sub(1, 2), 16) / 255,
            tonumber(hex:sub(3, 4), 16) / 255,
            tonumber(hex:sub(5, 6), 16) / 255,
        },
        mode = mode,
    }
    local percent
    if mode == 'static' then
        percent = tonumber((((parts[3] or ''):gsub('%%', ''))))
    elseif mode == 'pulse' or mode == 'blink' then
        style.period = tonumber(parts[3])
        percent = tonumber((((parts[4] or ''):gsub('%%', ''))))
        if not style.period or style.period <= 0 then return nil end
    else
        return nil
    end
    if not percent then return nil end
    style.alpha = math.max(0, math.min(100, percent)) / 100
    -- Optionale Zusätze: ring | fill | both (Form) und z. B. 95px (Ringgröße)
    local first = (mode == 'static') and 4 or 5
    for index = first, #parts do
        local token = parts[index]:lower()
        if token == 'fill' then style.shape = 0
        elseif token == 'ring' then style.shape = 1
        elseif token == 'both' then style.shape = 2
        elseif token == 'native' then style.native = true -- Ring in den Originalfarben der Mouseover-Textur
        else
            local size = tonumber((token:gsub('px$', '')))
            if size and size > 0 then style.size = size end
        end
    end
    return style
end

function Clock:SetGlow(key, spec, priority)
    self.glows = self.glows or {}
    local entry = self.glows[key]
    if entry and entry.spec == spec and entry.priority == (priority or 0) then return true end
    local style = self:ParseGlowSpec(spec)
    if not style then return false end
    self.glows[key] = { spec = spec, style = style, priority = priority or 0 }
    self:Debug('Glow an: %s (%s)', key, spec)
    self:RefreshGlow()
    return true
end

function Clock:ClearGlow(key)
    if self.glows and self.glows[key] then
        self.glows[key] = nil
        self:Debug('Glow aus: %s', key)
        self:RefreshGlow()
    end
end

local function GlowAlpha(style, now)
    if style.mode == 'static' then return style.alpha end
    local phase = (now % style.period) / style.period
    if style.mode == 'blink' then
        return phase < 0.5 and style.alpha or 0
    end
    -- pulse: weiche Sinuskurve zwischen 25 % und 100 % der Deckkraft
    return style.alpha * (0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)))
end

-- Leuchtform: gefüllte Fläche (Maske) und/oder Ring (Mouseover-Textur, eingefärbt).
-- Gemeinsam genutzt von der Uhr und der Testbühne; frame.layers enthält die Flächentextur.
function Clock:LayoutGlowShape(frame, anchor, scale, style)
    local shape = style.shape or T.GLOW_SHAPE
    for _, layer in ipairs(frame.layers) do layer:SetShown(shape ~= 1) end
    if shape == 0 then
        if frame.ringTex then frame.ringTex:Hide() end
        return
    end
    if not frame.ringTex then
        local tex = frame:CreateTexture(nil, 'OVERLAY', nil, 1)
        tex:SetTexture(COVER_HIGHLIGHT)
        tex:SetBlendMode('ADD')
        tex:SetDesaturated(true)
        frame.ringTex = tex
    end
    local tex = frame.ringTex
    if style.native then
        tex:SetDesaturated(false)
        tex:SetVertexColor(1, 1, 1, 1)
    else
        tex:SetDesaturated(true)
        tex:SetVertexColor(style.color[1], style.color[2], style.color[3], 1)
    end
    local ringSize = style.size or T.GLOW_RING_SIZE
    tex:SetSize(ringSize * scale, ringSize * scale)
    tex:ClearAllPoints()
    tex:SetPoint('CENTER', anchor, 'CENTER', T.GLOW_RING_DX * scale, T.GLOW_RING_DY * scale)
    tex:Show()
end

function Clock:CreateGlowFrame()
    local button = self.iconButton
    local frame = CreateFrame('Frame', nil, button)
    frame:SetAllPoints(button)
    frame.layers = {}
    -- Einfarbige, additive Fläche (Farbe kommt aus der Leuchtzeile). Die Mouseover-Textur des
    -- Buttons ist bläulich und verfälschte die Farben, deshalb wird sie hier nicht benutzt.
    local glow = frame:CreateTexture(nil, 'OVERLAY')
    glow:SetColorTexture(1, 1, 1, 1)
    glow:SetBlendMode('ADD')
    glow:SetAllPoints(frame)
    frame.layers[1] = glow
    -- Kreismaske: das Leuchten bleibt innerhalb des Rings (Innenfläche).
    if type(frame.CreateMaskTexture) == 'function' then
        local mask = frame:CreateMaskTexture()
        mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask',
            'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        glow:AddMaskTexture(mask)
        frame.mask = mask
    end
    frame:Hide()
    return frame
end

function Clock:RefreshGlow()
    local button = self.iconButton
    if not button or not self.db then return end
    local best
    -- Auch die kleine Uhr leuchtet (Alarm, letzte Timer-Sekunden); der Glow liegt
    -- unter der Analoguhr, die Zeiger bleiben sichtbar.
    for _, entry in pairs(self.glows or {}) do
        if not best or entry.priority > best.priority then best = entry end
    end
    if not best then
        if self.glowFrame then
            self.glowFrame:SetScript('OnUpdate', nil)
            self.glowFrame:Hide()
            self.glowEntry = nil
        end
        return
    end
    if not self.glowFrame then self.glowFrame = self:CreateGlowFrame() end
    local frame = self.glowFrame
    frame:SetFrameLevel(button:GetFrameLevel() + 1)
    if frame.mask then
        local scale = self:GetClockDiameter() / 64
        frame.mask:SetSize(T.GLOW_DISC * scale, T.GLOW_DISC * scale)
        frame.mask:ClearAllPoints()
        frame.mask:SetPoint('CENTER', button, 'CENTER', T.GLOW_DX * scale, T.GLOW_DY * scale)
    end
    self:LayoutGlowShape(frame, button, self:GetClockDiameter() / 64, best.style)
    if self.glowEntry ~= best then
        self.glowEntry = best
        local style = best.style
        for _, layer in ipairs(frame.layers) do
            layer:SetColorTexture(style.color[1], style.color[2], style.color[3], 1)
        end
        if style.mode == 'static' then
            frame:SetScript('OnUpdate', nil)
            frame:SetAlpha(style.alpha)
        else
            frame:SetScript('OnUpdate', function(f)
                local now = (type(_G.GetTime) == 'function' and _G.GetTime()) or Now()
                f:SetAlpha(GlowAlpha(style, now))
            end)
        end
    end
    frame:Show()
end

function Clock:UpdateCoverGlow()
    local covering, name = false, nil
    if self:GetClockDiameter() > ns.SMALL_DIAMETER then covering, name = self:IsCoveringSomething() end
    if covering then
        if self.coverName ~= name then
            self.coverName = name
            self:Debug('Uhr überdeckt: %s', tostring(name))
        end
        self:SetGlow('cover', 'FF2619, static, 80, fill', 20)
    else
        self.coverName = nil
        self:ClearGlow('cover')
    end
end

-- Öffentlich für andere Module (Bildschirmrand-Leuchten).
Clock.GlowAlpha = GlowAlpha
