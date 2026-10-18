"""Health global color removal and fixed category defaults regressions."""
import pathlib
import shutil
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
ADDON = ROOT / 'CantPlayForever'


class HealthGlobalColorTests(unittest.TestCase):
    def test_no_health_global_color_picker_but_individual_color_remains(self):
        options = (ADDON / 'Core/Options.lua').read_text(encoding='utf-8')
        self.assertIn("if source == 'health' then", options)
        self.assertIn('controls.color = nil', options)
        self.assertIn('ns.HealthIconAppearanceArgs(nil)', options)
        individual = (ADDON / 'Modules/Health/Options.lua').read_text(encoding='utf-8')
        self.assertIn("ns.EffectAppearanceArgs('health', Override,", individual)
        # Shared color picker still available for Timer, Alarms and individual categories.
        glow = (ADDON / 'Core/ScreenGlow.lua').read_text(encoding='utf-8')
        self.assertIn("color = {type = 'color'", glow)

    def test_global_health_color_is_ignored_even_from_old_profiles(self):
        glow = (ADDON / 'Core/ScreenGlow.lua').read_text(encoding='utf-8')
        self.assertIn("if source == 'health' and not isOverride then", glow)
        self.assertIn("if source == 'health' and field == 'color' then return false end", glow)
        self.assertNotIn('global.colorCustomized == true', glow)
        self.assertNotIn('config.colorCustomized = true', glow)
        for source in ('movement', 'drinking', 'eyes'):
            self.assertIn(f'{source} = {{ Alliance =', glow)

    def test_runtime_fixed_colors_and_category_overrides(self):
        lua = next((shutil.which(binary) for binary in ('lua', 'lua5.4', 'lua5.3', 'luajit')
                    if shutil.which(binary)), None)
        if not lua:
            self.skipTest('Kein Lua-Interpreter im PATH; Laufzeittest via liblua oder CI')
        result = subprocess.run([lua, 'tests/health_global_color_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('OK health fixed category colors', result.stdout)


if __name__ == '__main__':
    unittest.main()
