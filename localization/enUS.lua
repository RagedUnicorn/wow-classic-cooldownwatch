rgcw = rgcw or {}
rgcw.L = {}

rgcw.L["addon_name"] = "CooldownWatch"

-- console
rgcw.L["help"] = "|cFFFFFF00(%s)|r: Use |cFFFFFF00/rgcw|r or |cFFFFFF00/cooldownwatch|r for a list of options"
rgcw.L["reload"] = "|cFFFFFF00reload|r - reload UI"
rgcw.L["opt"] = "|cFFFFFF00opt|r - display Optionsmenu"
rgcw.L["info_title"] = "|cFFFFFF00CooldownWatch:|r"

-- about
rgcw.L["author"] = "Author: Michael Wiesendanger"
rgcw.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
rgcw.L["version"] = "Version: " .. GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
rgcw.L["issues"] = "Issues: https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues"

-- general
rgcw.L["general_category_name"] = "General"

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
rgcw.L["category_items"] = "Items"
