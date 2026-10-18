-- /cpf probe ... : Diagnose- und Testbefehle für Can't play Forever.
--   /cpf probe ring                       Ring-Atlas prüfen und Vorschau ein-/ausblenden
--   /cpf probe glow FF8000, pulse, 2, 55  Leuchten 10 Sekunden zeigen (off = beenden)
--   /cpf probe alert                      Alarmmeldung samt Leuchten und Ton testen
--   /cpf probe tune                       Tuning-Fenster mit Testbühne
--   /cpf test                             Alarm testen
--   /cpf frame                            Rahmen-Diagnose (FrameDump.lua)
local addon = _G.LibStub and LibStub('AceAddon-3.0', true)
local Clock = addon and addon:GetAddon('CantPlayForever', true)
if not (Clock and Clock.RegisterModule and _G.FrameDebugger) then return end
local L = Clock.L

local function Probe(self, args)
    args = tostring(args or ''):match('^%s*(.-)%s*$')
    local command, rest = args:match('^(%S+)%s*(.*)$')
    if command == 'ring' then
        local info = Clock.RingAtlasInfo and Clock.RingAtlasInfo()
        if info then
            self:Print(string.format('Atlas %s: %sx%s', tostring(Clock.RING_ATLAS),
                tostring(info.width), tostring(info.height)))
        else
            self:Print('Atlas ' .. tostring(Clock.RING_ATLAS) .. ': nicht vorhanden')
        end
        self:ToggleRingPreview()
    elseif command == 'glow' then
        self.probeToken = (self.probeToken or 0) + 1
        if rest == 'off' or rest == '' then
            self:ClearGlow('probe')
        elseif not self:SetGlow('probe', rest, 100) then
            self:Print('Format: /cpf probe glow FARBCODE, static|pulse|blink, [Sekunden,] Prozent  –  z. B. FF8000, pulse, 2, 55')
        elseif _G.C_Timer and type(C_Timer.After) == 'function' then
            local token = self.probeToken
            C_Timer.After(10, function()
                if self.probeToken == token then self:ClearGlow('probe') end
            end)
        end
    elseif command == 'alert' then
        self:Alert(L.TEST_ALARM)
    elseif command == 'tune' then
        if _G.FrameDebugger then FrameDebugger:Open('CantPlayForever') else self:Print('Tuning-Modul nicht geladen') end
    else
        self:Print('/cpf probe ring | /cpf probe glow FARBCODE, static|pulse|blink, [Sekunden,] Prozent | /cpf probe glow off | /cpf probe alert | /cpf probe tune')
    end
end

Clock:RegisterModule({
    id = 'probe',
    locked = true,
    hidden = true,
    OnSlash = function(self, input)
        if input == 'frame' then
            self:DumpOptionsFrame()
            return true
        elseif input == 'test' then
            self:Alert(L.TEST_ALARM)
            return true
        end
        if input == 'probe' or input:match('^probe%s') then
            Probe(self, input:match('^probe%s+(.*)$') or '')
            return true
        end
    end,
})
