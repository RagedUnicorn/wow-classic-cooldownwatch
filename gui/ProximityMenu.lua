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

--[[
  Options panel of the proximity cooldown window (gui/ProximityCooldownBar.lua). Every
  change writes through the configuration accessors and then invokes
  ProximityCooldownBarUiUpdate, so it applies to the live window immediately - the
  max-displayed and hide-long options are additionally re-read by every render pass
  either way.
]]--

local mod = rgcw
local me = {}

mod.proximityMenu = me

me.tag = "ProximityMenu"

--[[
  Option texts for checkbutton options - keyed by the option frame name; the
  description is rendered always-visible beneath the checkbox label
]]--
local options = {
  [RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_ENABLE_PROXIMITY_COOLDOWN_WINDOW] = {
    label = rgcw.L["option_enable_proximity_cooldown_window"],
    description = rgcw.L["option_enable_proximity_cooldown_window_tooltip"]
  },
  [RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_HIDE_LONG_PROXIMITY_COOLDOWNS] = {
    label = rgcw.L["option_hide_long_proximity_cooldowns"],
    description = string.format(
      rgcw.L["option_hide_long_proximity_cooldowns_tooltip"],
      RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
    )
  }
}

-- track whether the menu was already built
local builtMenu = false
--[[
  References to the panel's option controls, kept for two consumers: the
  defaults reset re-syncs every control from the store without navigating away
  (checkboxes re-read through their OnShow callbacks, sliders through
  UpdateSliderValue), and the enable-flag gate disables every sub-option below
  the window-enable checkbox (see UpdateSubOptionsState). enableCheckBox marks
  that master inside the checkBoxes list - it is the one control the gate
  never touches.
]]--
local optionControls = {
  checkBoxes = {},
  enableCheckBox = nil,
  scaleSlider = nil,
  maxDisplayedSlider = nil,
  placeModeButton = nil,
  defaultsButton = nil
}

--[[
  Build the ui for the proximity cooldowns menu

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  mod.guiHelper.CreatePanelTitle(
    frame,
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_TITLE,
    rgcw.L["proximity_title"]
  )

  optionControls.enableCheckBox = me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_ENABLE_PROXIMITY_COOLDOWN_WINDOW,
    20,
    -52,
    me.EnableProximityWindowOnShow,
    me.EnableProximityWindowOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_HIDE_LONG_PROXIMITY_COOLDOWNS,
    20,
    -104,
    me.HideLongCooldownsOnShow,
    me.HideLongCooldownsOnClick
  )

  optionControls.scaleSlider = mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_SCALE_SLIDER,
    frame,
    {"TOPLEFT", 20, -183},
    {
      minValue = RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_MIN,
      maxValue = RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_MAX,
      stepSize = RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_STEP,
      initialValue = mod.configuration.GetProximityCooldownsScale()
    },
    rgcw.L["proximity_scale_slider_title"],
    rgcw.L["proximity_scale_slider_tooltip"],
    me.ScaleSliderOnValueChanged,
    me.FormatScaleValue
  )

  optionControls.maxDisplayedSlider = mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_MAX_DISPLAYED_SLIDER,
    frame,
    {"TOPLEFT", 20, -263},
    {
      minValue = RGCW_CONSTANTS.PROXIMITY_MAX_DISPLAYED_SLIDER_MIN,
      -- the render layer's fixed row pool is the ceiling; a larger range would be dead travel
      maxValue = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT,
      stepSize = RGCW_CONSTANTS.PROXIMITY_MAX_DISPLAYED_SLIDER_STEP,
      initialValue = mod.configuration.GetProximityCooldownsMaxDisplayed()
    },
    rgcw.L["proximity_max_displayed_slider_title"],
    rgcw.L["proximity_max_displayed_slider_tooltip"],
    me.MaxDisplayedSliderOnValueChanged
  )

  optionControls.placeModeButton = mod.guiHelper.CreateTextButton(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_PLACE_MODE_BUTTON,
    frame,
    {"TOPLEFT", 20, -368},
    me.PlaceModeButtonOnClick,
    rgcw.L["proximity_place_mode_button"]
  )

  optionControls.defaultsButton = mod.guiHelper.CreateTextButton(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_DEFAULTS_BUTTON,
    frame,
    {"LEFT", optionControls.placeModeButton, "RIGHT", 10, 0},
    me.DefaultsButtonOnClick,
    rgcw.L["proximity_defaults_button"]
  )

  builtMenu = true

  -- every control exists now - apply the enable-flag gate to the initial state
  me.UpdateSubOptionsState()
end

