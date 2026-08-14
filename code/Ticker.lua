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

-- luacheck: globals C_Timer

local mod = rgcw
local me = {}

mod.ticker = me

me.tag = "Ticker"

local targetCooldownBarTicker
local targetCooldownBarPreviewTicker
local proximityCooldownBarTicker
local friendlyProximityCooldownBarTicker

--[[
  Start the repeating update ticker for targetCastBar
]]--
function me.StartTickerTargetCooldownBar()
  if targetCooldownBarTicker == nil or targetCooldownBarTicker:IsCancelled() then
    targetCooldownBarTicker = C_Timer.NewTicker(
      RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_UPDATE_INTERVAL, mod.targetCooldownBar.TargetCooldownBarOnUpdate)
      mod.logger.LogInfo(me.tag, "Started 'TargetCooldownBarTicker'")
  end
end

--[[
  Stop the repeating update ticker for targetCastBar
]]--
function me.StopTickerTargetCooldownBar()
  if targetCooldownBarTicker then
    targetCooldownBarTicker:Cancel()
    targetCooldownBarTicker = nil
    mod.logger.LogInfo(me.tag, "Stopped 'TargetCooldownBarTicker'")
  end
end

--[[
  Start the repeating update ticker for the proximityCooldownBar. Started exclusively
  through mod.proximityCooldownBar.WakeRenderTicker, which owns the something-to-render
  check; stops itself after a render pass that found nothing
  (see ProximityCooldownBarOnUpdate)
]]--
function me.StartTickerProximityCooldownBar()
  if proximityCooldownBarTicker == nil or proximityCooldownBarTicker:IsCancelled() then
    proximityCooldownBarTicker = C_Timer.NewTicker(
      RGCW_CONSTANTS.PROXIMITY_COOLDOWN_WINDOW_UPDATE_INTERVAL,
      mod.proximityCooldownBar.ProximityCooldownBarOnUpdate)
      mod.logger.LogInfo(me.tag, "Started 'ProximityCooldownBarTicker'")
  end
end

--[[
  Stop the repeating update ticker for the proximityCooldownBar
]]--
function me.StopTickerProximityCooldownBar()
  if proximityCooldownBarTicker then
    proximityCooldownBarTicker:Cancel()
    proximityCooldownBarTicker = nil
    mod.logger.LogInfo(me.tag, "Stopped 'ProximityCooldownBarTicker'")
  end
end

--[[
  Start the repeating update ticker for the friendlyProximityCooldownBar. Started
  exclusively through mod.friendlyProximityCooldownBar.WakeRenderTicker, which owns
  the something-to-render check; stops itself after a render pass that found nothing
  (see the shared ProximityWindow OnUpdate)
]]--
function me.StartTickerFriendlyProximityCooldownBar()
  if friendlyProximityCooldownBarTicker == nil or friendlyProximityCooldownBarTicker:IsCancelled() then
    friendlyProximityCooldownBarTicker = C_Timer.NewTicker(
      RGCW_CONSTANTS.PROXIMITY_COOLDOWN_WINDOW_UPDATE_INTERVAL,
      mod.friendlyProximityCooldownBar.FriendlyProximityCooldownBarOnUpdate)
      mod.logger.LogInfo(me.tag, "Started 'FriendlyProximityCooldownBarTicker'")
  end
end

--[[
  Stop the repeating update ticker for the friendlyProximityCooldownBar
]]--
function me.StopTickerFriendlyProximityCooldownBar()
  if friendlyProximityCooldownBarTicker then
    friendlyProximityCooldownBarTicker:Cancel()
    friendlyProximityCooldownBarTicker = nil
    mod.logger.LogInfo(me.tag, "Stopped 'FriendlyProximityCooldownBarTicker'")
  end
end

--[[
  Start the repeating update ticker for the targetCooldownBar preview ("example") mode. Runs at
  the same interval as the live ticker so the preview animates exactly like the live bar.
]]--
function me.StartTickerTargetCooldownBarPreview()
  if targetCooldownBarPreviewTicker == nil or targetCooldownBarPreviewTicker:IsCancelled() then
    targetCooldownBarPreviewTicker = C_Timer.NewTicker(
      RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_UPDATE_INTERVAL,
      mod.targetCooldownBarPreview.TargetCooldownBarPreviewOnUpdate)
      mod.logger.LogInfo(me.tag, "Started 'TargetCooldownBarPreviewTicker'")
  end
end

--[[
  Stop the repeating update ticker for the targetCooldownBar preview ("example") mode
]]--
function me.StopTickerTargetCooldownBarPreview()
  if targetCooldownBarPreviewTicker then
    targetCooldownBarPreviewTicker:Cancel()
    targetCooldownBarPreviewTicker = nil
    mod.logger.LogInfo(me.tag, "Stopped 'TargetCooldownBarPreviewTicker'")
  end
end
