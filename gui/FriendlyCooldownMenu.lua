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
  Options panel of the friendly cooldown features: the tracking master flag,
  the friendly target bar display and the friendly proximity cooldown window
  (gui/FriendlyProximityCooldownBar.lua). Every change writes through the
  configuration accessors and applies live:

  - the tracking flag is re-read by CombatLog on every event, so toggling it
    starts or stops friendly detection immediately with no further wiring
  - the target bar display re-evaluates the current target on toggle, so a
    friendly target already in the crosshairs appears (or vanishes) at once
    instead of waiting for the next target change
  - the window controls invoke FriendlyProximityCooldownBarUiUpdate, which
    owns the live application (show/hide, lock backdrop, SetScale) and
    re-wakes the render ticker when a filter change makes queued cooldowns
    renderable again - the max-displayed, hide-long and scope options are
    additionally re-read by every render pass either way
]]--

local mod = rgcw
local me = {}

mod.friendlyCooldownMenu = me

me.tag = "FriendlyCooldownMenu"

--[[
  Option texts for checkbutton options - keyed by the option frame name; the
  description is rendered always-visible beneath the checkbox label
]]--
local options = {
  [RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_TRACK_FRIENDLY_COOLDOWNS] = {
    label = rgcw.L["option_track_friendly_cooldowns"],
    description = rgcw.L["option_track_friendly_cooldowns_tooltip"]
  },
  [RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_SHOW_FRIENDLY_TARGET_COOLDOWNS] = {
    label = rgcw.L["option_show_friendly_target_cooldowns"],
    description = rgcw.L["option_show_friendly_target_cooldowns_tooltip"]
  },
  [RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_ENABLE_FRIENDLY_PROXIMITY_COOLDOWN_WINDOW] = {
    label = rgcw.L["option_enable_friendly_proximity_cooldown_window"],
    description = rgcw.L["option_enable_friendly_proximity_cooldown_window_tooltip"]
  },
  [RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_WINDOW_LOCK_FRIENDLY_PROXIMITY_COOLDOWN_WINDOW] = {
    label = rgcw.L["window_lock_friendly_proximity_cooldown_window"],
    description = rgcw.L["window_lock_friendly_proximity_cooldown_window_tooltip"]
  },
  [RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_HIDE_LONG_FRIENDLY_PROXIMITY_COOLDOWNS] = {
    label = rgcw.L["option_hide_long_friendly_proximity_cooldowns"],
    description = string.format(
      rgcw.L["option_hide_long_friendly_proximity_cooldowns_tooltip"],
      RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
    )
  }
}

-- track whether the menu was already built
local builtMenu = false

--[[
  Build the ui for the friendly cooldowns menu

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  mod.guiHelper.CreatePanelTitle(
    frame,
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_TITLE,
    rgcw.L["friendly_title"]
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_TRACK_FRIENDLY_COOLDOWNS,
    20,
    -52,
    me.TrackFriendlyCooldownsOnShow,
    me.TrackFriendlyCooldownsOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_SHOW_FRIENDLY_TARGET_COOLDOWNS,
    20,
    -104,
    me.ShowFriendlyTargetCooldownsOnShow,
    me.ShowFriendlyTargetCooldownsOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_ENABLE_FRIENDLY_PROXIMITY_COOLDOWN_WINDOW,
    20,
    -156,
    me.EnableFriendlyProximityWindowOnShow,
    me.EnableFriendlyProximityWindowOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_WINDOW_LOCK_FRIENDLY_PROXIMITY_COOLDOWN_WINDOW,
    20,
    -208,
    me.LockWindowFriendlyProximityCooldownWindowOnShow,
    me.LockWindowFriendlyProximityCooldownWindowOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_OPT_HIDE_LONG_FRIENDLY_PROXIMITY_COOLDOWNS,
    20,
    -260,
    me.HideLongCooldownsOnShow,
    me.HideLongCooldownsOnClick
  )

  mod.guiHelper.CreateSettingsDropdown(
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_PROXIMITY_SCOPE_DROPDOWN,
    frame,
    {"TOPLEFT", 20, -350},
    RGCW_CONSTANTS.OPTION_DROPDOWN_WIDTH,
    rgcw.L["friendly_proximity_scope_title"],
    rgcw.L["friendly_proximity_scope_tooltip"],
    me.BuildScopeRadios
  )

  mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_PROXIMITY_SCALE_SLIDER,
    frame,
    {"TOPLEFT", 20, -424},
    {
      minValue = RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_MIN,
      maxValue = RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_MAX,
      stepSize = RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_STEP,
      initialValue = mod.configuration.GetProximityCooldownsScale(true)
    },
    rgcw.L["friendly_scale_slider_title"],
    rgcw.L["friendly_scale_slider_tooltip"],
    me.ScaleSliderOnValueChanged,
    me.FormatScaleValue
  )

  mod.guiHelper.CreateSlider(
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_PROXIMITY_MAX_DISPLAYED_SLIDER,
    frame,
    {"TOPLEFT", 20, -500},
    {
      minValue = RGCW_CONSTANTS.PROXIMITY_MAX_DISPLAYED_SLIDER_MIN,
      -- the render layer's fixed row pool is the ceiling; a larger range would be dead travel
      maxValue = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT,
      stepSize = RGCW_CONSTANTS.PROXIMITY_MAX_DISPLAYED_SLIDER_STEP,
      initialValue = mod.configuration.GetProximityCooldownsMaxDisplayed(true)
    },
    rgcw.L["friendly_max_displayed_slider_title"],
    rgcw.L["friendly_max_displayed_slider_tooltip"],
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
  OnShow callback for checkbuttons - track friendly cooldowns

  @param {table} self
]]--
function me.TrackFriendlyCooldownsOnShow(self)
  if mod.configuration.IsTrackFriendlyCooldownsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - track friendly cooldowns. The flag is
  re-read by CombatLog on every event, so detection follows it immediately.

  @param {table} self
]]--
function me.TrackFriendlyCooldownsOnClick(self)
  mod.configuration.UpdateTrackFriendlyCooldownsState(self:GetChecked() == true)
