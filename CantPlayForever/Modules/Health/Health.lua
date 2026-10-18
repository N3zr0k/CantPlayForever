-- Health: eigenes, optionales Modul; die Bewegungsfunktion ist die erste Ausbaustufe.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

Clock:RegisterModule({
    id = 'health',
    logo = 'Interface\\AddOns\\CantPlayForever\\Media\\Logos\\pause_logo',
    OnEnable = function(self) self:SyncHealthMovement() end,
    -- OnChanged wird auch für ausgeschaltete Module aufgerufen: Laufzeitstatus
    -- beim Umschalten über Allgemein > Module sofort starten bzw. zurücksetzen.
    OnChanged = function(self) self:SyncHealthMovement() end,
    OnRefresh = function(self) self:ResetHealthMovement() end,
    OnTick = function(self) self:TickHealthMovement() end,
    GetOptions = function() return ns.HealthOptions() end,
})
