-- AceConfig-Optionen: Gerüst. Jedes Modul liefert über GetOptions() seinen eigenen Reiter;
-- hier kommen nur der Reiter „Module“ und die allgemeinen Einstellungen dazu.
local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

-- Löschabfrage für alles im Addon (Alarme, Timer, ...): AceConfig nimmt als confirm Text oder false.
function ns.ConfirmDelete()
    return Clock.db.profile.alarmConfirmDelete ~= false and L.CONFIRM_DELETE_ALARM or false
end

local function ModuleArgs()
    local args = {
        info = {type = 'description', order = 1, name = L.MODULES_INFO},
    }
    for index, module in ipairs(Clock.MODULES) do
      if not module.hidden then
        local id = module.id
        args[id] = {
            type = 'toggle', width = 'full', order = 10 + index,
            name = L['MODULE_' .. id:upper()],
            desc = L['MODULE_' .. id:upper() .. '_DESC'],
            disabled = module.locked or module.available == false,
            get = function() return Clock:IsModuleEnabled(id) end,
            set = function(_, value)
                Clock.db.profile.modules[id] = value
                Clock:OAPLog('info', 'Module {1}: {2}', id, value and 'enabled' or 'disabled')
                Clock:NotifyOptions()
            end,
        }
        if module.available == false then
            args[id].name = args[id].name .. ' |cff888888(' .. L.MODULE_PLANNED .. ')|r'
        end
      end
    end
    return args
end

