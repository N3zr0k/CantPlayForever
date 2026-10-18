local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L = ns.Clock, ns.L

-- Das Blizzard-Infoicon ist im Original gruen. Ein RGB-Tint allein
-- veraendert dessen Grundfarbe nicht zu Blau. Daher zuerst entsaettigen,
-- erst danach blau einfaerben. Ein WoW-Texture-Objekt ist hier notwendig:
-- Inline-|T...|t kann die Quelldatei nicht entsaettigen.
local PLAYTIME_INFO_TEXTURE = 'Interface\\FriendsFrame\\InformationIcon'
local PLAYTIME_INFO_R, PLAYTIME_INFO_G, PLAYTIME_INFO_B = 0.30, 0.70, 1.00

local function AddBlueInfoHint(tooltip)
    local hint = L.PLAYTIME_SHIFT_HINT
    -- Sicherer Text-Fallback fuer namenlose Tooltip-Varianten: immer blau,
    -- niemals das original gruene Inline-Bild.
    tooltip:AddLine('|cff4db3ff(i)|r ' .. hint,
        PLAYTIME_INFO_R, PLAYTIME_INFO_G, PLAYTIME_INFO_B)

    local name = tooltip.GetName and tooltip:GetName()
    local line = tooltip.NumLines and tooltip:NumLines()
    local label = name and line and _G[name .. 'TextLeft' .. line]
    if not (label and label.SetText and type(tooltip.CreateTexture) == 'function') then return end

    local icon = tooltip.cpfPlaytimeInfoIcon
    if not icon then
        icon = tooltip:CreateTexture(nil, 'OVERLAY')
        icon:SetTexture(PLAYTIME_INFO_TEXTURE)
        icon:SetSize(13, 13)
        icon:SetDesaturated(true) -- Originalfarbe entfernen
        icon:SetVertexColor(PLAYTIME_INFO_R, PLAYTIME_INFO_G, PLAYTIME_INFO_B) -- danach Blau
        tooltip.cpfPlaytimeInfoIcon = icon
    end
    -- Leerraum reservieren, damit sich Text und Textur nicht ueberlagern.
    label:SetText('     ' .. hint)
    icon:Hide()
    icon:ClearAllPoints()
    icon:SetPoint('LEFT', label, 'LEFT', 0, 0)
    icon:Show()
end

-- LibDBIcon nutzt einen eigenen, wiederverwendeten GameTooltip.
-- Die Felder werden während des Mouseovers aktualisiert, ohne ihn
-- bei jeder Sekunde zu schließen oder den Mouseover neu auszulösen.
function Clock:TooltipSignature()
    local fields = {self.db.profile.activeTimer and 'timer' or 'no-timer', 'cover:' .. tostring(self.coverName),
        'shift:' .. tostring(type(_G.IsShiftKeyDown) == 'function' and IsShiftKeyDown() or false),
        'played:' .. tostring(self.playtimeReceived == true),
        'fresh:' .. tostring(self.playtimeFreshForHover == true),
        'pending:' .. tostring(self.playtimePending == true)}
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed then
            fields[#fields + 1] = tostring(alarm.id) .. ':'
                .. tostring(alarm.hour) .. ':' .. tostring(alarm.minute)
                .. ':' .. tostring(alarm.name) .. ':' .. tostring(alarm.alarmType)
                .. ':' .. tostring(alarm.customEffect and alarm.effect and alarm.effect.spec)
        end
    end
    return table.concat(fields, ';')
end

-- WoW-Klassenfarben mit Fallback für Forever-Clients, die die globalen
-- Tabellen beim Anzeigen des Tooltips noch nicht bereitstellen.
local FALLBACK_CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43}, PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45}, ROGUE = {1, 0.96, 0.41},
    PRIEST = {1, 1, 1}, SHAMAN = {0, 0.44, 0.87},
    MAGE = {0.25, 0.78, 0.92}, WARLOCK = {0.53, 0.53, 0.93},
    DRUID = {1, 0.49, 0.04}, DEATHKNIGHT = {0.77, 0.12, 0.23},
    MONK = {0, 1, 0.6}, DEMONHUNTER = {0.64, 0.19, 0.79},
    EVOKER = {0.20, 0.58, 0.50},
}

