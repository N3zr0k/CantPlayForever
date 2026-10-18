"""Exercise real Lua functions in a mocked WoW client when Lua is installed."""
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class AlarmCustomRuntime(unittest.TestCase):
    def test_custom_alarm_effects_and_types(self):
        lua = next((shutil.which(binary) for binary in ('lua', 'lua5.4', 'lua5.3', 'luajit', 'texlua')
                    if shutil.which(binary)), None)
        if not lua:
            self.skipTest('Lua interpreter not available; CI installs Lua')
        result = subprocess.run([lua, 'tests/alarm_custom_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Lua runtime alarm custom effect', result.stdout)

if __name__ == '__main__': unittest.main()
