"""Health notices: centralized screen position and category background icons."""
from pathlib import Path
import re
import struct
import unittest

ROOT = Path(__file__).resolve().parent.parent
HEALTH = ROOT / 'CantPlayForever/Modules/Health'


class HealthNoticeTests(unittest.TestCase):
    def test_notice_loads_before_reminders(self):
        text = (HEALTH / 'Health.xml').read_text(encoding='utf-8')
        self.assertLess(text.index('file="Notice.lua"'), text.index('file="Reminders.lua"'))

    def test_centered_message_and_translucent_background_texture(self):
        text = (HEALTH / 'Notice.lua').read_text(encoding='utf-8')
        self.assertIn("frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)", text)
        self.assertIn("icon:SetPoint('CENTER', frame, 'CENTER', 0, 0)", text)
        self.assertIn("label:SetPoint('CENTER', frame, 'CENTER', 0, 0)", text)
        self.assertIn("frame:CreateTexture(nil, 'ARTWORK')", text)
        self.assertIn("frame:CreateFontString(nil, 'OVERLAY'", text)
        self.assertIn('transparency / 100', text)
        self.assertIn('self.healthNoticeIcon:SetAlpha(1 - transparency / 100)', text)
        self.assertIn('self.healthNoticeIcon:SetTexture(self:GetHealthNoticeIcon(category))', text)

    def test_faction_icons_and_usable_tga_assets(self):
        text = (HEALTH / 'Notice.lua').read_text(encoding='utf-8')
        for asset in ('movement_alliance', 'movement_horde', 'drink_alliance',
                      'drink_horde', 'eye_break_all_factions'):
            self.assertIn("'" + asset + "'", text)
            path = ROOT / 'CantPlayForever/Media/Health' / (asset + '.tga')
            self.assertTrue(path.is_file(), asset)
            self.assertGreater(path.stat().st_size, 200000)
        self.assertIn('UnitFactionGroup', text)
        self.assertIn("'THICKOUTLINE'", text)
        self.assertIn('self:GetHealthEffectOverride(category)', text)
        self.assertIn('function Clock:GetHealthNoticeIcon(category)', text)
        self.assertIn('function Clock:ShowHealthNotice(category, title, message)', text)

    def test_global_and_category_effect_previews(self):
        text = (HEALTH / 'Notice.lua').read_text(encoding='utf-8')
        reminder = (HEALTH / 'Reminders.lua').read_text(encoding='utf-8')
        options = (HEALTH / 'Options.lua').read_text(encoding='utf-8')
        core = (ROOT / 'CantPlayForever/Core/Options.lua').read_text(encoding='utf-8')
        self.assertIn("MEDIA .. 'faction_alliance'", text)
        self.assertIn("MEDIA .. 'faction_horde'", text)
        self.assertIn('function Clock:PreviewHealthEffect(category)', text)
        self.assertIn('self:ShowHealthNotice(category, title, message)', text)
        self.assertIn('self:StartHealthSafetyMonitor()', text)
        self.assertIn('self.healthNoticePreviewToken == token', text)
        self.assertIn("self:PreviewScreenGlow('health', override)", text)
        self.assertIn('self:GetHealthReminderText(category)', text)
        self.assertIn('function Clock:GetHealthReminderText(category)', reminder)
        self.assertIn('Clock:PreviewHealthEffect(id)', options)
        self.assertIn('Clock:PreviewHealthEffect()', core)
        for locale in ('deDE', 'enUS', 'frFR'):
            locale_text = (HEALTH / f'Locales/{locale}.lua').read_text(encoding='utf-8')
            self.assertIn('L.HEALTH_PREVIEW_TITLE', locale_text)
            self.assertIn('L.HEALTH_PREVIEW_MESSAGE', locale_text)

    def test_custom_faction_emblems_are_transparent_wow_textures(self):
        code = (HEALTH / 'Notice.lua').read_text(encoding='utf-8')
        self.assertIn("Alliance = MEDIA .. 'faction_alliance'", code)
        self.assertIn("Horde = MEDIA .. 'faction_horde'", code)
        self.assertNotIn('PVP-Currency-Alliance', code)
        self.assertNotIn('PVP-Currency-Horde', code)
        self.assertIn('UnitFactionGroup', code)
        self.assertIn('if not icons then return FACTION_ICONS[faction] end', code)
        self.assertIn("movement = { Alliance = MEDIA .. 'movement_alliance'", code)
        self.assertIn("drinking = { Alliance = MEDIA .. 'drink_alliance'", code)
        self.assertIn("eyes = { Alliance = MEDIA .. 'eye_break_all_factions'", code)
        for basename in ('faction_alliance', 'faction_horde'):
            path = ROOT / 'CantPlayForever/Media/Health' / (basename + '.tga')
            self.assertTrue(path.is_file(), basename)
            raw = path.read_bytes()
            # 32-bit uncompressed true-color TGA, with 8 alpha bits, expected by WoW.
            self.assertEqual(raw[2], 2)
            width, height, bits = struct.unpack_from('<HHB', raw, 12)
            self.assertEqual((width, height, bits), (256, 256, 32))
            self.assertEqual(raw[17] & 0x0F, 8)
            offset = 18 + raw[0]
            self.assertEqual(raw[offset + 3], 0)  # fully transparent background
            center = offset + (128 * 256 + 128) * 4
            self.assertGreater(raw[center + 3], 200)  # opaque emblem
            self.assertTrue((ROOT / 'docs/images/health' / (basename + '.png')).is_file())

    def test_existing_safety_and_lifetime_remain(self):
        text = (HEALTH / 'Notice.lua').read_text(encoding='utf-8')
        reminders = (HEALTH / 'Reminders.lua').read_text(encoding='utf-8')
        self.assertIn('if self:IsHealthRestricted() then', text)
        self.assertIn('function Clock:HideHealthNotice()', text)
        self.assertIn('self:ShowHealthNotice(entry.category, entry.title, entry.message)', reminders)
        self.assertIn('self.healthNoticeUntil = start + NOTICE_SECONDS', reminders)
        self.assertIn("self:Print(L.HEALTH_CHAT_PREFIX .. ' ' .. message)", reminders)
        self.assertNotIn('C_Timer.NewTicker', text)


if __name__ == '__main__':
    unittest.main()
