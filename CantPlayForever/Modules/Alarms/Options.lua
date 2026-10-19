local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

local editing = {} -- alarm id -> Bearbeitungsbereich aufgeklappt

-- Alarm im Bearbeitungsbereich aufklappen (z. B. beim Klick auf den Alarm im Spielkalender)
function ns.EditAlarm(id)
    if id then editing[id] = true end
end

local function RemoveAlarm(alarm)
    for index, alarmEntry in ipairs(Clock.db.profile.alarms) do
        if alarmEntry.id == alarm.id then
            table.remove(Clock.db.profile.alarms, index)
            break
        end
    end
    editing[alarm.id] = nil
    Clock:NotifyOptions()
end

-- Löschabfrage (Optionen > Alarme abschaltbar): AceConfig nimmt Text oder false.
local ConfirmDelete = function() return ns.ConfirmDelete() end

local draftOpen = false -- Anlege-Maske aufgeklappt
local draft = {alarmHour = 19, alarmMinute = 0, alarmName = '', days = {true, true, true, true, true, true, true},
    everyMonth = true, everyYear = true, repeating = false, alarmType = 'alarm', customEffect = false, inCalendar = true,
    calendarIcon = false}

local DAY_ORDER = {2, 3, 4, 5, 6, 7, 1} -- Mo..So (WoW: 1 = Sonntag)

local MONTH_VALUES = {}
for n = 1, 12 do MONTH_VALUES[n] = string.format('%02d', n) end

-- Zeitplan-Felder für einen Alarm oder den Entwurf: Wochentage (immer sichtbar), Datum (immer
-- sichtbar; Tag ist bei angehakten Wochentagen ausgegraut), Monat/Jahr mit "jeden/jedes".
local function ScheduleArgs(target, firstOrder, onChange)
    local function Today()
        local _, year, month, day = Clock:GetToday()
        return year, month, day
    end
    -- Größter wählbarer Tag: richtet sich nach Monat und Jahr (Februar, Schaltjahr); bei "jeden
    -- Monat" gilt 31 (kürzere Monate klingeln dann am letzten Tag), bei "jedes Jahr" im Februar 29.
    local function MaxDay()
        if target.everyMonth then return 31 end
        local year = target.year or (Today())
        if target.everyYear then year = 2000 end -- Schaltjahr
        return ns.DaysInMonth(target.month or select(2, Today()), year)
    end
    local function Changed()
        if target.day and target.day > MaxDay() then target.day = MaxDay() end
        if onChange then onChange() end
    end
    local function Days() return ns.AlarmHasDays(target) end
    local args = {
        allDays = {
            type = 'execute', name = L.ALL_DAYS, order = firstOrder + 0.1, width = 0.52,
            desc = L.ALL_DAYS_DESC,
            func = function() -- alle angehakt -> alle abhaken, sonst alle anhaken
                local all = true
                for wday = 1, 7 do all = all and target.days and target.days[wday] == true end
                target.days = {}
                if not all then
                    for wday = 1, 7 do target.days[wday] = true end
                end
                Changed()
            end,
        },
        day = {
            type = 'select', name = L.DAY, order = firstOrder + 0.5, width = 0.85,
            values = function()
                local values = {}
                for n = 1, MaxDay() do values[n] = tostring(n) end
                return values
            end,
            disabled = Days,
            get = function() return target.day or select(3, Today()) end,
            set = function(_, value) target.day = value Changed() end,
        },
        month = {
            type = 'select', name = L.MONTH, order = firstOrder + 0.6, width = 0.85,
            values = MONTH_VALUES, disabled = function() return target.everyMonth == true end,
            get = function() return target.month or select(2, Today()) end,
            set = function(_, value) target.month = value Changed() end,
        },
        everyMonth = {
            type = 'toggle', name = L.EVERY_MONTH, order = firstOrder + 0.71, width = 0.65,
            get = function() return target.everyMonth == true end,
            set = function(_, value) target.everyMonth = value Changed() end,
        },
        year = {
            type = 'select', name = L.YEAR, order = firstOrder + 0.7, width = 0.85,
            values = function()
                local values, current = {}, Today()
                for y = current - 1, current + 10 do values[y] = tostring(y) end
                if target.year then values[target.year] = tostring(target.year) end
                return values
            end,
            disabled = function() return target.everyYear == true end,
            get = function() return target.year or (Today()) end,
            set = function(_, value) target.year = value Changed() end,
        },
        everyYear = {
            type = 'toggle', name = L.EVERY_YEAR, order = firstOrder + 0.72, width = 0.6,
            get = function() return target.everyYear == true end,
            set = function(_, value) target.everyYear = value Changed() end,
        },
        repeating = {
            type = 'toggle', name = L.ALARM_REPEAT, desc = L.ALARM_REPEAT_DESC, order = firstOrder + 0.8,
            width = 'full',
            -- Datum ohne Wochentage mit jeden Monat/jedes Jahr wiederholt sich von selbst
            disabled = function() return not Days() and (target.everyMonth or target.everyYear) end,
            get = function() return target.repeating == true or ns.AlarmRepeats(target) end,
            set = function(_, value) target.repeating = value Changed() end,
        },
    }
    -- Alle Tage (0.52) gefolgt von sieben Tagesfeldern (je 0.35):
    -- zusammen 2.97 von 3 AceGUI-Einheiten. Das Datum folgt in der naechsten Zeile.
    for n, wday in ipairs(DAY_ORDER) do
        args['day' .. wday] = {
            type = 'toggle', name = L['DAY_' .. wday], order = firstOrder + 0.2 + n * 0.01,
            width = 0.35,
            get = function() return target.days and target.days[wday] == true end,
            set = function(_, value)
                target.days = target.days or {}
                target.days[wday] = value or nil
                Changed()
            end,
        }
    end
    return args
