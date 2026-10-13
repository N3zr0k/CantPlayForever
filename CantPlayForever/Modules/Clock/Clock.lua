local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, T, Now = ns.Clock, ns.T, ns.Now
local Broker, DBIcon = ns.Broker, ns.DBIcon

function Clock:GetHourMinute()
    if self.db.profile.useLocalTime then
        local info = date('*t')
        return info.hour, info.min
    end
    return GetGameTime()
end

function Clock:FormatClock()
    local hour, minute = self:GetHourMinute()
    if not self.db.profile.use24Hour then
        local twelve = hour % 12
        hour = twelve == 0 and 12 or twelve
    end
    return string.format('%02d:%02d', hour, minute)
end

-- Im Tooltip wird auch der laufende Sekundenzeiger angezeigt.
function Clock:FormatTooltipTime()
    local hour, minute = self:GetHourMinute()
    local second
    if self.db.profile.useLocalTime then
        second = date('*t').sec
    else
        second = Now() % 60
    end
    if not self.db.profile.use24Hour then
        local twelve = hour % 12
        hour = twelve == 0 and 12 or twelve
    end
    return string.format('%02d:%02d:%02d', hour, minute, second)
end

-- Die Original-TGA des Nutzers bildet bei 33..128 Pixeln (mittel 64, groß 95 mit derselben Grafik) den Kreis.
-- Bei 32px bleibt der LibDBIcon-Standardbutton erhalten. Unter 64px
-- wird zur besseren Lesbarkeit nur das Blizzard-Uhrsymbol dargestellt.
local LARGE_CLOCK_TEXTURE = 'Interface\\AddOns\\CantPlayForever\\Media\\ClockLarge'

local SMALL_CLOCK_ICON = 'Interface\\Icons\\INV_Misc_PocketWatch_01'

local SMALL_DIAMETER, MEDIUM_DIAMETER, LARGE_DIAMETER = 32, 64, 95

ns.SMALL_DIAMETER = SMALL_DIAMETER

local CLOCK_TEXT_MIN = 64

function Clock:UseBlizzardLook()
    -- Alle drei Größen verwenden dieselbe Blizzard-Optik (Globus + Ring), nur skaliert.
    return ns.RingAtlasInfo() ~= nil
        and type(_G.CreateFrame('Frame').SetClipsChildren) == 'function'
end

function Clock:GetClockDiameter()
    local p = self.db and self.db.profile
    local value = p and tonumber(p.clockSize) or nil
    if value == 32 or value == 64 or value == 95 then return value end
    if value then
        if value < 48 then return 32 end
        if value < 80 then return 64 end
        return 95
    end
    return p and p.smallClock and 32 or 64
end

function Clock:IsSmallClock()
    return self:GetClockDiameter() == SMALL_DIAMETER
end

-- Beide Minimap-Größen haben voneinander unabhängige gespeicherte Positionen.
-- LibDBIcon erhält weiterhin seinen gewohnten Winkel (0° = Osten).
local DEFAULT_MINIMAP_ANGLES = { [32] = 270, [64] = 90 }

function Clock:SetClockSize(size)
    if size ~= SMALL_DIAMETER and size ~= MEDIUM_DIAMETER
        and size ~= LARGE_DIAMETER then return end
    local profile = self.db.profile
    local previous = self:GetClockDiameter()
    if previous == SMALL_DIAMETER or previous == MEDIUM_DIAMETER then
        profile.minimapPositions[previous] =
            (tonumber(profile.minimap.minimapPos) or DEFAULT_MINIMAP_ANGLES[previous]) % 360
    end
    profile.clockSize = size
    if size == SMALL_DIAMETER or size == MEDIUM_DIAMETER then
        profile.minimap.minimapPos =
            profile.minimapPositions[size] or DEFAULT_MINIMAP_ANGLES[size]
    end
    self:RefreshDisplay()
    self:NotifyOptions()
end

