
-- luacheck: globals GetAddOnMetadata

rgcw = rgcw or {}
rgcw.L = {}

rgcw.L["addon_name"] = "CooldownWatch"

-- console
rgcw.L["help"] = "|cFFFFC300(%s)|r: Use |cFFFFC300/rgcw|r or |cFFFFC300/cooldownwatch|r for a list of options"
rgcw.L["reload"] = "|cFFFFC300reload|r - Reload UI"
rgcw.L["opt"] = "|cFFFFC300opt|r - Display Optionsmenu"
rgcw.L["conf"] = "|cFFFFC300conf enable||disable|r - Show or hide the example target cooldown bar "
  .. "for positioning (drag it while unlocked)"
rgcw.L["test"] = "|cFFFFFF00test|r - Test commands (use |cFFFFC300/rgcw test|r for the full menu)"
rgcw.L["info_title"] = "|cFF00FFB0CooldownWatch:|r"
rgcw.L["invalid_argument"] = "Invalid argument passed"
rgcw.L["update_available"] = "New version |cFFFFC300%s|r is available - |cFF00FFB0consider updating!|r"

-- about
rgcw.L["author"] = "Author: Michael Wiesendanger"
rgcw.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
rgcw.L["version"] = "Version: " .. GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
rgcw.L["issues"] = "Issues: https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues"

-- general
rgcw.L["general_category_name"] = "Options"
rgcw.L["general_title"] = "Options"
rgcw.L["window_lock_target_cooldown_bar"] = "Lock Targetcooldownbar"
rgcw.L["window_lock_target_cooldown_bar_tooltip"] = "Prevents Targetcooldownbar frame from being moved"
rgcw.L["option_global_assume_worst_case"] = "Assume worst case for all cooldowns"
rgcw.L["option_global_assume_worst_case_tooltip"] = "Assume every enemy has talents or gear reducing "
  .. "their cooldowns. Worst case settings on individual cooldowns still take precedence."

-- profiles
rgcw.L["profile_category_name"] = "Profiles"
rgcw.L["profile_title"] = "Profiles"
rgcw.L["profile_list_label"] = "Saved Profiles"
rgcw.L["profile_string_label"] = "Profile String (Export / Import)"
rgcw.L["profile_save_button"] = "Save current as..."
rgcw.L["profile_apply_button"] = "Apply"
rgcw.L["profile_rename_button"] = "Rename"
rgcw.L["profile_delete_button"] = "Delete"
rgcw.L["profile_export_button"] = "Export"
rgcw.L["profile_import_button"] = "Import"
rgcw.L["profile_name_prompt"] = "Enter a name for the new profile:"
rgcw.L["profile_rename_prompt"] = "Enter a new name for the profile:"
rgcw.L["profile_import_name_prompt"] = "Enter a name to save the imported profile under:"
rgcw.L["profile_apply_confirm"] = "Apply profile \"%s\"? This overwrites your current settings and reloads the UI."
rgcw.L["profile_delete_confirm"] = "Delete profile \"%s\"?"
rgcw.L["profile_save_success"] = "Saved profile \"%s\""
rgcw.L["profile_import_success"] = "Imported profile \"%s\""
rgcw.L["profile_delete_success"] = "Deleted profile \"%s\""
rgcw.L["profile_rename_success"] = "Renamed profile to \"%s\""
rgcw.L["profile_error_empty"] = "There is no profile string to import"
rgcw.L["profile_error_invalid"] = "The profile string is invalid or could not be read"
rgcw.L["profile_error_checksum"] = "The profile string is corrupt (checksum mismatch)"
rgcw.L["profile_error_wrong_addon"] = "This profile string was not created by CooldownWatch"
rgcw.L["profile_error_version"] = "This profile string was created by a newer version of CooldownWatch"
rgcw.L["profile_error_name_empty"] = "The profile name cannot be empty"
rgcw.L["profile_error_name_exists"] = "A profile with that name already exists"
rgcw.L["profile_error_no_selection"] = "No profile selected"

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
rgcw.L["option_assume_worst_case"] = "Worst case"
rgcw.L["option_assume_worst_case_tooltip"] = "Assume the enemy has talents or gear reducing this cooldown. "
  .. "The bar counts down the shortest realistic cooldown instead of the base value."
rgcw.L["option_cooldown_values"] = "%gs cooldown"
rgcw.L["option_cooldown_values_worst_case"] = "%gs cooldown / %gs worst case"
rgcw.L["option_manual_cooldown_override"] = "Cooldown override"
rgcw.L["option_manual_cooldown_override_tooltip"] = "Manually override the tracked cooldown in seconds. "
  .. "Takes precedence over all worst case settings. Leave empty for no override. "
  .. "The override can only lower the tracked time - values above the base cooldown are capped."
