if (GetLocale() == "deDE") then
  rgcw = rgcw or {}
  rgcw.L = {}

  rgcw.L["addon_name"] = "CooldownWatch"

  -- console
  rgcw.L["help"] = "|cFFFFFF00(%s)|r: Benutze |cFFFFFF00/rgcw|r oder |cFFFFFF00/cooldownwatch|r für eine Liste der verfügbaren Optionen"
  rgcw.L["reload"] = "|cFFFFFF00reload|r - UI neu laden"
  rgcw.L["opt"] = "|cFFFFFF00opt|r - zeige Optionsmenu an"
  rgcw.L["info_title"] = "|cFFFFFF00CooldownWatch:|r"

  -- about tab
  rgcw.L["author"] = "Autor: Michael Wiesendanger"
  rgcw.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
  rgcw.L["version"] = "Version: " .. GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
  rgcw.L["issues"] = "Probleme: https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues"

  -- general
  rgecb.L["general_category_name"] = "Allgemein"

  -- cooldown menu TODO translate
  rgcw.L["category_priest"] = "Priester"
  rgcw.L["category_rogue"] = "Schurke"
  rgcw.L["category_mage"] = "Magier"
  rgcw.L["category_hunter"] = "Jäger"
  rgcw.L["category_warlock"] = "Hexenmeister"
  rgcw.L["category_paladin"] = "Paladin"
  rgcw.L["category_druid"] = "Druide"
  rgcw.L["category_shaman"] = "Shamane"
  rgcw.L["category_warrior"] = "Krieger"
  rgcw.L["category_racials"] = "Rassenfähigkeiten"
  rgcw.L["category_items"] = "Items"
end
