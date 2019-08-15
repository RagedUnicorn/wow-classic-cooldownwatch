--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_FRAME = "CW_TargetCooldownWatchBar",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_WIDTH = 650,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_HEIGHT = 70,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT = "$parentSlot_",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE = 60,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_X = 5,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_Y = 0,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT = 10,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_ANIMATION = "CooldownWatchAnimation",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_COOLDOWN_FRAME = "$parent_Cooldown",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_ICON_TEXTURE_NAME = "$parent_Icon",
  ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT = "$parent_BigText",
  ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_SIZE = 17,
  ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT = "$parent_SmallText",
  ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT_SIZE = 15,
  --[[
    Threshold in percent of the total cooldowntime to trigger warning glow for the cooldownslot
  ]]--
  ELEMENT_TARGET_COOLDOWN_WARN_TRESHOLD = 50,
  ELEMENT_TARGET_COOLDOWN_ALERT_TRESHOLD = 20,
  --[[
    Positions
  ]]--
  ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_LOW = 17,
  ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_HIGH = 12,
  --[[
    Addon configuration
  ]]--
  ELEMENT_ADDON_PANEL = "CW_AddonPanel",
  ELEMENT_TOOLTIP = "GameTooltip",
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
  ELEMENT_GENERAL_CHECK_OPTION_SIZE = 32,
  ELEMENT_GENERAL_OPT = "CW_Opt",
  ELEMENT_GENERAL_FRAME = "CW_GeneralFrame",
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
      ["categoryName"] = "items",
      ["localizationKey"] = "category_items",
      ["name"] = "CW_ItemsOptionsFrame"
    }
  },
  ELEMENT_CATEGORY_SCROLL_FRAME = "CW_CategoryScrollFrame",
  ELEMENT_CATEGORY_SCROLL_FRAME_SLIDER = "CW_CategoryScrollFrameSlider",
  ELEMENT_CATEGORY_SCROLL_FRAME_SLIDER_STEP_SIZE = 10,
  ELEMENT_CATEGORY_CONTENT_FRAME = "CW_CategoryContentFrame",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_FRAME = "CW_CategoryCooldownSpellFrame_",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_FRAME_HEIGHT = 50,
  ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON = "$parentIcon",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON_SIZE = 32,
  ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS = "$parentStatus",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS_SIZE = 32,
  --[[
    Configuration values for scrollframe slider
    0 is all the way up
    100 is all the way down
  ]]--
  CATEGORY_CONFIG_SLIDER_MIN_VALUE = 0,
  CATEGORY_CONFIG_SLIDER_MAX_VALUE = 100,
  --[[
    QuickChange spellList frame
  ]]--
  ELEMENT_SPELL_LIST_SCROLL_FRAME = "CW_SpellListScrollFrame",
  ELEMENT_SPELL_LIST_CONTENT_FRAME_WIDTH = 570,
  ELEMENT_SPELL_LIST_SPELL_ROW = "$parentRow",
  ELEMENT_SPELL_LIST_MAX_ROWS = 9,
  ELEMENT_SPELL_LIST_ROW_HEIGHT = 50,

}
