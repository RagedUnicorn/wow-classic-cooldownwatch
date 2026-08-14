--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

--[[
  The ENEMY proximity cooldown window: the active cooldowns of every tracked
  hostile caster EXCEPT the current target (the target bar already shows that
  one). All machinery lives in the shared builder (gui/ProximityWindow.lua) -
  this module only supplies what makes the window the enemy one: the frame
  name, the enemy-side configuration accessors, the enemy ticker pair and the
  eligibility filter that keeps friendly-flagged entries out (they belong to
  the friendly window, see gui/FriendlyProximityCooldownBar.lua).

  The target exclusion is evaluated against the live target guid on every
  render pass, so a target change needs no special handling: the old target's
  still-running cooldowns appear in the list by themselves and the new
  target's rows vanish (they render on the target bar instead).
]]--

local mod = rgcw
local me = {}

mod.proximityCooldownBar = me

me.tag = "ProximityCooldownBar"

local instance = mod.proximityWindow.CreateInstance({
  frameName = RGCW_CONSTANTS.ELEMENT_PROXIMITY_COOLDOWN_WINDOW_FRAME,
  IsEnabled = function() return mod.configuration.IsProximityCooldownsEnabled() end,
  GetScale = function() return mod.configuration.GetProximityCooldownsScale() end,
  GetMaxDisplayed = function() return mod.configuration.GetProximityCooldownsMaxDisplayed() end,
  IsHideLongEnabled = function() return mod.configuration.IsProximityCooldownsHideLongEnabled() end,
  StartTicker = function() mod.ticker.StartTickerProximityCooldownBar() end,
  StopTicker = function() mod.ticker.StopTickerProximityCooldownBar() end,
  GetExcludeGuid = function() return mod.target.GetCurrentTargetGuid() end,
  --[[
    Hostile entries only: friendly casts carry the friendly marker on their
    spellData (see CombatLog) and render in the friendly window instead -
    without this filter the enemy window would mix teammates into the threat
    list whenever friendly tracking is enabled.
  ]]--
  IsEligibleEntry = function(cooldownEvent)
    return cooldownEvent.spellData.friendly ~= true
  end
})

me.BuildUi = instance.BuildUi
me.ProximityCooldownBarUiUpdate = instance.UiUpdate
me.WakeRenderTicker = instance.WakeRenderTicker
me.ProximityCooldownBarOnUpdate = instance.OnUpdate
me.IsRenderableCooldown = instance.IsRenderableCooldown
-- preview seam consumed by the test/place mode (gui/ProximityCooldownBarPreview.lua)
me.IsPreviewActive = instance.IsPreviewActive
me.ShowPreview = instance.ShowPreview
me.RenderPreviewEntries = instance.RenderPreviewEntries
me.HidePreview = instance.HidePreview
me.GetWindowFrame = instance.GetWindowFrame
