"""Simulierter Lua-Laufzeittest fuer die Session- und Tooltip-Verwaltung."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PlaytimeRuntimeTests(unittest.TestCase):
    def test_playtime_login_reload_and_shift(self):
        lua = next((shutil.which(tool) for tool in ('lua', 'lua5.4', 'lua5.3', 'luajit', 'texlua') if shutil.which(tool)), None)
        if not lua:
            self.skipTest('Kein Lua-Interpreter vorhanden')
        result = subprocess.run([lua, 'tests/playtime_runtime.lua', 'CantPlayForever/Core/Playtime.lua'],
                                cwd=ROOT, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('OK playtime:', result.stdout)


if __name__ == '__main__':
    unittest.main()
