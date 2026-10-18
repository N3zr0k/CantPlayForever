-- Entwicklungs-Anbindung an den Frame Debugger (nur im Repo, nicht im Release-ZIP; siehe .pkgmeta).
-- Das Addon liefert dem Frame Debugger seine Tuning-Werte, Gruppen, Anwenden-Logik und Aktionen
-- selbst; der Frame Debugger stellt nur die Oberfläche bereit. Ohne Frame Debugger tut die Datei nichts.
local _, ns = ...
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
if not (Clock and _G.FrameDebugger and Clock.tune) then return end

local function P(key, label, step, group) return { key = key, label = label, step = step, group = group } end
local G0, G1, G2, G3, G4, G5, G7, G8, G9 = 'Testbühne', 'Ring (Atlas-Ausschnitt)', 'Ring-Maske', 'Globus-Maske',
    'Schatten', 'Glow', 'Uhrzeit-Text', 'Timer-Zahl', 'Timer-Warnleuchten'
local GB, GA, GT, GH, GP, GL = 'Symbole allgemein (Rahmen aller Symbole)', 'Glocke (Alarm-Symbol)', 'Uhr (Timer-Symbol)',
    'Kalender: Fest-Symbol an der Uhr', 'Kalender: Symbol im Tooltip', 'Symbole: alte Darstellung (ohne Wirkung, nur noch Altbestand)'
local G11 = 'Kleine Uhr (Standardrahmen)'
local G10 = 'Optionen-Logo und Rauten (nur ohne Blizzard-Rahmen; Optionen-Fenster offen lassen)'
local G16 = 'Optionsfenster: Listen-Symbole (Pfeil, Zahnrad, Papierkorb; Optionen mit Timer/Alarmen offen lassen)'
local G12, G13, G14, G15 = 'Optionsfenster: Uhrenkreis in der Ecke', 'Optionsfenster: Uhrzeit',
    'Optionsfenster: rotes X', 'Optionsfenster: Name, Untertitel, Inhalt'

-- Fest-Symbol: Layout neu berechnen (Zwischenspeicher leeren) und Vorschau aktualisieren.
function Clock:RefreshHolidayBadge()
    for _, badge in pairs(self.badges or {}) do badge.cpfDiameter = nil end
    if self.holidayOverlay then self.holidayOverlay.cpfDiameter = nil end
    self:UpdateBadges()
    if self.RefreshStage then self:RefreshStage() end
end

-- Symbole zum Durchschalten: alle bekannten Fest-Symbole (Katalog), dann ein paar Beispiele.
local PREVIEW_ICONS = { 235462, 235458, 'Interface\\Icons\\INV_Misc_Bell_01', 'Interface\\Icons\\INV_Misc_PocketWatch_01',
    'Interface\\Icons\\INV_Misc_QuestionMark' }
