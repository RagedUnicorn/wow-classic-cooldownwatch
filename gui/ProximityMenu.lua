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
  [RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_WINDOW_LOCK_PROXIMITY_COOLDOWN_WINDOW] = {
    label = rgcw.L["window_lock_proximity_cooldown_window"],
    description = rgcw.L["window_lock_proximity_cooldown_window_tooltip"]
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

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_ENABLE_PROXIMITY_COOLDOWN_WINDOW,
    20,
    -52,
    me.EnableProximityWindowOnShow,
    me.EnableProximityWindowOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_WINDOW_LOCK_PROXIMITY_COOLDOWN_WINDOW,
    20,
    -104,
    me.LockWindowProximityCooldownWindowOnShow,
    me.LockWindowProximityCooldownWindowOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_OPT_HIDE_LONG_PROXIMITY_COOLDOWNS,
    20,
    -156,
    me.HideLongCooldownsOnShow,
    me.HideLongCooldownsOnClick
  )

  mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_SCALE_SLIDER,
    frame,
    {"TOPLEFT", 20, -235},
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

  mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_MAX_DISPLAYED_SLIDER,
    frame,
    {"TOPLEFT", 20, -315},
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
end

--[[
  OnShow callback for checkbuttons - enable proximity cooldown window

  @param {table} self
]]--
function me.EnableProximityWindowOnShow(self)
  if mod.configuration.IsProximityCooldownsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable proximity cooldown window

  @param {table} self
]]--
function me.EnableProximityWindowOnClick(self)
  mod.configuration.UpdateProximityCooldownsEnabled(self:GetChecked() == true)
  mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
end

--[[
  OnShow callback for checkbuttons - window lock proximity cooldown window

  @param {table} self
]]--
function me.LockWindowProximityCooldownWindowOnShow(self)
  if mod.configuration.IsProximityCooldownsLocked() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - window lock proximity cooldown window

  @param {table} self
]]--
function me.LockWindowProximityCooldownWindowOnClick(self)
  mod.configuration.UpdateProximityCooldownsLocked(self:GetChecked() == true)
  mod.proximityCooldownBar.ProximityCooldownBarUiUpdate()
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