end

-- Die Modulvorgabe bleibt unangetastet. Erst der Haken legt eine eigene
-- Kopie der Darstellung für diesen Alarm an; Ausschalten bewahrt seine Werte.
local function IndividualEffectArgs(target, firstOrder, onChange)
    local function Changed()
        if onChange then onChange() end
    end
    return {
        customEffect = {
            type = 'toggle', name = L.ALARM_CUSTOM_EFFECT,
            desc = L.ALARM_CUSTOM_EFFECT_DESC, order = firstOrder, width = 'full',
            get = function() return target.customEffect == true end,
            set = function(_, enabled)
                Clock:SetAlarmCustomEffect(target, enabled)
                Changed()
            end,
        },
        appearance = {
            type = 'group', inline = true, name = L.EFFECT_APPEARANCE,
            order = firstOrder + 0.1,
            hidden = function() return target.customEffect ~= true end,
            args = (function()
                local controls = ns.EffectAppearanceArgs('alarms',
                    function() return Clock:GetAlarmEffectOverride(target) end,
                    function() return target.customEffect ~= true end)
                controls.preview = {
                    type = 'execute', name = L.EFFECT_TEST_NOW, order = 5,
                    func = function()
                        Clock:PreviewScreenGlow('alarms', Clock:GetAlarmEffectOverride(target))
                    end,
                }
                return controls
            end)(),
        },
    }
end

