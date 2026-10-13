local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

function ns.ClockOptions()
    local function Off() return Clock.db.profile.minimap.hide end
    return {
        type = 'group', name = L.CLOCK_TAB, order = 1,
        args = {
            visible = {
                type = 'toggle', name = L.SHOW_CLOCK, order = 1, width = 'full',
                get = function() return not Clock.db.profile.minimap.hide end,
                set = function(_, value)
                    Clock.db.profile.minimap.hide = not value
                    Clock:RefreshDisplay()
                end,
            },
            hideBlizzardClock = {
                type = 'toggle', name = L.HIDE_BLIZZARD_CLOCK, desc = L.HIDE_BLIZZARD_CLOCK_DESC,
                order = 1.5, width = 'full', disabled = Off,
                get = function() return Clock.db.profile.hideBlizzardClock ~= false end,
                set = function(_, value)
                    Clock.db.profile.hideBlizzardClock = value
                    Clock:ApplyBlizzardClock()
                end,
            },
            display = {
                type = 'group', inline = true, name = L.SECTION_DISPLAY, order = 2,
                disabled = Off,
                args = {
                    clockStyle = {
                        type = 'select', style = 'radio', name = L.CLOCK_STYLE, order = 0, width = 'full',
                        desc = L.CLOCK_STYLE_DESC,
                        disabled = function() return Clock:GetClockDiameter() == 32 end,
                        values = {digital = L.STYLE_DIGITAL, analog = L.STYLE_ANALOG},
                        get = function() return Clock.db.profile.clockStyle == 'analog' and 'analog' or 'digital' end,
                        set = function(_, value)
                            Clock.db.profile.clockStyle = value
                            Clock:RefreshDisplay()
                        end,
                    },
                    localTime = {
                        type = 'toggle', name = L.USE_LOCAL, order = 1, width = 'full',
                        get = function() return Clock.db.profile.useLocalTime end,
                        set = function(_, value)
                            Clock.db.profile.useLocalTime = value
                            Clock:UpdateClock()
                        end,
                    },
                    military = {
                        type = 'toggle', name = L.H24, order = 2, width = 'full',
                        get = function() return Clock.db.profile.use24Hour end,
                        set = function(_, value)
                            Clock.db.profile.use24Hour = value
                            Clock:UpdateClock()
                        end,
                    },
                },
            },
            size = {
                type = 'group', inline = true, name = L.SECTION_SIZE, order = 3,
                disabled = Off,
                args = {
                    clockSize = {
                        type = 'range', order = 1,
                        name = L.SIZE_LABEL,
                        desc = L.SIZE_DESC,
                        min = 1, max = 3, step = 1,
                        dialogControl = 'CantPlayForeverSizeSlider',
                        get = function()
                            local size = Clock:GetClockDiameter()
                            return size == 32 and 1 or size == 64 and 2 or 3
                        end,
                        set = function(_, value)
                            local sizes = { 32, 64, 95 }
                            local index = math.max(1, math.min(3, math.floor(value + 0.5)))
                            Clock:SetClockSize(sizes[index])
                        end,
                    },
                },
            },
            position = {
                type = 'group', inline = true, name = L.SECTION_POSITION, order = 4,
                disabled = Off,
                args = {
                    resetPosition = {
                        type = 'execute', name = L.RESET_POS, order = 1,
                        desc = L.RESET_POS_DESC,
                        func = function() Clock:ResetClockPosition() end,
                    },
                },
            },
        },
    }
end
