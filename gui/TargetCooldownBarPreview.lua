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
  contract the live OnUpdate path uses. While the preview is active the live ticker is replaced by a preview
  ticker driving TargetCooldownBarPreviewOnUpdate, which animates the synthetic cooldowns and reseeds them
  on expiry so the preview loops until it is hidden again.
]]--

local mod = rgcw
local me = {}

mod.targetCooldownBarPreview = me

me.tag = "TargetCooldownBarPreview"

--[[
  Synthetic cooldowns currently driving the preview, indexed by slot position. Seeded in
  ShowExampleTargetCooldownBar, reseeded per slot by the preview tick once an entry's expiry fade
  has played out (this is what loops the preview), emptied in HideExampleTargetCooldownBar.
]]--
local exampleCooldowns = {}

--[[
  Interrupt regular onUpdate for the TargetCooldownBar and show example cooldowns to the player.
  Renders one immediate frame, then hands over to the preview ticker for animation.
]]--
function me.ShowExampleTargetCooldownBar()
  mod.ticker.StopTickerTargetCooldownBar() -- stop regular updates
  mod.cooldownQueue.ClearCooldownQueue() -- drop all current cooldowns

  local cooldownSlots = mod.targetCooldownBar.GetCooldownSlots()

  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    exampleCooldowns[i] = mod.cooldownQueue.BuildExampleCooldown(GetTime())
    mod.targetCooldownBarSlot.UpdateCooldownWatchSlot(cooldownSlots[i], exampleCooldowns[i])
  end

  mod.targetCooldownBar.GetTargetCooldownBarFrame():Show()

  mod.ticker.StartTickerTargetCooldownBarPreview()
end

--[[
  GUI callback for animating the preview - invoked regularly by the preview ticker while example
  mode is active. Re-renders every slot against its synthetic cooldown so the timer texts count
  down exactly like the live path. Once an entry has expired and its expiry fade had time to play
  out, the slot is reseeded with a fresh cooldown so the preview loops. Reseeding slightly early
  (while the fade is still playing) is safe: UpdateCooldownWatchSlot treats it like an enemy
  recasting mid-fade and cancels the fade.
]]--
function me.TargetCooldownBarPreviewOnUpdate()
  local cooldownSlots = mod.targetCooldownBar.GetCooldownSlots()
  local now = GetTime()

  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    local spellData = exampleCooldowns[i].spellData

    if now - spellData.castTime - spellData.cooldown >= RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_FADE_DURATION then
      exampleCooldowns[i] = mod.cooldownQueue.BuildExampleCooldown(now)
    end

    mod.targetCooldownBarSlot.UpdateCooldownWatchSlot(cooldownSlots[i], exampleCooldowns[i])
  end
end

--[[
  Stop the preview and restart regular onUpdate ticks for the TargetCooldownBar
]]--
function me.HideExampleTargetCooldownBar()
  mod.ticker.StopTickerTargetCooldownBarPreview()

  local cooldownSlots = mod.targetCooldownBar.GetCooldownSlots()

  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    --[[
      A slot can be mid expiry-fade when the preview closes. Cancel the fade before clearing so
      its OnFinished cleanup can't fire later against a slot the live path owns again.
    ]]--
    mod.targetCooldownBarSlot.CancelCooldownSlotFade(cooldownSlots[i])
    mod.targetCooldownBarSlot.ClearCooldownWatchSlot(cooldownSlots[i])
  end

  exampleCooldowns = {}

  mod.ticker.StartTickerTargetCooldownBar() -- restart regular updates
end
