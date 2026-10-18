"""Regressions for per-Health-category custom message storage and controls."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1] / 'CantPlayForever' / 'Modules' / 'Health'

class HealthCustomTextTests(unittest.TestCase):
    def test_source_picker(self):
        messages = (ROOT / 'Messages.lua').read_text(encoding='utf-8')
        reminder = (ROOT / 'Reminders.lua').read_text(encoding='utf-8')
        self.assertIn('function ns.HealthChooseMessage(category, settings)', messages)
        self.assertIn('entry.enabled ~= false', messages)
        self.assertIn('settings.customMessagesEnabled == true', messages)
        self.assertIn('settings.mixWithDefault ~= true or math.random(2) == 1', messages)
        self.assertIn("ns.HealthChooseMessage(category, h[category])", reminder)
        self.assertNotIn('C_Timer.NewTicker', reminder)

    def test_persistent_per_category_ui_and_icon_consistency(self):
        opts = (ROOT / 'Options.lua').read_text(encoding='utf-8')
        self.assertIn('args.customTexts = CategoryTextArgs(id)', opts)
        self.assertIn("type = 'toggle', name = L.HEALTH_CUSTOM_TEXTS_ENABLED", opts)
        self.assertIn('setting.customMessages[#setting.customMessages + 1]', opts)
        self.assertIn("ns.RowIcon('edit_gear')", opts)
        self.assertIn("ns.RowIcon('delete_bin')", opts)
        self.assertIn('confirm = function() return L.HEALTH_DELETE_TEXT_CONFIRM end', opts)
        self.assertIn('textEditorOpen[id]', opts)
        self.assertIn('setting.nextCustomMessageID', opts)
        self.assertIn('entry.enabled = value == true', opts)

    def test_alarm_style_saved_texts_and_explicit_editor_actions(self):
        options = (ROOT / 'Options.lua').read_text(encoding='utf-8')
        editor = (ROOT / 'TextEditor.lua').read_text(encoding='utf-8')
        self.assertIn("name = '|cff999999' .. L.HEALTH_CUSTOM_TEXTS_EMPTY_FALLBACK .. '|r'", options)
        self.assertIn("new = {type = 'execute', name = L.HEALTH_NEW_TEXT, order = 5", options)
        self.assertIn("type = 'header', name = L.HEALTH_SAVED_TEXTS", options)
        self.assertIn("args[key .. '_enabled']", options)
        self.assertIn("args[key .. '_edit']", options)
        self.assertIn("args[key .. '_delete']", options)
        self.assertIn("args[key .. '_summary']", options)
        self.assertIn("if index > 1 then", options)
        self.assertEqual(options.count("dialogControl = 'CPFHealthTextEditor'"), 2)
        self.assertEqual(options.count("name = L.HEALTH_SAVE_TEXT"), 2)
        self.assertEqual(options.count("name = L.HEALTH_CANCEL_TEXT"), 2)
        self.assertIn('self:DisableButton(true)', editor)
        self.assertIn("self:SetCallback('OnTextChanged'", editor)
        self.assertIn('option.set(nil, text)', editor)

    def test_three_locales_have_all_custom_text_keys(self):
        for loc in ('deDE', 'enUS', 'frFR'):
            content = (ROOT / 'Locales' / (loc + '.lua')).read_text(encoding='utf-8')
            for key in ('HEALTH_CUSTOM_TEXTS_ENABLED', 'HEALTH_CUSTOM_TEXTS_MIX',
                        'HEALTH_DELETE_TEXT_CONFIRM', 'HEALTH_NEW_TEXT',
                        'HEALTH_TEXT_ENABLED_DESC', 'HEALTH_SAVE_TEXT'):
                self.assertIn('L.' + key + ' =', content)

if __name__ == '__main__':
    unittest.main()
