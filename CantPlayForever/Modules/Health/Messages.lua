-- Lokalisierte Erinnerungstexte: feste Titel/Text-Paare je Kategorie.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local L = ns.L

-- Die Paare werden erst beim Aufruf aus der Lokalisierung gelesen.
local MOVE_COUNT, DRINK_COUNT, EYES_COUNT, EYES_VARIANTS = 10, 10, 6, 2

-- Liefert Titel und Text einer Standard-Erinnerung.
function ns.HealthReminderEntry(category)
    if category == 'movement' then
        local i = math.random(MOVE_COUNT)
        return L['HEALTH_MOVE_TITLE_' .. i], L['HEALTH_MOVE_MESSAGE_' .. i]
    elseif category == 'drinking' then
        local i = math.random(DRINK_COUNT)
        return L['HEALTH_DRINK_TITLE_' .. i], L['HEALTH_DRINK_MESSAGE_' .. i]
    elseif category == 'eyes' then
        local i = math.random(EYES_COUNT)
        return L['HEALTH_EYES_NAME_' .. i], L['HEALTH_EYES_MESSAGE_' .. i .. '_' .. math.random(EYES_VARIANTS)]
    end
end

-- Quellen der Standardtexte; sie werden nur zu Standardtexten angezeigt.
local SOURCES = {
    movement = {'https://gesund.bund.de/gesund-durch-bewegung'},
    drinking = {
        'https://www.dge.de/gesunde-ernaehrung/gut-essen-und-trinken/dge-ernaehrungskreis/getraenke/',
        'https://www.bzfe.de/einfache-sprache/gut-essen/warum-ist-trinken-so-wichtig',
    },
    eyes = {'https://www.dak.de/dak/gesundheit/bewegung-und-sport/bewegungstipps/augen-entspannen-das-sind-unsere-lieblingsuebungen_15250'},
}

function ns.HealthSourceText(category)
    local urls = SOURCES[category]
    if not urls then return nil end
    return L.HEALTH_SOURCE .. ' ' .. table.concat(urls, '\n')
end

function ns.HealthReminderMessage(category)
    local _, message = ns.HealthReminderEntry(category)
    return message or ''
end

-- Benutzerdefinierte Texte werden ausschliesslich bei aktivierter Kategorieoption verwendet.
-- Im gemischten Modus werden die beiden Quellen bei jeder Erinnerung 50:50 gewichtet,
-- auch wenn eine Quelle mehr Textvarianten enthaelt.
-- Rueckgabe: Text und (nur bei Standardtexten) der passende Titel.
function ns.HealthChooseMessage(category, settings)
    if settings and settings.customMessagesEnabled == true then
        local available = {}
        for _, entry in ipairs(settings.customMessages or {}) do
            if type(entry) == 'table' and entry.enabled ~= false
                and type(entry.text) == 'string' and entry.text:match('%S') then
                available[#available + 1] = entry.text
            end
        end
        if #available > 0 and (settings.mixWithDefault ~= true or math.random(2) == 1) then
            return available[math.random(#available)]
        end
    end
    local title, message = ns.HealthReminderEntry(category)
    return message, title
end
