"""Contract tests for optional, per-alarm visuals and WoW icons."""
from pathlib import Path
import unittest

A = Path(__file__).resolve().parents[1] / 'CantPlayForever'

class PerAlarmOptions(unittest.TestCase):
    def test_type_icons_and_all_three_display_surfaces(self):
        alarms = (A/'Modules/Alarms/Alarms.lua').read_text()
        options = (A/'Modules/Alarms/Options.lua').read_text()
        tooltip = (A/'Modules/Clock/Tooltip.lua').read_text()
        alert = (A/'Core/Alert.lua').read_text()
        for kind in ("alarm", "event", "reminder"):
            self.assertIn(f"{kind} = 'Interface", alarms)
        self.assertIn('ns.AlarmTypeIcon(', alarms)
        self.assertIn('ns.AlarmDisplayName(current, L.ALARM_GENERIC, 15)', options)
        self.assertIn('ns.AlarmDisplayName(alarm, L.ALARM_FALLBACK, 14)', tooltip)
        self.assertIn('ns.AlarmDisplayName(alarm, message, 24)', alert)
        self.assertIn('alarmType = draft.alarmType', options)
        self.assertIn("get = function() return current.alarmType or 'alarm' end", options)
        self.assertIn("values = ns.AlarmTypeValues", options)

    def test_individual_appearance_inherited_until_activated(self):
        glow = (A/'Core/ScreenGlow.lua').read_text()
        options = (A/'Modules/Alarms/Options.lua').read_text()
        self.assertIn('alarm.customEffect == true', glow)
        self.assertIn('function Clock:SetAlarmCustomEffect(alarm, enabled)', glow)
        self.assertIn("spec = self:GetScreenGlowSpec('alarms')", glow)
        self.assertIn('alarm.customEffect = enabled == true', glow)
        self.assertIn("ns.EffectAppearanceArgs('alarms',", options)
        self.assertIn('return target.customEffect ~= true', options)
        self.assertIn("Clock:PreviewScreenGlow('alarms', Clock:GetAlarmEffectOverride(target))", options)
        self.assertIn("Clock:GetEffectColorHex('alarms', effect)", options)
        # The module-wide enable/instance restriction is still authoritative.
        self.assertIn("if not config.screenGlow then return end", glow)
        self.assertIn('if config.skipInstances ~= false', glow)
        self.assertIn('self:GetEffectStyle(source, override)', glow)
        self.assertIn('self:ShowScreenGlow(source, false, override)', (A/'Core/Alert.lua').read_text())

    def test_days_widened_and_storage_is_backwards_compatible(self):
        options = (A/'Modules/Alarms/Options.lua').read_text()
        core = (A/'Core/Core.lua').read_text()
        self.assertIn("width = 0.35", options)
        self.assertIn("type = 'execute', name = L.ALL_DAYS, order = firstOrder + 0.1, width = 0.52", options)
        self.assertEqual(options.count("order = 4.1, width = 1"), 2)
        for offset in ('0.5','0.6','0.7'):
            self.assertIn(f'order = firstOrder + {offset}, width = 0.85', options)
        self.assertIn("width = 'full'", options)
        self.assertIn("effect = draft.effect and CopyTable(draft.effect) or nil", options)
        self.assertIn('ns.MigrateAlarm(alarm)', core)
        self.assertIn("return target.customEffect == true", options)
        self.assertIn("return current.alarmType or 'alarm'", options)

    def test_localized_labels_for_all_types_and_settings(self):
        for locale in ('deDE','enUS','frFR'):
            s = (A/f'Modules/Alarms/Locales/{locale}.lua').read_text()
            for key in ('ALARM_TYPE', 'ALARM_TYPE_DESC', 'ALARM_TYPE_ALARM',
                        'ALARM_TYPE_EVENT', 'ALARM_TYPE_REMINDER',
                        'ALARM_CUSTOM_EFFECT', 'ALARM_CUSTOM_EFFECT_DESC'):
                self.assertIn('L.'+key+' =',s)

if __name__ == '__main__': unittest.main()
