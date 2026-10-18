"""Contract tests for sub-tab Health UI and per-category effect overrides."""
from pathlib import Path
import unittest

A = Path(__file__).resolve().parents[1] / 'CantPlayForever'


class HealthEffectTests(unittest.TestCase):
    def test_each_category_is_a_tab_and_has_optional_appearance(self):
        options = (A / 'Modules/Health/Options.lua').read_text()
        self.assertIn("childGroups = 'tab'", options)
        for category in ('movement', 'drinking', 'eyes'):
            self.assertIn(f"{category} = CategoryGroup('{category}'", options)
        self.assertIn('customEffect = {', options)
        self.assertIn('Clock:SetHealthCustomEffect(id, enabled)', options)
        self.assertIn("local controls = ns.EffectAppearanceArgs('health', Override,", options)
        self.assertIn('controls.preview = {', options)
        self.assertIn("Clock:PreviewHealthEffect(id)", options)
        self.assertIn('return HealthSettings()[id].customEffect ~= true', options)
        self.assertIn("return not Clock:GetEffectConfig('health').screenGlow", options)
        self.assertIn('general = {', options)
        self.assertIn('ns.HealthIconAppearanceArgs(id)', options)
        self.assertNotIn('args.display = {', options)
        global_options = (A / 'Core/Options.lua').read_text()
        self.assertIn('ns.HealthIconAppearanceArgs(nil)', global_options)
        self.assertIn("if source == 'health' then", global_options)
        self.assertIn('Clock:PreviewHealthEffect()', global_options)


    def test_global_effect_fallback_and_saved_override(self):
        screen = (A / 'Core/ScreenGlow.lua').read_text()
        reminders = (A / 'Modules/Health/Reminders.lua').read_text()
        core = (A / 'Core/Core.lua').read_text()
        self.assertIn('function Clock:GetHealthEffectOverride(category)', screen)
        self.assertIn('function Clock:SetHealthCustomEffect(category, enabled)', screen)
        self.assertIn('setting.customEffect == true', screen)
        self.assertIn("spec = effective and effective.spec or self:GetScreenGlowSpec('health')", screen)
        self.assertIn("periodSeconds = self:GetEffectPeriod('health', effective)", screen)
        self.assertIn("setting.customEffect = enabled == true", screen)
        self.assertIn("self:ShowScreenGlow('health', false, self:GetHealthEffectOverride(entry.category))", reminders)
        self.assertIn('if not config.screenGlow then return end', screen)
        self.assertIn("source == 'health' and self.IsHealthRestricted", screen)
        for category in ('movement', 'drinking', 'eyes'):
            self.assertIn(f'{category} = {{ customEffect = false', core)

    def test_localization_is_complete(self):
        for locale in ('deDE', 'enUS', 'frFR'):
            s = (A / f'Modules/Health/Locales/{locale}.lua').read_text()
            self.assertIn('L.HEALTH_CUSTOM_EFFECT =', s)
            self.assertIn('L.HEALTH_CUSTOM_EFFECT_DESC =', s)
            for key in ('HEALTH_ICON_ENABLED', 'HEALTH_ICON_TRANSPARENCY', 'HEALTH_ICON_OFFSET_Y'):
                self.assertIn('L.' + key + ' =', s)



if __name__ == '__main__':
    unittest.main()
