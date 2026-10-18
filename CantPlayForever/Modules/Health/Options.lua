-- Health: alle Bereiche separat konfigurierbar; Bewegung ist bereits aktiv.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

local function HealthSettings() return Clock.db.profile.health end

local function EnabledOption(id, name, description, order)
    return {
        type = 'toggle', name = name, desc = description, order = order, width = 'full',
        get = function() return HealthSettings()[id].enabled == true end,
        set = function(_, value)
            HealthSettings()[id].enabled = value == true
            Clock:NotifyOptions()
        end,
    }
end

local function IntervalOption(id, name, order, maximum)
    return {
        type = 'range', name = name, order = order, width = 'full',
        min = 5, max = maximum, step = 5,
        get = function() return HealthSettings()[id].interval end,
        set = function(_, value)
            HealthSettings()[id].interval = value
            Clock:NotifyOptions()
        end,
    }
end

-- Pro Kategorie das gleiche Darstellungspanel wie bei individuellen Alarmen.
-- Ohne Haken verwendet die Kategorie die Werte aus Optionen > Effekte > Health.
local function CategoryEffectArgs(id)
    local function Override() return Clock:GetHealthEffectOverride(id) end
    return {
        customEffect = {
            type = 'toggle', name = L.HEALTH_CUSTOM_EFFECT,
            desc = L.HEALTH_CUSTOM_EFFECT_DESC, order = 20, width = 'full',
            get = function() return HealthSettings()[id].customEffect == true end,
            set = function(_, enabled)
                Clock:SetHealthCustomEffect(id, enabled)
                Clock:NotifyOptions()
            end,
        },
        appearance = {
            type = 'group', name = L.EFFECT_APPEARANCE, inline = true,
            order = 21, hidden = function() return HealthSettings()[id].customEffect ~= true end,
            args = (function()
                local controls = ns.EffectAppearanceArgs('health', Override,
                    function() return HealthSettings()[id].customEffect ~= true end)
                -- Icon-Einstellungen gehören zum selben individuellen Darstellungsrahmen.
                for key, option in pairs(ns.HealthIconAppearanceArgs(id)) do
                    controls[key] = option
                end
                controls.preview = {
                    type = 'execute', name = L.EFFECT_TEST_NOW, order = 20,
                    disabled = function() return not Clock:GetEffectConfig('health').screenGlow end,
                    func = function() Clock:PreviewHealthEffect(id) end,
                }
                return controls
            end)(),
        },
    }
end

-- Eigenen Text anlegen/bearbeiten/deaktivieren/loeschen wie die Alarmliste.
-- Nur tatsaechlich gespeicherte Eintraege werden in AceDB persistiert; kein Default-Array.
local textEditorOpen, textEditorInput, newTextOpen, newTextInput = {}, {}, {}, {}

