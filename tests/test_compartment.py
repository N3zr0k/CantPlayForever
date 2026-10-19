"""Contract tests for the optional Blizzard addon-compartment integration."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "CantPlayForever"


class CompartmentRegistration(unittest.TestCase):
    def test_separate_module_and_load_order(self):
        load = (ADDON / "Core/Core.xml").read_text(encoding="utf-8")
        core = (ADDON / "Core/Core.lua").read_text(encoding="utf-8")
        self.assertIn('<Script file="AddonCompartment.lua"/>', load)
        self.assertLess(load.index('AddonCompartment.lua'), load.index('Options.lua'))
        self.assertIn("self:GuardedTick('compartment.register', self.RegisterAddonCompartment)", core)
        self.assertIn('function Clock:OpenSettings(page, ...)', core)

    def test_optional_registration_not_a_second_minimap_launcher(self):
        code = (ADDON / "Core/AddonCompartment.lua").read_text(encoding="utf-8")
        self.assertIn('_G.AddonCompartmentFrame', code)
        self.assertIn("type(compartment.RegisterAddon) == 'function'", code)
        self.assertIn('if self.compartmentData then return end', code)
        self.assertIn('compartment:RegisterAddon(entry)', code)
        self.assertIn("self:OpenSettings('general')", code)
        self.assertNotIn('ToggleSelectedTimer', code)
        self.assertNotIn('AddButtonToCompartment', code)
        self.assertIn("funcOnEnter = ShowHelp", code)
        self.assertIn("funcOnLeave = HideHelp", code)

    def test_localization_and_existing_controls(self):
        code = (ADDON / "Core/AddonCompartment.lua").read_text(encoding="utf-8")
        for key in ('LEFT_CLICK', 'RIGHT_CLICK', 'CTRL_LEFT', 'STOPWATCH_HINT',
                    'BLIZZARD_CLOCK_HINT', 'DRAG_MINIMAP', 'DRAG_FREE'):
            self.assertIn('L.' + key, code)
        for locale in ('deDE', 'enUS', 'frFR'):
            text = (ADDON / f'Core/Locales/{locale}.lua').read_text(encoding="utf-8")
            for key in ('COMPARTMENT_CLICK', 'COMPARTMENT_CONTROLS'):
                self.assertIn('L.' + key + ' = ', text)


if __name__ == '__main__':
    unittest.main()
