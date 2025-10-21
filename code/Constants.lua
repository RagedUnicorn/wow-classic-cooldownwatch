--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

RGCW_CONSTANTS = {
  ADDON_NAME = "CooldownWatch",
  --[[
    Unit ids
  ]]--
  UNIT_ID_TARGET = "target",
  UNIT_ID_PLAYER = "player",
  --[[
    Update Intervals for tickers
  ]]--
  TARGET_COOLDOWN_BAR_UPDATE_INTERVAL = 0.05,
  --[[
    TargetCooldownFrame
  ]]--
  ELEMENT_TARGET_COOLDOWN_BAR_FRAME = "CW_TargetCooldownWatchBar",
  TARGET_COOLDOWN_BAR_WIDTH = 650,
  TARGET_COOLDOWN_BAR_HEIGHT = 70,
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT = "$parentSlot_",
  TARGET_COOLDOWN_BAR_SLOT_DEFAULT_SIZE = 60,
  TARGET_COOLDOWN_BAR_SLOT_X = 5,
  TARGET_COOLDOWN_BAR_SLOT_Y = 0,
  TARGET_COOLDOWN_BAR_SLOT_AMOUNT = 10,
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT_ANIMATION = "CooldownWatchAnimation",
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT_COOLDOWN_FRAME = "$parent_Cooldown",
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT_ICON_TEXTURE_NAME = "$parent_Icon",
  ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT = "$parent_BigText",
  TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_SIZE = 17,
  ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT = "$parent_SmallText",
  TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT_SIZE = 15,
  --[[
    Threshold in percent of the total cooldown time to trigger warning glow for the cooldown slot
  ]]--
  TARGET_COOLDOWN_WARN_THRESHOLD = 50,
  TARGET_COOLDOWN_ALERT_THRESHOLD = 20,
  --[[
    Positions
  ]]--
  TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_LOW = 17,
  TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_HIGH = 12,
  --[[
    Addon configuration
  ]]--
  ELEMENT_ADDON_PANEL = "CW_AddonPanel",
  ELEMENT_TOOLTIP = "GameTooltip",
  --[[
    Test UI Elements
  ]]--
  ELEMENT_TEST_LOG_WINDOW = "CooldownWatch_TestLogWindow",
  ELEMENT_TEST_LOG_WINDOW_TITLE = "CooldownWatch_TestLogWindowTitle",
  ELEMENT_TEST_LOG_WINDOW_SCROLL_FRAME = "CooldownWatch_TestLogWindowScrollFrame",
  ELEMENT_TEST_LOG_WINDOW_SCROLL_CHILD = "CooldownWatch_TestLogWindowScrollChild",
  ELEMENT_TEST_LOG_WINDOW_AUTO_SCROLL = "CooldownWatch_TestLogWindowAutoScrollCheckBox",
  ELEMENT_TEST_LOG_WINDOW_CLOSE_BUTTON = "CooldownWatch_TestLogWindowCloseButton",
  ELEMENT_TEST_LOG_WINDOW_CLEAR_BUTTON = "CooldownWatch_TestLogWindowClearButton",
  --[[
    SavedVariables
  ]]--
  SAVED_VARIABLE_TEST_LOG = "CooldownWatchTestLog",
  --[[
    Addon Configuration General Elements
  ]]--
  CHECK_OPTION_SIZE = 32,
  --[[
    AboutMenu
  ]]--
  ELEMENT_ABOUT_LOGO = "CW_AboutLogo",
  ELEMENT_ABOUT_AUTHOR_FONT_STRING = "CW_AboutAuthor",
  ELEMENT_ABOUT_EMAIL_FONT_STRING = "CW_AboutEmail",
  ELEMENT_ABOUT_VERSION_FONT_STRING = "CW_AboutVersion",
  ELEMENT_ABOUT_ISSUES_FONT_STRING = "CW_AboutIssues",
  --[[
    GeneralMenu
  ]]--
  ELEMENT_GENERAL_SUB_OPTION_FRAME = "CW_GeneralMenuOptionsFrame",
  ELEMENT_GENERAL_OPT = "CW_Opt",
  ELEMENT_GENERAL_TITLE = "CW_GeneralTitle",
  ELEMENT_GENERAL_OPT_WINDOW_LOCK_TARGET_COOLDOWN_BAR = "CW_OptWindowLockTargetCooldownBar",
  --[[
    CooldownMenu
  ]]
  CATEGORIES = {
    [1] = {
      ["categoryName"] = "priest",
      ["localizationKey"] = "category_priest",
      ["name"] = "CW_PriestOptionsFrame"
    },
    [2] = {
      ["categoryName"] = "rogue",
      ["localizationKey"] = "category_rogue",
      ["name"] = "CW_RogueOptionsFrame"
    },
    [3] = {
      ["categoryName"] = "mage",
      ["localizationKey"] = "category_mage",
      ["name"] = "CW_MageOptionsFrame"
    },
    [4] = {
      ["categoryName"] = "hunter",
      ["localizationKey"] = "category_hunter",
      ["name"] = "CW_HunterOptionsFrame"
    },
    [5] = {
      ["categoryName"] = "warlock",
      ["localizationKey"] = "category_warlock",
      ["name"] = "CW_WarlockOptionsFrame"
    },
    [6] = {
      ["categoryName"] = "paladin",
      ["localizationKey"] = "category_paladin",
      ["name"] = "CW_PaladinOptionsFrame"
    },
    [7] = {
      ["categoryName"] = "druid",
      ["localizationKey"] = "category_druid",
      ["name"] = "CW_DruidOptionsFrame"
    },
    [8] = {
      ["categoryName"] = "shaman",
      ["localizationKey"] = "category_shaman",
      ["name"] = "CW_ShamanOptionsFrame"
    },
    [9] = {
      ["categoryName"] = "warrior",
      ["localizationKey"] = "category_warrior",
      ["name"] = "CW_WarriorOptionsFrame"
    },
    [10] = {
      ["categoryName"] = "racials",
      ["localizationKey"] = "category_racials",
      ["name"] = "CW_RacialsOptionsFrame"
    },
    [11] = {
      ["categoryName"] = "misc",
      ["localizationKey"] = "category_misc",
      ["name"] = "CW_ItemsOptionsFrame"
    }
  },
  --[[
    Cooldown spellList frame
  ]]--
  ELEMENT_SPELL_LIST_CONTENT_FRAME = "$parent_CW_SpellListContentFrame",
  SPELL_LIST_CONTENT_FRAME_WIDTH = 580,
  SPELL_LIST_CONTENT_FRAME_HEIGHT = 552,
  SPELL_LIST_MAX_ROWS = 9,
  SPELL_LIST_ROW_HEIGHT = 50,
  --[[
    Cooldown spellList scroll frame
  ]]--
  ELEMENT_SPELL_LIST_SCROLL_FRAME = "CW_SpellListScrollFrame",
  ELEMENT_SPELL_LIST_SPELL_ROW = "$parentRow",
  --[[
    Cooldown spellList row
  ]]--
  ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON = "$parentIcon",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS = "$parentStatus",
  CATEGORY_COOLDOWN_SPELL_ICON_SIZE = 32,
  COOLDOWN_SPELL_DEFAULT_SIZE = 32,
}
