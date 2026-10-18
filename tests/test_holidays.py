"""Fest-Symbol: Kalenderabgleich, Tooltip und Verdrahtung."""
from pathlib import Path
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'CantPlayForever'


class HolidayTests(unittest.TestCase):
    def test_wiring(self):
        self.assertIn('Holidays.lua', (ADDON / 'Modules' / 'Clock' / 'Clock.xml').read_text(encoding='utf-8'))
        badges = (ADDON / 'Modules' / 'Clock' / 'Badges.lua').read_text(encoding='utf-8')
        self.assertIn("key = 'holiday'", badges)
        self.assertIn('AddCalendarLines', badges)
        for locale in ('deDE', 'enUS', 'frFR'):
            text = (ADDON / 'Modules' / 'Clock' / 'Locales' / f'{locale}.lua').read_text(encoding='utf-8')
            for key in ('CALENDAR_SHOW', 'CALENDAR_DISPLAY', 'DISPLAY_OVERLAY', 'DISPLAY_BOTH', 'DISPLAY_ICON', 'HOLIDAYS_TAB'):
                self.assertIn(f'L.{key} =', text)

    def test_overlay_assets(self):
        core = (ROOT / 'CantPlayForever/Core/Core.lua').read_text(encoding='utf-8')
        paths = re.findall(r"\[\d+\] = 'Interface\\\\AddOns\\\\CantPlayForever\\\\(Media[^']+)'", core)
        self.assertTrue(paths, 'HOLIDAY_OVERLAYS leer')
        for rel in paths:
            file = ROOT / 'CantPlayForever' / (rel.replace('\\\\', '/') + '.tga')
            self.assertTrue(file.is_file(), file)
            header = file.read_bytes()[:18]
            width = header[12] + header[13] * 256
            self.assertEqual(width & (width - 1), 0, 'Texturbreite keine Zweierpotenz')
            self.assertEqual(header[2], 2, 'unkomprimiertes TGA')

    def test_scan_in_lua(self):
        lua = next((shutil.which(e) for e in ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(e)), None)
        if lua is None:
            self.skipTest('Lua interpreter unavailable (CI uses Lua)')
        result = subprocess.run([lua, 'tests/holidays_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Holidays OK', result.stdout)

    def test_year_scan_in_lua(self):
        lua = next((shutil.which(e) for e in ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(e)), None)
        if lua is None:
            self.skipTest('Lua interpreter unavailable (CI uses Lua)')
        result = subprocess.run([lua, 'tests/holidays_year_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Holidays year OK', result.stdout)

    def test_tuning_baseline_in_lua(self):
        lua = next((shutil.which(e) for e in ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(e)), None)
        if lua is None:
            self.skipTest('Lua interpreter unavailable (CI uses Lua)')
        result = subprocess.run([lua, 'tests/tuning_baseline_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Tuning baseline OK', result.stdout)

    def test_all_lua_files_parse(self):
        lua = next((shutil.which(e) for e in ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(e)), None)
        if lua is None:
            self.skipTest('Lua interpreter unavailable (CI uses Lua)')
        files = [str(p) for p in ADDON.rglob('*.lua') if 'Libs' not in p.parts]
        result = subprocess.run([lua, 'tests/syntax_check.lua', *files], cwd=ROOT, capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
