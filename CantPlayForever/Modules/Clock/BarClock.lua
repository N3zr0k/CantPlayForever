local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, T = ns.Clock, ns.T

-- Breite Rechteck-Darstellung der großen Uhr im Stil von ElvUI und EllesmereUI:
-- halbtransparenter eckiger Hintergrund, links Uhrzeit (Timer-Countdown daneben) und Datum,
-- rechts die Symbole für Alarm, Timer und Fest (ohne Rahmen und ohne Festdekoration).
-- Der Minimap-Knopf der Uhr bleibt derselbe (Klicks, Tooltip, Ziehen, Leuchten);
-- nur Größe und Grafik wechseln.
local LARGE_DIAMETER = 95

local BADGE_PATH = 'Interface\\AddOns\\CantPlayForever\\Media\\Badges\\'
local PREVIEW_HOLIDAY_ICON = 235462

local LOOKS = {
    elvui = {
        bg = {0.08, 0.08, 0.08},
        outer = {0, 0, 0, 1},
        inner = {0.23, 0.23, 0.23, 1},
        pad = 10,
    },
    ellesmere = {
        bg = {0.04, 0.05, 0.07},
        outer = {1, 1, 1, 0.12},
        accent = {0.05, 0.82, 0.62, 1},
        accentWidth = 3,
        pad = 13,
    },
}

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function Clock:GetClockLook()
    local profile = self.db and self.db.profile
    local look = profile and profile.clockLook
    if LOOKS[look] and self:GetClockDiameter() == LARGE_DIAMETER then return look end
    return 'standard'
end

function Clock:IsBarClock()
    return self:GetClockLook() ~= 'standard'
end

function Clock:GetBarSize()
    local profile = self.db.profile
    return Clamp(tonumber(profile.barWidth) or 220, 120, 400),
        Clamp(tonumber(profile.barHeight) or 44, 28, 80)
end

-- Halbe Breite/Höhe der großen Uhr (Rand- und Einrastabstände).
function Clock:LargeHalfExtent()
    if self:IsBarClock() then
        local width, height = self:GetBarSize()
        return width / 2, height / 2
    end
    return LARGE_DIAMETER / 2, LARGE_DIAMETER / 2
end

local function NewEdges(button)
    local edges = {}
    for index = 1, 4 do edges[index] = button:CreateTexture(nil, 'BORDER') end
    return edges
end

-- Vier 1-px-Linien im Abstand inset vom Knopfrand.
local function LayoutEdges(edges, button, inset, color)
    local top, bottom, left, right = edges[1], edges[2], edges[3], edges[4]
    for _, edge in ipairs(edges) do
        edge:SetColorTexture(color[1], color[2], color[3], color[4])
        edge:ClearAllPoints()
        edge:Show()
    end
    top:SetPoint('TOPLEFT', button, 'TOPLEFT', inset, -inset)
    top:SetPoint('TOPRIGHT', button, 'TOPRIGHT', -inset, -inset)
    top:SetHeight(1)
    bottom:SetPoint('BOTTOMLEFT', button, 'BOTTOMLEFT', inset, inset)
    bottom:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -inset, inset)
    bottom:SetHeight(1)
    left:SetPoint('TOPLEFT', button, 'TOPLEFT', inset, -inset)
    left:SetPoint('BOTTOMLEFT', button, 'BOTTOMLEFT', inset, inset)
    left:SetWidth(1)
    right:SetPoint('TOPRIGHT', button, 'TOPRIGHT', -inset, -inset)
    right:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -inset, inset)
    right:SetWidth(1)
end

local function HideAll(list)
    for _, region in ipairs(list) do region:Hide() end
end

local ICON_TEXTURES = {
    alarm = BADGE_PATH .. 'alarm_icon',
    timer = BADGE_PATH .. 'timer_icon',
}

function Clock:EnsureBar()
    if self.bar then return self.bar end
    local button = self.iconButton
    local bar = { icons = {} }
    bar.bg = button:CreateTexture(nil, 'BACKGROUND', nil, -3)
    bar.bg:SetAllPoints(button)
    bar.outer = NewEdges(button)
    bar.inner = NewEdges(button)
    bar.accent = button:CreateTexture(nil, 'BORDER')
    bar.hover = button:CreateTexture(nil, 'ARTWORK')
    bar.hover:SetAllPoints(button)
    bar.hover:SetColorTexture(1, 1, 1, 0.08)
    bar.hover:Hide()
    bar.date = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    bar.date:SetJustifyH('LEFT')
    bar.date:SetTextColor(0.78, 0.78, 0.78, 1)
    bar.date:SetShadowColor(0, 0, 0, 1)
    bar.date:SetShadowOffset(1, -1)
    for _, key in ipairs({'alarm', 'timer', 'holiday'}) do
        local frame = CreateFrame('Frame', nil, button)
        frame.tex = frame:CreateTexture(nil, 'ARTWORK')
        frame.tex:SetAllPoints(frame)
        if key == 'holiday' then
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
        bar.icons[key] = frame
    end
    -- LibDBIcon setzt die Mouseover-Textur; sie ist rund. Hier hellt stattdessen die Fläche auf.
    button:HookScript('OnEnter', function() if self.barActive then bar.hover:Show() end end)
    button:HookScript('OnLeave', function() bar.hover:Hide() end)
    self.bar = bar
    return bar
