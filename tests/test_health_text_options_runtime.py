"""Exercise the real Lua option callbacks and AceGUI editor mock, if Lua is available."""
import ctypes
import ctypes.util
import os
from pathlib import Path
import shutil
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'tests' / 'health_text_options_runtime.lua'


class HealthTextOptionsRuntimeTests(unittest.TestCase):
    def test_health_text_form_and_saved_list(self):
        executable = next((shutil.which(name) for name in
                           ('lua', 'lua5.4', 'lua5.3', 'luajit') if shutil.which(name)), None)
        if executable:
            result = subprocess.run([executable, str(SCRIPT)], cwd=ROOT,
                                    capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('Health text list', result.stdout)
            return
        library = ctypes.util.find_library('lua5.4')
        if not library:
            self.skipTest('No Lua interpreter or Lua 5.4 shared library available')
        lua = ctypes.CDLL(library)
        lua.luaL_newstate.restype = ctypes.c_void_p
        lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
        lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
        lua.luaL_loadfilex.restype = ctypes.c_int
        lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int,
                                  ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
        lua.lua_pcallk.restype = ctypes.c_int
        lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = [ctypes.c_void_p]
        state = lua.luaL_newstate()
        if not state:
            self.skipTest('Lua state unavailable')
        old_dir = os.getcwd()
        try:
            lua.luaL_openlibs(state)
            os.chdir(ROOT)
            result = lua.luaL_loadfilex(state, str(SCRIPT).encode(), None)
            if result == 0:
                result = lua.lua_pcallk(state, 0, 0, 0, 0, None)
            if result != 0:
                error = lua.lua_tolstring(state, -1, None)
                self.fail((error or b'Unknown Lua error').decode('utf-8', errors='replace'))
        finally:
            os.chdir(old_dir)
            lua.lua_close(state)


if __name__ == '__main__':
    unittest.main()
