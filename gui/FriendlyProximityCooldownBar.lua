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
  The FRIENDLY proximity cooldown window: the active cooldowns of tracked
  friendly casters, rendered in its own window with its own configuration
  block (friendlyProximityCooldowns) and its own persisted position -
  deliberately separate from the enemy window so the threat list and the
  support overview never blur into one another. All machinery lives in the
  shared builder (gui/ProximityWindow.lua); this module supplies the friendly
  frame name, the friendly-side configuration accessors, the friendly ticker
  pair and the eligibility filter.

  Eligibility is two checks: the entry must carry the friendly marker
  (hostile entries belong to the enemy window), and its caster must fall
  inside the configured scope - the player's group, the raid, or every
  tracked friendly (see GroupRoster.IsGuidInScope). Both are evaluated per
  entry on every render pass, so a scope change takes effect on the next pass
  without any special handling.

  The current target guid is excluded like on the enemy window. Target.lua
  only records a friendly target's guid while showFriendlyTargetCooldowns is
  on - exactly when the target bar renders that caster - so the exclusion
  tracks "the target bar already shows it" for free: with the display flag
  off a targeted teammate keeps their rows here instead of vanishing from
  both surfaces.

  The window itself renders only what the queue holds: with friendly tracking
  (trackFriendlyCooldowns) off no friendly entries are ever queued and the
  enabled window simply stays empty - enabling it never silently writes the
  tracking flag.
]]--

local mod = rgcw
local me = {}

mod.friendlyProximityCooldownBar = me

me.tag = "FriendlyProximityCooldownBar"

local instance = mod.proximityWindow.CreateInstance({
  frameName = RGCW_CONSTANTS.ELEMENT_FRIENDLY_PROXIMITY_COOLDOWN_WINDOW_FRAME,
  IsEnabled = function() return mod.configuration.IsProximityCooldownsEnabled(true) end,
  IsLocked = function() return mod.configuration.IsProximityCooldownsLocked(true) end,
  GetScale = function() return mod.configuration.GetProximityCooldownsScale(true) end,
  GetMaxDisplayed = function() return mod.configuration.GetProximityCooldownsMaxDisplayed(true) end,
  IsHideLongEnabled = function() return mod.configuration.IsProximityCooldownsHideLongEnabled(true) end,
  StartTicker = function() mod.ticker.StartTickerFriendlyProximityCooldownBar() end,
  StopTicker = function() mod.ticker.StopTickerFriendlyProximityCooldownBar() end,
  GetExcludeGuid = function() return mod.target.GetCurrentTargetGuid() end,
  IsEligibleEntry = function(cooldownEvent)
    if cooldownEvent.spellData.friendly ~= true then return false end

    return mod.groupRoster.IsGuidInScope(
      cooldownEvent.sourceGuid,
      mod.configuration.GetFriendlyProximityCooldownsScope()
    )
  end
})

me.BuildUi = instance.BuildUi
me.FriendlyProximityCooldownBarUiUpdate = instance.UiUpdate
me.WakeRenderTicker = instance.WakeRenderTicker
me.FriendlyProximityCooldownBarOnUpdate = instance.OnUpdate
me.IsRenderableCooldown = instance.IsRenderableCooldown