end

-- Erste Zeichen (UTF-8-sicher) für das Kurzwort des Wochentags.
local function Abbreviate(name, count)
    local result, taken = {}, 0
    for char in name:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        taken = taken + 1
        result[taken] = char
        if taken >= count then break end
    end
    return table.concat(result)
end

local dateKey, dateText
function Clock:FormatBarDate()
    local weekday, _, month, day = self:GetToday()
    local key = weekday * 10000 + month * 100 + day
    if key ~= dateKey then
        dateKey = key
        local names = _G.CALENDAR_WEEKDAY_NAMES
        local name = names and names[weekday] or date('%a')
        name = Abbreviate(name, 2)
        local locale = (_G.GetLocale and GetLocale()) or 'enUS'
        if locale == 'enUS' or locale == 'enGB' then
            dateText = string.format('%s, %02d/%02d', name, month, day)
        else
            dateText = string.format('%s, %02d.%02d.', name, day, month)
        end
    end
    return dateText
end

-- Knopfgröße, Hintergrund, Rand, Schriften. Aufruf aus ApplyClockArt (große Uhr in Balkenform).
function Clock:ApplyBarArt()
    local button = self.iconButton
    local bar = self:EnsureBar()
    local look = LOOKS[self:GetClockLook()]
    local width, height = self:GetBarSize()
    local profile = self.db.profile
    button:SetSize(width, height)
    if self.clockFace then self.clockFace:Hide() end
    if self.smallIcon then self.smallIcon:Hide() end
    if self.clockRing then self.clockRing:Hide() end
    self:ApplyGlobeMask(false)
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end

    local opacity = Clamp((tonumber(profile.barOpacity) or 60) / 100, 0, 1)
    bar.bg:SetColorTexture(look.bg[1], look.bg[2], look.bg[3], opacity)
    bar.bg:Show()
    LayoutEdges(bar.outer, button, 0, look.outer)
    if look.inner then
        LayoutEdges(bar.inner, button, 1, look.inner)
    else
        HideAll(bar.inner)
    end
    if look.accent then
        bar.accent:SetColorTexture(look.accent[1], look.accent[2], look.accent[3], look.accent[4])
        bar.accent:ClearAllPoints()
        bar.accent:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
        bar.accent:SetPoint('BOTTOMLEFT', button, 'BOTTOMLEFT', 0, 0)
        bar.accent:SetWidth(look.accentWidth)
        bar.accent:Show()
    else
        bar.accent:Hide()
    end

    local timeSize = Clamp(math.floor(height * 0.50), 12, 40)
    local dateSize = Clamp(math.floor(height * 0.24), 9, 16)
    local pad = look.pad
    local clockText, seconds = self.clockText, self.clockSeconds
    clockText.cpfText = nil -- beim Zurückwechseln neu anordnen (PlaceText)
    clockText:ClearAllPoints()
    clockText:SetPoint('LEFT', button, 'LEFT', pad, height * 0.14)
    clockText:SetJustifyH('LEFT')
    Clock.ResizeClockFont(clockText, 'GameFontHighlightLarge', timeSize, width * 0.45)
    clockText:Show()
    seconds.cpfText = nil
    seconds:ClearAllPoints()
    seconds:SetPoint('LEFT', clockText, 'RIGHT', 8, 0)
    seconds:SetJustifyH('LEFT')
    Clock.ResizeClockFont(seconds, 'GameFontHighlightLarge', Clamp(math.floor(height * 0.30), 9, 20), width * 0.25)
    bar.date:ClearAllPoints()
    bar.date:SetPoint('LEFT', button, 'LEFT', pad, -height * 0.26)
    Clock.ResizeClockFont(bar.date, 'GameFontHighlightLarge', dateSize, width * 0.45)
    bar.date:Show()

    bar.timeText, bar.dateText, bar.badgeKey = nil, nil, nil
    bar.iconSize, bar.pad = Clamp(math.floor(height * 0.52), 14, 30), pad
    self.barActive = true
    self:UpdateBarClock()
    self:UpdateBarBadges()
