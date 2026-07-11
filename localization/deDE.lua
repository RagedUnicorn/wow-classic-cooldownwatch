
-- luacheck: globals GetLocale GetAddOnMetadata

if (GetLocale() == "deDE") then
  rgcw = rgcw or {}
  rgcw.L = {}

  rgcw.L["addon_name"] = "CooldownWatch"

  -- console
  rgcw.L["help"] = "|cFFFFC300(%s)|r: Benutze |cFFFFC300/rgcw|r oder |cFFFFC300/cooldownwatch|r "
    .. "für eine Liste der verfügbaren Optionen"
  rgcw.L["reload"] = "|cFFFFC300reload|r - UI neu laden"
  rgcw.L["opt"] = "|cFFFFC300opt|r - Zeige Optionsmenu an"
  rgcw.L["conf"] = "|cFFFFC300conf enable||disable|r - Zeigt oder versteckt die Beispiel-Ziel-Cooldown-Leiste "
    .. "zum Positionieren (bei entsperrter Leiste verschiebbar)"
  rgcw.L["test"] = "|cFFFFFF00test|r - Test-Befehle (nutze |cFFFFC300/rgcw test|r für das vollständige Menü)"
  rgcw.L["info_title"] = "|cFF00FFB0CooldownWatch:|r"
  rgcw.L["invalid_argument"] = "Ungültiges Argument übergeben"

  -- about tab
  rgcw.L["author"] = "Autor: Michael Wiesendanger"
  rgcw.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
  rgcw.L["version"] = "Version: " .. GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
  rgcw.L["issues"] = "Probleme: https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues"

  -- general
  rgcw.L["general_category_name"] = "Allgemein"
  rgcw.L["general_title"] = "Allgemeine Konfiguration"
  rgcw.L["window_lock_target_cooldown_bar"] = "Sperre Zielabklingzeitenbalken"
  rgcw.L["window_lock_target_cooldown_bar_tooltip"] = "Verhindert das bewegen des Zielabklingzeitenbalken"
  rgcw.L["option_global_assume_worst_case"] = "Worst Case für alle Abklingzeiten annehmen"
  rgcw.L["option_global_assume_worst_case_tooltip"] = "Nimmt an, dass jeder Gegner Talente oder Ausrüstung "
    .. "besitzt, die seine Abklingzeiten verkürzen. Worst-Case-Einstellungen einzelner Abklingzeiten "
    .. "haben weiterhin Vorrang."

  -- cooldown menu
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
  rgcw.L["category_misc"] = "Verschiedenes"
  rgcw.L["option_assume_worst_case"] = "Worst Case"
  rgcw.L["option_assume_worst_case_tooltip"] = "Nimmt an, dass der Gegner Talente oder Ausrüstung besitzt, "
    .. "die diese Abklingzeit verkürzen. Die Leiste zählt die kürzeste realistische Abklingzeit "
    .. "statt des Grundwerts herunter."
end