-- Kurztext des Zeitplans für die Zeile: täglich / Mo,Di / Datum, mit * für "jeden Monat/jedes Jahr".
local function ScheduleText(alarm)
    local text
    if ns.AlarmHasDays(alarm) then
        local names = {}
        for _, wday in ipairs(DAY_ORDER) do
            if alarm.days[wday] then names[#names + 1] = L['DAY_' .. wday] end
        end
        text = #names == 7 and L.ALARM_DAILY or table.concat(names, ',')
        if not (alarm.everyMonth and alarm.everyYear) then
            text = text .. string.format(' %s.%s', alarm.everyMonth and '*' or string.format('%02d', alarm.month or 1),
                alarm.everyYear and '*' or tostring(alarm.year or ''))
        end
    else
        text = string.format('%d.%s.%s', alarm.day or 1,
            alarm.everyMonth and '*' or string.format('%02d', alarm.month or 1),
            alarm.everyYear and '*' or tostring(alarm.year or ''))
    end
    if not ns.AlarmRepeats(alarm) then text = text .. ' (' .. L.ALARM_ONCE .. ')' end
    return text
end

local function AlarmArgs()
    local args = {
        hour = {
            type = 'range', name = L.HOUR, order = 2, width = 0.9,
            min = 0, max = 23, step = 1,
            get = function() return draft.alarmHour end,
            set = function(_, value) draft.alarmHour = value end,
        },
        minute = {
            type = 'range', name = L.MINUTE, order = 3, width = 0.9,
            min = 0, max = 59, step = 1,
            get = function() return draft.alarmMinute end,
            set = function(_, value) draft.alarmMinute = value end,
        },
        message = {
            type = 'input', name = L.ALARM_MESSAGE, order = 4, width = 1.7,
            get = function() return draft.alarmName end,
            set = function(_, value) draft.alarmName = value end,
        },
        alarmType = {
            type = 'select', name = L.ALARM_TYPE, desc = L.ALARM_TYPE_DESC,
            values = ns.AlarmTypeValues, order = 4.1, width = 1,
            get = function() return draft.alarmType or 'alarm' end,
            set = function(_, value) draft.alarmType = value end,
        },
        inCalendar = {
            type = 'toggle', name = L.ALARM_IN_CALENDAR, desc = L.ALARM_IN_CALENDAR_DESC, order = 4.2, width = 'full',
            get = function() return draft.inCalendar ~= false end,
            set = function(_, value) draft.inCalendar = value end,
        },
        calendarIcon = {
            type = 'toggle', name = L.ALARM_CALENDAR_ICON, desc = L.ALARM_CALENDAR_ICON_DESC, order = 4.3, width = 'full',
            disabled = function() return draft.inCalendar == false end,
            get = function() return draft.calendarIcon == true end,
            set = function(_, value) draft.calendarIcon = value end,
        },
        add = {
            type = 'execute', name = L.ADD_ALARM, order = 6,
            func = function()
                local db = Clock.db.profile
                table.insert(db.alarms, {
                    id = db.nextAlarmID,
                    uid = ns.NewAlarmUID and ns.NewAlarmUID() or nil,
                    hour = draft.alarmHour,
                    minute = draft.alarmMinute,
                    name = draft.alarmName,
                    enabled = true,
                    selected = true,
                    armed = false,
                    sched = 2,
                    days = CopyTable(draft.days),
                    year = draft.year or select(2, Clock:GetToday()),
                    month = draft.month or select(3, Clock:GetToday()),
                    day = draft.day or select(4, Clock:GetToday()),
                    everyMonth = draft.everyMonth, everyYear = draft.everyYear,
                    repeating = draft.repeating,
                    alarmType = draft.alarmType or 'alarm',
                    inCalendar = draft.inCalendar ~= false,
                    calendarIcon = draft.calendarIcon == true,
                    customEffect = draft.customEffect == true,
                    effect = draft.effect and CopyTable(draft.effect) or nil,
                })
                db.nextAlarmID = db.nextAlarmID + 1
                draft.alarmName = ''
                draft.customEffect, draft.effect = false, nil
                draftOpen = false
                Clock:NotifyOptions()
            end,
        },
        existingHeader = {
            type = 'header', name = L.SAVED_ALARMS, order = 10,
        },
    }
    for key, option in pairs(ScheduleArgs(draft, 4.5)) do args['draft_' .. key] = option end
    for key, option in pairs(IndividualEffectArgs(draft, 5.31)) do args['draft_' .. key] = option end
    -- Anlege-Maske: zugeklappt nur ein Button, aufgeklappt eine Box mit Rahmen
    local box = {}
    for key in pairs(args) do
        if key == 'hour' or key == 'minute' or key == 'message' or key == 'alarmType' or key == 'add'
            or key:find('^draft_') then
            box[key], args[key] = args[key], nil
        end
    end
    args.newAlarm = {
        type = 'execute', name = L.NEW_ALARM, order = 1,
        func = function() draftOpen = not draftOpen Clock:NotifyOptions() end,
    }
    args.newBox = {
        type = 'group', inline = true, name = L.NEW_ALARM, order = 2,
        hidden = function() return not draftOpen end,
        args = box,
    }
    if #Clock.db.profile.alarms == 0 then
        args.empty = {type = 'description', name = L.NO_SAVED_ALARMS, order = 11}
    end
    for i, alarm in ipairs(Clock.db.profile.alarms) do
        local current = alarm
        local key = 'alarm_' .. tostring(current.id)
        local function Editing() return editing[current.id] end
        local base = 100 + i * 10
        if i > 1 then args[key .. '_sep'] = {type = 'header', name = '', order = base} end -- schmale Trennlinie
        args[key .. '_armed'] = {
            type = 'toggle', name = '', order = base + 1, width = 0.14,
            desc = L.ALARM_ACTIVE_DESC,
            get = function() return current.armed == true end,
            set = function(_, value) Clock:SetAlarmArmed(current, value) end,
        }
        args[key .. '_summary'] = {
            type = 'description', order = base + 3, width = 2.5, fontSize = 'medium',
            name = function()
                local label = ns.AlarmDisplayName(current, L.ALARM_GENERIC, 15)
                local text = string.format('%s - %02d:%02d - %s', label,
                    current.hour, current.minute, ScheduleText(current))
                text = '  ' .. text -- kleiner Abstand zum Mülleimer
                local effect = Clock:GetAlarmEffectOverride(current)
                if effect then
                    return '|cff' .. Clock:GetEffectColorHex('alarms', effect) .. text .. '|r'
                end
                return current.armed and '|cff55ff55' .. text .. '|r' or text
            end,
        }
        args[key .. '_edit'] = { -- blau, direkt hinter dem Aktiv-Haken
            type = 'execute', name = '', order = base + 2, width = 0.147,
            image = ns.RowIcon('edit_gear'),
            imageWidth = 18, imageHeight = 18,
            desc = L.EDIT_ALARM,
            func = function()
                editing[current.id] = not editing[current.id] or nil
                Clock:NotifyOptions()
            end,
        }
        args[key .. '_delete'] = {
            type = 'execute', name = '', order = base + 2.5, width = 0.147, desc = L.DELETE_ALARM,
            image = ns.RowIcon('delete_bin'),
            imageWidth = 18, imageHeight = 18,
            confirm = ConfirmDelete,
            func = function() RemoveAlarm(current) end,
        }
        -- Bearbeitungsmaske: eigener Rahmen (inline-Gruppe), nur bei aufgeklapptem Zahnrad
        local mask = {
            selected = {
                type = 'toggle', name = L.SELECT_FOR_CTRL, order = 1, width = 'full',
                get = function() return current.selected == true end,
                set = function(_, value)
                    current.selected = value
                    if not value then current.armed = false end
                    Clock:NotifyOptions()
                end,
            },
            hour = {
                type = 'range', name = L.HOUR, order = 2, width = 0.9,
                min = 0, max = 23, step = 1,
                get = function() return current.hour end,
                set = function(_, value) current.hour = value Clock:NotifyOptions() end,
            },
            minute = {
                type = 'range', name = L.MINUTE, order = 3, width = 0.9,
                min = 0, max = 59, step = 1,
                get = function() return current.minute end,
                set = function(_, value) current.minute = value Clock:NotifyOptions() end,
            },
            message = {
                type = 'input', name = L.ALARM_MESSAGE, order = 4, width = 1.7,
                get = function() return current.name end,
                set = function(_, value) current.name = value Clock:NotifyOptions() end,
            },
            alarmType = {
                type = 'select', name = L.ALARM_TYPE, order = 4.1, width = 1,
                desc = L.ALARM_TYPE_DESC, values = ns.AlarmTypeValues,
                disabled = function() return current.calendarKey ~= nil end, -- importierte Alarme behalten ihren Typ
                get = function() return current.alarmType or 'alarm' end,
                set = function(_, value) current.alarmType = value Clock:NotifyOptions() end,
            },
            calendarSource = {
                type = 'description', order = 4.15, width = 2, fontSize = 'medium',
                hidden = function() return current.calendarKey == nil end,
                name = '   |TInterface\\common\\help-i:24:24:0:-2|t |cff999999' .. string.format(L.ALARM_IMPORTED_FROM, current.calendarSource == 'game' and L.CALLINK_SOURCE_GAME or 'Classic Calendar - Revived') .. '|r', -- Abstand links, Info-Symbol
            },
            calendarSourceBreak = { -- Zeilenumbruch nach dem Hinweis
                type = 'description', order = 4.16, width = 'full', name = '',
                hidden = function() return current.calendarKey == nil end,
            },
            inCalendar = {
                type = 'toggle', name = L.ALARM_IN_CALENDAR, desc = L.ALARM_IN_CALENDAR_DESC, order = 4.2, width = 'full',
                hidden = function() return current.calendarKey ~= nil end, -- aus dem Kalender importiert: nicht zurueckspiegeln
                get = function() return current.inCalendar ~= false end,
                set = function(_, value) current.inCalendar = value Clock:NotifyOptions() end,
            },
            calendarIcon = {
                type = 'toggle', name = L.ALARM_CALENDAR_ICON, desc = L.ALARM_CALENDAR_ICON_DESC, order = 4.3, width = 'full',
                hidden = function() return current.calendarKey ~= nil end,
                disabled = function() return current.inCalendar == false end,
                get = function() return current.calendarIcon == true end,
                set = function(_, value) current.calendarIcon = value Clock:NotifyOptions() end,
            },
        }
        for k, option in pairs(ScheduleArgs(current, 5, function() Clock:NotifyOptions() end)) do
            mask[k] = option
        end
        for k, option in pairs(IndividualEffectArgs(current, 5.82, function() Clock:NotifyOptions() end)) do
            mask[k] = option
        end
        args[key .. '_mask'] = {
            type = 'group', inline = true, name = L.EDIT_ALARM, order = base + 4,
            hidden = function() return not Editing() end,
            args = mask,
        }
    end
    return args
end

function ns.AlarmOptions()
    return {type = 'group', name = L.ALARMS_TAB, order = 2, args = AlarmArgs()}
end

-- Reihenfolge beim Abschalten per Strg+Linksklick: Reiter Optionen > Alarme.
-- Allgemein: eigener Kasten "Alarme" (inline, kein Reiter) mit Erklärtext und Reihenfolge beim
-- Abschalten per Strg+Linksklick.
function ns.AlarmGeneralArgs()
    return {
        alarms = {
            type = 'group', inline = true, name = L.ALARMS_TAB, order = 90,
            args = {
                instruction = {
                    type = 'description', name = '|cff999999' .. L.ALARM_INSTRUCTION .. '|r', order = 1, fontSize = 'medium',
                },
                disarmOrder = {
                    type = 'select', name = L.DISARM_ORDER, desc = L.DISARM_ORDER_DESC, order = 2, width = 'full',
                    values = {farthest = L.DISARM_FARTHEST, nearest = L.DISARM_NEAREST},
                    get = function() return Clock.db.profile.alarmDisarmOrder == 'nearest' and 'nearest' or 'farthest' end,
                    set = function(_, value) Clock.db.profile.alarmDisarmOrder = value end,
                },
            },
        },
    }
end
