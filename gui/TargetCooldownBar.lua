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

-- luacheck: globals CreateFrame UIParent

--[[
  Lifecycle, frame construction and per-tick orchestration for the TargetCooldownBar. Owns the bar frame
  and the fixed set of cooldown slots. Per-slot construction and update logic lives in
  mod.targetCooldownBarSlot; example/preview mode lives in mod.targetCooldownBarPreview.
]]--

local mod = rgcw
local me = {}

mod.targetCooldownBar = me

me.tag = "TargetCooldownBar"

--[[
  Local references to ui elements
]]--
local targetCooldownBarFrame
--[[
  Cached cooldown slot frames in creation order. Populated once in CreateCooldownSlots and never mutated
  afterwards (the slot set is fixed for the lifetime of the addon). Read from the hot OnUpdate path instead
  of allocating a fresh {targetCooldownBarFrame:GetChildren()} table on every tick.
]]--
local cooldownSlots = {}

--[[
  Build initial targetCooldownBarFrame ui
]]--
function me.BuildUi()
  targetCooldownBarFrame = me.CreateTargetCooldownBarFrame()
  me.SetupDragFrame(targetCooldownBarFrame)
  me.CreateCooldownSlots(targetCooldownBarFrame)
end

--[[
  Create the targetCooldownBarFrame

  @return {table}
    The created frame
]]--
function me.CreateTargetCooldownBarFrame()
  local frame = CreateFrame(
    "Frame", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_FRAME, UIParent, "BackdropTemplate")
  frame:SetWidth(RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_WIDTH)
  frame:SetHeight(RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_HEIGHT)
  frame:SetBackdropColor(0, 0, 0, .5)
  frame:SetBackdropBorderColor(0, 0, 0, .8)
  frame:SetPoint("CENTER", 0, 0)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)

  return frame
end

--[[
  Create all cooldown slots and attach them to the targetCooldownBarFrame

  @param {table} frame
]]--
function me.CreateCooldownSlots(frame)
  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    cooldownSlots[i] = mod.targetCooldownBarSlot.CreateCooldownSlot(frame, i)
  end
end

--[[
  Accessor for the fixed set of cooldown slot frames. Returned directly (not cloned); read-only by
  convention. Used by mod.targetCooldownBarPreview to drive the slots in example mode.

  @return {table}
    The cooldown slot frames in creation order
]]--
function me.GetCooldownSlots()
  return cooldownSlots
end

--[[
  Accessor for the bar frame. Used by mod.targetCooldownBarPreview to show the bar in example mode.

  @return {table}
    The targetCooldownBarFrame
]]--
function me.GetTargetCooldownBarFrame()
  return targetCooldownBarFrame
end

--[[
  Callback that should be invoked if anything related to the ui has to be updated. Should not be invoked
  for regular ui updates instead only use this function to update single time changes to the ui. Usually
  mostly related to changes in the configuration
]]--
function me.TargetCooldownBarUiUpdate()
  me.UpdateTargetBarFramePosition()
  me.UpdateTargetBarLockedState()
end

--[[
  Update the locked/unlocked state of the targetBar
]]--
function me.UpdateTargetBarLockedState()
  if mod.configuration.IsTargetCooldownBarLocked() then
    targetCooldownBarFrame:SetBackdrop(nil)
  else
    targetCooldownBarFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
    })
  end
end

--[[
  Update the targetBars frame position
]]--
function me.UpdateTargetBarFramePosition()
  local framePosition =
    mod.configuration.GetUserPlacedFramePosition(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_FRAME)
  --[[
    Set user frame position if there is one saved
  ]]--
  if framePosition ~= nil then
    targetCooldownBarFrame:ClearAllPoints() -- very important to clear all points first
    targetCooldownBarFrame:SetPoint(
      framePosition.point,
      framePosition.relativeTo,
      framePosition.relativePoint,
      framePosition.posX,
      framePosition.posY
    )
  else
    -- initial position for first time use
    targetCooldownBarFrame:SetPoint("CENTER", 0, 0)
  end
end

--[[
  Start the render ticker if there is anything for it to render: an enemy target with at
  least one queued cooldown. The single start edge for the ticker - invoked on target
  change (Core.OnTargetChanged), on enqueue (CooldownQueue.AddCooldown) and when preview
  mode hands the bar back (TargetCooldownBarPreview.HideExampleTargetCooldownBar) - so
  callers never start it unconditionally. Safe to skip the start when the queue is empty:
  the ticker only ever stops right after a full clear pass (see TargetCooldownBarOnUpdate)
  so a stopped ticker implies cleared slots. No-ops while preview mode owns the slots and,
  via the guard in StartTickerTargetCooldownBar, while the ticker is already running.
]]--
function me.WakeRenderTicker()
  if mod.targetCooldownBarPreview.IsPreviewActive() then return end

  local targetGuid = mod.target.GetCurrentTargetGuid()

  if targetGuid ~= "" and mod.cooldownQueue.HasCooldowns(targetGuid) then
    mod.ticker.StartTickerTargetCooldownBar()
  end
end

--[[
  GUI callback for updating the targetCooldownBar - invoked regularly by the render ticker
  while there is something to render. Once there is not - the target was lost or its last
  cooldown left the queue (removed by its expiry timer, the expiry fade's OnFinished or
  the target-change sweep) - the pass below doubles as the final clear pass and the ticker
  stops itself; one of the WakeRenderTicker edges brings it back up.

  Note: Operations within TargetCooldownBarOnUpdate should not be expensive because it is invoked heavily
  to create a smooth visual representation. Make sure to abort as soon as possible.
]]--
function me.TargetCooldownBarOnUpdate()
  local targetGuid = mod.target.GetCurrentTargetGuid()
  --[[
    No (enemy) target: skip the queue lookup entirely. cooldowns stays nil so the
    loop below clears every slot - this is what empties the bar when the target is lost.
  ]]--
  local cooldowns

  if targetGuid ~= "" then
    cooldowns = mod.cooldownQueue.GetCooldownsByTarget(targetGuid)
  end

  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    if cooldowns and cooldowns[i] ~= nil then
      mod.targetCooldownBarSlot.UpdateCooldownWatchSlot(cooldownSlots[i], cooldowns[i])
    else
      mod.targetCooldownBarSlot.ClearCooldownWatchSlot(cooldownSlots[i])
    end
  end

  if cooldowns == nil or cooldowns[1] == nil then
    mod.ticker.StopTickerTargetCooldownBar()
  end
end

--[[
  @param {table} frame
    The frame to attach drag handlers
]]--
function me.SetupDragFrame(frame)
  frame:SetScript("OnMouseDown", me.StartDragFrame)
  frame:SetScript("OnMouseUp", me.StopDragFrame)
end

--[[
  Frame callback to start moving the passed (self) frame

  @param {table} self
]]--
function me.StartDragFrame(self)
  if mod.configuration.IsTargetCooldownBarLocked() then return end

  self:StartMoving()
end

--[[
  Frame callback to stop moving the passed (self) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  if mod.configuration.IsTargetCooldownBarLocked() then return end

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint()

  mod.configuration.SaveUserPlacedFramePosition(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_FRAME,
    point,
    relativeTo,
    relativePoint,
    posX,
    posY
  )
end
