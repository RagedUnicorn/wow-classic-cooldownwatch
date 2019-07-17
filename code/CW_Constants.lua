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
    Treshold in percent of the total cooldowntime to trigger warning glow for the cooldownslot
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
  ELEMENT_TOOLTIP = "GameTooltip",
  --[[
    About
  ]]--
  ELEMENT_ABOUT_LOGO = "CW_AboutLogo",
  ELEMENT_ABOUT_AUTHOR_FONT_STRING = "CW_AboutAuthor",
  ELEMENT_ABOUT_EMAIL_FONT_STRING = "CW_AboutEmail",
  ELEMENT_ABOUT_VERSION_FONT_STRING = "CW_AboutVersion",
  ELEMENT_ABOUT_ISSUES_FONT_STRING = "CW_AboutIssues",
  --[[
    General
  ]]--
  ELEMENT_GENERAL_SUB_OPTION_FRAME = "CW_GeneralMenuOptionsFrame",
}
