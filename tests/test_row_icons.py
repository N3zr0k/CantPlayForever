"""Verify that Health, Timer and Alarms use Blizzard-styled, tinted edit/delete controls."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'CantPlayForever'


class RowIconTests(unittest.TestCase):
    def test_shared_controls_and_blizzard_sources(self):
        source = (ADDON / 'Core' / 'RowIcons.lua').read_text(encoding='utf-8')
        self.assertIn('Interface\\\\Buttons\\\\UI-OptionsButton', source)
        self.assertIn("BADGE_DIR .. 'delete_bin'", source)
        self.assertTrue((ADDON / 'Media' / 'Badges' / 'delete_bin.tga').is_file())
        self.assertIn('icon:SetDesaturated(highlight)', source)
        self.assertIn('icon:SetDesaturated(highlight)', source)
        self.assertIn('local color = highlight and EDIT_HOVER or {1, 1, 1}', source)
        self.assertIn('SetVertexColor(color[1], color[2], color[3]', source)
        self.assertIn('cpfIconWrapped', source)
        for module in ('Alarms', 'Timer', 'Health'):
            options = (ADDON / 'Modules' / module / 'Options.lua').read_text(encoding='utf-8')
            self.assertIn("ns.RowIcon('edit_gear')", options)
            self.assertIn("ns.RowIcon('delete_bin')", options)

    def test_hover_and_reuse_in_lua(self):
        lua = next((shutil.which(executable) for executable in
                    ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(executable)), None)
        if lua is None:
            self.skipTest('Lua interpreter unavailable (CI uses Lua)')
        result = subprocess.run([lua, 'tests/row_icons_runtime.lua'], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('RowIcons Blizzard gear', result.stdout)


if __name__ == '__main__':
    unittest.main()