function Clock:InitializeOptions()
    -- AceConfig erlaubt eine Funktion nur als Generator der gesamten Optionstabelle,
    -- nicht als .args einer Untergruppe. Bei jeder Aktualisierung erzeugen wir
    -- deshalb die komplette Tabelle mit den aktuellen Modulen, Alarmen und Timer-Vorgaben.
    local function BuildOptions()
        local args = {}
        for _, module in ipairs(Clock.MODULES) do
            if module.GetOptions and module.available ~= false then
                local group = module.GetOptions()
                local id = module.id
                if not module.locked then
                    group.hidden = function() return not Clock:IsModuleEnabled(id) end
                end
                args[id] = group
            end
        end
        -- Hauptreiter: Allgemein, Optionen, Alarme, Timer. Darunter genau eine weitere Ebene.
        --   Allgemein: Speichern, Module        Optionen: Uhr, Audio, Effekte
        local clockGroup = args.clock
        args.clock = nil
        args.general = {
            type = 'group', name = L.GENERAL_TAB, order = 0, childGroups = 'tab',
            args = {
                save = {
                    type = 'group', name = L.SECTION_SAVE, order = 1,
                    args = {
                        mode = {
                            type = 'select', name = L.SAVE_SCOPE, order = 1,
                            desc = L.SAVE_SCOPE_DESC,
                            values = {account = L.ACCOUNT, character = L.CHARACTER},
                            get = function() return Clock.db.global.scope end,
                            set = function(_, v) Clock:SwitchProfile(v) end,
                        },
                        commands = {
                            type = 'description', name = L.COMMANDS,
                            order = 4,
                        },
                    },
                },
                modules = {type = 'group', name = L.MODULES_TAB, order = 2, args = ModuleArgs()},
            },
        }
        local optionsArgs = {
            audio = {
                type = 'group', name = L.SECTION_AUDIO, order = 2,
                args = {
                        sound = {
                            type = 'toggle', name = L.PLAY_SOUND, order = 2,
                            get = function() return Clock.db.profile.playSound end,
                            set = function(_, v) Clock.db.profile.playSound = v end,
                        },
                        alarmSound = {
                            type = 'select', name = L.ALARM_SOUND, order = 2.1, width = 'full',
                            values = {
                                alarm1 = L.SOUND_1,
                                alarm2 = L.SOUND_2,
                                alarm3 = L.SOUND_3,
                                ready = L.SOUND_READY,
                            },
                            get = function() return Clock.db.profile.alarmSound end,
                            set = function(_, value) Clock.db.profile.alarmSound = value end,
                        },
                        alarmRepeats = {
                            type = 'range', name = L.SOUND_REPEAT, order = 2.2, width = 'full',
                            desc = L.SOUND_REPEAT_DESC,
                            min = 1, max = 10, step = 1,
                            get = function() return Clock.db.profile.alarmRepeats end,
                            set = function(_, value) Clock.db.profile.alarmRepeats = value end,
                        },
                        preview = {
                            type = 'execute', name = L.PLAY, order = 2.3, width = 0.5,
                            func = function() Clock:PlayAlarmSound() end,
                        },
                        previewText = {
                            type = 'description', name = L.PREVIEW_SOUND, order = 2.31, width = 'double',
                            fontSize = 'medium',
                        },
                },
            },
            effects = {
                type = 'group', name = L.EFFECTS_TAB, order = 3, childGroups = 'tab',
                args = (function()
                    local groups = {}
                    local function MakeEffectGroup(source, title, order)
                        local function Config() return Clock:GetEffectConfig(source) end
                        groups[source] = {
                            type = 'group', name = title, order = order,
                            args = {
                                -- Zeile 1: Modul-Effekt einschalten.
                                enabled = {
                                    type = 'toggle', name = L['EFFECT_GLOW_' .. source:upper()],
                                    order = 1, width = 'full', desc = L.SCREEN_GLOW_DESC,
                                    get = function() return Config().screenGlow == true end,
                                    set = function(_, value) Config().screenGlow = value == true end,
                                },
                                -- Zeile 2: bei Health fest vorgegeben (auch Kampf ist gesperrt).
                                skipInstances = {
                                    type = 'toggle', name = L.SCREEN_GLOW_NO_INSTANCE,
                                    order = 2, width = 'full',
                                    desc = source == 'health' and L.HEALTH_RESTRICTED_NOTICE
                                        or L.SCREEN_GLOW_NO_INSTANCE_DESC,
                                    disabled = function()
                                        return source == 'health' or not Config().screenGlow
                                    end,
                                    get = function()
                                        if source == 'health' then return true end
                                        return Config().skipInstances ~= false
                                    end,
                                    set = function(_, value)
                                        if source ~= 'health' then Config().skipInstances = value == true end
                                    end,
                                },
                                -- Zeile 3: gerahmte Gruppe "Darstellung"; darunter vier Zeilen.
                                appearance = {
                                    type = 'group', inline = true, name = L.EFFECT_APPEARANCE,
                                    order = 3,
                                    args = (function()
                                        -- Die Health-Darstellung darf auch ohne aktives
                                        -- Bildschirmrand-Leuchten vorbereitet werden.
                                        local controls = ns.EffectAppearanceArgs(source, nil,
                                            function()
                                                return source ~= 'health' and not Config().screenGlow
                                            end)
                                        if source == 'health' then
                                            -- Health hat keine globale Farbe: jede Kategorie
                                            -- verwendet ihre eigene Fraktions-/Standardfarbe.
                                            controls.color = nil
                                            for key, option in pairs(ns.HealthIconAppearanceArgs(nil)) do
                                                controls[key] = option
                                            end
                                        end
                                        return controls
                                    end)(),
                                },
                                -- Zeile 8: nur Bildschirmrand-Effekt vorschauen, ohne Alarmton.
                                test = {
                                    type = 'execute', name = L.EFFECT_TEST_NOW, order = 4,
                                    disabled = function() return not Config().screenGlow end,
                                    func = function()
                                        if source == 'health' then
                                            Clock:PreviewHealthEffect()
                                        else
                                            Clock:PreviewScreenGlow(source)
                                        end
                                    end,
                                },
                            },
                        }
                    end
                    MakeEffectGroup('timer', L.EFFECT_SOURCE_TIMER, 1)
                    MakeEffectGroup('alarms', L.EFFECT_SOURCE_ALARMS, 2)
                    MakeEffectGroup('health', L.EFFECT_SOURCE_HEALTH, 3)
                    return groups
                end)(),
            },
        }
        args.general.args.confirmDelete = {
            type = 'toggle', name = L.CONFIRM_DELETE_OPTION, desc = L.CONFIRM_DELETE_OPTION_DESC,
            order = 92, width = 'full',
            get = function() return Clock.db.profile.alarmConfirmDelete ~= false end,
            set = function(_, value) Clock.db.profile.alarmConfirmDelete = value end,
        }
        if ns.AlarmGeneralArgs and Clock:IsModuleEnabled('alarms') then
            for key, option in pairs(ns.AlarmGeneralArgs()) do args.general.args[key] = option end
        end
        if clockGroup then
            clockGroup.order = 1
            optionsArgs.clock = clockGroup
        end
        -- Vollständiger Top-Level-Reiter nur wenn OAP Debug tatsächlich geladen ist.
        -- Bei fehlendem OAP Debug existiert kein Debug-Reiter und kein Debug-Schalter.
        if Clock:IsOAPDebugAvailable() then
            args.oapdebug = {
                type = 'group', name = L.OAP_TAB, order = 95,
                childGroups = 'tab',
                args = {
                    logging = {
                        type = 'group', name = L.OAP_LOGGING_TAB, order = 1,
                        args = {
                            level = {
                                type = 'select', name = L.OAP_LEVEL,
                                desc = L.OAP_LEVEL_DESC, order = 1, width = 'full',
                                values = {
                                    errors = L.OAP_ERRORS,
                                    normal = L.OAP_NORMAL,
                                    metrics = L.OAP_METRICS,
                                    detailed = L.OAP_DETAILED,
                                },
                                get = function() return Clock.db.global.oapLevel end,
                                set = function(_, v)
                                    Clock.db.global.oapLevel = v
                                    Clock:OAPLog('info', 'OAP level set to {1}', v)
                                end,
                            },
                            state = {
                                type = 'description', name = L.OAP_INSTALLED, order = 2,
                                width = 'full',
                            },
                        },
                    },
                    inspector = {
                        type = 'group', name = L.OAP_INSPECT_TAB, order = 2,
                        args = {
                            help = {type = 'description', name = L.OAP_INSPECT_HELP, order = 1, width = 'full'},
                            target = {type = 'select', name = L.OAP_TARGET, order = 2,
                                values = {
                                    core = L.OAP_TARGET_CORE, settings = L.OAP_TARGET_SETTINGS,
                                    diagnostics = L.OAP_TARGET_DIAGNOSTICS, health = L.OAP_TARGET_HEALTH,
                                    ui = L.OAP_TARGET_UI,
                                },
                                get = function() return Clock.oapInspectTarget or 'core' end,
                                set = function(_, value) Clock.oapInspectTarget = value end,
                            },
                            inspect = {type = 'execute', name = L.OAP_INSPECT_BUTTON, order = 3,
                                func = function() Clock:OAPInspectPreset(Clock.oapInspectTarget or 'core') end},
                            watchTarget = {type = 'select', name = L.OAP_WATCH_TARGET, order = 4,
                                values = {
                                    core = L.OAP_TARGET_CORE, timer = L.OAP_TARGET_TIMER,
                                    alarms = L.OAP_TARGET_ALARMS, health = L.OAP_TARGET_HEALTH,
                                    settings = L.OAP_TARGET_SETTINGS,
                                    diagnostics = L.OAP_TARGET_DIAGNOSTICS,
                                },
                                get = function() return Clock.oapWatchTarget or 'timer' end,
                                set = function(_, value) Clock.oapWatchTarget = value end,
                            },
                            watch = {type = 'execute', name = L.OAP_WATCH_ADD, order = 5,
                                func = function() Clock:OAPWatchPreset(Clock.oapWatchTarget or 'timer') end},
                            unwatch = {type = 'execute', name = L.OAP_WATCH_REMOVE, order = 6,
                                func = function() Clock:OAPUnwatchPreset(Clock.oapWatchTarget or 'timer') end},
                            info = {type = 'description', name = L.OAP_INSPECT_COMMANDS, order = 7,
                                width = 'full'},
                        },
                    },
                    tools = {
                        type = 'group', name = L.OAP_TOOLS_TAB, order = 3,
                        args = {
                            note = {type = 'description', name = L.OAP_TOOLS_HELP, order = 1,
                                width = 'full'},
                            log = {type = 'execute', name = L.OAP_OPEN_LOG, order = 2,
                                func = function() Clock:OAPShow('log') end},
                            metrics = {type = 'execute', name = L.OAP_OPEN_METRICS, order = 3,
                                func = function() Clock:OAPShow('metrics') end},
                            perf = {type = 'execute', name = L.OAP_OPEN_PERF, order = 4,
                                func = function() Clock:OAPShow('perf') end},
                            frames = {type = 'execute', name = L.OAP_OPEN_FRAMES, order = 5,
                                func = function() Clock:OAPShow('frames') end},
                            errors = {type = 'execute', name = L.OAP_OPEN_ERRORS, order = 6,
                                func = function() Clock:OAPShow('errors') end},
                            chat = {type = 'execute', name = L.OAP_OPEN_CHAT, order = 7,
                                func = function() Clock:OAPShow('chat') end},
                        },
                    },
                },
            }
        end
        args.options = {
            type = 'group', name = L.OPTIONS_TAB, order = 1, childGroups = 'tab',
            args = optionsArgs,
        }

        return {
            type = 'group',
            name = "Can't play Forever",
            childGroups = 'tab',
            args = args,
        }
    end
    self.aceConfig:RegisterOptionsTable('CantPlayForever', BuildOptions)
    -- AceConfigDialog works both standalone and, where supported, in Blizzard AddOn settings.
    pcall(function()
        local frame = self.aceDialog:AddToBlizOptions('CantPlayForever', "Can't play Forever")
        -- Allgemein-Logo links neben der Überschrift im Blizzard-Optionsfenster.
        local widget = frame and frame.obj
        local label = widget and widget.label
        if label then
            local icon = frame:CreateTexture(nil, 'OVERLAY')
            icon:SetSize(64, 64)
            icon:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -6)
            icon:SetTexture('Interface\\AddOns\\CantPlayForever\\Media\\Logos\\allgemein_logo')
            label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 84, -20)
            local tagline = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
            tagline:SetPoint('TOPLEFT', frame, 'TOPLEFT', 84, -44)
            tagline:SetTextColor(0.6, 0.6, 0.6)
            tagline:SetText(L.ADDON_TAGLINE)
            -- Inhalt unter das größere Logo schieben. AceConfigDialog ruft SetTitle bei jedem
            -- Anzeigen erneut auf und setzt die Position zurück, daher SetTitle erweitern.
            local baseSetTitle = widget.SetTitle
            local function PlaceContent(group)
                group.content:ClearAllPoints()
                group.content:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -78)
                group.content:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -10, 10)
            end
            widget.SetTitle = function(group, title)
                baseSetTitle(group, title)
                PlaceContent(group)
            end
            PlaceContent(widget)
        end
    end)
end
