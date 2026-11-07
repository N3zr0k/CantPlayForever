-- Test der Balkenform der großen Uhr (BarClock.lua) mit einfachen Frame-Attrappen.
local realOs = os
time = realOs.time
date = realOs.date
os = nil

local function NewFrame(name)
    local frame = {name = name, shown = false, width = 0, height = 0, points = {}, masks = 0}
    local methods = {
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        IsShown = function(self) return self.shown end,
        SetSize = function(self, w, h) self.width, self.height = w, h end,
        SetWidth = function(self, w) self.width = w end,
        SetHeight = function(self, h) self.height = h end,
        GetWidth = function(self) return self.width end,
        GetFrameLevel = function() return 5 end,
        SetPoint = function(self, ...) self.points[#self.points + 1] = {...} end,
        ClearAllPoints = function(self) self.points = {} end,
        SetText = function(self, text) self.text = text end,
        CreateTexture = function() return NewFrame('tex') end,
        CreateFontString = function() return NewFrame('fs') end,
        GetHighlightTexture = function(self) local hl = rawget(self, 'highlight'); if not hl then hl = NewFrame('hl'); self.highlight = hl end; return hl end,
        SetAlpha = function(self, a) self.alpha = a end,
        SetColorTexture = function(self, r, g, b, a) self.color = {r, g, b, a} end,
        SetTexture = function(self, t) self.texture = t end,
        SetTexCoord = function() end,
        HookScript = function() end,
        SetScript = function() end,
    }
    return setmetatable(frame, {__index = function(_, key) return methods[key] or function() end end})
end

CreateFrame = function() return NewFrame('frame') end
CALENDAR_WEEKDAY_NAMES = {'Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'}
GetLocale = function() return 'deDE' end

local profile = {clockLook = 'elvui', barWidth = 240, barHeight = 40, barOpacity = 50, alarms = {}, activeTimer = nil}
local Clock = {
    db = {profile = profile},
    IsModuleEnabled = function() return true end,
    GetToday = function() return 6, 2026, 11, 6 end,
    FormatClock = function() return '21:47' end,
    CountdownText = function() return nil end,
    CountArmedAlarms = function() return 0 end,
    GetBadgeIcon = function() return nil end,
    GetClockDiameter = function() return 95 end,
    ApplyGlobeMask = function() end,
    InvalidateClockText = function() end,
    iconButton = NewFrame('button'),
    clockText = NewFrame('time'),
    clockSeconds = NewFrame('seconds'),
    clockFace = NewFrame('face'),
    smallIcon = NewFrame('small'),
}
Clock.ResizeClockFont = function() end
local ns = {Clock = Clock, T = {TIMER_ICON_R = 1, TIMER_ICON_G = 1, TIMER_ICON_B = 1, TIMER_ICON_DESAT = 0,
    ALARM_ARMED_R = 0, ALARM_ARMED_G = 1, ALARM_ARMED_B = 0, ALARM_ICON_R = 1, ALARM_ICON_G = 1, ALARM_ICON_B = 1, ALARM_ICON_DESAT = 1}}
assert(loadfile('CantPlayForever/Modules/Clock/BarClock.lua'))('CantPlayForever', ns)

assert(Clock:GetClockLook() == 'elvui' and Clock:IsBarClock(), 'Balkenform bei großer Uhr')
profile.clockLook = 'unbekannt'
assert(Clock:GetClockLook() == 'standard' and not Clock:IsBarClock(), 'unbekannter Wert = Standard')
profile.clockLook = 'ellesmere'
local width, height = Clock:GetBarSize()
assert(width == 240 and height == 40, 'Größe aus dem Profil')
profile.barWidth, profile.barHeight = 5, 500
width, height = Clock:GetBarSize()
assert(width == 120 and height == 80, 'Größe begrenzt')
profile.barWidth, profile.barHeight = 240, 40
local rx, ry = Clock:LargeHalfExtent()
assert(rx == 120 and ry == 20, 'halbe Ausdehnung des Balkens')

assert(Clock:FormatBarDate() == 'Fr, 06.11.', 'Datum: ' .. tostring(Clock:FormatBarDate()))
GetLocale = function() return 'enUS' end
Clock:GetToday() -- anderer Schlüssel nötig: Tag ändern
Clock.GetToday = function() return 6, 2026, 11, 7 end
assert(Clock:FormatBarDate() == 'Fr, 11/07', 'englisches Datum: ' .. tostring(Clock:FormatBarDate()))
GetLocale = function() return 'deDE' end
Clock.GetToday = function() return 6, 2026, 11, 6 end

Clock:ApplyBarArt()
local button, bar = Clock.iconButton, Clock.bar
assert(Clock.barActive and button.width == 240 and button.height == 40, 'Knopf wird zum Balken')
assert(bar.bg.color[4] == 0.5, 'Hintergrund halbtransparent')
assert(Clock.clockText.text == '21:47' and bar.date.text == 'Fr, 06.11.', 'Uhrzeit und Datum')
assert(button.highlight.alpha == 0, 'runde Mouseover-Textur aus')
assert(not bar.icons.alarm.shown and not bar.icons.timer.shown and not bar.icons.holiday.shown, 'keine Symbole ohne Alarm/Timer/Fest')

profile.alarms = {{}}
profile.activeTimer = {}
Clock.GetBadgeIcon = function() return 235462 end
Clock.IconTexture = function(_, icon) return 'icon' .. icon end
Clock.HolidayTexCoord = function() return 0, 1, 0, 1 end
Clock:UpdateBarBadges()
assert(bar.icons.alarm.shown and bar.icons.timer.shown and bar.icons.holiday.shown, 'alle drei Symbole')
local function RightOffset(frame) return frame.points[1][4] end
assert(RightOffset(bar.icons.holiday) > RightOffset(bar.icons.timer)
    and RightOffset(bar.icons.timer) > RightOffset(bar.icons.alarm), 'Fest-Symbol ganz rechts, Alarm ganz links')
assert(bar.icons.holiday.tex.texture == 'icon235462', 'Fest-Symbol aus dem Kalender')

Clock.CountdownText = function() return '5 min' end
Clock:UpdateBarClock()
assert(Clock.clockSeconds.text == '5 min' and Clock.clockSeconds.shown, 'Timer-Countdown neben der Uhrzeit')
Clock.CountdownText = function() return nil end
Clock:UpdateBarClock()
assert(not Clock.clockSeconds.shown, 'Countdown weg')

-- Fest-Dekoration und runde Symbole verschwinden
Clock.holidayOverlay = NewFrame('overlay'); Clock.holidayOverlay.shown = true
Clock.badges = {alarm = NewFrame('b'), timer = NewFrame('b')}
Clock.badges.alarm.shown = true
bar.badgeKey = nil
Clock:UpdateBarBadges()
assert(not Clock.holidayOverlay.shown and not Clock.badges.alarm.shown, 'keine Dekoration, keine runden Symbole')

Clock:HideBarArt()
assert(not Clock.barActive and not bar.bg.shown and not bar.icons.alarm.shown and button.highlight.alpha == 1, 'zurück zur runden Uhr')

-- Automatische Wahl: erkanntes UI-Addon stellt Stil und Größe einmalig ein
local loaded = {}
IsAddOnLoaded = function(name) return loaded[name] end
local sized
Clock.SetClockSize = function(_, size) sized = size end
Clock.Debug = function() end
Clock.GetClockDiameter = function() return 64 end
profile.clockLook = 'standard'
Clock:AutoSelectLook()
assert(profile.clockLook == 'standard' and sized == nil, 'ohne UI-Addon keine Änderung')
loaded.EllesmereUI = true
Clock:AutoSelectLook()
assert(profile.clockLook == 'ellesmere' and sized == 95 and profile.autoLookFor == 'ellesmere', 'EllesmereUI erkannt')
profile.clockLook = 'standard'; sized = nil
Clock:AutoSelectLook()
assert(profile.clockLook == 'standard' and sized == nil, 'eigene Wahl bleibt, nur einmal automatisch')
loaded.ElvUI = true
Clock:AutoSelectLook()
assert(profile.clockLook == 'elvui' and sized == 95, 'ElvUI hat Vorrang und wird einmalig übernommen')
print('BarClock OK')
