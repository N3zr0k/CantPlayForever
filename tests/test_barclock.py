"""Balkenform der großen Uhr (ElvUI / EllesmereUI)."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLOCK = ROOT / 'CantPlayForever' / 'Modules' / 'Clock'


class BarClockTests(unittest.TestCase):
    def test_wiring(self):
        xml = (CLOCK / 'Clock.xml').read_text(encoding='utf-8')
        self.assertIn('BarClock.lua', xml)
        self.assertLess(xml.index('Badges.lua'), xml.index('BarClock.lua'))
        options = (CLOCK / 'Options.lua').read_text(encoding='utf-8')
        for key in ('clockLook', 'barWidth', 'barHeight', 'barOpacity'):
            self.assertIn(key, options)
        core = (ROOT / 'CantPlayForever' / 'Core' / 'Core.lua').read_text(encoding='utf-8')
        self.assertIn("clockLook = 'standard'", core)

    def test_locale_keys_in_all_languages(self):
        keys = ('SECTION_LOOK', 'CLOCK_LOOK', 'CLOCK_LOOK_DESC', 'LOOK_STANDARD', 'LOOK_ELLESMERE',
                'LOOK_ELVUI', 'BAR_WIDTH', 'BAR_HEIGHT', 'BAR_OPACITY')
        for lang in ('enUS', 'deDE', 'frFR'):
            text = (CLOCK / 'Locales' / (lang + '.lua')).read_text(encoding='utf-8')
            for key in keys:
                self.assertIn('L.' + key + ' =', text, lang + ' ' + key)

    def test_bar_in_lua(self):
        lua = next((shutil.which(e) for e in ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(e)), None)
        if lua is None:
            self.skipTest('Lua interpreter unavailable (CI uses Lua)')
        result = subprocess.run([lua, 'tests/barclock_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('BarClock OK', result.stdout)


if __name__ == '__main__':
    unittest.main()