local function CleanText(text)
    if type(text) ~= 'string' then return '' end
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function CategoryTextArgs(id)
    local function Settings() return HealthSettings()[id] end
    local function Items() return Settings().customMessages or {} end
    local function Updated() Clock:NotifyOptions() end
    local args = {
        mixWithDefault = {
            type = 'toggle', name = L.HEALTH_CUSTOM_TEXTS_MIX,
            desc = L.HEALTH_CUSTOM_TEXTS_MIX_DESC, order = 2, width = 'full',
            hidden = function() return Settings().customMessagesEnabled ~= true end,
            get = function() return Settings().mixWithDefault == true end,
            set = function(_, value) Settings().mixWithDefault = value == true; Updated() end,
        },
        info = {type = 'description',
            name = '|cff999999' .. L.HEALTH_CUSTOM_TEXTS_EMPTY_FALLBACK .. '|r',
            order = 3, width = 'full'},
        -- Wie bei Alarmen bleibt der Button kompakt. Die folgende Ueberschrift
        -- eroeffnet eine neue Zeile, sodass keine Text-Icons neben ihm landen.
        new = {type = 'execute', name = L.HEALTH_NEW_TEXT, order = 5,
            func = function()
                newTextOpen[id] = not newTextOpen[id]
                if newTextOpen[id] then newTextInput[id] = '' end
                Updated()
            end},
        newBox = {
            type = 'group', inline = true, name = L.HEALTH_NEW_TEXT, order = 6,
            hidden = function() return not newTextOpen[id] end,
            args = {
                message = {type = 'input', name = L.HEALTH_TEXT, order = 1,
                    width = 'full', multiline = 4, dialogControl = 'CPFHealthTextEditor',
                    get = function() return newTextInput[id] or '' end,
                    set = function(_, value) newTextInput[id] = value end},
                save = {type = 'execute', name = L.HEALTH_SAVE_TEXT, order = 2,
                    func = function()
                        local text = CleanText(newTextInput[id])
                        if text == '' then return end
                        local setting = Settings()
                        -- Beim ersten Schreiben initialisieren: geloeschte Texte duerfen
                        -- von AceDB-Defaults nicht wieder auftauchen.
                        if type(setting.customMessages) ~= 'table' then setting.customMessages = {} end
                        local maxID = 0
                        for _, item in ipairs(setting.customMessages) do
                            maxID = math.max(maxID, tonumber(item.id) or 0)
                        end
                        local nextID = math.max(tonumber(setting.nextCustomMessageID) or 1, maxID + 1)
                        setting.customMessages[#setting.customMessages + 1] = {
                            id = nextID, text = text, enabled = true,
                        }
                        setting.nextCustomMessageID = nextID + 1
                        newTextOpen[id], newTextInput[id] = nil, nil
                        Updated()
                    end},
                cancel = {type = 'execute', name = L.HEALTH_CANCEL_TEXT, order = 3,
                    func = function() newTextOpen[id], newTextInput[id] = nil, nil; Updated() end},
            },
        },
        savedHeader = {type = 'header', name = L.HEALTH_SAVED_TEXTS, order = 10, width = 'full'},
    }
    if #Items() == 0 then
        args.empty = {type = 'description', name = L.HEALTH_NO_CUSTOM_TEXTS,
            order = 11, width = 'full'}
    end
    for index, item in ipairs(Items()) do
        if type(item) == 'table' then
            local entry = item
            local entryID = tonumber(entry.id) or index
            local key = 'text_' .. tostring(entryID) .. '_' .. tostring(index)
            local base = 100 + index * 10
            if index > 1 then
                args[key .. '_divider'] = {type = 'header', name = '', order = base}
            end
            args[key .. '_enabled'] = {
                type = 'toggle', name = '', order = base + 1, width = 0.14,
                desc = L.HEALTH_TEXT_ENABLED_DESC,
                get = function() return entry.enabled ~= false end,
                set = function(_, value) entry.enabled = value == true; Updated() end,
            }
            args[key .. '_edit'] = {
                type = 'execute', name = '', order = base + 2, width = 0.147,
                desc = L.HEALTH_EDIT_TEXT, image = ns.RowIcon('edit_gear'),
                imageWidth = 18, imageHeight = 18,
                func = function()
                    if textEditorOpen[id] == entry then
                        textEditorOpen[id], textEditorInput[id] = nil, nil
                    else
                        textEditorOpen[id] = entry
                        textEditorInput[id] = entry.text or ''
                    end
                    Updated()
                end,
            }
            args[key .. '_delete'] = {
                type = 'execute', name = '', order = base + 2.5, width = 0.147,
                desc = L.HEALTH_DELETE_TEXT, image = ns.RowIcon('delete_bin'),
                imageWidth = 18, imageHeight = 18,
                confirm = function() return L.HEALTH_DELETE_TEXT_CONFIRM end,
                func = function()
                    for i, stored in ipairs(Items()) do
                        if stored == entry then table.remove(Items(), i); break end
                    end
                    if textEditorOpen[id] == entry then
                        textEditorOpen[id], textEditorInput[id] = nil, nil
                    end
                    Updated()
                end,
            }
            args[key .. '_summary'] = {
                type = 'description', order = base + 3, width = 2.5, fontSize = 'medium',
                name = function()
                    local summary = (entry.text or ''):gsub('[\r\n]+', ' '):gsub('|', '||')
                    if #summary > 90 then summary = summary:sub(1, 87) .. '...' end
                    summary = '  ' .. summary -- Abstand nach dem Papierkorb wie bei Alarmen
                    return entry.enabled == false and '|cff888888' .. summary .. '|r' or '|cff55ff55' .. summary .. '|r'
                end,
            }
            args[key .. '_mask'] = {
                type = 'group', inline = true, name = L.HEALTH_EDIT_TEXT,
                order = base + 4, hidden = function() return textEditorOpen[id] ~= entry end,
                args = {
                    message = {type = 'input', name = L.HEALTH_TEXT, order = 1,
                        width = 'full', multiline = 4, dialogControl = 'CPFHealthTextEditor',
                        get = function() return textEditorInput[id] or '' end,
                        set = function(_, value) textEditorInput[id] = value end},
                    save = {type = 'execute', name = L.HEALTH_SAVE_TEXT, order = 2,
                        func = function()
                            local text = CleanText(textEditorInput[id])
                            if text == '' then return end
                            entry.text = text
                            textEditorOpen[id], textEditorInput[id] = nil, nil
                            Updated()
                        end},
                    cancel = {type = 'execute', name = L.HEALTH_CANCEL_TEXT, order = 3,
                        func = function()
                            textEditorOpen[id], textEditorInput[id] = nil, nil
                            Updated()
                        end},
                },
            }
        end
    end
    return {type = 'group', inline = true, name = L.HEALTH_CUSTOM_TEXTS,
        order = 10,
        hidden = function() return HealthSettings()[id].customMessagesEnabled ~= true end,
        args = args}
