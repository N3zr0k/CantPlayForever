local ADDON_NAME, ns = ...
if not ns.Clock then return end
local Clock, L, Between, Now = ns.Clock, ns.L, ns.Between, ns.Now

-- Vier im Spiel vorhandene SoundKits (Blizzard-ID als Fallback, falls
-- SOUNDKIT im Forever-Client die jeweilige Konstante nicht definiert).
local ALARM_SOUNDS = {
    alarm1 = {key='ALARM_CLOCK_WARNING_1', id=18871},
    alarm2 = {key='ALARM_CLOCK_WARNING_2', id=12867},
    alarm3 = {key='ALARM_CLOCK_WARNING_3', id=12889},
    ready  = {key='READY_CHECK',           id=8960},
}

function Clock:PlayAlarmSound()
    if not self.db.profile.playSound or type(_G.PlaySound) ~= 'function' then return end
    local sound = ALARM_SOUNDS[self.db.profile.alarmSound] or ALARM_SOUNDS.alarm2
    local id = (_G.SOUNDKIT and _G.SOUNDKIT[sound.key]) or sound.id
    pcall(_G.PlaySound, id, 'Master')
end

-- Eine Soundfolge pro Alarm, standardmäßig genau zweimal. Die Folgetöne
-- werden im vorhandenen 1-Sekunden-Ticker ohne neue Timer/OnUpdate ausgelöst.
function Clock:StartAlarmSoundSequence()
    if not self.db.profile.playSound then return end
    local count = Between(self.db.profile.alarmRepeats, 1, 10)
    self:PlayAlarmSound()
    self.pendingAlarmSounds = self.pendingAlarmSounds or {}
    local now = (type(_G.GetTime) == 'function' and _G.GetTime()) or Now()
    for number = 2, count do
        self.pendingAlarmSounds[#self.pendingAlarmSounds + 1] = now + (number - 1) * 2
    end
end

function Clock:UpdateAlarmSoundSequence()
    if not self.pendingAlarmSounds then return end
    local now = (type(_G.GetTime) == 'function' and _G.GetTime()) or Now()
    for i = #self.pendingAlarmSounds, 1, -1 do
        if now >= self.pendingAlarmSounds[i] then
            table.remove(self.pendingAlarmSounds, i)
            self:PlayAlarmSound()
        end
    end
end

-- Custom screen text is deliberately created with WoW's own font objects:
-- no image assets and no modal popup that blocks gameplay.
local function NoticeTime()
    return (type(_G.GetTime) == 'function' and _G.GetTime()) or Now()
end

function Clock:InitializeAlarmNotice()
    if self.noticeText then return end
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetSize(720, 170)
    frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 135)
    frame:SetFrameStrata('HIGH')
    local text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalHuge')
    text:SetPoint('CENTER', frame, 'CENTER')
    text:SetWidth(700)
    text:SetJustifyH('CENTER')
    text:SetTextColor(1, 0.14, 0.14, 1)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(2, -2)
    text:SetText('')
    frame:Hide()
    self.noticeFrame = frame
    self.noticeText = text
    self.recentAlerts = {}
end

function Clock:UpdateAlarmNotice()
    if not self.recentAlerts or not self.noticeFrame then return end
    local now = NoticeTime()
    for i = #self.recentAlerts, 1, -1 do
        if self.recentAlerts[i].expiresAt <= now then
            table.remove(self.recentAlerts, i)
        end
    end
    if #self.recentAlerts == 0 then
        self.noticeFrame:Hide()
        self:ClearGlow('alert')
        self:HideScreenGlow()
        return
    end
    -- Nur zwei Zeilen: Addonname, dann Nachricht des letzten Alarms.
    local active = self.recentAlerts[#self.recentAlerts]
    self.noticeText:SetText("Can't play Forever\n" .. active.message)
    self.noticeFrame:Show()
end

function Clock:Alert(message)
    message = tostring(message or L.ALARM_GENERIC)
    self:Debug('Alert: %s', message)
    message = message:gsub('[\r\n\t]', ' '):gsub('|', '')
    self:InitializeAlarmNotice()
    local number = Between(self.db.profile.alarmRepeats, 1, 10)
    local visibleFor = math.max(9, (number - 1) * 2 + 3)
    self.recentAlerts[#self.recentAlerts + 1] = {
        message = message, expiresAt = NoticeTime() + visibleFor,
    }
    -- Rot, schnell pulsierend, solange die Meldung sichtbar ist (Priorität 40).
    local speed = Between(tonumber(self.db.profile.glowSpeed) or 1, 0.3, 5) -- Pulse pro Sekunde
    self:SetGlow('alert', string.format('FF2619, pulse, %.3f, 100, fill', 1 / speed), 40)
    self:ShowScreenGlow()
    self:UpdateAlarmNotice()
    self:StartAlarmSoundSequence()
end