local function PreviewList()
    local list, seen = {}, {}
    local ids = {}
    -- zuerst alle Symbole mit Overlay oder Stil, damit man durch die Overlays schalten kann
    local own = {}
    for icon in pairs(ns.HOLIDAY_OVERLAYS or {}) do own[icon] = true end
    for icon in pairs(ns.HOLIDAY_STYLES or {}) do own[icon] = true end
    for icon in pairs(own) do ids[#ids + 1] = icon end
    for _, entry in pairs(Clock.db.global.holidayCatalog or {}) do ids[#ids + 1] = entry.icon end
    table.sort(ids, function(a, b) return tostring(a) < tostring(b) end)
    for _, icon in ipairs(ids) do if not seen[icon] then seen[icon] = true; list[#list + 1] = icon end end
    for _, icon in ipairs(PREVIEW_ICONS) do if not seen[icon] then seen[icon] = true; list[#list + 1] = icon end end
    return list
end

-- Einstellungen je Fest-Symbol (ns.HOLIDAY_STYLES, Schluessel = Textur-ID). Die Regler gelten fuer das
-- gerade angezeigte Symbol: "Stil speichern" uebernimmt sie, beim Durchschalten werden gespeicherte
-- Werte in die Regler geladen, "Stile ausgeben" liefert die Tabelle zum Einfuegen in Core.lua.
local STYLES = ns.HOLIDAY_STYLES or {}

local function LoadStyle(icon)
    local style = STYLES[icon]
    local tune, def = _G.FrameDebugger, _G.FrameDebugger and _G.FrameDebugger.registry and _G.FrameDebugger.registry.CantPlayForever
    if not (style and tune and def and tune.SetValue) then return end
    for _, key in ipairs(Clock.HOLIDAY_STYLE_KEYS) do
        if style[key] ~= nil then tune:SetValue(def, key, style[key]) end
    end
end

local function SaveStyle()
    local icon = Clock.holidayPreviewIcon
    if not (Clock.holidayPreview and icon) then Clock:Print('Erst ein Symbol mit "Nächstes Symbol" wählen.') return end
    local style = {}
    for _, key in ipairs(Clock.HOLIDAY_STYLE_KEYS) do style[key] = Clock.tune[key] end
    STYLES[icon] = style
    Clock:Print('Stil für Symbol ' .. tostring(icon) .. ' gespeichert (bis zum Neuladen; "Stile ausgeben" zum Übernehmen).')
end

local function PrintStyles()
    local names = {}
    for _, entry in pairs(Clock.db.global.holidayCatalog or {}) do names[entry.icon] = entry.title end
    local ids = {}
    for icon in pairs(STYLES) do ids[#ids + 1] = icon end
    table.sort(ids, function(a, b) return tostring(a) < tostring(b) end)
    local lines = {'ns.HOLIDAY_STYLES = {'}
    for _, icon in ipairs(ids) do
        local parts = {}
        for _, key in ipairs(Clock.HOLIDAY_STYLE_KEYS) do
            if STYLES[icon][key] ~= nil then parts[#parts + 1] = key .. ' = ' .. tostring(STYLES[icon][key]) end
        end
        local key = type(icon) == 'number' and '[' .. icon .. ']' or '[' .. string.format('%q', icon) .. ']'
        lines[#lines + 1] = string.format('    %s = { %s },%s', key, table.concat(parts, ', '),
            names[icon] and ('  -- ' .. names[icon]) or '')
    end
    lines[#lines + 1] = '}'
    local text = table.concat(lines, '\n')
    if Clock.DevShowText then Clock.DevShowText(text) else print(text) end
end

local function StepPreviewIcon(direction)
    local list = PreviewList()
    local index = 0
    for i, icon in ipairs(list) do if icon == Clock.holidayPreviewIcon then index = i end end
    index = (index - 1 + direction) % #list + 1
    Clock.holidayPreview, Clock.holidayPreviewIcon = true, list[index]
    LoadStyle(list[index])
    Clock:Print(string.format('Fest-Symbol %d/%d: %s', index, #list, tostring(list[index])))
    Clock:RefreshHolidayBadge()
end

-- Gespeicherte Abweichungen des Frame Debuggers (CPFTuneDB) gelten nur, solange der Standardwert im Addon
-- derselbe ist wie beim Speichern. Aenderst du einen Standardwert im Code, gilt der neue Wert
-- (statt eines veralteten Gespeicherten) in Frame Debugger und Testbuehne.
local saved = _G.CPFTuneDB and _G.CPFTuneDB.CantPlayForever
if type(saved) == 'table' then
    local base = type(saved._base) == 'table' and saved._base or {}
    for key in pairs(saved) do
        if key ~= '_base' and base[key] ~= Clock.tuneDefaults[key] then saved[key] = nil end
    end
end
local function RememberBase(key)
    local db = _G.CPFTuneDB and _G.CPFTuneDB.CantPlayForever
    if key and type(db) == 'table' and db[key] ~= nil then
        if type(db._base) ~= 'table' then db._base = {} end
        db._base[key] = Clock.tuneDefaults[key]
    end
end

FrameDebugger:Register('CantPlayForever', {
    title = "Can't play Forever Uhr",
    values = Clock.tune,
    defaults = Clock.tuneDefaults,
    params = {
        P('STAGE_ZOOM', 'Vergrößerung', 0.5, G0),
        P('STAGE_GRID', 'Mittelkreuz (1/0)', 1, G0),
        P('STAGE_BADGES', 'Symbole zeigen (1/0)', 1, G0),
        P('STAGE_TEXT', 'Texte zeigen (1/0)', 1, G0),
        P('STAGE_TIMER', 'Timer aktiv (1/0)', 1, G0),
        P('STAGE_TIMER_SEC', 'Timer-Einheit (0 min, 1 sec, 2 hrs)', 1, G0),
        P('RING_OFFSET', 'Ring-Ecke Abstand', 0.5, G1),
        P('RING_X0', 'Atlas-Start X', 0.5, G1),
        P('RING_Y0', 'Atlas-Start Y', 0.5, G1),
        P('RING_SIZE', 'Ausschnitt Größe', 0.5, G1),
        P('RING_MASK', 'Maske Breite', 0.1, G2),
        P('RING_MASK_H', 'Maske Höhe', 0.1, G2),
        P('RING_MASK_DX', 'Maske X (rechts +)', 0.1, G2),
        P('RING_MASK_DY', 'Maske Y (oben +)', 0.1, G2),
        P('GLOBE_MASK', 'Globus-Maske Größe', 0.5, G3),
        P('GLOBE_MASK_DX', 'Globus-Maske X', 0.1, G3),
        P('GLOBE_MASK_DY', 'Globus-Maske Y', 0.1, G3),
        P('SHADOW_SIZE', 'Schatten Größe', 0.5, G4),
        P('SHADOW_ALPHA', 'Schatten Deckkraft', 0.05, G4),
        P('SHADOW_DROP', 'Schatten nach unten', 0.25, G4),
        P('GLOW_SHAPE', 'Form (0 voll, 1 Ring, 2 beides)', 1, G5),
        P('GLOW_DISC', 'Fläche Größe', 0.5, G5),
        P('GLOW_DX', 'Fläche X', 0.1, G5),
        P('GLOW_DY', 'Fläche Y', 0.1, G5),
        P('GLOW_RING_SIZE', 'Ring Größe', 0.5, G5),
        P('GLOW_RING_DX', 'Ring X', 0.1, G5),
        P('GLOW_RING_DY', 'Ring Y', 0.1, G5),
        P('BADGE_SIZE', 'Symbol Rahmen', 0.5, GB),
        P('BADGE_FRAME_DESAT', 'Symbol-Rahmen entsättigen (1/0)', 1, GB),
        P('BADGE_FRAME_R', 'Symbol-Rahmen Rot', 0.05, GB),
        P('BADGE_FRAME_G', 'Symbol-Rahmen Grün', 0.05, GB),
        P('BADGE_FRAME_B', 'Symbol-Rahmen Blau', 0.05, GB),
        P('ALARM_SCALE', 'Glocke Faktor', 0.05, GA),
        P('ALARM_X', 'Glocke X', 0.5, GA),
        P('ALARM_Y', 'Glocke Y', 0.5, GA),
        P('ALARM_ICON_SIZE', 'Alarm-Symbol Bildgröße', 0.5, GA),
        P('ALARM_FRAME_SIZE', 'Alarm-Symbol Rahmengröße', 0.5, GA),
        P('ALARM_ICON_X', 'Alarm-Symbol Bild X im Rahmen', 0.5, GA),
        P('ALARM_ICON_Y', 'Alarm-Symbol Bild Y im Rahmen', 0.5, GA),
        P('ALARM_ICON_DESAT', 'Alarm-Symbol entsättigen (1/0)', 1, GA),
        P('ALARM_ICON_R', 'Alarm-Symbol Rot', 0.05, GA),
        P('ALARM_ICON_G', 'Alarm-Symbol Grün', 0.05, GA),
        P('ALARM_ICON_B', 'Alarm-Symbol Blau', 0.05, GA),
        P('ALARM_ARMED_R', 'Alarm-Symbol aktiviert Rot', 0.05, GA),
        P('ALARM_ARMED_G', 'Alarm-Symbol aktiviert Grün', 0.05, GA),
        P('ALARM_ARMED_B', 'Alarm-Symbol aktiviert Blau', 0.05, GA),
        P('TIMER_SCALE', 'Uhr Faktor', 0.05, GT),
        P('TIMER_X', 'Uhr X', 0.5, GT),
        P('TIMER_Y', 'Uhr Y', 0.5, GT),
        P('TIMER_ICON_SIZE', 'Timer-Symbol Bildgröße', 0.5, GT),
        P('TIMER_FRAME_SIZE', 'Timer-Symbol Rahmengröße', 0.5, GT),
        P('TIMER_ICON_X', 'Timer-Symbol Bild X im Rahmen', 0.5, GT),
        P('TIMER_ICON_Y', 'Timer-Symbol Bild Y im Rahmen', 0.5, GT),
        P('TIMER_ICON_DESAT', 'Timer-Symbol entsättigen (1/0)', 1, GT),
        P('TIMER_ICON_R', 'Timer-Symbol Rot', 0.05, GT),
        P('TIMER_ICON_G', 'Timer-Symbol Grün', 0.05, GT),
        P('TIMER_ICON_B', 'Timer-Symbol Blau', 0.05, GT),
        P('HOLIDAY_SCALE', 'Fest-Symbol Faktor', 0.05, GH),
        P('HOLIDAY_X', 'Fest-Symbol X', 0.5, GH),
        P('HOLIDAY_Y', 'Fest-Symbol Y', 0.5, GH),
        P('HOLIDAY_ICON_SIZE', 'Fest-Symbol Bildgröße', 0.5, GH),
        P('HOLIDAY_FRAME_SIZE', 'Fest-Symbol Rahmengröße', 0.5, GH),
        P('HOLIDAY_ICON_X', 'Fest-Symbol Bild X im Rahmen', 0.5, GH),
        P('HOLIDAY_ICON_Y', 'Fest-Symbol Bild Y im Rahmen', 0.5, GH),
        P('HOLIDAY_MASK_SIZE', 'Fest-Symbol Kreis-Ausschnitt (kleiner als Rahmen)', 0.5, GH),
        P('HOLIDAY_ICON_ROUND', 'Fest-Symbol rund beschneiden (1/0)', 1, GH),
        P('HOLIDAY_ICON_CROP', 'Fest-Symbol Rand beschneiden', 0.01, GH),
        P('HOLIDAY_CROP_X', 'Fest-Symbol Ausschnitt in Textur X', 0.01, GH),
        P('HOLIDAY_CROP_Y', 'Fest-Symbol Ausschnitt in Textur Y', 0.01, GH),
        P('HOLIDAY_ICON_DESAT', 'Fest-Symbol entsättigen (1/0)', 1, GH),
        P('HOLIDAY_ICON_R', 'Fest-Symbol Rot', 0.05, GH),
        P('HOLIDAY_ICON_G', 'Fest-Symbol Grün', 0.05, GH),
        P('HOLIDAY_ICON_B', 'Fest-Symbol Blau', 0.05, GH),
        P('HOLIDAY_OVERLAY_SIZE', 'Fest-Dekoration Größe', 0.5, GH),
        P('HOLIDAY_OVERLAY_X', 'Fest-Dekoration X', 0.5, GH),
        P('HOLIDAY_OVERLAY_Y', 'Fest-Dekoration Y', 0.5, GH),
        P('HOLIDAY_OVERLAY_ALPHA', 'Fest-Dekoration Deckkraft', 0.05, GH),
        { key = 'HOLIDAY_GENERIC_ICON', label = 'Allgemeines Kalender-Symbol (ID oder Pfad)', text = true, group = GH },
        P('HOLIDAY_TIP_ICON_SIZE', 'Fest-Symbol Größe im Tooltip', 1, GP),
        P('HOLIDAY_TIP_ICON_Y', 'Fest-Symbol Y im Tooltip (oben +)', 1, GP),
        P('BADGE_DISC', 'Symbol Scheibe', 0.5, GL),
        P('BADGE_ICON', 'Symbol Icon', 0.5, GL),
        P('BADGE_RING_SCALE', 'Symbol Ring Skalierung', 0.01, GL),
        P('BADGE_RING', 'Ring zeigen (1/0)', 1, GL),
        P('BADGE_R', 'Farbe Rot', 0.05, GL),
        P('BADGE_G', 'Farbe Grün', 0.05, GL),
        P('BADGE_B', 'Farbe Blau', 0.05, GL),
        P('TEXT_SIZE', 'Größe (ohne Timer)', 0.5, G7),
        P('TEXT_SIZE_CD', 'Größe (mit Timer)', 0.5, G7),
        P('TEXT_MAXW', 'Maximale Breite', 1, G7),
        P('TEXT_X', 'X', 0.5, G7),
        P('TEXT_Y', 'Y (ohne Timer)', 0.5, G7),
        P('TEXT_Y_CD', 'Y (mit Timer)', 0.5, G7),
        P('CD_SIZE', 'Größe', 0.5, G8),
        P('CD_MAXW', 'Maximale Breite', 1, G8),
        P('CD_X', 'X', 0.5, G8),
        P('CD_Y', 'Y', 0.5, G8),
        { key = 'CD_SUFFIX_MIN', label = 'Text hinter Minuten (leer = Sprache)', text = true, group = G8 },
        { key = 'CD_SUFFIX_SEC', label = 'Text hinter Sekunden (leer = Sprache)', text = true, group = G8 },
        { key = 'CD_SUFFIX_HRS', label = 'Text hinter Stunden (leer = Sprache)', text = true, group = G8 },
        P('TIMER_WARN_SEC', 'Warnung ab Restsekunden', 1, G9),
        { key = 'TIMER_WARN_GLOW', label = 'Glow-Spec', text = true, group = G9 },
        P('SMALL_DOTS', 'Punkte Größe (größer = weiter außen)', 0.5, G11),
        P('SMALL_HOUR_LEN', 'Stundenzeiger Länge', 0.25, G11),
        P('SMALL_HOUR_W', 'Stundenzeiger Dicke', 0.25, G11),
        P('SMALL_MIN_LEN', 'Minutenzeiger Länge', 0.25, G11),
        P('SMALL_MIN_W', 'Minutenzeiger Dicke', 0.25, G11),
        P('SMALL_DX', 'Mitte X', 0.25, G11),
        P('SMALL_DY', 'Mitte Y', 0.25, G11),
        P('LOGO_X', 'Logo X (rechts +)', 0.5, G10),
        P('LOGO_Y', 'Logo Höhe (oben +)', 0.5, G10),
        P('DIAMOND_X', 'Abstand von der Mitte', 0.5, G10),
        P('DIAMOND_Y', 'Höhe (oben +)', 0.5, G10),
        P('DIAMOND_SIZE', 'Größe', 0.5, G10),
        P('DIAMOND_DESAT', 'Entsättigen zu Grau (1/0)', 1, G10),
        P('DIAMOND_R', 'Farbe Rot', 0.05, G10),
        P('DIAMOND_G', 'Farbe Grün', 0.05, G10),
        P('DIAMOND_B', 'Farbe Blau', 0.05, G10),
        P('OPT_CLOCK_DX', 'Kreis X zur Eckenmitte (rechts +)', 0.5, G12),
        P('OPT_CLOCK_DY', 'Kreis Y zur Eckenmitte (oben +)', 0.5, G12),
        P('OPT_CLOCK_SIZE', 'Kreis Durchmesser', 0.5, G12),
        P('OPT_TIME_SIZE', 'Schriftgröße', 0.5, G13),
        P('OPT_TIME_DX', 'Uhrzeit X', 0.5, G13),
        P('OPT_TIME_DY', 'Uhrzeit Y', 0.5, G13),
        P('OPT_CLOSE_X', 'X: Versatz rechts (rechts +)', 0.5, G14),
        P('OPT_CLOSE_Y', 'X: Versatz oben (oben +)', 0.5, G14),
        P('OPT_CLOSE_SIZE', 'X: Größe', 0.5, G14),
        P('OPT_TITLE_X', 'Name X (von links)', 0.5, G15),
        P('OPT_TITLE_Y', 'Name Y (von oben, negativ)', 0.5, G15),
        P('OPT_TAGLINE_DY', 'Untertitel Abstand zum Namen', 0.5, G15),
        P('OPT_CONTENT_TOP', 'Inhalt beginnt (Abstand von oben)', 1, G15),
        P('ROW_PLAY_SIZE', 'Pfeil (Start/Stopp) Größe', 0.5, G16),
        P('ROW_PLAY_X', 'Pfeil X (rechts +)', 0.5, G16),
        P('ROW_PLAY_Y', 'Pfeil Y (oben +)', 0.5, G16),
        P('ROW_EDIT_SIZE', 'Zahnrad Größe', 0.5, G16),
        P('ROW_EDIT_X', 'Zahnrad X (rechts +)', 0.5, G16),
        P('ROW_EDIT_Y', 'Zahnrad Y (oben +)', 0.5, G16),
        P('ROW_DEL_SIZE', 'Papierkorb Größe', 0.5, G16),
        P('ROW_DEL_X', 'Papierkorb X (rechts +)', 0.5, G16),
        P('ROW_DEL_Y', 'Papierkorb Y (oben +)', 0.5, G16),
    },
    -- Einzelwerte wirken nur auf der Testbühne; apply(nil) (Laden/Zurücksetzen) auch auf der Uhr.
    apply = function(key)
        RememberBase(key)
        if not key then Clock:ApplyClockArt(); Clock:UpdateClock() end
        Clock:RefreshStage()
        if key and (key:find('^SMALL_') or key:find('^BADGE_FRAME_') or key:find('_ICON_SIZE$') or key:find('_FRAME_SIZE$') or key == 'ALARM_SCALE' or key == 'TIMER_SCALE' or key:find('_ICON_') or key:find('^ALARM_ARMED_')) then Clock:UpdateClock(); Clock:UpdateBadges() end
        if not key or key:find('^HOLIDAY_') or key:find('^ALARM_') or key:find('^TIMER_') or key:find('^BADGE_') then Clock:RefreshHolidayBadge() end
        if not key or key:find('^DIAMOND_') or key:find('^LOGO_') then Clock:RefreshDiamonds() end
        if not key or key:find('^OPT_') then Clock:ApplyOptionsLayout() end
        if not key or key:find('^ROW_') then if Clock.RefreshRowIcons then Clock:RefreshRowIcons() end end
    end,
    onOpen = function() Clock:ToggleStage(true) end,
    onClose = function() Clock:ToggleStage(false); Clock.holidayPreview, Clock.holidayPreviewIcon = nil, nil; Clock:RefreshHolidayBadge() end,
    actions = {
        { label = 'Auf Uhr anwenden', fn = function() Clock:ApplyClockArt(); Clock:UpdateClock() end },
        { label = 'Glow auf Bühne', input = '3399FF, pulse, 1, 90, ring, 95px, native', fn = function(spec)
            if spec == '' or spec:lower() == 'off' then spec = nil end
            if spec and not Clock:ParseGlowSpec(spec) then Clock:Print('Ungültiger Glow') return end
            Clock:SetStageGlow(spec)
        end },
        { label = 'Glow aus', fn = function() Clock:SetStageGlow(nil) end },
        { label = 'Fest-Symbol Vorschau', fn = function() Clock.holidayPreview = not Clock.holidayPreview or nil; Clock:RefreshHolidayBadge() end },
        { label = 'Nächstes Symbol', fn = function() StepPreviewIcon(1) end },
        { label = 'Vorheriges Symbol', fn = function() StepPreviewIcon(-1) end },
        { label = 'Stil für dieses Symbol speichern', fn = SaveStyle },
        { label = 'Stil dieses Symbols entfernen', fn = function()
            if Clock.holidayPreviewIcon then STYLES[Clock.holidayPreviewIcon] = nil; Clock:RefreshHolidayBadge() end
        end },
        { label = 'Stile ausgeben (kopieren)', fn = PrintStyles },
        { label = 'Symbol setzen (ID oder Pfad)', input = '235462', fn = function(spec)
            Clock.holidayPreview, Clock.holidayPreviewIcon = true, tonumber(spec) or spec
            LoadStyle(Clock.holidayPreviewIcon)
            Clock:RefreshHolidayBadge()
        end },
        { label = 'Optionsfenster öffnen', fn = function() Clock:OpenSettings('general') end },
    },
    extra = function()
        return string.format('-- Uhrgröße %s px', tostring(Clock:GetClockDiameter()))
    end,
})
