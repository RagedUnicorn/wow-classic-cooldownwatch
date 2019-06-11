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
  --[[
    Update Intervals for tickers
  ]]--
  TARGET_COOLDOWN_BAR_UPDATE_INTERVAL = 0.1,

  --[[
    TargetCooldownFrame
  ]]--
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_FRAME = "CW_TargetCooldownWatchBar",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_WIDTH = 650,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_HEIGHT = 70,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT = "$parentSlot_",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE = 64,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_BASE_X = 5,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_X = 5,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_Y = 0,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT = 10,
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_COOLDOWN_FRAME = "$parentCooldown",

  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_BIG_COOLDOWN = "$parentBigTimeFrame",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_BIG_COOLDOWN_TEXT = "$parentText",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SMALL_COOLDOWN = "$parentSmallTimeFrame",
  ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SMALL_COOLDOWN_TEXT = "$parentText",


  --[[
    Addon configuration
  ]]--
  ELEMENT_ADDON_PANEL = "CooldownWatchPanel",
  ELEMENT_ADDON_PANEL_NAME = "CooldownWatch",
  ELEMENT_TOOLTIP = "GameTooltip",
  --[[
    about
  ]]--
  ELEMENT_ABOUT_LOGO = "CW_AboutLogo",
  ELEMENT_ABOUT_AUTHOR_FONT_STRING = "CW_AboutAuthor",
  ELEMENT_ABOUT_EMAIL_FONT_STRING = "CW_AboutEmail",
  ELEMENT_ABOUT_VERSION_FONT_STRING = "CW_AboutVersion",
  ELEMENT_ABOUT_ISSUES_FONT_STRING = "CW_AboutIssues",
}
