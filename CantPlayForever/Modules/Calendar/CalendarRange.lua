local _, ns = ...
if not ns.Clock then return end
local Clock = ns.Clock

-- Tage im Voraus, fuer die wiederholende Alarme im Kalender stehen (Einstellung, Standard 60)
function Clock:CalendarShowDays()
    return math.min(365, math.max(1, math.floor(tonumber(self.db and self.db.profile.calLinkShowDays) or 60)))
end

-- Einzelalarm (festes Datum, keine Wiederholung): steht immer im Kalender, egal wie weit voraus
local function IsSingleAlarm(alarm)
    if alarm.everyMonth or alarm.everyYear then return false end
    for wday = 1, 7 do
        if alarm.days and alarm.days[wday] then return false end
    end
    return true
end

-- Liegt der Alarm "ahead" Tage nach heute im Kalenderzeitraum? Einzelalarme immer, wiederholende nur im Zeitraum.
function Clock:AlarmInRange(alarm, ahead)
    return ahead >= 0 and (IsSingleAlarm(alarm) or ahead <= self:CalendarShowDays())
end

-- Alle Tage (ab heute, "ahead") im Kalenderzeitraum, an denen der Alarm laeuft.
function Clock:AlarmAheadDays(alarm, year, month, day)
    local list = {}
    local run = ns.AlarmRunsOnDay
    if not run then return list end
    if IsSingleAlarm(alarm) then
        if alarm.year and alarm.month and alarm.day then
            local ahead = math.floor(time({ year = alarm.year, month = alarm.month, day = alarm.day, hour = 12 }) / 86400)
                - math.floor(time({ year = year, month = month, day = day, hour = 12 }) / 86400)
            if ahead >= 0 and run(alarm, ahead, year, month, day) then list[1] = ahead end
        end
        return list
    end
    for ahead = 0, self:CalendarShowDays() do
        if run(alarm, ahead, year, month, day) then list[#list + 1] = ahead end
    end
    return list
end