local function ClassRGB(classFile)
    -- Forever bietet die aktuelle Klassenfarbe auch ueber C_ClassColor an.
    -- Diese API funktioniert, wenn RAID_CLASS_COLORS noch nicht gefuellt ist.
    local api = _G.C_ClassColor
    if classFile and type(api) == 'table' and type(api.GetClassColor) == 'function' then
        local ok, color = pcall(api.GetClassColor, classFile)
        if ok and color then return color.r or 0.7, color.g or 0.7, color.b or 0.7 end
    end
    local custom = _G.CUSTOM_CLASS_COLORS
    local standard = _G.RAID_CLASS_COLORS
    local color = (type(custom) == 'table' and custom[classFile])
        or (type(standard) == 'table' and standard[classFile])
    if color then return color.r or 0.7, color.g or 0.7, color.b or 0.7 end
    local fallback = FALLBACK_CLASS_COLORS[classFile]
    if fallback then return fallback[1], fallback[2], fallback[3] end
    return 0.7, 0.7, 0.7
end

-- Faction-Embleme aus Blizzards UI; kein weiteres Addon oder eigenes Bild nötig.
local FACTION_ICONS = {
    Alliance = 'Interface\\PVPFrame\\PVP-Currency-Alliance',
    Horde = 'Interface\\PVPFrame\\PVP-Currency-Horde',
}

local function CharacterLabel(name, classFile, faction)
    local r, g, b = ClassRGB(classFile)
    local icon = FACTION_ICONS[faction]
    local prefix = icon and ('|T' .. icon .. ':14:14:0:0|t ') or ''
    -- Explizite Farb-Tags sichern die Klassenfarbe im GameTooltip, selbst wenn
    -- eine andere Tooltip-Erweiterung die Standard-Textfarbe überschreibt.
    local className = string.format('|cff%02x%02x%02x%s|r',
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5), name)
    return prefix .. className, r, g, b
end

-- Hinweiszeile "Taste: Wirkung" als zweispaltige Zeile (Taste gold, Wirkung hell).
local function AddHint(tooltip, text)
    local key, action = tostring(text):match('^(.-)%s*:%s*(.+)$')
    if key then
        tooltip:AddDoubleLine(key, action, 1, 0.82, 0, 0.85, 0.85, 0.85)
    else
        tooltip:AddLine(text, 0.85, 0.85, 0.85)
    end
end

