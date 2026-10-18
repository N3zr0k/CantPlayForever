"""Structural checks for session timing, Shift tooltip and centered header logo."""
from pathlib import Path
import re
import unittest

BASE = Path(__file__).resolve().parents[1] / 'CantPlayForever'


class PlaytimeUITests(unittest.TestCase):
    def test_source_loads_before_modules(self):
        xml = (BASE/'Core/Core.xml').read_text(encoding='utf8')
        self.assertIn('<Script file="Playtime.lua"/>', xml)
        self.assertLess(xml.index('Playtime.lua'), xml.index('Options.lua'))
        core = (BASE/'Core/Core.lua').read_text(encoding='utf8')
        for method in ('self.InitializePlaytime)', 'self.EnablePlaytime)', 'self.PlaytimeOnTick)'):
            self.assertIn(method, core)

    def test_accountwide_by_guid_and_server_played(self):
        code=(BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        self.assertIn("frame:RegisterEvent('TIME_PLAYED_MSG')", code)
        self.assertIn('pcall(_G.RequestTimePlayed)', code)
        self.assertIn('chars[guid]', code)
        self.assertIn('self.db.global.playtime', code)
        self.assertIn("frame:RegisterEvent('PLAYER_LOGOUT')", code)

    def test_session_always_displayed_and_shift_details(self):
        code=(BASE/'Modules/Clock/Tooltip.lua').read_text(encoding='utf8')
        self.assertLess(code.index('L.CLOCK_LABEL, self:FormatTooltipTime()'),
                        code.index('L.PLAYTIME_SESSION, self:Duration(self:GetSessionSeconds())'))
        self.assertLess(code.index('L.PLAYTIME_SESSION, self:Duration(self:GetSessionSeconds())'),
                        code.index('if type(_G.IsShiftKeyDown)'))
        self.assertIn('GetAccountPlayedSeconds()',code)
        self.assertNotIn('AddPlaytimeDivider(tooltip)',code)
        self.assertNotIn('UI-TooltipDivider-Transparent',code)
        self.assertIn("tooltip:AddLine(L.PLAYTIME_TOTAL_HEADER, 1, 0.82, 0)\n        local current =", code)
        self.assertNotIn("string.rep('-', 44)",code)
        self.assertIn("'shift:'",code)

    def test_logo_restores_stable_031_implementation(self):
        logo = (BASE/'Modules/Clock/OptionsLogo.lua').read_text(encoding='utf8')
        self.assertIn('local TAB_LOGOS = {', logo)
        self.assertNotIn("general = LOGO_PATH", logo)  # Allgemein zeigt die laufende Uhr
        self.assertIn("health = LOGO_PATH .. 'pause_logo'", logo)
        self.assertIn("tab == 'general'", logo)
        self.assertIn('function Clock:ApplyOptionsLayout()', logo)
        core = (BASE/'Core/Core.lua').read_text(encoding='utf8')
        for key in ('OPT_CLOCK_DX','OPT_CLOCK_SIZE','OPT_TIME_SIZE','OPT_CLOSE_X','OPT_CLOSE_Y',
                    'OPT_TITLE_X','OPT_TAGLINE_DY','OPT_CONTENT_TOP'):
            self.assertIn(key, core)
            self.assertIn('T.'+key, logo)
        self.assertIn('PlaceMover(open, shown)', logo)  # ganze Kopfzeile verschiebt das Fenster
        self.assertIn('if logo.skinned then', logo)  # im Rahmen nur Uhrzeit, keine Logos
        self.assertIn('Clock:FormatClock()', logo)
        # Blizzard-Uhrenfenster-Rahmen: Spielatlanten, rotes X, kein Schliessen-Knopf unten
        for atlas in ('UI-Frame-PortraitMetal-CornerTopLeft', '_UI-Frame-Metal-EdgeTop',
                      'RedButton-Exit', '_UI-Frame-TopTileStreaks'):
            self.assertIn(atlas, logo)
        self.assertIn('aceClose:SetShown(not shown)', logo)
        self.assertIn('logo.default:Show()', logo)
        self.assertNotIn('LayoutHeaderTabs', logo)
        self.assertNotIn('HEADER_GAP', logo)

    def test_playtime_cannot_block_core_tick_and_collision(self):
        code = (BASE/'Core/Core.lua').read_text(encoding='utf8')
        self.assertIn("self:GuardedTick('playtime', self.PlaytimeOnTick)", code)
        self.assertIn("self:GuardedTick('playtime.enable', self.EnablePlaytime)", code)
        self.assertIn("self:GuardedTick('playtime.initialize', self.InitializePlaytime)", code)
        self.assertNotIn('        self:PlaytimeOnTick()\n', code)
        self.assertIn("self:GuardedTick('compartment.register', self.RegisterAddonCompartment)", code)
        self.assertIn("self:GuardedTick('modules.enable', function(core) core:RunHook('OnEnable') end)", code)
        self.assertIn("self:GuardedTick('options.style', self.StyleOptionsFrame)", code)
        clock = (BASE/'Modules/Clock/Clock.lua').read_text(encoding='utf8')
        self.assertIn('if self.UpdateCoverGlow then self:UpdateCoverGlow() end', clock)
        glow = (BASE/'Modules/Clock/Glow.lua').read_text(encoding='utf8')
        self.assertIn('function Clock:IsCoveringSomething()', glow)
        self.assertIn("self:SetGlow('cover'", glow)

    def test_reload_is_not_logout_and_has_last_session(self):
        code = (BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        self.assertIn("function Clock:PlaytimeEnteringWorld(isInitialLogin, isReloadingUi)", code)
        self.assertIn('isReloadingUi == true', code)
        self.assertIn('record.lastSessionSeconds', code)
        self.assertIn('session.pendingExitAt', code)
        self.assertIn('function Clock:GetLastSessionSeconds()', code)
        self.assertIn('SampleDelta(record, self.sessionStartedAt, logoutEstimate ~= nil)', code)
        self.assertIn('record.logoutTotalPlayed', code)
        self.assertIn('record.logoutSavedAt', code)
        self.assertIn('function Clock:GetServerPlayedSeconds()', code)
        self.assertIn('function Clock:GetServerLevelSeconds()', code)

    def test_shift_requests_and_modifier_changes(self):
        playtime = (BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        tooltip = (BASE/'Modules/Clock/Tooltip.lua').read_text(encoding='utf8')
        self.assertIn("frame:RegisterEvent('MODIFIER_STATE_CHANGED')", playtime)
        self.assertIn('function Clock:RequestPlayedOnHover()', playtime)
        self.assertIn("self.playtimeRequestAllowedAt = now + PLAYED_REFRESH_SECONDS", playtime)
        self.assertIn("L.PLAYTIME_LAST_SESSION", tooltip)
        self.assertIn('self:RequestPlayedOnHover()', (BASE/'Modules/Clock/Clock.lua').read_text(encoding='utf8'))
        self.assertIn('function Clock:RequestPlayedOnShift()', playtime)
        self.assertIn('self:RequestPlayedOnShift()', playtime)
        self.assertIn('local PLAYED_INITIAL_DELAY = 30', playtime)
        self.assertIn('record.nextAutoPlayedAt = now + PLAYED_INITIAL_DELAY', playtime)
        self.assertIn('recordForSchedule.nextAutoPlayedAt = nextAt', playtime)
        self.assertIn('self:StorePlayedTime(...)', playtime)
        self.assertNotIn('self.playtimeNextRequest = Uptime() + PLAYED_REFRESH_SECONDS', playtime)
        self.assertNotIn('self:RequestPlayedOnHover()', tooltip)
        self.assertIn('L.PLAYTIME_LOADING', tooltip)
        for locale in ('deDE', 'enUS', 'frFR'):
            code = (BASE/'Core/Locales'/f'{locale}.lua').read_text(encoding='utf8')
            self.assertIn('L.PLAYTIME_LAST_SESSION', code)
            self.assertIn('L.PLAYTIME_LOADING', code)

    def test_played_uses_localized_units_sessions_keep_hms(self):
        playtime = (BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        tooltip = (BASE/'Modules/Clock/Tooltip.lua').read_text(encoding='utf8')
        self.assertIn('function Clock:FormatPlayedDuration(seconds)', playtime)
        self.assertIn('seconds % 86400', playtime)
        self.assertIn('seconds % 3600', playtime)
        self.assertIn('self:FormatPlayedDuration(value)', tooltip)
        self.assertIn('self:FormatPlayedDuration(values[i])', tooltip)
        self.assertIn('self:Duration(self:GetSessionSeconds())', tooltip)
        self.assertIn('self:Duration(lastSession)', tooltip)
        for locale in ('deDE', 'enUS', 'frFR'):
            code = (BASE/'Core/Locales'/f'{locale}.lua').read_text(encoding='utf8')
            for unit in ('DAY', 'HOUR', 'MINUTE'):
                self.assertIn('L.PLAYTIME_' + unit + '_ONE', code)
                self.assertIn('L.PLAYTIME_' + unit + '_MANY', code)

    def test_playtime_sections_and_class_colored_character_list(self):
        tooltip = (BASE/'Modules/Clock/Tooltip.lua').read_text(encoding='utf8')
        playtime = (BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        self.assertNotIn('HighlightClockTime(', tooltip)
        self.assertNotIn('GameFontHighlightLarge', tooltip)
        self.assertIn('1, 0.82, 0.25, 1, 1, 1)', tooltip)
        self.assertIn('L.PLAYTIME_SESSION_HEADER', tooltip)
        self.assertIn('L.PLAYTIME_TOTAL_HEADER', tooltip)
        self.assertIn('L.PLAYTIME_SHIFT_HINT', tooltip)
        self.assertIn(r"FriendsFrame\\InformationIcon", tooltip)
        self.assertIn('icon:SetDesaturated(true)', tooltip)
        self.assertIn('icon:SetVertexColor(PLAYTIME_INFO_R, PLAYTIME_INFO_G, PLAYTIME_INFO_B)', tooltip)
        self.assertLess(tooltip.index('icon:SetDesaturated(true)'), tooltip.index('icon:SetVertexColor('))
        self.assertIn("tooltip:AddLine('|cff4db3ff(i)|r ' .. hint", tooltip)
        self.assertIn('AddBlueInfoHint(tooltip)', tooltip)
        self.assertNotIn('PLAYTIME_INFO_ICON = "|T', tooltip)
        self.assertIn('if tooltip.cpfPlaytimeInfoIcon then tooltip.cpfPlaytimeInfoIcon:Hide() end', tooltip)
        self.assertIn('self.hoverTooltip.cpfPlaytimeInfoIcon:Hide()',
                      (BASE/'Modules/Clock/Clock.lua').read_text(encoding='utf8'))
        self.assertIn('L.PLAYTIME_CHARACTERS_HEADER', tooltip)
        self.assertLess(tooltip.index('L.PLAYTIME_ACCOUNT,'), tooltip.index('for _, char in ipairs(characters) do'))
        self.assertIn('CharacterLabel(name, char.classFile, char.faction)', tooltip)
        self.assertIn("tooltip:AddDoubleLine('  ' .. charLabel", tooltip)
        self.assertIn('r, g, b, r, g, b)', tooltip)
        self.assertIn('self.hoverCharacterLines = characterLines', tooltip)
        self.assertIn('record.classFile = classFile or record.classFile', playtime)
        self.assertIn('record.faction = faction or record.faction', playtime)
        self.assertIn('classFile = record.classFile', playtime)
        self.assertIn('faction = record.faction', playtime)
        self.assertIn("_G.GetUnitName('player', false)", playtime)
        self.assertIn('HasSurname(record.name)', playtime)
        self.assertIn('C_ClassColor', tooltip)
        self.assertIn('PVP-Currency-Alliance', tooltip)
        self.assertIn('PVP-Currency-Horde', tooltip)
        self.assertIn('L.TIMER_LABEL, self:Duration(remaining)', tooltip)
        self.assertLess(tooltip.index('L.TIMER_LABEL, self:Duration(remaining)'),
                        tooltip.index('L.PLAYTIME_SESSION_HEADER'))
        self.assertIn('L.PLAYTIME_TOTAL_HEADER', tooltip)
        self.assertIn('local played = SafeSeconds(record.totalPlayed)', playtime)
        for locale in ('deDE', 'enUS', 'frFR'):
            content = (BASE/'Core/Locales'/f'{locale}.lua').read_text(encoding='utf8')
            self.assertIn('L.PLAYTIME_SHIFT_HINT =', content)
            for key in ('SESSION_HEADER', 'TOTAL_HEADER', 'CHARACTERS_HEADER'):
                self.assertIn('L.PLAYTIME_' + key + ' =', content)

    def test_background_and_shift_played_queries_do_not_spam_chat(self):
        playtime = (BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        self.assertIn('function Clock:MutePlayedChat()', playtime)
        self.assertIn("frame:IsEventRegistered('TIME_PLAYED_MSG')", playtime)
        self.assertIn("pcall(frame.UnregisterEvent, frame, 'TIME_PLAYED_MSG')", playtime)
        self.assertIn("pcall(frame.RegisterEvent, frame, 'TIME_PLAYED_MSG')", playtime)
        self.assertIn('self:MutePlayedChat()\n    local ok = pcall(_G.RequestTimePlayed)', playtime)
        self.assertIn('if not ok then self:RestorePlayedChat() end', playtime)
        self.assertIn('self:RestorePlayedChatNextFrame()', playtime)
        self.assertIn('if self.playtimeMutedChatFrames == mutedFrames then', playtime)
        self.assertIn('self:RestorePlayedChat()\n    end\n    local record =', playtime)
        self.assertNotIn('ChatFrame_AddMessageEventFilter', playtime.split('function Clock:MutePlayedChat()', 1)[1])

    def test_logout_persists_confirmed_played_and_background_refresh(self):
        code = (BASE/'Core/Playtime.lua').read_text(encoding='utf8')
        self.assertIn('local PLAYED_REFRESH_SECONDS = 10 * 60', code)
        self.assertIn('self.playtimeNextRequest = nextAt', code)
        self.assertIn('self.playtimeNextRequest = nil -- Erst nach PLAYER_ENTERING_WORLD', code)
        self.assertIn('self:RequestPlayedTime(true)', code)
        self.assertNotIn('self.playtimeNextRequest = Uptime() + 3', code)
        self.assertNotIn('self.playtimeNextRequest = math.max(Uptime() + 3', code)
        # Shift triggers a request only while actually hovering over the clock.
        modifier = code.split("elseif event == 'MODIFIER_STATE_CHANGED' then", 1)[1].split("elseif event == 'PLAYER_LEVEL_UP' then", 1)[0]
        self.assertNotIn('RequestPlayedOnHover', modifier)
        self.assertIn('self:RequestPlayedOnShift()', modifier)
        self.assertNotIn('EndPlayedHover', modifier)
        # TooltipShow tracks hover; it only requests when Shift is already held.
        clock = (BASE/'Modules/Clock/Clock.lua').read_text(encoding='utf8')
        self.assertIn('OnTooltipShow = function(tooltip)', clock)
        self.assertLess(clock.index('if self.RequestPlayedOnHover then self:RequestPlayedOnHover() end'), clock.index('self:BuildHoverTooltip(tooltip)'))
        self.assertIn('if self.RequestPlayedOnHover then self:RequestPlayedOnHover() end', (BASE/'Modules/Clock/Clock.lua').read_text(encoding='utf8'))
        self.assertIn('record.logoutConfirmedTotalPlayed = SafeSeconds(record.totalPlayed)', code)
        self.assertIn('record.logoutConfirmedLevelPlayed = SafeSeconds(record.levelPlayed)', code)
        self.assertIn('record.logoutConfirmedAt = SafeSeconds(record.updatedAt)', code)
        self.assertIn('record.logoutSnapshotAt = now', code)
        self.assertIn('self:SavePlaytimeEstimate()', code)

    def test_current_version(self):
        toc=(BASE/'CantPlayForever.toc').read_text(encoding='utf8')
        match=re.search(r'(?m)^## Version: (\d+\.\d+\.\d+)-(alpha|beta|latest)\.\d+$',toc)
        self.assertIsNotNone(match)
        changelog=(BASE.parent/'CHANGELOG.md').read_text(encoding='utf8')
        self.assertIn('## [%s]'%match.group(1),changelog)

if __name__=='__main__':
    unittest.main()