function Clock:ResetClockPosition()
    local size = self:GetClockDiameter()
    if size == LARGE_DIAMETER then
        -- nil bedeutet oberer Bildschirmrand, horizontal zentriert.
        -- Kein absoluter Pixelwert wird persistiert: auch Auflösungswechsel
        -- erhalten so den Abstand zum Bildschirmrand.
        self.db.profile.freeClock = nil
    else
        local angle = DEFAULT_MINIMAP_ANGLES[size]
        self.db.profile.minimapPositions[size] = angle
        self.db.profile.minimap.minimapPos = angle
    end
    self:UpdateClockPosition()
    self:NotifyOptions()
end

-- Derselbe Schriftpfad für Uhrzeit und Countdown; eine dunkle Kontur
-- verbessert die Lesbarkeit auf dem dunklen, strukturierten Zifferblatt.
function Clock.ResizeClockFont(text, fontObject, size, maxWidth)
    local obj = _G[fontObject]
    if obj and type(obj.GetFont) == 'function' then
        local path, _, flags = obj:GetFont()
        if path then
            text:SetFont(path, size, 'OUTLINE')
            local actualWidth = text:GetStringWidth() or 0
            if maxWidth and actualWidth > maxWidth and actualWidth > 0 then
                text:SetFont(path, math.max(8, size * maxWidth / actualWidth), 'OUTLINE')
            end
            return
        end
    end
    text:SetFontObject(fontObject)
end

-- Klein ist immer analog; Mittel und Groß folgen dem Schalter Analog/Digital.
function Clock:IsAnalogClock()
    if not self.db then return false end
    return self:GetClockDiameter() == SMALL_DIAMETER or self.db.profile.clockStyle == 'analog'
end

function Clock:UpdateClock()
    local label = self:FormatClock()
    if self.dataObject then self.dataObject.text = label end
    if self.UpdateAnalogClock then self:UpdateAnalogClock() end
    if not self.clockText then return end

    local diameter = self:GetClockDiameter()
    if self:IsAnalogClock() then
        self.clockText:Hide()
        -- Mittel/Groß: Timer-Zahl bleibt sichtbar, liegt aber hinter den Zeigern
        -- (Zeiger sind Linien in einem Kind-Frame über dem Button).
        local countdown = diameter >= CLOCK_TEXT_MIN and self:CountdownText() or nil
        if self.clockSeconds then
            if countdown then
                local k = diameter / 64
                self.clockSeconds:SetText(countdown)
                self.clockSeconds:ClearAllPoints()
                self.clockSeconds:SetPoint('CENTER', self.iconButton, 'CENTER', T.CD_X * k, T.CD_Y * k)
                Clock.ResizeClockFont(self.clockSeconds, 'GameFontHighlightLarge',
                    T.CD_SIZE * k, T.CD_MAXW * k)
                self.clockSeconds:Show()
            else
                self.clockSeconds:Hide()
            end
        end
        return
    end

    local small = diameter < CLOCK_TEXT_MIN
    -- Klein: nur die Uhrzeit, ohne Countdown-Zeile.
    local countdown = (not small) and self:CountdownText() or nil
    local k = diameter / 64
    self.clockText:SetText(label)
    self.clockText:ClearAllPoints()
    self.clockText:SetPoint('CENTER', self.iconButton, 'CENTER', T.TEXT_X * k,
        (countdown and T.TEXT_Y_CD or T.TEXT_Y) * k)
    Clock.ResizeClockFont(self.clockText, 'GameFontHighlightLarge',
        (countdown and T.TEXT_SIZE_CD or T.TEXT_SIZE) * k, small and 26 or T.TEXT_MAXW * k)
    self.clockText:Show()

    if self.clockSeconds then
        if countdown then
            self.clockSeconds:SetText(countdown)
            self.clockSeconds:ClearAllPoints()
            self.clockSeconds:SetPoint('CENTER', self.iconButton, 'CENTER', T.CD_X * k, T.CD_Y * k)
            Clock.ResizeClockFont(self.clockSeconds, 'GameFontHighlightLarge',
                T.CD_SIZE * k, T.CD_MAXW * k)
            self.clockSeconds:Show()
        else
            self.clockSeconds:Hide()
        end
    end
