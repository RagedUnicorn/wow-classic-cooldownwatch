--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

-- luacheck: globals STANDARD_TEXT_FONT CreateFrame

local mod = rgcw
local me = {}
mod.generalMenu = me

me.tag = "GeneralMenu"

--[[
  Option texts for checkbutton options
]]--
local options = {
  {
    "WindowLockTargetCooldownBar",
    rgcw.L["window_lock_target_cooldow_bar"],
    rgcw.L["window_lock_target_cooldow_bar_tooltip"]
  }
}


-- track whether the menu was already built
local builtMenu = false

--[[
  Build the ui for the general menu

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  local titleFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_GENERAL_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(frame:GetWidth(), 20)
  titleFontString:SetText(rgcw.L["general_title"])

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_GENERAL_OPT_WINDOW_LOCK_TARGET_COOLDOWN_BAR,
    20,
    -80,
    me.LockWindowTargetCooldownBarOnShow,
    me.LockWindowTargetCooldownBarOnClick
  )

  builtMenu = true
end

--[[
  Build a checkbutton option

  @param {table} parentFrame
  @param {string} optionFrameName
  @param {number} posX
  @param {number} posY
  @param {function} onShowCallback
  @param {function} onClickCallback
]]--
function me.BuildCheckButtonOption(parentFrame, optionFrameName, posX, posY, onShowCallback, onClickCallback)
  local checkButtonOptionFrame = CreateFrame("CheckButton", optionFrameName, parentFrame, "UICheckButtonTemplate")
  checkButtonOptionFrame:SetSize(
    RGCW_CONSTANTS.CHECK_OPTION_SIZE,
    RGCW_CONSTANTS.CHECK_OPTION_SIZE
  )
  checkButtonOptionFrame:SetPoint("TOPLEFT", posX, posY)

  for _, region in ipairs({checkButtonOptionFrame:GetRegions()}) do
    if string.find(region:GetName() or "", "Text$") and region:IsObjectType("FontString") then
      region:SetFont(STANDARD_TEXT_FONT, 15)
      region:SetTextColor(.95, .95, .95)
      region:SetText(me.GetLabelText(checkButtonOptionFrame))
      break
    end
  end

  checkButtonOptionFrame:SetScript("OnEnter", me.OptTooltipOnEnter)
  checkButtonOptionFrame:SetScript("OnLeave", me.OptTooltipOnLeave)
  checkButtonOptionFrame:SetScript("OnShow", onShowCallback)
  checkButtonOptionFrame:SetScript("OnClick", onClickCallback)
  -- load initial state
  onShowCallback(checkButtonOptionFrame)
end

--[[
  Get the label text for the checkbutton

  @param {table} frame

  @return {string}
    The text for the label
]]--
function me.GetLabelText(frame)
  local name = frame:GetName()

  if not name then return end

  for i = 1, table.getn(options) do
    if name == RGCW_CONSTANTS.ELEMENT_GENERAL_OPT .. options[i][1] then
      return options[i][2]
    end
  end
end

--[[
  OnEnter callback for checkbuttons - show tooltip

  @param {table} self
]]--
function me.OptTooltipOnEnter(self)
  local name = self:GetName()

  if not name then return end

  for i = 1, table.getn(options) do
    if name == RGCW_CONSTANTS.ELEMENT_GENERAL_OPT .. options[i][1] then
      mod.tooltip.BuildTooltipForOption(options[i][2], options[i][3])
      break
    end
  end
end

--[[
  OnEnter callback for checkbuttons - hide tooltip
]]--
function me.OptTooltipOnLeave()
  _G[RGCW_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
end

--[[
  OnShow callback for checkbuttons - window lock gearBar

  @param {table} self
]]--
function me.LockWindowTargetCooldownBarOnShow(self)
  if mod.configuration.IsTargetCooldownBarLocked() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - window lock gearBar

  @param {table} self
]]--
function me.LockWindowTargetCooldownBarOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.LockTargetCooldownBar()
  else
    mod.configuration.UnlockTargetCooldownBar()
  end
end
