std = "lua51"
max_line_length = false
codes = true
exclude_files = { "CantPlayForever/Libs/**" }
ignore = {
    "212", -- unused argument (Ace/WoW callbacks have fixed signatures)
    "211/ADDON_NAME", -- "local ADDON_NAME, ns = ..." in every file
}
read_globals = {
    -- Lua / WoW Lua extensions
    "date", "time", "format", "strsplit", "strjoin", "wipe", "tinsert", "tremove", "unpack",
    "hooksecurefunc", "CreateColor", "CopyTable", "LibStub", "ipairs", "pairs",
    -- WoW API
    "CreateFrame", "UIParent", "GameTooltip", "C_Timer", "C_Texture", "C_AddOns", "C_DateAndTime",
    "GetTime", "GetServerTime", "GetGameTime", "GetCVar", "GetCursorPosition", "IsShiftKeyDown",
    "IsControlKeyDown", "IsAltKeyDown", "IsInInstance", "PlaySound", "PlaySoundFile", "LoadAddOn",
    "GetLocale", "GetAddOnMetadata", "SlashCmdList", "Minimap", "MinimapCluster", "BackdropTemplateMixin",
    "FrameDebugger", "TimeManagerClockButton", "TimeManager_Toggle", "Stopwatch_Toggle", "InterfaceOptions_AddCategory",
}
globals = { "BetterClockSettings", "CantPlayForeverSettings", "SLASH_CPF1", "SLASH_CPF2", "SLASH_CPFHOLIDAYS1" }

-- Laufzeittests: Mocks setzen absichtlich WoW-Globals und ersetzen Standardfunktionen.
files["tests/**"] = {
    ignore = { "11", "12", "14", "43" },
}