end

-- In klein und mittel bleibt die von LibDBIcon berechnete Minimap-Position
-- der MITTELPUNKT des Kreises. Groß ist davon völlig unabhängig und besitzt
-- einen gespeicherten, frei verschiebbaren UIParent-Anker.
local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

-- Einrastpunkte: Minimap-Norden (mittlere Größe) und, bei der großen Uhr,
-- oben mittig oder unten rechts. Sonst frei; klein rastet nirgends ein.
local SNAP_MARGIN = 16
local SNAP_DISTANCE = 40 -- Pixel (groß)
local SNAP_ANGLE = 8     -- Grad (mittel)
local MEDIUM_SNAP_ANGLE = 90 -- LibDBIcon: 90° = Norden

function Clock:SaveFreePosition(centerX, centerY)
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if not width or not height or width <= 0 or height <= 0 then return end
    local radius = LARGE_DIAMETER / 2
    local x = Clamp(centerX, radius, math.max(radius, width - radius))
    local y = Clamp(centerY, radius, math.max(radius, height - radius))
    self.db.profile.freeClock = {x = x / width, y = y / height}
end

function Clock:UpdateClockPosition()
    local button = self.iconButton
    if not (button and self.db and Minimap) then return end
    local profile = self.db.profile
    local size = self:GetClockDiameter()
    button:ClearAllPoints()
    if size == LARGE_DIAMETER then
        button:SetParent(UIParent)
        local free = profile.freeClock
        if type(free) == 'table' and free.snap == 'bottomright' then
            button:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -SNAP_MARGIN, SNAP_MARGIN)
        elseif type(free) ~= 'table' then
            -- Frei verschiebbare große Uhr: Standard oben mittig, mit 16px Rand.
            button:SetPoint('TOP', UIParent, 'TOP', 0, -(LARGE_DIAMETER / 2 + SNAP_MARGIN))
        else
            local width, height = UIParent:GetWidth(), UIParent:GetHeight()
            if not width or not height or width <= 0 or height <= 0 then return end
            local cx = (tonumber(free.x) or 0.5) * width
            local cy = (tonumber(free.y) or 0.5) * height
            self:SaveFreePosition(cx, cy)
            button:SetPoint('CENTER', UIParent, 'BOTTOMLEFT',
                profile.freeClock.x * width, profile.freeClock.y * height)
        end
    else
        button:SetParent(Minimap)
        local angle = (tonumber(profile.minimapPositions[size])
            or DEFAULT_MINIMAP_ANGLES[size]) % 360
        profile.minimap.minimapPos = angle
        self.iconLibrary:SetButtonToPosition(button, angle)
    end
end

function Clock:MoveClockToCursor()
    local px, py = GetCursorPosition()
    if self:GetClockDiameter() == LARGE_DIAMETER then
        local scale = UIParent:GetEffectiveScale()
        if not px or not py or not scale or scale <= 0 then return end
        local x = px / scale - (self.dragOffsetX or 0)
        local y = py / scale - (self.dragOffsetY or 0)
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        local radius = LARGE_DIAMETER / 2
        local function Near(tx, ty)
            return (x - tx) ^ 2 + (y - ty) ^ 2 <= SNAP_DISTANCE ^ 2
        end
        if width and height and Near(width / 2, height - radius - SNAP_MARGIN) then
            self.db.profile.freeClock = nil
        elseif width and height and Near(width - radius - SNAP_MARGIN, radius + SNAP_MARGIN) then
            self.db.profile.freeClock = {snap = 'bottomright', x = 1, y = 0}
        else
            self:SaveFreePosition(x, y)
        end
    else
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        if not mx or not my or not px or not py or not scale or scale <= 0 then return end
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx)) % 360
        if self:GetClockDiameter() == MEDIUM_DIAMETER then
            local delta = math.abs((angle - MEDIUM_SNAP_ANGLE + 180) % 360 - 180)
            if delta <= SNAP_ANGLE then angle = MEDIUM_SNAP_ANGLE end
        end
        self.db.profile.minimapPositions[self:GetClockDiameter()] = angle
        self.db.profile.minimap.minimapPos = angle
    end
    self:UpdateClockPosition()