function Clock:BuildHoverTooltip(tooltip)
    -- Der Tooltip gehoert LibDBIcon und wird auch von anderen Addons benutzt.
    -- Nach Shift-/Reiterwechsel keine alte Info-Textur stehen lassen.
    if tooltip.cpfPlaytimeInfoIcon then tooltip.cpfPlaytimeInfoIcon:Hide() end
    self.hoverTooltip = tooltip
    self.hoverSignature = self:TooltipSignature()
    tooltip:AddLine("Can't play Forever", 1, 0.82, 0)
    self.hoverClockLine = tooltip:NumLines() + 1
    tooltip:AddDoubleLine(L.CLOCK_LABEL, self:FormatTooltipTime(),
        1, 0.82, 0.25, 1, 1, 1)

    -- Laufender Timer direkt an der Uhrzeit: vor Sessions und /played.
    self.hoverTimerLine = nil
    local remaining = self:RemainingTimer()
    if remaining then
        self.hoverTimerLine = tooltip:NumLines() + 1
        tooltip:AddDoubleLine(L.TIMER_LABEL, self:Duration(remaining),
            0.75, 0.75, 0.75, .39, .79, 1)
    end

    -- Der Sessionblock bleibt ohne Shift sichtbar. Seine Zeiten sind hh:mm:ss.
    tooltip:AddLine(' ')
    tooltip:AddLine(L.PLAYTIME_SESSION_HEADER, 1, 0.82, 0)
    self.hoverSessionLine = tooltip:NumLines() + 1
    tooltip:AddDoubleLine(L.PLAYTIME_SESSION, self:Duration(self:GetSessionSeconds()),
        0.75, 0.75, 0.75, 1, 1, 1)
    self.hoverLastSessionLine = tooltip:NumLines() + 1
    local lastSession = self:GetLastSessionSeconds()
    tooltip:AddDoubleLine(L.PLAYTIME_LAST_SESSION,
        lastSession and self:Duration(lastSession) or L.PLAYTIME_UNAVAILABLE,
        0.75, 0.75, 0.75, 1, 1, 1)
    self.hoverPlayedLines = nil
    self.hoverCharacterLines = nil
    -- Ein gemeinsamer Platz direkt unter den Sessions: entweder der blaue
    -- Shift-Hinweis oder (mit Shift) die Überschrift "Spielzeit".
    -- Der Abstand zur Session und zu den nachfolgenden Daten bleibt bestehen.
    tooltip:AddLine(' ')
    if type(_G.IsShiftKeyDown) == 'function' and IsShiftKeyDown() then
        tooltip:AddLine(L.PLAYTIME_TOTAL_HEADER, 1, 0.82, 0)
        local current = self:GetServerPlayedSeconds()
        local level = self:GetServerLevelSeconds()
        local account, count, characters = self:GetAccountPlayedSeconds()
        local lines = {}
        local function PlaytimeRow(label, value)
            local line = tooltip:NumLines() + 1
            local unavailable = self.playtimePending and L.PLAYTIME_LOADING or L.PLAYTIME_UNAVAILABLE
            tooltip:AddDoubleLine(label, value == nil and unavailable or self:FormatPlayedDuration(value),
                0.75, 0.75, 0.75, 1, 1, 1)
            lines[#lines + 1] = {line = line, label = label}
        end
        PlaytimeRow(L.PLAYTIME_CHARACTER, current)
        PlaytimeRow(L.PLAYTIME_LEVEL, level)
        PlaytimeRow(L.PLAYTIME_ACCOUNT,
            self.playtimeFreshForHover and count > 0 and account or nil)

        -- Forever-Namen enthalten Vor- und Nachnamen. Gleichnamige Alt-Eintraege
        -- bleiben ueber die GUID getrennt; Realm nur bei echten Namensduplikaten.
        if #characters > 0 then
            tooltip:AddLine(L.PLAYTIME_CHARACTERS_HEADER, 0.55, 0.55, 0.55)
            local duplicateNames = {}
            for _, char in ipairs(characters) do
                duplicateNames[char.name] = (duplicateNames[char.name] or 0) + 1
            end
            local characterLines = {}
            for _, char in ipairs(characters) do
                local name = char.name
                if duplicateNames[name] > 1 and char.realm ~= '' then
                    name = name .. '-' .. char.realm
                end
                local charLabel, r, g, b = CharacterLabel(name, char.classFile, char.faction)
                local line = tooltip:NumLines() + 1
                local played = (not char.isCurrent or self.playtimeFreshForHover) and char.played or nil
                local unavailable = char.isCurrent and self.playtimePending and L.PLAYTIME_LOADING
                    or L.PLAYTIME_UNAVAILABLE
                tooltip:AddDoubleLine('  ' .. charLabel,
                    played == nil and unavailable or self:FormatPlayedDuration(played),
                    r, g, b, r, g, b)
                characterLines[#characterLines + 1] = {line = line, guid = char.guid}
            end
            self.hoverCharacterLines = characterLines
        end
        self.hoverPlayedLines = lines
    else
        AddBlueInfoHint(tooltip)
    end
    local active = {}
    for _, alarm in ipairs(self.db.profile.alarms) do
        if alarm.armed then active[#active + 1] = alarm end
    end
    if #active > 0 then
        table.sort(active, function(a,b)
            local minsA = self:AlarmMinutesUntil(a)
            local minsB = self:AlarmMinutesUntil(b)
            if minsA == minsB then return (a.id or 0) < (b.id or 0) end
            return minsA < minsB
        end)
        tooltip:AddLine(' ')
        tooltip:AddLine(L.ARMED_HEADER, .35, 1, .35)
        for _, alarm in ipairs(active) do
            tooltip:AddDoubleLine(string.format('%02d:%02d', alarm.hour, alarm.minute),
                (function()
                    local name = ns.AlarmDisplayName(alarm, L.ALARM_FALLBACK, 14)
                    local override = self:GetAlarmEffectOverride(alarm)
                    if override then
                        local hex = self:GetEffectColorHex('alarms', override)
                        return '|cff' .. hex .. name .. '|r'
                    end
                    return name
                end)(),
                1, 1, 1, .75, 1, .75)
        end
    end
    tooltip:AddLine(' ')
    AddHint(tooltip, L.LEFT_CLICK)
    AddHint(tooltip, L.RIGHT_CLICK)
    AddHint(tooltip, L.CTRL_LEFT)
    AddHint(tooltip, L.STOPWATCH_HINT)
    AddHint(tooltip, L.BLIZZARD_CLOCK_HINT)
    AddHint(tooltip, self:GetClockDiameter() == 95 and L.DRAG_FREE or L.DRAG_MINIMAP)
    if self.coverName then
        -- LibDBIcon-Symbole heißen "LibDBIcon10_<Addon>"; angezeigt wird nur der Addon-Name.
        local shown = tostring(self.coverName):gsub('^LibDBIcon%d*_', '')
        tooltip:AddLine(' ')
        tooltip:AddLine(string.format(L.COVERS_ICON, shown), 0.6, 0.6, 0.6)
    end
end

function Clock:UpdateHoverTooltip()
    local tooltip = self.hoverTooltip
    if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then return end
    -- LibDBIconTooltip ist gemeinsam mit anderen Addons nutzbar.
    if tooltip.GetOwner and tooltip:GetOwner() ~= self.iconButton then return end
    local signature = self:TooltipSignature()
    if signature ~= self.hoverSignature then
        tooltip:ClearLines()
        self:BuildHoverTooltip(tooltip)
        tooltip:Show()
        return
    end
    local name = tooltip.GetName and tooltip:GetName()
    if not name or name == '' then
        -- Fallback für Clients, die FontStrings nicht namentlich exponieren.
        tooltip:ClearLines()
        self:BuildHoverTooltip(tooltip)
        tooltip:Show()
        return
    end
    local timeText = _G[name .. 'TextRight' .. self.hoverClockLine]
    if timeText then
        timeText:SetText(self:FormatTooltipTime())
    end
    if self.hoverSessionLine then
        local sessionText = _G[name .. 'TextRight' .. self.hoverSessionLine]
        if sessionText then sessionText:SetText(self:Duration(self:GetSessionSeconds())) end
    end
    if self.hoverLastSessionLine then
        local lastSessionText = _G[name .. 'TextRight' .. self.hoverLastSessionLine]
        if lastSessionText then
            local lastSession = self:GetLastSessionSeconds()
            lastSessionText:SetText(lastSession and self:Duration(lastSession) or L.PLAYTIME_UNAVAILABLE)
        end
    end
    if self.hoverPlayedLines then
        local account, count = self:GetAccountPlayedSeconds()
        local values = {
            self:GetServerPlayedSeconds(),
            self:GetServerLevelSeconds(),
            self.playtimeFreshForHover and count > 0 and account or nil,
        }
        for i, row in ipairs(self.hoverPlayedLines) do
            local playedText = _G[name .. 'TextRight' .. row.line]
            if playedText then
                local unavailable = self.playtimePending and L.PLAYTIME_LOADING or L.PLAYTIME_UNAVAILABLE
                playedText:SetText(values[i] == nil and unavailable or self:FormatPlayedDuration(values[i]))
            end
        end
    end
    if self.hoverCharacterLines then
        local _, _, characters = self:GetAccountPlayedSeconds()
        local byGuid = {}
        for _, char in ipairs(characters) do byGuid[char.guid] = char end
        for _, row in ipairs(self.hoverCharacterLines) do
            local text = _G[name .. 'TextRight' .. row.line]
            local char = byGuid[row.guid]
            if text and char then
                local value = (not char.isCurrent or self.playtimeFreshForHover) and char.played or nil
                local unavailable = char.isCurrent and self.playtimePending and L.PLAYTIME_LOADING
                    or L.PLAYTIME_UNAVAILABLE
                text:SetText(value == nil and unavailable or self:FormatPlayedDuration(value))
            end
        end
    end
    if self.hoverTimerLine then
        local timerText = _G[name .. 'TextRight' .. self.hoverTimerLine]
        if timerText then
            timerText:SetText(self:Duration(self:RemainingTimer() or 0))
        end
    end
end
