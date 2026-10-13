local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

local draft = {
    timerHour = 0, timerMinute = 5, timerSecond = 0,
    presetName = '', presetHour = 0, presetMinute = 5, presetSecond = 0,
}

local draftOpen = false -- Anlege-Maske aufgeklappt
local editing = {} -- Timer-Vorgabe id -> Bearbeitungsbereich aufgeklappt

local function TimerArgs()
    local args = {
        active = {
            type = 'description', order = 2,
            name = function()
                local remaining = Clock:RemainingTimer()
                if remaining then
                    return string.format(L.ACTIVE_TIMER, Clock:Duration(remaining))
                end
                return L.NO_ACTIVE_TIMER
            end,
            fontSize = 'medium',
        },
        stop = {
            type = 'execute', name = L.STOP_TIMER, order = 3,
            disabled = function() return not Clock.db.profile.activeTimer end,
            func = function() Clock:StopTimer() end,
        },
        adjust = {
            type = 'execute', name = L.ADJUST_TIMER, order = 4,
            desc = L.ADJUST_TIMER_DESC,
            disabled = function()
                return not Clock.db.profile.activeTimer
                    or (draft.timerHour * 3600 + draft.timerMinute * 60 + draft.timerSecond) == 0
            end,
            func = function()
                Clock:SetTimerRemaining(draft.timerHour * 3600 + draft.timerMinute * 60 + draft.timerSecond)
            end,
        },
        header = {type = 'header', name = L.START_NEW_TIMER, order = 10},
        hours = {
            type = 'range', name = L.HOURS, min = 0, max = 168, step = 1, order = 11,
            get = function() return draft.timerHour end,
            set = function(_, v) draft.timerHour = v end,
        },
        minutes = {
            type = 'range', name = L.MINUTES, min = 0, max = 59, step = 1, order = 12,
            get = function() return draft.timerMinute end,
            set = function(_, v) draft.timerMinute = v end,
        },
        seconds = {
            type = 'range', name = L.SECONDS, min = 0, max = 59, step = 1, order = 13,
            get = function() return draft.timerSecond end,
            set = function(_, v) draft.timerSecond = v end,
        },
        start = {
            type = 'execute', name = L.START_COUNTDOWN, order = 14,
            disabled = function()
                return (draft.timerHour * 3600 + draft.timerMinute * 60 + draft.timerSecond) == 0
            end,
            func = function()
                Clock:StartTimer(draft.timerHour * 3600 + draft.timerMinute * 60 + draft.timerSecond)
            end,
        },
        presetHeader = {type = 'header', name = L.SAVED_PRESETS, order = 20},
    }
    for index, preset in ipairs(Clock.db.profile.presets) do
        local current = preset
        local key = 'preset_' .. tostring(current.id)
        local base = 20 + index -- Zeile: Trennlinie, Haken, Sanduhr, Zahnrad, Mülleimer, Text, Maske
        local function Running()
            local timer = Clock.db.profile.activeTimer
            return timer and timer.presetID == current.id
        end
        if index > 1 then args[key .. '_sep'] = {type = 'header', name = '', order = base} end
        args[key .. '_select'] = { -- Standard-Haken: immer nur ein Timer ist ausgewählt
            type = 'toggle', name = '', order = base + 0.01, width = 0.14,
            desc = L.ONE_PRESET,
            get = function() return Clock.db.profile.selectedPresetID == current.id end,
            set = function(_, value)
                Clock.db.profile.selectedPresetID = value and current.id or false
                Clock:NotifyOptions()
            end,
        }
        args[key .. '_edit'] = {
            type = 'execute', name = '', order = base + 0.03, width = 0.147, desc = L.EDIT_TIMER,
            image = ns.RowIcon('edit_gear'), imageWidth = 18, imageHeight = 18,
            func = function()
                editing[current.id] = not editing[current.id] or nil
                Clock:NotifyOptions()
            end,
        }
        args[key .. '_delete'] = {
            type = 'execute', name = '', order = base + 0.04, width = 0.147, desc = L.DELETE,
            image = ns.RowIcon('delete_bin'), imageWidth = 18, imageHeight = 18,
            confirm = ns.ConfirmDelete,
            func = function()
                for i, entry in ipairs(Clock.db.profile.presets) do
                    if entry.id == current.id then
                        table.remove(Clock.db.profile.presets, i)
                        if Clock.db.profile.selectedPresetID == current.id then
                            Clock.db.profile.selectedPresetID = false
                        end
                        break
                    end
                end
                editing[current.id] = nil
                Clock:NotifyOptions()
            end,
        }
        args[key .. '_toggle'] = { -- Sanduhr: starten/stoppen; läuft der Timer, bleibt sie grün
            type = 'execute', name = '', order = base + 0.02, width = 0.147,
            desc = function() return Running() and L.STOP or L.START end,
            image = function() return ns.RowIcon(Running() and 'hourglass_on' or 'hourglass') end,
            imageWidth = 18, imageHeight = 18,
            func = function()
                if Running() then
                    Clock:StopTimer()
                else
                    Clock:StartTimer(current.seconds, current.name, current.id)
                end
                Clock:NotifyOptions()
            end,
        }
        args[key .. '_summary'] = {
            type = 'description', order = base + 0.05, width = 2.4, fontSize = 'medium',
            name = function()
                local text = '  ' .. current.name .. ' - ' .. Clock:Duration(current.seconds)
                return Running() and '|cff55ff55' .. text .. '|r' or text
            end,
        }
        args[key .. '_mask'] = {
            type = 'group', inline = true, name = L.EDIT_TIMER, order = base + 0.06,
            hidden = function() return not editing[current.id] end,
            args = {
                presetName = {
                    type = 'input', name = L.NAME, order = 1, width = 1.1,
                    get = function() return current.name end,
                    set = function(_, value)
                        value = value:match('^%s*(.-)%s*$')
                        current.name = value ~= '' and value or Clock:Duration(current.seconds)
                        Clock:NotifyOptions()
                    end,
                },
                presetHours = {
                    type = 'range', name = L.HOURS, min = 0, max = 168, step = 1, order = 2, width = 0.8,
                    get = function() return math.floor(current.seconds / 3600) end,
                    set = function(_, value)
                        current.seconds = math.max(1, value * 3600 + current.seconds % 3600)
                        Clock:NotifyOptions()
                    end,
                },
                presetMinutes = {
                    type = 'range', name = L.MINUTES, min = 0, max = 59, step = 1, order = 3, width = 0.8,
                    get = function() return math.floor((current.seconds % 3600) / 60) end,
                    set = function(_, value)
                        current.seconds = math.max(1, current.seconds - (math.floor((current.seconds % 3600) / 60)) * 60 + value * 60)
                        Clock:NotifyOptions()
                    end,
                },
                presetSeconds = {
                    type = 'range', name = L.SECONDS, min = 0, max = 59, step = 1, order = 4, width = 0.8,
                    get = function() return current.seconds % 60 end,
                    set = function(_, value)
                        current.seconds = math.max(1, current.seconds - current.seconds % 60 + value)
                        Clock:NotifyOptions()
                    end,
                },
            },
        }
    end
    local function PresetRange(key, title, maximum, order)
        return {
            type = 'range', name = title, min = 0, max = maximum, step = 1, order = order, width = 0.8,
            get = function() return draft[key] end,
            set = function(_, value) draft[key] = value end,
        }
    end
    -- Timer anlegen: Button über der Liste klappt die Maske (Rahmen) auf
    args.newTimer = {
        type = 'execute', name = L.CREATE_TIMER, order = 0.5,
        func = function() draftOpen = not draftOpen Clock:NotifyOptions() end,
    }
    args.newBox = {
        type = 'group', inline = true, name = L.CREATE_TIMER, order = 0.6,
        hidden = function() return not draftOpen end,
        args = {
            newName = {
                type = 'input', name = L.NAME, order = 1, width = 1.1,
                get = function() return draft.presetName end,
                set = function(_, value) draft.presetName = value end,
            },
            newHours = PresetRange('presetHour', L.HOURS, 168, 2),
            newMinutes = PresetRange('presetMinute', L.MINUTES, 59, 3),
            newSeconds = PresetRange('presetSecond', L.SECONDS, 59, 4),
            save = {
                type = 'execute', name = L.SAVE_PRESET, order = 5,
                disabled = function()
                    return (draft.presetHour * 3600 + draft.presetMinute * 60 + draft.presetSecond) == 0
                end,
                func = function()
                    local db = Clock.db.profile
                    local duration = draft.presetHour * 3600 + draft.presetMinute * 60 + draft.presetSecond
                    local name = draft.presetName:match('^%s*(.-)%s*$')
                    if name == '' then name = Clock:Duration(duration) end
                    table.insert(db.presets, {id = db.nextPresetID, name = name, seconds = duration})
                    db.nextPresetID = db.nextPresetID + 1
                    draft.presetName = ''
                    draftOpen = false
                    Clock:NotifyOptions()
                end,
            },
        },
    }
    return args
end

function ns.TimerOptions()
    return {type = 'group', name = L.TIMER_LABEL, order = 3, args = TimerArgs()}
end
