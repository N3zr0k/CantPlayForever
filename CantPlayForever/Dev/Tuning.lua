-- Entwicklungs-Anbindung an den Frame Debugger (nur im Repo, nicht im Release-ZIP; siehe .pkgmeta).
-- Das Addon liefert dem Frame Debugger seine Tuning-Werte, Gruppen, Anwenden-Logik und Aktionen
-- selbst; der Frame Debugger stellt nur die Oberfläche bereit. Ohne Frame Debugger tut die Datei nichts.
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
if not (Clock and _G.FrameDebugger and Clock.tune) then return end

local function P(key, label, step, group) return { key = key, label = label, step = step, group = group } end
local G0, G1, G2, G3, G4, G5, G6, G7, G8, G9 = 'Testbühne', 'Ring (Atlas-Ausschnitt)', 'Ring-Maske', 'Globus-Maske',
    'Schatten', 'Glow', 'Indikator-Symbole (Glocke / Uhr)', 'Uhrzeit-Text', 'Timer-Zahl', 'Timer-Warnleuchten'
local G11 = 'Kleine Uhr (Standardrahmen)'
local G10 = 'Optionen-Logo und Rauten (nur ohne Blizzard-Rahmen; Optionen-Fenster offen lassen)'
local G16 = 'Optionsfenster: Listen-Symbole (Pfeil, Zahnrad, Papierkorb; Optionen mit Timer/Alarmen offen lassen)'
local G12, G13, G14, G15 = 'Optionsfenster: Uhrenkreis in der Ecke', 'Optionsfenster: Uhrzeit',
    'Optionsfenster: rotes X', 'Optionsfenster: Name, Untertitel, Inhalt'

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
        P('BADGE_SIZE', 'Symbol Rahmen', 0.5, G6),
        P('BADGE_DISC', 'Symbol Scheibe', 0.5, G6),
        P('BADGE_ICON', 'Symbol Icon', 0.5, G6),
        P('BADGE_RING_SCALE', 'Symbol Ring Skalierung', 0.01, G6),
        P('BADGE_RING', 'Ring zeigen (1/0)', 1, G6),
        P('BADGE_R', 'Farbe Rot', 0.05, G6),
        P('BADGE_G', 'Farbe Grün', 0.05, G6),
        P('BADGE_B', 'Farbe Blau', 0.05, G6),
        P('ALARM_SCALE', 'Glocke Faktor', 0.05, G6),
        P('TIMER_SCALE', 'Uhr Faktor', 0.05, G6),
        P('ALARM_X', 'Glocke X', 0.5, G6),
        P('ALARM_Y', 'Glocke Y', 0.5, G6),
        P('TIMER_X', 'Uhr X', 0.5, G6),
        P('TIMER_Y', 'Uhr Y', 0.5, G6),
        P('TIMER_ICON_SIZE', 'Timer-Symbol Bildgröße', 0.5, G6),
        P('TIMER_FRAME_SIZE', 'Timer-Symbol Rahmengröße', 0.5, G6),
        P('ALARM_ICON_SIZE', 'Alarm-Symbol Bildgröße', 0.5, G6),
        P('ALARM_FRAME_SIZE', 'Alarm-Symbol Rahmengröße', 0.5, G6),
        P('BADGE_FRAME_DESAT', 'Symbol-Rahmen entsättigen (1/0)', 1, G6),
        P('BADGE_FRAME_R', 'Symbol-Rahmen Rot', 0.05, G6),
        P('BADGE_FRAME_G', 'Symbol-Rahmen Grün', 0.05, G6),
        P('BADGE_FRAME_B', 'Symbol-Rahmen Blau', 0.05, G6),
        P('TIMER_ICON_DESAT', 'Timer-Symbol entsättigen (1/0)', 1, G6),
        P('TIMER_ICON_R', 'Timer-Symbol Rot', 0.05, G6),
        P('TIMER_ICON_G', 'Timer-Symbol Grün', 0.05, G6),
        P('TIMER_ICON_B', 'Timer-Symbol Blau', 0.05, G6),
        P('ALARM_ARMED_R', 'Alarm-Symbol aktiviert Rot', 0.05, G6),
        P('ALARM_ARMED_G', 'Alarm-Symbol aktiviert Grün', 0.05, G6),
        P('ALARM_ARMED_B', 'Alarm-Symbol aktiviert Blau', 0.05, G6),
        P('ALARM_ICON_DESAT', 'Alarm-Symbol entsättigen (1/0)', 1, G6),
        P('ALARM_ICON_R', 'Alarm-Symbol Rot', 0.05, G6),
        P('ALARM_ICON_G', 'Alarm-Symbol Grün', 0.05, G6),
        P('ALARM_ICON_B', 'Alarm-Symbol Blau', 0.05, G6),
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
        P('TIMER_WARN_SEC', 'Warnung ab Restsekunden', 1, G9),
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
        { key = 'TIMER_WARN_GLOW', label = 'Glow-Spec', text = true, group = G9 },
        { key = 'CD_SUFFIX_MIN', label = 'Text hinter Minuten (leer = Sprache)', text = true, group = G8 },
        { key = 'CD_SUFFIX_SEC', label = 'Text hinter Sekunden (leer = Sprache)', text = true, group = G8 },
        { key = 'CD_SUFFIX_HRS', label = 'Text hinter Stunden (leer = Sprache)', text = true, group = G8 },
    },
    -- Einzelwerte wirken nur auf der Testbühne; apply(nil) (Laden/Zurücksetzen) auch auf der Uhr.
    apply = function(key)
        if not key then Clock:ApplyClockArt(); Clock:UpdateClock() end
        Clock:RefreshStage()
        if key and (key:find('^SMALL_') or key:find('^BADGE_FRAME_') or key:find('_ICON_SIZE$') or key:find('_FRAME_SIZE$') or key == 'ALARM_SCALE' or key == 'TIMER_SCALE' or key:find('_ICON_') or key:find('^ALARM_ARMED_')) then Clock:UpdateClock(); Clock:UpdateBadges() end
        if not key or key:find('^DIAMOND_') or key:find('^LOGO_') then Clock:RefreshDiamonds() end
        if not key or key:find('^OPT_') then Clock:ApplyOptionsLayout() end
        if not key or key:find('^ROW_') then if Clock.RefreshRowIcons then Clock:RefreshRowIcons() end end
    end,
    onOpen = function() Clock:ToggleStage(true) end,
    onClose = function() Clock:ToggleStage(false) end,
    actions = {
        { label = 'Auf Uhr anwenden', fn = function() Clock:ApplyClockArt(); Clock:UpdateClock() end },
        { label = 'Glow auf Bühne', input = '3399FF, pulse, 1, 90, ring, 95px, native', fn = function(spec)
            if spec == '' or spec:lower() == 'off' then spec = nil end
            if spec and not Clock:ParseGlowSpec(spec) then Clock:Print('Ungültiger Glow') return end
            Clock:SetStageGlow(spec)
        end },
        { label = 'Glow aus', fn = function() Clock:SetStageGlow(nil) end },
        { label = 'Optionsfenster öffnen', fn = function() Clock:OpenSettings('general') end },
    },
    extra = function()
        return string.format('-- Uhrgröße %s px', tostring(Clock:GetClockDiameter()))
    end,
})
