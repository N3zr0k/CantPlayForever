"""Control-map regressions for the minimap clock and localized options."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'CantPlayForever'

class ClockClicks(unittest.TestCase):
    def test_ctrl_left_arms_alarms_and_shift_does_not(self):
        code = (ADDON / 'Modules/Clock/Clock.lua').read_text(encoding='utf-8')
        left = code.split("elseif button == 'LeftButton' then", 1)[1].split("end,", 1)[0]
        self.assertIn('if IsControlKeyDown and IsControlKeyDown() then', left)
        self.assertIn('self:ToggleSelectedAlarms()', left)
        self.assertIn('self:ToggleSelectedTimer()', left)
        self.assertLess(left.index('self:ToggleSelectedAlarms()'), left.index('self:ToggleSelectedTimer()'))
        self.assertNotRegex(left, r'if\s+IsShiftKeyDown')
        self.assertIn("elseif IsControlKeyDown and IsControlKeyDown() then", code)  # Ctrl+right stopwatch
        self.assertIn("self:RequestPlayedOnHover()", code)  # Shift hover is independent

    def test_localized_help_and_option_labels(self):
        tooltip=(ADDON / 'Modules/Clock/Tooltip.lua').read_text(encoding='utf-8')
        compartment=(ADDON / 'Core/AddonCompartment.lua').read_text(encoding='utf-8')
        options=(ADDON / 'Modules/Alarms/Options.lua').read_text(encoding='utf-8')
        for content in (tooltip,compartment):
            self.assertIn('L.CTRL_LEFT', content)
            self.assertNotIn('L.SHIFT_LEFT', content)
        self.assertIn('L.SELECT_FOR_CTRL',options)
        for locale,word in [('deDE','Strg'),('enUS','Ctrl'),('frFR','Ctrl')]:
            clk=(ADDON / f'Modules/Clock/Locales/{locale}.lua').read_text(encoding='utf-8')
            alarm=(ADDON / f'Modules/Alarms/Locales/{locale}.lua').read_text(encoding='utf-8')
            core=(ADDON / f'Core/Locales/{locale}.lua').read_text(encoding='utf-8')
            self.assertIn(f'L.CTRL_LEFT = "{word}', clk)
            self.assertNotIn('L.SHIFT_LEFT',clk)
            self.assertIn('L.SELECT_FOR_CTRL',alarm)
            self.assertIn('L.DISARM_ORDER_DESC',alarm)
            self.assertIn(word,core.split('L.COMMANDS = ',1)[1].split('\n',1)[0])

if __name__ == '__main__':
    unittest.main()
