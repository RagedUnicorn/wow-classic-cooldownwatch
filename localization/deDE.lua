if (GetLocale() == "deDE") then
  rgcw = rgcw or {}
  rgcw.L = {}

  rgcw.L["addon_name"] = "CooldownWatch"

  -- console
  rgcw.L["help"] = "|cFFFFC300(%s)|r: Benutze |cFFFFC300/rgcw|r oder |cFFFFC300/cooldownwatch|r für eine Liste der verfügbaren Optionen"
  rgcw.L["reload"] = "|cFFFFC300reload|r - UI neu laden"
  rgcw.L["opt"] = "|cFFFFC300opt|r - zeige Optionsmenu an"
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
  rgcw.L["window_lock_target_cooldow_bar"] = "Sperre Zielabklingzeitenbalken"
  rgcw.L["window_lock_target_cooldow_bar_tooltip"] = "Verhindert das bewegen des Zielabklingzeitenbalken"

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
  rgcw.L["category_misc"] = "Misc"


  -- profilesmenu TODO which ones are used?
  rgcw.L["profiles_menu_label"] = "Profile:"
  rgcw.L["save_current_profile_button"] = "Konfiguration speichern"
  rgcw.L["delete_selected_profile_button"] = "Profil löschen"
  rgcw.L["set_active_profile_button"] = "Profil laden"
  rgcw.L["load_default_profile_button"] = "Standard laden"
  rgcw.L["profile_active_status"] = "Aktive"
  rgcw.L["profile_inactive_status"] = "Inaktive"
  rgcw.L["choose_profile_name_dialog_text"] = "Wähle einen Namen für das neue Profil"
  rgcw.L["choose_profile_name_accept_button"] = "Akzeptieren"
  rgcw.L["choose_profile_name_cancel_button"] = "Abbrechen"
  rgcw.L["confirm_override_profile_dialog_text"] = "Dies überschreibt dein aktuelles Profil. Möchtest du fortfahren?"
  rgcw.L["confirm_override_profile_yes_button"] = "Ja"
  rgcw.L["confirm_override_profile_no_button"] = "Nein"
  rgcw.L["user_message_select_profile_before_delete"] = "Wähle ein Profil zum Löschen aus"
  rgcw.L["user_message_select_profile_before_load"] = "Wähle ein Profil zum laden aus"
  rgcw.L["user_message_select_profile_already_exists"] = "Profil existiert bereits - wähle einen anderen Namen"
  rgcw.L["user_message_add_new_profile_max_reached"] = "Ein Maximum von %s Profilen ist erlaubt, du hast das Maximum erreicht"
end
