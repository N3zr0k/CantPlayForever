-- Die Standard-Uhr von Blizzard an der Minimap wird ausgeblendet, solange unsere Uhr aktiv ist (Option
-- unter Uhr, standardmäßig an; ist unsere Uhr abgeschaltet, bleibt die von Blizzard sichtbar). Das Bild gehört Blizzard; es wird
-- nur versteckt und bei Show() sofort wieder versteckt, solange die Option an ist. Die Uhr kommt aus
-- Blizzard_TimeManager (wird erst nach dem Start geladen), deshalb auch auf ADDON_LOADED lauschen.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

-- Ausblenden gilt nur, solange unsere Uhr sichtbar ist; ist sie aus, zeigt Blizzard seine wieder.
local function ShouldHide()
    local db = Clock.db and Clock.db.profile
    return db and db.hideBlizzardClock ~= false and not (db.minimap and db.minimap.hide) or false
end
Clock.ShouldHideBlizzardClock = ShouldHide

local function BlizzardClockFrames()
    local frames = {}
    if _G.TimeManagerClockButton then frames[#frames + 1] = _G.TimeManagerClockButton end
    local cluster = _G.MinimapCluster
    if cluster and cluster.Clock then frames[#frames + 1] = cluster.Clock end
    return frames
end

function Clock:ApplyBlizzardClock()
    local hide = ShouldHide()
    for _, frame in ipairs(BlizzardClockFrames()) do
        if not frame.cpfHooked then
            frame.cpfHooked = true
            hooksecurefunc(frame, 'Show', function(shown)
                if ShouldHide() then shown:Hide() end
            end)
        end
        if hide then
            if frame:IsShown() then frame.cpfHidden = true end
            frame:Hide()
        elseif frame.cpfHidden then
            frame.cpfHidden = nil
            -- Wie Blizzard: nur zeigen, wenn die Spieleinstellung "Uhr anzeigen" an ist.
            local cvar = type(_G.GetCVar) == 'function' and _G.GetCVar('showMinimapClock')
            if cvar ~= '0' then frame:Show() end
        end
    end
end

-- Blizzards Stoppuhr (Blizzard_TimeManager, Stopwatch_Toggle) öffnen oder schließen.
function Clock:ToggleStopwatch()
    if type(_G.Stopwatch_Toggle) ~= 'function' then
        local load = (_G.C_AddOns and _G.C_AddOns.LoadAddOn) or _G.LoadAddOn
        if load then pcall(load, 'Blizzard_TimeManager') end
    end
    if type(_G.Stopwatch_Toggle) == 'function' then
        _G.Stopwatch_Toggle()
    else
        self:Print(ns.L.STOPWATCH_MISSING)
    end
end

-- Blizzards Uhren-Menü (Fenster der Standard-Uhr: Alarm, 24-Stunden-Anzeige, Ortszeit) öffnen/schließen.
function Clock:ToggleBlizzardClockMenu()
    if type(_G.TimeManager_Toggle) ~= 'function' then
        local load = (_G.C_AddOns and _G.C_AddOns.LoadAddOn) or _G.LoadAddOn
        if load then pcall(load, 'Blizzard_TimeManager') end
    end
    if type(_G.TimeManager_Toggle) == 'function' then
        _G.TimeManager_Toggle()
    else
        self:Print(ns.L.BLIZZARD_CLOCK_MENU_MISSING)
    end
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent', function(_, event, addon)
    if event == 'ADDON_LOADED' and addon ~= 'Blizzard_TimeManager' then return end
    Clock:ApplyBlizzardClock()
end)
