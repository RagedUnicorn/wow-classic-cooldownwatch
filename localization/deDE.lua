
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

  -- profiles
  rgcw.L["profile_category_name"] = "Profile"
  rgcw.L["profile_title"] = "Konfigurationsprofile"
  rgcw.L["profile_list_label"] = "Gespeicherte Profile"
  rgcw.L["profile_string_label"] = "Profil-Zeichenkette (Export / Import)"
  rgcw.L["profile_save_button"] = "Aktuelles speichern als..."
  rgcw.L["profile_apply_button"] = "Anwenden"
  rgcw.L["profile_rename_button"] = "Umbenennen"
  rgcw.L["profile_delete_button"] = "Löschen"
  rgcw.L["profile_export_button"] = "Exportieren"
  rgcw.L["profile_import_button"] = "Importieren"
  rgcw.L["profile_name_prompt"] = "Gib einen Namen für das neue Profil ein:"
  rgcw.L["profile_rename_prompt"] = "Gib einen neuen Namen für das Profil ein:"
  rgcw.L["profile_import_name_prompt"] = "Gib einen Namen ein, unter dem das importierte Profil gespeichert wird:"
  rgcw.L["profile_apply_confirm"] = "Profil \"%s\" anwenden? Dies überschreibt deine aktuellen Einstellungen "
    .. "und lädt die UI neu."
  rgcw.L["profile_delete_confirm"] = "Profil \"%s\" löschen?"
  rgcw.L["profile_save_success"] = "Profil \"%s\" gespeichert"
  rgcw.L["profile_import_success"] = "Profil \"%s\" importiert"
  rgcw.L["profile_delete_success"] = "Profil \"%s\" gelöscht"
  rgcw.L["profile_rename_success"] = "Profil umbenannt in \"%s\""
  rgcw.L["profile_error_empty"] = "Es gibt keine Profil-Zeichenkette zum Importieren"
  rgcw.L["profile_error_invalid"] = "Die Profil-Zeichenkette ist ungültig oder konnte nicht gelesen werden"
  rgcw.L["profile_error_checksum"] = "Die Profil-Zeichenkette ist beschädigt (Prüfsumme stimmt nicht)"
  rgcw.L["profile_error_wrong_addon"] = "Diese Profil-Zeichenkette wurde nicht von CooldownWatch erstellt"
  rgcw.L["profile_error_version"] = "Diese Profil-Zeichenkette wurde mit einer neueren Version "
    .. "von CooldownWatch erstellt"
  rgcw.L["profile_error_name_empty"] = "Der Profilname darf nicht leer sein"
  rgcw.L["profile_error_name_exists"] = "Ein Profil mit diesem Namen existiert bereits"
  rgcw.L["profile_error_no_selection"] = "Kein Profil ausgewählt"

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
  rgcw.L["option_manual_cooldown_override"] = "Abklingzeit überschreiben"
  rgcw.L["option_manual_cooldown_override_tooltip"] = "Überschreibt die verfolgte Abklingzeit in Sekunden. "
    .. "Hat Vorrang vor allen Worst-Case-Einstellungen. Leer lassen für keine Überschreibung. "
    .. "Die Überschreibung kann die verfolgte Zeit nur verkürzen - Werte über der Grundabklingzeit "
    .. "werden begrenzt."
end
