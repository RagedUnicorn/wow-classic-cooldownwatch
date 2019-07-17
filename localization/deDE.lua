if (GetLocale() == "deDE") then
  rgcw = rgcw or {}
  rgcw.L = {}

  rgcw.L["addon_name"] = "CooldownWatch"

  -- console
  rgcw.L["help"] = "|cFFFFFF00(%s)|r: Benutze |cFFFFFF00/rgcw|r oder |cFFFFFF00/cooldownwatch|r für eine Liste der verfügbaren Optionen"
  rgcw.L["reload"] = "|cFFFFFF00reload|r - UI neu laden"
  rgcw.L["info_title"] = "|cFFFFFF00CooldownWatch:|r"

  -- about tab
  rgcw.L["author"] = "Autor: Michael Wiesendanger"
  rgcw.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
  rgcw.L["version"] = "Version: " .. GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
  rgcw.L["issues"] = "Probleme: https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues"

  -- general
  rgecb.L["general_category_name"] = "Allgemein"
end
