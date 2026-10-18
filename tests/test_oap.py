"""OAP Debug integration contracts and optional Lua runtime test."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parent.parent
ADDON = ROOT / 'CantPlayForever'


class OAPDebugContract(unittest.TestCase):
    def test_optional_dependency_and_load_order(self):
        toc = (ADDON / 'CantPlayForever.toc').read_text(encoding='utf-8')
        self.assertIn('## OptionalDeps: OAPDebug', toc)
        xml = (ADDON / 'Core/Core.xml').read_text(encoding='utf-8')
        self.assertLess(xml.index('file="Core.lua"'), xml.index('file="OAPDebug.lua"'))
        self.assertLess(xml.index('file="OAPDebug.lua"'), xml.index('file="Alert.lua"'))

    def test_technical_messages_do_not_print_to_chat(self):
        core = (ADDON / 'Core/Core.lua').read_text(encoding='utf-8')
        oap = (ADDON / 'Core/OAPDebug.lua').read_text(encoding='utf-8')
        self.assertNotIn("self:Print('|cff999999[Debug]'", core)
        self.assertNotIn('self:Print(', oap)
        self.assertIn('api.Register', oap)
        self.assertIn('api.Log', oap)
        self.assertIn('pcall(api.Log', oap)
        self.assertIn('pcall(handler, self)', oap)
        self.assertIn('self:GuardedTick(', core)
        self.assertNotIn('self.db.global.debug) then', core)

    def test_level_option_and_translations(self):
        options = (ADDON / 'Core/Options.lua').read_text(encoding='utf-8')
        self.assertIn('args.oapdebug = {', options)
        self.assertIn('if Clock:IsOAPDebugAvailable() then', options)
        self.assertIn("Clock:OAPShow('metrics')", options)
        self.assertIn('Clock:OAPWatchPreset(', options)
        self.assertNotIn('oapLevel = {', options)
        self.assertNotIn('oapState = {', options)
        self.assertNotIn('type = \'toggle\', name = L.DEBUG_MODE', options)
        for language in ('deDE', 'enUS', 'frFR'):
            text = (ADDON / f'Core/Locales/{language}.lua').read_text(encoding='utf-8')
            for key in ('OAP_LEVEL', 'OAP_LEVEL_DESC', 'OAP_ERRORS', 'OAP_NORMAL',
                        'OAP_DETAILED', 'OAP_INSTALLED', 'OAP_NOT_INSTALLED',
                        'OAP_METRICS', 'OAP_TOOLS_TAB', 'OAP_WATCH_ADD', 'OAP_TAB', 'OAP_LOGGING_TAB', 'OAP_INSPECT_TAB', 'OAP_INSPECT_HELP',
                        'OAP_INSPECT_COMMANDS'):
                self.assertIn(f'L.{key} =', text)

    def test_live_telemetry_and_no_unverified_calls(self):
        bridge = (ADDON / 'Core/OAPDebug.lua').read_text(encoding='utf-8')
        core = (ADDON / 'Core/Core.lua').read_text(encoding='utf-8')
        self.assertIn('function Clock:OAPCounter(', bridge)
        self.assertIn('function Clock:OAPGauge(', bridge)
        self.assertIn('function Clock:OAPObserve(', bridge)
        self.assertIn('function Clock:OAPSnapshot(', bridge)
        self.assertIn('if not Enabled(LEVEL.metrics) then', bridge)
        self.assertIn('Clock.oapTelemetry = nil', bridge)
        self.assertIn("self:GuardedTick('telemetry.snapshot', self.OAPSnapshot)", core)
        self.assertIn("self:OAPStopTimer('core.tick')", core)
        self.assertIn('pcall(api.Count, SOURCE, name, n)', bridge)
        self.assertIn('pcall(api.Gauge, SOURCE, name, value)', bridge)
        self.assertIn('pcall(api.Watch, SOURCE, label, value)', bridge)
        self.assertIn('pcall(api.StartTimer, SOURCE, name)', bridge)
        self.assertIn('pcall(api.StopTimer, SOURCE, name)', bridge)

    def test_lua_runtime_if_available(self):
        lua = next((shutil.which(cmd) for cmd in ('lua5.1', 'lua', 'lua5.4', 'texlua') if shutil.which(cmd)), None)
        if not lua:
            self.skipTest('No Lua interpreter available')
        proc = subprocess.run([lua, str(ROOT / 'tests/oap_runtime.lua'),
                               str(ADDON / 'Core/OAPDebug.lua')], text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)


if __name__ == '__main__':
    unittest.main()
