"""Health contract checks that run in the repository's normal stdlib-only CI."""
import pathlib
import re
import shutil
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / 'CantPlayForever'
HEALTH = ADDON / 'Modules' / 'Health'


class HealthStructure(unittest.TestCase):
    def test_renamed_module_is_loaded(self):
        index = (ADDON / 'Modules' / 'Modules.xml').read_text(encoding='utf-8')
        self.assertIn(r'Health\Health.xml', index)
        self.assertNotIn(r'Wellness\Wellness.xml', index)
        self.assertFalse((ADDON / 'Modules' / 'Wellness').exists())
        script = (HEALTH / 'Health.lua').read_text(encoding='utf-8')
        self.assertIn("id = 'health'", script)
        self.assertNotIn('available = false', script)
        self.assertIn('OnTick', script)
        self.assertIn('OnChanged', script)
        self.assertIn('OnRefresh', script)

    def test_module_off_by_default_and_three_component_defaults(self):
        text = (ADDON / 'Core' / 'Core.lua').read_text(encoding='utf-8')
        self.assertIn('health = false', text)
        for component in ('movement', 'drinking', 'eyes'):
            self.assertRegex(text, rf'\b{component}\s*=\s*{{\s*customEffect\s*=\s*false,\s*enabled\s*=')
        self.assertIn('savedModules.wellness', text)
        self.assertIn('savedModules.health == nil', text)

    def test_each_component_toggle_and_range(self):
        text = (HEALTH / 'Options.lua').read_text(encoding='utf-8')
        for component in ('movement', 'drinking', 'eyes'):
            self.assertIn(f"CategoryGroup('{component}'", text)
        self.assertIn('EnabledOption(id,', text)
        self.assertIn('IntervalOption(id,', text)
        self.assertIn("type = 'range'", text)
        self.assertIn('step = 5', text)
        self.assertIn('movementTest', text)
        self.assertNotIn('deferInCombat = {', text)
        self.assertNotIn('deferInInstances = {', text)
        self.assertIn('restrictedNotice', text)

    def test_only_core_ticker(self):
        reminders = (HEALTH / 'Reminders.lua').read_text(encoding='utf-8')
        self.assertNotIn('NewTicker', reminders)
        self.assertNotIn(':Alert(', reminders)
        self.assertIn('runtime.pending', reminders)
        self.assertIn('UnitAffectingCombat', reminders)
        self.assertIn('IsInInstance', reminders)
        self.assertIn('Clock:IsHealthRestricted()', reminders)
        self.assertIn('PLAYER_REGEN_DISABLED', reminders)
        self.assertIn("'health.' .. category .. '.chat_only'", reminders)
        self.assertNotIn('DeferredReason(', reminders)
        self.assertIn('runtime.pending = false', reminders)

    def test_movement_timing_uses_login_session_without_extra_ticker(self):
        reminders = (HEALTH / 'Reminders.lua').read_text(encoding='utf-8')
        self.assertIn('GetSessionSeconds', reminders)
        self.assertIn('NextBoundary(elapsed, minutes * 60)', reminders)
        self.assertIn('if not self.sessionStartedAt then return end', reminders)
        self.assertNotIn('SessionTime() + minutes * 60', reminders)

    def test_priority_rule_is_anchored_to_scheduled_session_boundaries(self):
        reminders = (HEALTH / 'Reminders.lua').read_text(encoding='utf-8')
        self.assertIn("local CATEGORIES = { 'drinking', 'movement', 'eyes' }", reminders)
        self.assertIn('local COLLISION_WINDOW_SECONDS = 5 * 60', reminders)
        self.assertIn('local function HigherPriorityNearby(', reminders)
        self.assertIn('math.floor(scheduledAt / interval) * interval', reminders)
        self.assertIn('previous > 0', reminders)
        self.assertIn('following - scheduledAt <= COLLISION_WINDOW_SECONDS', reminders)
        self.assertIn('if dueNow[higher] then return higher end', reminders)

    def test_lower_priority_does_not_send_any_notification(self):
        reminders = (HEALTH / 'Reminders.lua').read_text(encoding='utf-8')
        self.assertIn('local winner = HigherPriorityNearby(', reminders)
        self.assertIn('runtime.suppressed = (runtime.suppressed or 0) + 1', reminders)
        self.assertIn("'health.' .. category .. '.suppressed'", reminders)
        self.assertRegex(reminders, r'if winner then[\s\S]*?else[\s\S]*?self:ShowHealthReminder\(category\)')
        self.assertNotIn('C_Timer.NewTicker', reminders)

    def test_fully_localized_health(self):
        for locale in ('enUS', 'deDE', 'frFR'):
            content = (HEALTH / 'Locales' / f'{locale}.lua').read_text(encoding='utf-8')
            for number in range(1, 11):
                for prefix in ('MOVE', 'DRINK'):
                    self.assertIn(f'HEALTH_{prefix}_TITLE_{number}', content)
                    self.assertIn(f'HEALTH_{prefix}_MESSAGE_{number}', content)
            for number in range(1, 7):
                self.assertIn(f'HEALTH_EYES_NAME_{number}', content)
                for variant in (1, 2):
                    self.assertIn(f'HEALTH_EYES_MESSAGE_{number}_{variant}', content)

    def test_lua_runtime_if_available(self):
        interpreter = next((shutil.which(name) for name in ('lua5.1', 'lua', 'lua5.4') if shutil.which(name)), None)
        if not interpreter:
            self.skipTest('No Lua runtime on this machine; GitHub CI installs Lua via luarocks')
        script = ROOT / 'tests' / 'health_runtime.lua'
        process = subprocess.run([interpreter, str(script), str(HEALTH)], capture_output=True, text=True)
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)


if __name__ == '__main__':
    unittest.main()
