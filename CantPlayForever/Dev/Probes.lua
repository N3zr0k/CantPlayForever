-- BugLab-Probes für Can't play Forever (nur im Repo, nicht im Release-ZIP; siehe .pkgmeta).
-- Die Logik liegt im Addon (Dev/FrameDump.lua, Dev/HolidayList.lua, Core, Glow); hier werden die
-- Proben nur angemeldet. Start, Beenden und Protokoll übernimmt BugLab (Reiter Probe, /buglab probe).
-- Ohne BugLab tut die Datei nichts.
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
local BugLab = _G.BugLab
if not (Clock and BugLab and BugLab.RegisterProbe) then return end
local ADDON = 'CantPlayForever'

-- Ring-Atlas prüfen und Vorschau ein-/ausblenden
BugLab:RegisterProbe(ADDON, 'ring', {
    title = 'Ring-Vorschau',
    desc = 'Prüft den Ring-Atlas und zeigt Atlas, Ring mit/ohne Maske und Globus auf dunklem Grund.',
    mode = 'toggle',
    run = function(ctx)
        local info = Clock.RingAtlasInfo and Clock.RingAtlasInfo()
        if info then
            ctx.log:Info('Atlas %s: %sx%s', tostring(Clock.RING_ATLAS), tostring(info.width), tostring(info.height))
        else
            ctx.log:Warn('Atlas %s: nicht vorhanden', tostring(Clock.RING_ATLAS))
        end
        if not (Clock.ringPreview and Clock.ringPreview:IsShown()) then Clock:ToggleRingPreview() end
    end,
    stop = function()
        if Clock.ringPreview then Clock.ringPreview:Hide() end
    end,
})

-- Leuchten um die Uhr (Schlüssel 'probe', Priorität 100)
BugLab:RegisterProbe(ADDON, 'glow', {
    title = 'Leuchten',
    desc = 'Zeigt das Leuchten um die Uhr, bis es beendet wird.',
    mode = 'toggle',
    params = {
        { key = 'farbe', type = 'color', label = 'Farbe', default = 'FF8000' },
        { key = 'modus', type = 'choice', label = 'Modus', values = { 'static', 'pulse', 'blink' }, default = 'pulse' },
        { key = 'sek', type = 'number', label = 'Sekunden je Takt (pulse, blink)', default = 2 },
        { key = 'prozent', type = 'number', label = 'Deckkraft in Prozent', default = 55 },
    },
    run = function(ctx, p)
        local parts = { p.farbe, p.modus }
        if p.modus ~= 'static' then parts[#parts + 1] = tostring(p.sek) end
        parts[#parts + 1] = tostring(p.prozent)
        local spec = table.concat(parts, ', ')
        if Clock:SetGlow('probe', spec, 100) then
            ctx.log:Info('Leuchten: %s', spec)
        else
            ctx.log:Error('Ungültige Angabe: %s (Format: FARBCODE, static|pulse|blink, [Sekunden,] Prozent)', spec)
        end
    end,
    stop = function()
        Clock:ClearGlow('probe')
    end,
})

-- Alarmmeldung samt Leuchten und Ton
BugLab:RegisterProbe(ADDON, 'alert', {
    title = 'Testalarm',
    desc = 'Löst die Alarmmeldung samt Leuchten und Ton aus.',
    mode = 'once',
    params = {
        { key = 'text', type = 'text', label = 'Text', default = 'Testalarm' },
    },
    run = function(ctx, p)
        Clock:Alert(p.text)
        ctx.log:Info('Alarmmeldung ausgelöst: %s', p.text)
    end,
})

-- Rahmen-Diagnose des Optionsfensters
BugLab:RegisterProbe(ADDON, 'frame', {
    title = 'Rahmen-Diagnose',
    desc = 'Texturen des Optionsfensters im Log, Ecke 4-fach vergrößert. Optionen (/cpf) vorher öffnen.',
    mode = 'toggle',
    run = function(ctx)
        Clock:DumpOptionsFrame(ctx.log)
    end,
    stop = function()
        Clock:HideCornerPreview()
    end,
})

-- Kalender-Feste eines Jahres auslesen
if Clock.CollectHolidays then
    BugLab:RegisterProbe(ADDON, 'holidays', {
        title = 'Kalender-Feste',
        desc = 'Liest alle Feste eines Jahres aus (dauert ca. 10 Sekunden) und schreibt sie ins Probe-Log.',
        mode = 'once',
        params = {
            { key = 'jahr', type = 'number', label = 'Jahr', optional = true },
        },
        run = function(ctx, p)
            Clock:CollectHolidays(p.jahr, ctx.log)
        end,
    })
end