end

local function CategoryGroup(id, label, description, intervalLabel, maximum, order)
    local args = {
        intro = {type = 'description', name = '|cff999999' .. description .. '|r',
            order = 1, width = 'full'},
        [id] = EnabledOption(id, label, description, 2),
        interval = IntervalOption(id, intervalLabel, 3, maximum),
    }
    if id == 'movement' then
        args.movementTest = {
            type = 'execute', name = L.HEALTH_TEST_NOW, order = 4,
            disabled = function() return not HealthSettings().movement.enabled end,
            func = function() Clock:ShowHealthMovement() end,
        }
    else
        args.categoryTest = {
            type = 'execute', name = L.HEALTH_TEST_CATEGORY, order = 4,
            disabled = function() return not HealthSettings()[id].enabled end,
            func = function() Clock:ShowHealthReminder(id) end,
        }
    end
    args.customMessagesEnabled = {
        type = 'toggle', name = L.HEALTH_CUSTOM_TEXTS_ENABLED,
        desc = L.HEALTH_CUSTOM_TEXTS_ENABLED_DESC, order = 9, width = 'full',
        get = function() return HealthSettings()[id].customMessagesEnabled == true end,
        set = function(_, value)
            HealthSettings()[id].customMessagesEnabled = value == true
            Clock:NotifyOptions()
        end,
    }
    -- Quelle der Standardtexte unten im jeweiligen Menuepunkt.
    local sourceText = ns.HealthSourceText and ns.HealthSourceText(id)
    if sourceText then
        args.sourceInfo = {type = 'description', order = 99, width = 'full', fontSize = 'small',
            name = '|cff999999' .. sourceText .. '|r'}
    end
    args.customTexts = CategoryTextArgs(id)
    for key, value in pairs(CategoryEffectArgs(id)) do args[key] = value end
    return {type = 'group', name = label, order = order, args = args}
end

function ns.HealthOptions()
    return {
        type = 'group', name = L.MODULE_HEALTH, order = 4, childGroups = 'tab',
        args = {
            movement = CategoryGroup('movement', L.HEALTH_MOVEMENT, L.HEALTH_MOVEMENT_DESC,
                L.HEALTH_MOVEMENT_INTERVAL, 180, 1),
            drinking = CategoryGroup('drinking', L.HEALTH_DRINKING, L.HEALTH_DRINKING_DESC,
                L.HEALTH_DRINKING_INTERVAL, 120, 2),
            eyes = CategoryGroup('eyes', L.HEALTH_EYES, L.HEALTH_EYES_DESC,
                L.HEALTH_EYES_INTERVAL, 60, 3),
            general = {
                type = 'group', name = L.HEALTH_GENERAL, order = 4,
                args = {
                    introduction = {type = 'description', name = '|cff999999' .. L.HEALTH_INTRO .. '|r',
                        order = 1, width = 'full'},
                    notice = {
                        type = 'select', name = L.HEALTH_NOTICE, order = 2, width = 'full',
                        values = { screen = L.HEALTH_NOTICE_SCREEN, chat = L.HEALTH_NOTICE_CHAT,
                            both = L.HEALTH_NOTICE_BOTH },
                        get = function() return HealthSettings().notice end,
                        set = function(_, value)
                            HealthSettings().notice = value
                            Clock:HideHealthNotice()
                        end,
                    },
                    sound = {
                        type = 'toggle', name = L.HEALTH_SOUND, order = 3, width = 'full',
                        get = function() return HealthSettings().sound == true end,
                        set = function(_, value) HealthSettings().sound = value == true end,
                    },
                    restrictedNotice = {
                        type = 'description', name = L.HEALTH_RESTRICTED_NOTICE,
                        order = 5, width = 'full',
                    },
                },
            },
        },
    }
end