end

--[[
  OnShow callback for checkbuttons - show friendly target cooldowns

  @param {table} self
]]--
function me.ShowFriendlyTargetCooldownsOnShow(self)
  if mod.configuration.IsShowFriendlyTargetCooldownsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - show friendly target cooldowns.

  Re-evaluates the current target so the toggle acts on a friendly already in
  the crosshairs: enabling records their guid and wakes the target bar,
  disabling clears it - the running bar ticker sees the empty target, clears
  the slots and stops itself, while the friendly proximity window regains the
  no-longer-excluded caster's rows (so it is woken too, in case its ticker
  stopped while every queued cooldown belonged to the excluded target).

  @param {table} self
]]--
function me.ShowFriendlyTargetCooldownsOnClick(self)
  mod.configuration.UpdateShowFriendlyTargetCooldownsState(self:GetChecked() == true)
  mod.target.UpdateCurrentTarget()
  mod.targetCooldownBar.WakeRenderTicker()
  mod.friendlyProximityCooldownBar.WakeRenderTicker()
end

--[[
  OnShow callback for checkbuttons - enable friendly proximity cooldown window

  @param {table} self
]]--
function me.EnableFriendlyProximityWindowOnShow(self)
  if mod.configuration.IsProximityCooldownsEnabled(true) then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable friendly proximity cooldown window

  @param {table} self
]]--
function me.EnableFriendlyProximityWindowOnClick(self)
  mod.configuration.UpdateProximityCooldownsEnabled(self:GetChecked() == true, true)
  mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarUiUpdate()
end

--[[
  OnShow callback for checkbuttons - window lock friendly proximity cooldown window

  @param {table} self
]]--
function me.LockWindowFriendlyProximityCooldownWindowOnShow(self)
  if mod.configuration.IsProximityCooldownsLocked(true) then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - window lock friendly proximity cooldown window

  @param {table} self
]]--
function me.LockWindowFriendlyProximityCooldownWindowOnClick(self)
  mod.configuration.UpdateProximityCooldownsLocked(self:GetChecked() == true, true)
  mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarUiUpdate()
end

--[[
  OnShow callback for checkbuttons - hide long cooldowns

  @param {table} self
]]--
function me.HideLongCooldownsOnShow(self)
  if mod.configuration.IsProximityCooldownsHideLongEnabled(true) then
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
  mod.configuration.UpdateProximityCooldownsHideLong(self:GetChecked() == true, true)
  mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarUiUpdate()
end

--[[
  Menu generator for the scope dropdown - fills the root description with a
  radio entry per scope the friendly proximity window accepts

  @param {table} dropdown
    The dropdown the menu is generated for
  @param {table} rootDescription
]]--
function me.BuildScopeRadios(_, rootDescription)
  local scopes = {
    { value = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP, label = rgcw.L["friendly_proximity_scope_group"] },
    { value = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_RAID, label = rgcw.L["friendly_proximity_scope_raid"] },
    { value = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_ALL, label = rgcw.L["friendly_proximity_scope_all"] }
  }

  for _, scope in ipairs(scopes) do
    rootDescription:CreateRadio(
      scope.label,
      function(value) return mod.configuration.GetFriendlyProximityCooldownsScope() == value end,
      function(value)
        mod.configuration.UpdateFriendlyProximityCooldownsScope(value)
        --[[ the scope filter is re-read per render pass; the UiUpdate re-wakes the
             ticker in case it stopped while everything queued was out of scope ]]--
        mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarUiUpdate()
      end,
      scope.value
    )
  end
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

  if mod.configuration.UpdateProximityCooldownsScale(scale, true) ~= nil then
    mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarUiUpdate()
  end
end

--[[
  OnValueChanged callback for the max displayed cooldowns slider

  @param {table} self
  @param {number} value
]]--
function me.MaxDisplayedSliderOnValueChanged(_, value)
  if mod.configuration.UpdateProximityCooldownsMaxDisplayed(math.floor(value + 0.5), true) ~= nil then
    mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarUiUpdate()
  end
end
