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
  GlobalAssumeWorstCase = {
    label = rgcw.L["option_global_assume_worst_case"],
    description = rgcw.L["option_global_assume_worst_case_tooltip"]
  }
}

-- track whether the menu was already built
local builtMenu = false
--[[
  References to the panel's option controls, kept so the defaults reset can
  re-sync every control from the store without navigating away (checkboxes
  re-read through their OnShow callbacks, the slider through UpdateSliderValue)
]]--
local optionControls = {
  checkBoxes = {},
  scaleSlider = nil
}

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
    RGCW_CONSTANTS.ELEMENT_GENERAL_OPT_GLOBAL_ASSUME_WORST_CASE,
    20,
    -52,
    me.GlobalAssumeWorstCaseOnShow,
    me.GlobalAssumeWorstCaseOnClick
  )

  optionControls.scaleSlider = mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_GENERAL_TARGET_BAR_SCALE_SLIDER,
    frame,
    {"TOPLEFT", 20, -131},
    {
      minValue = RGCW_CONSTANTS.TARGET_BAR_SCALE_SLIDER_MIN,
      maxValue = RGCW_CONSTANTS.TARGET_BAR_SCALE_SLIDER_MAX,
      stepSize = RGCW_CONSTANTS.TARGET_BAR_SCALE_SLIDER_STEP,
      initialValue = mod.configuration.GetTargetCooldownBarScale()
    },
    rgcw.L["target_bar_scale_slider_title"],
    rgcw.L["target_bar_scale_slider_tooltip"],
    me.ScaleSliderOnValueChanged,
    me.FormatScaleValue
  )

  local placeModeButton = mod.guiHelper.CreateTextButton(
    RGCW_CONSTANTS.ELEMENT_GENERAL_OPT_PLACE_MODE_BUTTON,
    frame,
    {"TOPLEFT", 20, -236},
    me.PlaceModeButtonOnClick,
    rgcw.L["target_bar_place_mode_button"]
  )

  mod.guiHelper.CreateTextButton(
    RGCW_CONSTANTS.ELEMENT_GENERAL_OPT_DEFAULTS_BUTTON,
    frame,
    {"LEFT", placeModeButton, "RIGHT", 10, 0},
    me.DefaultsButtonOnClick,
    rgcw.L["target_bar_defaults_button"]
  )

  builtMenu = true
end

--[[
  Format a scale slider value for its labels - one decimal, hiding the float
  artifacts of the stepped slider

  @param {number} value

  @return {string}
]]--
function me.FormatScaleValue(value)
  return string.format("%.1f", value)
end

--[[
  OnValueChanged callback for the target cooldown bar scale slider

  @param {table} self
  @param {number} value
]]--
function me.ScaleSliderOnValueChanged(_, value)
  -- snap the float artifacts of the stepped slider off before storing the value
  local scale = math.floor(value * 10 + 0.5) / 10

  if mod.configuration.UpdateTargetCooldownBarScale(scale) ~= nil then
    mod.targetCooldownBar.TargetCooldownBarUiUpdate()
  end
end

--[[
  OnClick callback for the test/place mode button - hands off to the mode
  lifecycle, which closes the Settings window
]]--
function me.PlaceModeButtonOnClick()
  mod.targetCooldownBarPlaceMode.EnterPlaceMode()
end

--[[
  OnClick callback for the defaults button. Resets the target cooldown bar's
  settings to their shipped defaults - the lock flag, the scale and the saved
  bar position (proximity-panel parity). globalAssumeWorstCase is deliberately
  untouched: it governs cooldown resolution, not the bar (the friendly panel's
  reset draws the same line around its detection flags).
]]--
function me.DefaultsButtonOnClick()
  mod.configuration.ResetTargetCooldownBar()
  mod.configuration.ClearUserPlacedFramePosition(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_FRAME)
  mod.targetCooldownBar.TargetCooldownBarUiUpdate()
  me.RefreshOptionControls()
end

--[[
  Re-read every panel control from the store after it changed through another
  path (the defaults reset). Checkboxes re-run their OnShow callbacks; the
  slider goes through UpdateSliderValue, which detaches the OnValueChanged
  callback for the write - a plain SetValue would fire it and turn this
  re-sync into a store write.
]]--
function me.RefreshOptionControls()
  for _, checkBox in ipairs(optionControls.checkBoxes) do
    checkBox:GetScript("OnShow")(checkBox)
  end

  mod.guiHelper.UpdateSliderValue(
    optionControls.scaleSlider,
    mod.configuration.GetTargetCooldownBarScale()
  )
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
  -- kept so the defaults reset can re-sync the checkbox without navigating away
  table.insert(optionControls.checkBoxes, checkButtonOptionFrame)
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