--[[
  Enable or disable every sub-option below the window-enable checkbox. With
  the window disabled nothing below it has any effect, so the panel body reads
  as inert instead of inviting configuration that appears to do nothing
  (FriendlyCooldownMenu master-flag parity). The stored values are untouched -
  the gate is a ui affordance only, so re-enabling the window brings every
  sub-option back exactly as configured.

  Runs on panel build, on every enable toggle, and on every panel show (the
  enable checkbox's OnShow callback), so the gate can never go stale - the
  defaults reset in particular re-applies it for free, since RefreshOptionControls
  re-runs the enable checkbox's OnShow after the reset switched the window off.
]]--
function me.UpdateSubOptionsState()
  -- during the initial build the enable checkbox's OnShow fires before the
  -- other controls exist - BuildUi applies the gate once everything is built
  if not builtMenu then return end

  local enabled = mod.configuration.IsProximityCooldownsEnabled()

  for _, checkBox in ipairs(optionControls.checkBoxes) do
    if checkBox ~= optionControls.enableCheckBox then
      mod.guiHelper.SetCheckBoxEnabled(checkBox, enabled)
    end
  end

  -- the slider template grays its own labels (see GuiHelper.SetSettingsDropdownEnabled)
  optionControls.scaleSlider:SetEnabled(enabled)
  optionControls.maxDisplayedSlider:SetEnabled(enabled)
  optionControls.placeModeButton:SetEnabled(enabled)
  optionControls.defaultsButton:SetEnabled(enabled)
end

--[[
  OnClick callback for the test/place mode button - hands off to the mode
  lifecycle, which closes the Settings window
]]--
function me.PlaceModeButtonOnClick()
  mod.proximityCooldownBarPreview.EnterPlaceMode()
end

--[[
  OnClick callback for the defaults button. Resets every proximity-window
  setting to its shipped defaults, including the saved window position ("all
  settings" deliberately covers the position - unlike the PVPWarn precedent,
  which splits the anchor reset into its own button), applies the reset to the
  live window and re-syncs the panel controls in place.
]]--
function me.DefaultsButtonOnClick()
  mod.configuration.ResetProximityCooldowns()
  mod.configuration.ClearUserPlacedFramePosition(RGCW_CONSTANTS.ELEMENT_PROXIMITY_COOLDOWN_WINDOW_FRAME)
  mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
  me.RefreshOptionControls()
end

--[[
  Re-read every panel control from the store after it changed through another
  path (the defaults reset). Checkboxes re-run their OnShow callbacks; the
  sliders go through UpdateSliderValue, which detaches the OnValueChanged
  callback for the write - a plain SetValue would fire it and turn this
  re-sync into a store write.
]]--
function me.RefreshOptionControls()
  for _, checkBox in ipairs(optionControls.checkBoxes) do
    checkBox:GetScript("OnShow")(checkBox)
  end

  mod.guiHelper.UpdateSliderValue(
    optionControls.scaleSlider,
    mod.configuration.GetProximityCooldownsScale()
  )
  mod.guiHelper.UpdateSliderValue(
    optionControls.maxDisplayedSlider,
    mod.configuration.GetProximityCooldownsMaxDisplayed()
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
  local optionData = options[optionFrameName]
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

  return checkButtonOptionFrame
end

--[[
  OnShow callback for checkbuttons - enable proximity cooldown window. Also
  re-applies the sub-option gate so a panel revisit reflects a flag that
  changed through another path in the meantime.

  @param {table} self
]]--
function me.EnableProximityWindowOnShow(self)
  if mod.configuration.IsProximityCooldownsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end

  me.UpdateSubOptionsState()
end

--[[
  OnClick callback for checkbuttons - enable proximity cooldown window. The
  panel's sub-options follow the flag immediately through the gate.

  @param {table} self
]]--
function me.EnableProximityWindowOnClick(self)
  mod.configuration.UpdateProximityCooldownsEnabled(self:GetChecked() == true)
  mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
  me.UpdateSubOptionsState()
end

--[[
  OnShow callback for checkbuttons - hide long cooldowns

  @param {table} self
]]--
function me.HideLongCooldownsOnShow(self)
  if mod.configuration.IsProximityCooldownsHideLongEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - hide long cooldowns

  @param {table} self
]]--
function me.HideLongCooldownsOnClick(self)
  mod.configuration.UpdateProximityCooldownsHideLong(self:GetChecked() == true)
  mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
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
  OnValueChanged callback for the window scale slider

  @param {table} self
  @param {number} value
]]--
function me.ScaleSliderOnValueChanged(_, value)
  -- snap the float artifacts of the stepped slider off before storing the value
  local scale = math.floor(value * 10 + 0.5) / 10

  if mod.configuration.UpdateProximityCooldownsScale(scale) ~= nil then
    mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
  end
end

--[[
  OnValueChanged callback for the max displayed cooldowns slider

  @param {table} self
  @param {number} value
]]--
function me.MaxDisplayedSliderOnValueChanged(_, value)
  if mod.configuration.UpdateProximityCooldownsMaxDisplayed(math.floor(value + 0.5)) ~= nil then
    mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
  end
end
