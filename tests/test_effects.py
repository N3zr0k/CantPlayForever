"""Test source-isolated effects and compatibility of the 0.3.9 effect controls."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
A = ROOT / 'CantPlayForever'

class EffectsStructure(unittest.TestCase):
    def test_alert_text_uses_health_font_and_effect_color(self):
        alert = (A / 'Core/Alert.lua').read_text(encoding='utf-8')
        health = (A / 'Modules/Health/Notice.lua').read_text(encoding='utf-8')
        self.assertIn("24, 'THICKOUTLINE'", alert)
        self.assertIn("24, 'THICKOUTLINE'", health)
        self.assertIn('noticeStyle = self:GetEffectStyle(source, override)', alert)
        self.assertNotIn('GameFontNormalHuge', alert)

    def test_separate_settings_and_old_alarm_migration(self):
        core = (A / 'Core/Core.lua').read_text()
        for source in ('timer', 'alarms', 'health'):
            self.assertIn(f'{source} = {{screenGlow = false', core)
        self.assertIn('if not p.effectsMigrated then', core)
        self.assertIn('alarmsEffect.screenGlow = p.screenGlow == true', core)
        self.assertIn('p.effectsMigrated = true', core)

    def test_module_effect_defaults_and_saved_values(self):
        core = (A / 'Core/Core.lua').read_text()
        glow = (A / 'Core/ScreenGlow.lua').read_text()
        defaults = {
            'timer': '3399FF, pulse, 1, 30',
            'alarms': 'FF2619, pulse, 1, 30',
            'health': '5FFF4F, pulse, 1, 10',
        }
        for source, spec in defaults.items():
            self.assertIn(f"spec = '{spec}'", core)
            self.assertIn(f"{source} = '{spec}'", glow)
        self.assertNotIn('70BBFF, pulse, 1, 25', core + glow)
        # GetEffectConfig must return saved per-module settings without resetting them.
        self.assertIn('if config then return config end', glow)
        # Invalid settings must fall back to the *same module* default.
        self.assertIn('return EFFECT_DEFAULT_SPECS[source]', glow)

    def test_visual_sources_and_calls(self):
        glow = (A/'Core/ScreenGlow.lua').read_text()
        self.assertIn('function Clock:GetEffectConfig(source)', glow)
        self.assertIn('function Clock:ShowScreenGlow(source, isPreview, override)', glow)
        self.assertIn('local config = self:GetEffectConfig(source)', glow)
        self.assertIn('config.skipInstances ~= false', glow)
        self.assertIn("source == 'health'", glow)
        alerts = (A/'Core/Alert.lua').read_text()
        self.assertIn('function Clock:Alert(message, source, alarm)', alerts)
        self.assertIn('self:GetEffectPeriod(source, override)', alerts)
        self.assertIn('self:ShowScreenGlow(source, false, override)', alerts)
        timer = (A/'Modules/Timer/Timer.lua').read_text()
        self.assertIn("self:Alert(timer.name or L.TIMER_FINISHED, 'timer')", timer)
        alarms = (A/'Modules/Alarms/Alarms.lua').read_text()
        self.assertIn("self:Alert(message, 'alarms', alarm)", alarms)
        health = (A/'Modules/Health/Reminders.lua').read_text()
        self.assertIn("self:ShowScreenGlow('health', false, self:GetHealthEffectOverride(entry.category))", health)
        self.assertNotIn('NewTicker', health)

    def test_sound_repeats_do_not_extend_or_retrigger_visuals(self):
        alerts = (A/'Core/Alert.lua').read_text()
        self.assertIn('local ALERT_VISIBLE_SECONDS = 9', alerts)
        self.assertIn('expiresAt = NoticeTime() + ALERT_VISIBLE_SECONDS', alerts)
        self.assertNotIn('(number - 1) * 2 + 3', alerts)
        self.assertNotIn('local number = Between(self.db.profile.alarmRepeats, 1, 10)', alerts)
        self.assertIn('local count = Between(self.db.profile.alarmRepeats, 1, 10)', alerts)
        start = alerts.split('function Clock:StartAlarmSoundSequence()', 1)[1].split('function Clock:UpdateAlarmSoundSequence()', 1)[0]
        followup = alerts.split('function Clock:UpdateAlarmSoundSequence()', 1)[1].split('local function NoticeTime()', 1)[0]
        for sound_only in (start, followup):
            self.assertNotIn('SetGlow(', sound_only)
            self.assertNotIn('ShowScreenGlow(', sound_only)
            self.assertNotIn('Alert(', sound_only)
            self.assertIn('PlayAlarmSound()', sound_only)
        trigger = alerts.split('function Clock:Alert(message, source, alarm)', 1)[1]
        self.assertEqual(trigger.count("self:SetGlow('alert'"), 1)
        self.assertEqual(trigger.count('self:ShowScreenGlow(source, false, override)'), 1)
        self.assertEqual(trigger.count('self:StartAlarmSoundSequence()'), 1)

    def test_oap_health_watch_uses_login_session_elapsed(self):
        api = (A/'Core/OAPDebug.lua').read_text()
        self.assertIn('h.nextAt - self:GetSessionSeconds()', api)
        self.assertIn('health.nextAt - self:GetSessionSeconds()', api)
        self.assertNotIn('h.nextAt - _G.GetTime()', api)


    def test_effects_tab_layout_and_independent_preview(self):
        ui = (A/'Core/Options.lua').read_text()
        # Parent rows 1+2, framed inline row 3 with four child controls, test row 4.
        start = ui.index('local function MakeEffectGroup(source, title, order)')
        end = ui.index("MakeEffectGroup('timer'", start)
        section = ui[start:end]
        self.assertLess(section.index('enabled = {'), section.index('skipInstances = {'))
        self.assertLess(section.index('skipInstances = {'), section.index('appearance = {'))
        self.assertLess(section.index('appearance = {'), section.index('test = {'))
        self.assertIn("type = 'group', inline = true, name = L.EFFECT_APPEARANCE", section)
        self.assertIn("type = 'toggle', name = L['EFFECT_GLOW_' .. source:upper()]", section)
        self.assertIn("type = 'toggle', name = L.SCREEN_GLOW_NO_INSTANCE", section)
        self.assertIn("return source == 'health' or not Config().screenGlow", section)
        self.assertIn("if source == 'health' then return true end", section)
        self.assertIn("name = L.EFFECT_TEST_NOW", section)
        self.assertIn("Clock:PreviewScreenGlow(source)", section)
        self.assertNotIn('colorPreview', section)
        self.assertNotIn('EFFECT_COLOR_PREVIEW', section)
        self.assertIn('local controls = ns.EffectAppearanceArgs(source, nil,', section)
        # All appearance widgets are authored once and reused for global and per-alarm controls.
        glow = (A/'Core/ScreenGlow.lua').read_text()
        common = glow.split('function ns.EffectAppearanceArgs(', 1)[1].split('-- Farbverlauf',1)[0]
        color = common.index('color = {')
        mode = common.index('mode = {', color)
        duration = common.index('duration = {', mode)
        opacity = common.index('opacity = {', duration)
        self.assertLess(color, mode)
        self.assertLess(mode, duration)
        self.assertLess(duration, opacity)
        # The preview starts only the screen-edge effect and expires on its own.
        glow = (A/'Core/ScreenGlow.lua').read_text()
        preview = glow.split('function Clock:PreviewScreenGlow(source, override)',1)[1].split('function Clock:HideScreenGlow()',1)[0]
        self.assertIn('self:ShowScreenGlow(source, true, override)', preview)
        self.assertIn('self:HideScreenGlow()', preview)
        self.assertIn('_G.C_Timer.After(9', preview)
        self.assertNotIn('StartAlarmSoundSequence', preview)
        self.assertNotIn(':Alert(', preview)
        alert = (A/'Core/Alert.lua').read_text()
        self.assertIn('not self.screenGlowPreviewActive', alert)

    def test_independent_aceconfig_pages_and_locale_completeness(self):
        ui = (A/'Core/Options.lua').read_text()
        self.assertIn("childGroups = 'tab'", ui)
        self.assertIn("MakeEffectGroup('timer'", ui)
        self.assertIn("MakeEffectGroup('alarms'", ui)
        self.assertIn("MakeEffectGroup('health'", ui)
        self.assertIn('local controls = ns.EffectAppearanceArgs(source, nil,', ui)
        self.assertIn("type = 'color'", (A/'Core/ScreenGlow.lua').read_text())
        self.assertIn("type = 'select', name = L.EFFECT_MODE", (A/'Core/ScreenGlow.lua').read_text())
        self.assertIn('min = 0.2, max = 10, step = 0.1', (A/'Core/ScreenGlow.lua').read_text())
        self.assertIn('min = 0, max = 100, step = 1', (A/'Core/ScreenGlow.lua').read_text())
        self.assertNotIn("type = 'input', name = L.SCREEN_GLOW_SPEC", ui)
        glow=(A/'Core/ScreenGlow.lua').read_text()
        self.assertIn('function Clock:SetEffectSetting(source, field, value, green, blue)', glow)
        self.assertIn('config.spec = table.concat(parts', glow)
        self.assertNotIn('style.mode, style.period = alert.style.mode', glow)
        self.assertIn('style.period = self:GetEffectPeriod(source, override)', glow)
        self.assertIn('Config().skipInstances', ui)
        for locale in ('deDE','enUS','frFR'):
            source = (A/f'Core/Locales/{locale}.lua').read_text()
            for token in ('EFFECT_SOURCE_TIMER', 'EFFECT_SOURCE_ALARMS', 'EFFECT_SOURCE_HEALTH', 'EFFECTS_SCOPE_NOTE', 'EFFECT_COLOR', 'EFFECT_GLOW_TIMER', 'EFFECT_GLOW_ALARMS', 'EFFECT_GLOW_HEALTH', 'EFFECT_APPEARANCE', 'EFFECT_TEST_NOW', 'EFFECT_MODE', 'EFFECT_SECONDS', 'EFFECT_PERCENT'):
                self.assertIn('L.'+token+' =',source)

if __name__ == '__main__':
    unittest.main()
