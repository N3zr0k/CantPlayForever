import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'tools'))
import check  # noqa: E402


class StripLua(unittest.TestCase):
    def test_dashes_in_string(self):
        self.assertEqual(check.strip_lua("x = '-- a' .. y"), 'x = "" .. y')

    def test_comment(self):
        self.assertEqual(check.strip_lua('x = 1 -- (c'), 'x = 1 ')


class Repo(unittest.TestCase):
    def test_check_clean(self):
        check.errors.clear()
        check.check_lua_balance()
        check.check_locales()
        self.assertEqual(check.errors, [])


if __name__ == '__main__':
    unittest.main()
