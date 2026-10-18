local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

-- Analoguhr für alle Größen (Schalter Analog/Digital in den Uhr-Optionen).
-- Zeiger und Strichmarken sind gezeichnete Texturen (Media/Analog; Zeiger mit Kontur, Schliff und
-- eingebautem Schatten) und werden per SetRotation gedreht.
local SMALL_DIAMETER = ns.SMALL_DIAMETER
local T = ns.T
local HAND_FRACTION = 0.40 -- Bezugsradius der Zeigertexturen
-- Kleine Uhr: das Ziffernblatt sitzt im 32-px-Button optisch etwas rechts unten; Versatz in Pixeln
-- (nach links / nach oben), bei Bedarf hier nachjustieren.
local PATH = 'Interface\\AddOns\\CantPlayForever\\Media\\Analog\\'

local function HandAngles(self)
    local hour, minute = self:GetHourMinute()
    local second = self:GetSecond()
    return ((hour % 12) + minute / 60) / 12 * 360,
        (minute + second / 60) / 60 * 360,
        second / 60 * 360
end

-- Quadratische Zeigertextur, Drehpunkt in der Mitte; Winkel im Uhrzeigersinn ab 12 Uhr.
local function SetHand(tex, size, angle)
    tex:SetSize(size, size)
    tex:SetRotation(-math.rad(angle))
    tex:Show()
end

function Clock:CreateAnalogClock()
    local button = self.iconButton
    if self.analog or not button then return end
    local face = CreateFrame('Frame', nil, button)
    face:SetAllPoints(button)
    face:SetFrameLevel(button:GetFrameLevel() + 2)
    local center = face:CreateTexture(nil, 'OVERLAY')
    center:SetSize(1, 1)
    center:SetPoint('CENTER', face, 'CENTER', 0, 0)
    local function NewTexture(name, sublevel)
        local tex = face:CreateTexture(nil, 'OVERLAY', nil, sublevel)
        tex:SetTexture(PATH .. name)
        tex:SetPoint('CENTER', center, 'CENTER', 0, 0)
        return tex
    end
    self.analog = {
        frame = face, center = center,
        hour = NewTexture('hand_hour', 2),
        minute = NewTexture('hand_minute', 3),
        second = NewTexture('hand_second', 4),
    }
    -- Zifferblatt-Striche: ein fertig gezeichnetes Bild mit allen zwölf Strichen auf dem
    -- gemeinsamen äußeren Kreis (die langen bei 12/3/6/9 Uhr); wird auf den Durchmesser skaliert.
    self.analog.dial = NewTexture('dial_ticks', 1)
end

function Clock:UpdateAnalogBig()
    if not self.analog then self:CreateAnalogClock() end
    local analog = self.analog
    if not analog or type(analog.hour.SetRotation) ~= 'function' then return end
    local diameter = self:GetClockDiameter()
    local small = diameter <= SMALL_DIAMETER
    -- Klein: Standard-Minimap-Rahmen der Bibliothek; Zifferblatt und Zeiger passen auf dessen
    -- dunkle Scheibe (button.background, Feinlage T.SMALL_DX/DY).
    local backdrop = small and self.iconButton.background
    local dialSize = diameter
    local radius = diameter * HAND_FRACTION
    analog.frame:Show()

    analog.center:ClearAllPoints()
    if backdrop then
        analog.center:SetPoint('CENTER', backdrop, 'CENTER', T.SMALL_DX, T.SMALL_DY)
    else
        analog.center:SetPoint('CENTER', analog.frame, 'CENTER', 0, 0)
    end
    local hourAngle, minuteAngle, secondAngle = HandAngles(self)

    if small then
        -- Klein: Punkte als Textur (dial_dots_small, Größe T.SMALL_DOTS), Zeiger als dünne Striche;
        -- Längen und Dicken liegen in der zentralen Clock.tune-Tabelle.
        analog.dial:Show()
        analog.dial:SetTexture(PATH .. 'dial_dots_small')
        analog.dial:SetSize(T.SMALL_DOTS, T.SMALL_DOTS)
        analog.hour:Hide()
        analog.minute:Hide()
        analog.second:Hide()
        self:UpdateSmallAnalog(hourAngle, minuteAngle)
        return
    end
    if analog.small then
        analog.small.hour:Hide()
        analog.small.minute:Hide()
    end
    analog.dial:Show()
    analog.dial:SetTexture(PATH .. 'dial_ticks')
    analog.dial:SetSize(dialSize, dialSize)
    analog.hour:SetTexture(PATH .. 'hand_hour')

    -- Die Texturbreite entspricht dem doppelten Zeigerradius (Zeigerlänge = Bruchteil davon).
    SetHand(analog.hour, radius * 2, hourAngle)
    SetHand(analog.minute, radius * 2, minuteAngle)
    -- Läuft ein Timer, steht dessen Countdown im Vordergrund: dann kein Sekundenzeiger.
    local timerRunning = self:IsModuleEnabled('timer') and self.db.profile.activeTimer ~= nil
    if timerRunning then
        analog.second:Hide()
    else
        SetHand(analog.second, radius * 2, secondAngle)
    end
end

-- Kleine Uhr: zwei dünne Striche (Linien); die Punkte kommen aus dem Zifferblatt-Bild.
function Clock:UpdateSmallAnalog(hourAngle, minuteAngle)
    local analog = self.analog
    if not analog.small then
        local face = analog.frame
        local small = {}
        small.hour = face:CreateLine(nil, 'OVERLAY', nil, 3)
        small.minute = face:CreateLine(nil, 'OVERLAY', nil, 4)
        small.hour:SetColorTexture(0.86, 0.84, 0.78, 1)
        small.minute:SetColorTexture(1, 1, 1, 1)
        analog.small = small
    end
    local small = analog.small
    local function Place(line, angle, length, width)
        local rad = math.rad(angle)
        line:SetThickness(width)
        line:SetStartPoint('CENTER', analog.center, 0, 0)
        line:SetEndPoint('CENTER', analog.center, length * math.sin(rad), length * math.cos(rad))
        line:Show()
    end
    Place(small.hour, hourAngle, T.SMALL_HOUR_LEN, T.SMALL_HOUR_W)
    Place(small.minute, minuteAngle, T.SMALL_MIN_LEN, T.SMALL_MIN_W)
end

function Clock:UpdateAnalogClock()
    if not self.db then return end
    if not self:IsAnalogClock() then
        if self.analog then self.analog.frame:Hide() end
        return
    end
    self:UpdateAnalogBig()
end