end

function Clock:SetupClockDragging()
    local button = self.iconButton
    if not button then return end
    button:SetScript('OnDragStart', function(btn)
        btn.isMouseDown = true
        btn:LockHighlight()
        if GameTooltip then GameTooltip:Hide() end
        self.dragOffsetX, self.dragOffsetY = nil, nil
        if self:GetClockDiameter() == LARGE_DIAMETER then
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            local cx, cy = btn:GetCenter()
            if px and py and cx and cy and scale and scale > 0 then
                self.dragOffsetX = px / scale - cx
                self.dragOffsetY = py / scale - cy
            end
        end
        btn:SetScript('OnUpdate', function() self:MoveClockToCursor() end)
    end)
    button:SetScript('OnDragStop', function(btn)
        btn:SetScript('OnUpdate', nil)
        btn.isMouseDown = false
        btn:UnlockHighlight()
        self.dragOffsetX, self.dragOffsetY = nil, nil
        self:UpdateClockPosition()
    end)
    if not self.clockPositionEvents then
        local f = CreateFrame('Frame')
        f:RegisterEvent('PLAYER_LOGIN')
        f:RegisterEvent('PLAYER_ENTERING_WORLD')
        f:SetScript('OnEvent', function()
            self:UpdateClockPosition()
            if _G.C_Timer and type(C_Timer.After) == 'function' then
                C_Timer.After(0, function() self:UpdateClockPosition() end)
            end
        end)
        self.clockPositionEvents = f
    end
end

function Clock:ApplyClockArt()
    local button = self.iconButton
    if not button then return end
    local name = 'CantPlayForever'
    local diameter = self:GetClockDiameter()
    button:SetScale(1)
    -- Die Uhr soll über den übrigen Minimap-Symbolen liegen (z. B. Fraktions-/Schlachtfeldsymbol).
    if type(button.SetFixedFrameStrata) == 'function' then button:SetFixedFrameStrata(false) end
    button:SetFrameStrata('FULLSCREEN')
    button:SetFrameLevel(200)
    if type(button.SetFixedFrameStrata) == 'function' then button:SetFixedFrameStrata(true) end
    if type(button.SetFixedFrameLevel) == 'function' then button:SetFixedFrameLevel(true) end

    if not self.clockFace then
        self.clockFace = button:CreateTexture(nil, 'BACKGROUND')
        self.clockFace:SetPoint('CENTER', button, 'CENTER', 0, 0)
    end
    if not self.smallIcon then
        self.smallIcon = button:CreateTexture(nil, 'ARTWORK')
        self.smallIcon:SetPoint('CENTER', button, 'CENTER', 0, -0.5)
        self.smallIcon:SetTexture(SMALL_CLOCK_ICON)
    end
    if not self.clockText then
        self.clockText = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
        self.clockText:SetJustifyH('CENTER')
        self.clockText:SetTextColor(1, 1, 1, 1)
        self.clockText:SetShadowColor(0, 0, 0, 1)
        self.clockText:SetShadowOffset(1, -1)
    end
    if not self.clockSeconds then
        self.clockSeconds = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
        self.clockSeconds:SetJustifyH('CENTER')
        self.clockSeconds:SetTextColor(0.39, 0.79, 1.0, 1)
        self.clockSeconds:SetShadowColor(0, 0, 0, 1)
        self.clockSeconds:SetShadowOffset(1, -1)
    end

    if diameter == SMALL_DIAMETER then
        -- Klein: Standard-Minimap-Symbol der Bibliothek (Rahmen, dunkle Scheibe, Standardgröße);
        -- die Analoguhr (AnalogClock.lua) sitzt auf der Scheibe.
        local lib = self.iconLibrary
        lib:ResetButtonSize(name)
        lib:ResetButtonBorder(name)
        lib:ResetButtonBackground(name)
        if button.background then button.background:SetVertexColor(0, 0, 0, 1) end -- einfarbig schwarz, ohne Bildstruktur
        if button.icon then button.icon:Hide() end
        self:ApplyGlobeMask(false)
        if self.clockRing then self.clockRing:Hide() end
        self.clockFace:Hide()
        self.smallIcon:Hide()
    else
        button:SetSize(diameter, diameter)
        if button.icon then button.icon:Hide() end
        if button.border then button.border:Hide() end
        if button.background then button.background:Hide() end
        if self:UseBlizzardLook() then
            self.clockFace:SetTexture(ns.GLOBE_TEXTURE)
            self:ApplyGlobeMask(true, diameter)
            self:ApplyRing(diameter)
        else
            self.clockFace:SetTexture(LARGE_CLOCK_TEXTURE)
            self:ApplyGlobeMask(false)
            if self.clockRing then self.clockRing:Hide() end
        end
        self.clockFace:SetSize(diameter, diameter)
        self.clockFace:Show()
        self.smallIcon:Hide()
    end
    self:UpdateClockPosition()
    self:UpdateClock()
    self:UpdateCoverGlow()
    self:UpdateBadges()
