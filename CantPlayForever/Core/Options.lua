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
                debug = {
                    type = 'toggle', name = L.DEBUG_MODE, desc = L.DEBUG_MODE_DESC, order = 100, width = 'full',
                    get = function() return Clock.db.global.debug == true end,
                    set = function(_, v) Clock.db.global.debug = v and true or false end,
                },
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
                type = 'group', name = L.EFFECTS_TAB, order = 3,
                args = {
                        screenGlow = {
                            type = 'toggle', name = L.SCREEN_GLOW, order = 2.4, width = 'full',
                            desc = L.SCREEN_GLOW_DESC,
                            get = function() return Clock.db.profile.screenGlow == true end,
                            set = function(_, v) Clock.db.profile.screenGlow = v end,
                        },
                        glowSpeed = {
                            type = 'range', name = L.GLOW_SPEED, desc = L.GLOW_SPEED_DESC, order = 2.42,
                            width = 'double', min = 0.3, max = 5, step = 0.1,
                            get = function() return tonumber(Clock.db.profile.glowSpeed) or 1 end,
                            set = function(_, v) Clock.db.profile.glowSpeed = v end,
                        },
                        screenGlowSkipInstances = {
                            type = 'toggle', name = L.SCREEN_GLOW_NO_INSTANCE, order = 2.45, width = 'full',
                            desc = L.SCREEN_GLOW_NO_INSTANCE_DESC,
                            disabled = function() return not Clock.db.profile.screenGlow end,
                            get = function() return Clock.db.profile.screenGlowSkipInstances ~= false end,
                            set = function(_, v) Clock.db.profile.screenGlowSkipInstances = v end,
                        },
                        screenGlowSpec = {
                            type = 'input', name = L.SCREEN_GLOW_SPEC, order = 2.5, width = 'double',
                            desc = L.SCREEN_GLOW_SPEC_DESC,
                            disabled = function() return not Clock.db.profile.screenGlow end,
                            get = function() return Clock:GetScreenGlowSpec() end,
                            set = function(_, v)
                                if Clock:ParseGlowSpec(v) then
                                    Clock.db.profile.screenGlowSpec = v
                                else
                                    Clock:Print(L.SCREEN_GLOW_SPEC_DESC)
                                end
                            end,
                        },
                        test = {
                            type = 'execute', name = L.TEST_NOW, order = 3,
                            desc = L.TEST_NOW_DESC,
                            func = function() Clock:Alert(L.TEST_ALARM) end,
                        },
                },
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
    pcall(function() self.aceDialog:AddToBlizOptions('CantPlayForever', "Can't play Forever") end)
end
