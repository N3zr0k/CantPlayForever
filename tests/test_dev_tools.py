"""Entwicklungs-Anbindung (Frame Debugger): nur im Repo, nicht im Release."""
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'CantPlayForever'
DEV_FILES = ('Stage.lua', 'Tuning.lua', 'FrameDump.lua', 'Probe.lua', 'HolidayList.lua')


class DevToolsTests(unittest.TestCase):
    def test_dev_files_are_listed_in_toc_and_excluded_from_release(self):
        toc = (ADDON / 'CantPlayForever.toc').read_text(encoding='utf-8')
        pkgmeta = (ROOT / '.pkgmeta').read_text(encoding='utf-8')
        self.assertIn('Frame_Debugger', toc)
        self.assertRegex(pkgmeta, r'(?m)^\s*-\s*CantPlayForever/Dev\s*$')
        for name in DEV_FILES:
            self.assertTrue((ADDON / 'Dev' / name).is_file(), name)
            self.assertIn('Dev\\' + name, toc)

    def test_dev_files_do_nothing_without_frame_debugger(self):
        for name in DEV_FILES:
            text = (ADDON / 'Dev' / name).read_text(encoding='utf-8')
            head = text[:900]
            self.assertIn('_G.FrameDebugger', head, name)
            self.assertRegex(head, r'(?m)^if not \(.*\) then return end', name)

    def test_tuning_registers_with_frame_debugger(self):
        text = (ADDON / 'Dev' / 'Tuning.lua').read_text(encoding='utf-8')
        self.assertIn("FrameDebugger:Register('CantPlayForever'", text)
        keys = set(re.findall(r"P\('([A-Z0-9_]+)'", text))
        tune = (ADDON / 'Core' / 'Core.lua').read_text(encoding='utf-8')
        for key in keys:
            self.assertIn(key, tune, key)


if __name__ == '__main__':
    unittest.main()