end

function Clock:RefreshDisplay()
    if not self.db then return end
    if self.iconLibrary:IsRegistered('CantPlayForever') then
        self.iconLibrary:Refresh('CantPlayForever', self.db.profile.minimap)
        if self.db.profile.minimap.hide then
            self.iconLibrary:Hide('CantPlayForever')
        else
            self.iconLibrary:Show('CantPlayForever')
        end
    end
    self:ApplyClockArt()
    self:SetupClockDragging()
    if self.ApplyBlizzardClock then self:ApplyBlizzardClock() end -- Blizzard-Uhr folgt dem Zustand unserer Uhr
    self:UpdateClock()
end

Clock:RegisterModule({
    id = 'clock',
    locked = true,
    logo = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\uhr_logo',
    OnInitialize = function(self)
        self.dataObject = Broker:NewDataObject('CantPlayForever', {
            type = 'launcher',
            icon = 'Interface\\Icons\\INV_Misc_PocketWatch_01',
            text = self:FormatClock(),
            OnClick = function(_, button)
                self:Debug('Click %s ctrl=%s shift=%s alt=%s', tostring(button),
                    tostring(IsControlKeyDown and IsControlKeyDown()), tostring(IsShiftKeyDown and IsShiftKeyDown()),
                    tostring(IsAltKeyDown and IsAltKeyDown()))
                if button == 'RightButton' then
                    if IsAltKeyDown and IsAltKeyDown() then
                        self:ToggleBlizzardClockMenu()
                    elseif IsControlKeyDown and IsControlKeyDown() then
                        self:ToggleStopwatch()
                    else
                        self:OpenSettings('general')
                    end
                elseif button == 'LeftButton' then
                    if IsShiftKeyDown and IsShiftKeyDown() then
                        self:ToggleSelectedAlarms()
                    else
                        self:ToggleSelectedTimer()
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                self:BuildHoverTooltip(tooltip)
            end,
            OnLeave = function()
                self.hoverTooltip = nil
                self.hoverClockLine = nil
                self.hoverTimerLine = nil
            end,
        })
        DBIcon:Register('CantPlayForever', self.dataObject, self.db.profile.minimap)
        self.iconButton = DBIcon:GetMinimapButton('CantPlayForever')
        self:SetupClockDragging()
        self:ApplyClockArt()
    end,
    OnEnable = function(self)
        self:RefreshDisplay()
        self:ApplyBlizzardClock()
    end,
    OnTick = function(self)
        self:UpdateClock()
        self:UpdateCoverGlow()
        self:UpdateBadges()
        self:UpdateHoverTooltip()
    end,
    OnChanged = function(self)
        self:UpdateClock()
        self:UpdateBadges()
        self:UpdateHoverTooltip()
    end,
    OnRefresh = function(self) self:RefreshDisplay() end,
    GetOptions = function() return ns.ClockOptions() end,
})
