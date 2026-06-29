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

-- luacheck: globals GetTime

--[[
  Preview ("example") mode for the TargetCooldownBar. Drives the slot widgets with synthetic cooldowns so
  the player can position and inspect the bar while configuring it. Reads the slot set and bar frame from
  mod.targetCooldownBar and renders them through mod.targetCooldownBarSlot, exercising the exact slot-update
  contract the live OnUpdate path uses.
]]--

local mod = rgcw
local me = {}

mod.targetCooldownBarPreview = me

me.tag = "TargetCooldownBarPreview"

--[[
  Interrupt regular onUpdate for the TargetCooldownBar and show example cooldowns to the player
]]--
function me.ShowExampleTargetCooldownBar()
  mod.ticker.StopTickerTargetCooldownBar() -- stop regular updates
  mod.cooldownQueue.ClearCooldownQueue() -- drop all current cooldowns

  local cooldownSlots = mod.targetCooldownBar.GetCooldownSlots()
  local cooldowns = {}

  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    cooldowns[i] = mod.cooldownQueue.BuildExampleCooldown(GetTime())
    mod.targetCooldownBarSlot.UpdateCooldownWatchSlot(cooldownSlots[i], cooldowns[i])
  end

  mod.targetCooldownBar.GetTargetCooldownBarFrame():Show()
end

--[[
  Restart regular onUpdate ticks for the TargetCooldownBar
]]--
function me.HideExampleTargetCooldownBar()
  local cooldownSlots = mod.targetCooldownBar.GetCooldownSlots()

  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    cooldownSlots[i]:Hide()
  end

  mod.targetCooldownBar.GetTargetCooldownBarFrame():Show()

  mod.ticker.StartTickerTargetCooldownBar() -- restart regular updates
end