end

-- Zurück zur runden Uhr (oder kleiner/mittlerer Größe): alle Balkenteile weg.
function Clock:HideBarArt()
    local bar = self.bar
    if not (bar and self.barActive) then return end
    self.barActive = false
    bar.bg:Hide()
    bar.accent:Hide()
    bar.hover:Hide()
    bar.date:Hide()
    HideAll(bar.outer)
    HideAll(bar.inner)
    for _, frame in pairs(bar.icons) do frame:Hide() end
    local button = self.iconButton
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(1) end
    self.clockText:SetJustifyH('CENTER')
    self.clockSeconds:SetJustifyH('CENTER')
    self:InvalidateClockText()
end

function Clock:UpdateBarClock()
    local bar = self.bar
    if not (bar and self.barActive) then return end
    local label = self:FormatClock()
    if bar.timeText ~= label then
        bar.timeText = label
        self.clockText:SetText(label)
    end
    local dateLine = self:FormatBarDate()
    if bar.dateText ~= dateLine then
        bar.dateText = dateLine
        bar.date:SetText(dateLine)
    end
    local countdown = self:CountdownText()
    local seconds = self.clockSeconds
    if countdown then
        if seconds.cpfText ~= countdown then
            seconds.cpfText = countdown
            seconds:SetText(countdown)
        end
        if not seconds:IsShown() then seconds:Show() end
    elseif seconds:IsShown() then
        seconds.cpfText = nil
        seconds:Hide()
    end
end

-- Symbole rechts, von rechts nach links gepackt: Fest zuletzt (ganz rechts), davor Timer, davor Alarm.
function Clock:UpdateBarBadges()
    local bar = self.bar
    if not (bar and self.barActive) then return end
    -- Runde Symbole und Festdekoration gehören nicht zu dieser Darstellung.
    if self.holidayOverlay and self.holidayOverlay:IsShown() then self.holidayOverlay:Hide() end
    for _, badge in pairs(self.badges or {}) do
        if badge:IsShown() then badge:Hide() end
    end
    local profile = self.db.profile
    local alarm = self:IsModuleEnabled('alarms') and #profile.alarms > 0
    local timer = self:IsModuleEnabled('timer') and profile.activeTimer ~= nil
    local holidayIcon = self.holidayPreview and (self.holidayPreviewIcon or PREVIEW_HOLIDAY_ICON)
        or self:GetBadgeIcon()
    local armed = alarm and self:CountArmedAlarms() > 0
    local key = table.concat({
        alarm and 1 or 0, timer and 1 or 0, armed and 1 or 0, tostring(holidayIcon),
        bar.iconSize, bar.pad, self.iconButton:GetWidth() or 0,
    }, ',')
    if bar.badgeKey == key then return end
    bar.badgeKey = key

    local icons = bar.icons
    local size = bar.iconSize
    local x = -bar.pad
    local function Place(frame)
        frame:SetSize(size, size)
        frame:ClearAllPoints()
        frame:SetPoint('RIGHT', self.iconButton, 'RIGHT', x, 0)
        frame:SetFrameLevel(self.iconButton:GetFrameLevel() + 4)
        frame:Show()
        x = x - size - 5
    end
    if holidayIcon then
        local frame = icons.holiday
        frame.tex:SetTexture(self:IconTexture(holidayIcon))
        frame.tex:SetTexCoord(self:HolidayTexCoord(holidayIcon))
        Place(frame)
    else
        icons.holiday:Hide()
    end
    if timer then
        local frame = icons.timer
        frame.tex:SetTexture(ICON_TEXTURES.timer)
        frame.tex:SetDesaturated(T.TIMER_ICON_DESAT == 1)
        frame.tex:SetVertexColor(T.TIMER_ICON_R, T.TIMER_ICON_G, T.TIMER_ICON_B, 1)
        Place(frame)
    else
        icons.timer:Hide()
    end
    if alarm then
        local frame = icons.alarm
        frame.tex:SetTexture(ICON_TEXTURES.alarm)
        if armed then
            frame.tex:SetDesaturated(false)
            frame.tex:SetVertexColor(T.ALARM_ARMED_R, T.ALARM_ARMED_G, T.ALARM_ARMED_B, 1)
        else
            frame.tex:SetDesaturated(T.ALARM_ICON_DESAT == 1)
            frame.tex:SetVertexColor(T.ALARM_ICON_R, T.ALARM_ICON_G, T.ALARM_ICON_B, 1)
        end
        Place(frame)
    else
        icons.alarm:Hide()
    end
end
