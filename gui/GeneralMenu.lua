--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

local mod = rgcw
local me = {}

mod.generalMenu = me

me.tag = "GeneralMenu"

--[[
  Option texts for checkbutton options - keyed by the frame name suffix; the
  description is rendered always-visible beneath the checkbox label
]]--
local options = {
  WindowLockTargetCooldownBar = {
    label = rgcw.L["window_lock_target_cooldown_bar"],
    description = rgcw.L["window_lock_target_cooldown_bar_tooltip"]
  },
  GlobalAssumeWorstCase = {
    label = rgcw.L["option_global_assume_worst_case"],
    description = rgcw.L["option_global_assume_worst_case_tooltip"]
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

  mod.guiHelper.CreatePanelTitle(
    frame,
    RGCW_CONSTANTS.ELEMENT_GENERAL_TITLE,
    rgcw.L["options_title"]
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_GENERAL_OPT_WINDOW_LOCK_TARGET_COOLDOWN_BAR,
    20,
    -52,
    me.LockWindowTargetCooldownBarOnShow,
    me.LockWindowTargetCooldownBarOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_GENERAL_OPT_GLOBAL_ASSUME_WORST_CASE,
    20,
    -104,
    me.GlobalAssumeWorstCaseOnShow,
    me.GlobalAssumeWorstCaseOnClick
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
  local optionData = me.GetOptionData(optionFrameName)
  local checkButtonOptionFrame = mod.guiHelper.CreateCheckBox(
    optionFrameName,
    parentFrame,
    {"TOPLEFT", posX, posY},
    onClickCallback,
    onShowCallback,
    optionData and optionData.label,
    optionData and optionData.description
  )

  -- load initial state
  onShowCallback(checkButtonOptionFrame)
end

--[[
  Get the option metadata for a checkbutton

  @param {string} frameName

  @return {table | nil}
    The option data with label and description
]]--
function me.GetOptionData(frameName)
  if not frameName then return end

  for optionKey, optionData in pairs(options) do
    if frameName == RGCW_CONSTANTS.ELEMENT_GENERAL_OPT .. optionKey then
      return optionData
    end
  end
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

--[[
  OnShow callback for checkbuttons - global assume worst case

  @param {table} self
]]--
function me.GlobalAssumeWorstCaseOnShow(self)
  if mod.configuration.IsGlobalWorstCaseAssumed() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - global assume worst case

  @param {table} self
]]--
function me.GlobalAssumeWorstCaseOnClick(self)
  mod.configuration.UpdateGlobalWorstCaseState(self:GetChecked() == true)
end
