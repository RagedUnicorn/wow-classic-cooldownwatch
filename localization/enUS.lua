
-- luacheck: globals GetAddOnMetadata

rgcw = rgcw or {}
rgcw.L = {}

rgcw.L["addon_name"] = "CooldownWatch"

-- console
rgcw.L["help"] = "|cFFFFC300(%s)|r: Use |cFFFFC300/rgcw|r or |cFFFFC300/cooldownwatch|r for a list of options"
rgcw.L["reload"] = "|cFFFFC300reload|r - Reload UI"
rgcw.L["opt"] = "|cFFFFC300opt|r - Display Optionsmenu"
rgcw.L["conf"] = "|cFFFFC300conf|r - Configure target cooldown bar position"
rgcw.L["test"] = "|cFFFFFF00test|r - Test commands (use |cFFFFC300/rgcw test|r for the full menu)"
rgcw.L["info_title"] = "|cFF00FFB0CooldownWatch:|r"
rgcw.L["invalid_argument"] = "Invalid argument passed"

-- about
rgcw.L["author"] = "Author: Michael Wiesendanger"
rgcw.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
rgcw.L["version"] = "Version: " .. GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
rgcw.L["issues"] = "Issues: https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues"

-- general
rgcw.L["general_category_name"] = "General"
rgcw.L["general_title"] = "Allgemeine Konfiguration"
rgcw.L["window_lock_target_cooldow_bar"] = "Lock Targetcooldownbar"
rgcw.L["window_lock_target_cooldow_bar_tooltip"] = "Prevents Targetcooldownbar frame from being moved"

-- cooldown menu
rgcw.L["category_priest"] = "Priest"
rgcw.L["category_rogue"] = "Rogue"
rgcw.L["category_mage"] = "Mage"
rgcw.L["category_hunter"] = "Hunter"
rgcw.L["category_warlock"] = "Warlock"
rgcw.L["category_paladin"] = "Paladin"
rgcw.L["category_druid"] = "Druid"
rgcw.L["category_shaman"] = "Shaman"
rgcw.L["category_warrior"] = "Warrior"
rgcw.L["category_racials"] = "Racials"
rgcw.L["category_misc"] = "Misc"
