-- Modul "Statistics": geplant, noch nicht umgesetzt. Der Eintrag erscheint gesperrt unter
-- Optionen > Module; die Umsetzung kommt in dieses Verzeichnis.
local ADDON_NAME, ns = ...
if not ns.Clock then return end

ns.Clock:RegisterModule({
    id = 'stats',
    available = false,
})
