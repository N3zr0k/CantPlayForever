-- Modul "Wellness": geplant, noch nicht umgesetzt. Der Eintrag erscheint gesperrt unter
-- Optionen > Module; die Umsetzung kommt in dieses Verzeichnis.
local ADDON_NAME, ns = ...
if not ns.Clock then return end

ns.Clock:RegisterModule({
    id = 'wellness',
    logo = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\pause_logo',
    -- weiteres Bild für Pausen: Media/Logos/pausen_logo.tga
    available = false,
})
