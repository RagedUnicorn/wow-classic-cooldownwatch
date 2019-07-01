--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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

local mod = rgcw
local me = {}

mod.targetCooldownBar = me

me.tag = "TargetCooldownBar"

--[[
  Local references to heavily accessed targetcastbar ui elements
]]--
local targetCooldownBarFrame

--[[
  Build initial targetCooldownBarFrame ui
]]--
function me.BuildUi()
  targetCooldownBarFrame = CreateFrame("Frame", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_FRAME, UIParent)
  targetCooldownBarFrame:SetWidth(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_WIDTH)
  targetCooldownBarFrame:SetHeight(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_HEIGHT)
  targetCooldownBarFrame:SetBackdrop({
    bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]
  })
  targetCooldownBarFrame:SetBackdropColor(0, 0, 0, .5)
  targetCooldownBarFrame:SetBackdropBorderColor(0, 0, 0, .8)
  targetCooldownBarFrame:SetPoint("CENTER", 0, 0)
  targetCooldownBarFrame:SetMovable(true)
  targetCooldownBarFrame:SetClampedToScreen(true)

  local framePosition = mod.configuration.GetUserPlacedFramePosition(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_FRAME)
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

  me.SetupDragFrame(targetCooldownBarFrame)

  for i = 1, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT do
    me.CreateCooldownWatchSlot(targetCooldownBarFrame, i)
  end
end

--[[
  Create a cooldownslot and attach it to the cooldownframe

  @param {table} frame
  @param {number} position
]]--
-- TODO choose better naming
function me.CreateCooldownWatchSlot(frame, position)
  local cooldownWatchSlot = CreateFrame("FRAME", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT .. position, frame)

  cooldownWatchSlot:SetFrameLevel(1)
  cooldownWatchSlot:SetSize(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE)
  cooldownWatchSlot:SetPoint(
    "LEFT",
    frame,
    "LEFT",
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_X + (position -1) * RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE,
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_Y
  )

  local backdrop = {
    bgFile = [[Interface\AddOns\CooldownWatch\assets\ui_slot_background]],
    edgeFile = [[Interface\AddOns\CooldownWatch\assets\ui_slot_background]],
    -- edgeFile = nil,
    tile = false,
    tileSize = 32,
    edgeSize = 20,
    insets = {
      left = 12,
      right = 12,
      top = 12,
      bottom = 12
    }
  }

  cooldownWatchSlot:SetBackdrop(backdrop)
  cooldownWatchSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  cooldownWatchSlot:SetBackdropBorderColor(0, 0, 0, 1)

  local innerGlowFrame = CreateFrame("FRAME", nil, cooldownWatchSlot)
  innerGlowFrame:SetFrameLevel(2)
  innerGlowFrame:SetPoint("TOPLEFT", cooldownWatchSlot, "TOPLEFT")
  innerGlowFrame:SetPoint("BOTTOMRIGHT", cooldownWatchSlot, "BOTTOMRIGHT")

  backdrop_innerglow = {
    bgFile = [[Interface\AddOns\CooldownWatch\assets\ui_slot_background]],
    edgeFile = [[Interface\AddOns\CooldownWatch\assets\ui_slot_inner_glow]],
    tile = false,
    tileSize = 16,
    edgeSize = 16,
    insets = {
      left = 10,
      right = 10,
      top = 10,
      bottom = 10
    }
  }

  innerGlowFrame:SetBackdrop(backdrop_innerglow)
  innerGlowFrame:SetBackdropColor(1, 1, 1, 0)
  innerGlowFrame:Hide()

  cooldownWatchSlot.innerGlowFrame = innerGlowFrame
  cooldownWatchSlot.iconHolderTexture = me.CreateIconHolder(cooldownWatchSlot)
  cooldownWatchSlot.targetCooldownOverlay = me.CreateCooldownOverlay(cooldownWatchSlot)
  cooldownWatchSlot.targetSpellTimeBig = me.CreateBigTimerCooldown(cooldownWatchSlot)
  cooldownWatchSlot.targetSpellTimeSmall = me.CreateSmallTimerCooldown(cooldownWatchSlot)

  -- prepare animationgroup
  local animationGroup = cooldownWatchSlot:CreateAnimationGroup(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_ANIMATION)

  local animation = animationGroup:CreateAnimation("Alpha")
  animation:SetDuration(2)
  animation:SetFromAlpha(1)
  animation:SetToAlpha(0)
  animation:SetSmoothing("OUT")

  -- initially hide slots
  cooldownWatchSlot:Hide()
end

--[[
  Create a cooldown overlay and attach it to the cooldownslot

  @param {table} frame

  @return {table}
    The created texture
]]--
function me.CreateIconHolder(frame)
  local iconHolderTexture = frame:CreateTexture(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_ICON_TEXTURE_NAME,
    "LOW",
    nil,
    -8
  )
  iconHolderTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
  iconHolderTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
  iconHolderTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  return iconHolderTexture
end

--[[
  Create a cooldown overlay and attach it to the cooldownslot

  @param {table} frame

  @return {table}
    The created cooldown overlay
]]--
function me.CreateCooldownOverlay(frame)
  local cooldownOverlay = CreateFrame(
    "Cooldown",
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_COOLDOWN_FRAME,
    frame,
    "CooldownFrameTemplate"
  )
  cooldownOverlay:SetSize(32, 32)
  cooldownOverlay:SetAllPoints()
  cooldownOverlay:SetCooldown(GetTime(), 10)
  cooldownOverlay:SetFrameLevel(cooldownOverlay:GetFrameLevel() - 1)

  return cooldownOverlay
end

--[[
  Create a big timer cooldown and attach it to the cooldownslot

  @param {table} frame

  @return {table}
    The created fontString
]]--
function me.CreateBigTimerCooldown(frame)
  local bigTimerFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT, "OVERLAY")
  bigTimerFontString:SetFont("Fonts\\FRIZQT__.TTF", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_SIZE)
  bigTimerFontString:SetTextColor(1, 1, 0)
  bigTimerFontString:SetJustifyH("LEFT")

  return bigTimerFontString
end

--[[
  Create a small timer cooldown and attach it to the cooldownslot

  @param {table} frame

  @return {table}
    The created fontString
]]--
function me.CreateSmallTimerCooldown(frame)
  local smallTimerFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT, "OVERLAY")
  smallTimerFontString:SetFont("Fonts\\FRIZQT__.TTF", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT_SIZE)
  smallTimerFontString:SetPoint("TOPLEFT", 5, -5)
  smallTimerFontString:SetTextColor(.01, .66, 0.95, 1)
  smallTimerFontString:SetJustifyH("LEFT")

  return smallTimerFontString
end

--[[
  @param {table} frame
    the frame to attach drag handlers
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
  -- if mod.configuration.IsTargetCastBarLocked() then return end TODO

  self:StartMoving()
end

--[[
  Frame callback to stop moving the passed (self) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  -- if mod.configuration.IsTargetCastBarLocked() then return end TODO

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint()

  mod.configuration.SaveUserPlacedFramePosition(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_FRAME,
    point,
    relativeTo,
    relativePoint,
    posX,
    posY
  )
end

--[[
  GUI callback for updating the targetCooldownBar - invoked regularly by a timer

  Note: Operations within TargetCooldownBarOnUpdate should not be expensive because it is invoked heavily
  to create a smooth visual representation. Make sure to abort as soon as possible.
]]--
function me.TargetCooldownBarOnUpdate()
  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(mod.target.GetCurrentTargetGuid())
  local cooldownSlots = {targetCooldownBarFrame:GetChildren()}

  if cooldowns == nil then return end

  for i = 1, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT do
    if cooldowns[i] ~= nil then
      me.UpdateCooldownWatchSlot(cooldownSlots[i], cooldowns[i])
    else
      me.ClearCooldownWatchSlot(cooldownSlots[i])
    end
  end
end

--[[
  @param {table} cooldownWatchSlot
  @param {table} cooldown
]]--
function me.UpdateCooldownWatchSlot(cooldownWatchSlot, cooldown)
  local timePassed = (GetTime() - cooldown.spell.castTime)
  local timeLeftBig = cooldown.spell.cooldown - timePassed
  local timeLeftSmall

  if cooldown.spell.cooldownWorstCase ~= nil then
    timeLeftSmall = cooldown.spell.cooldownWorstCase - timePassed
  end

  if timeLeftBig <= 0 then
    me.ClearCooldownWatchSlotAnimated(cooldownWatchSlot, cooldown)
    return
  end

  if me.IsWarningTresholdBreached(cooldown.spell.cooldown, timeLeftBig) then
    cooldownWatchSlot.innerGlowFrame:SetBackdropBorderColor(0.8, 1, 0, 1)
    cooldownWatchSlot.innerGlowFrame:Show()
  end

  if me.IsAlertTresholdBreached(cooldown.spell.cooldown, timeLeftBig) then
    cooldownWatchSlot.innerGlowFrame:SetBackdropBorderColor(1, 0.2, 0, 1)
    cooldownWatchSlot.innerGlowFrame:Show()
  end

  -- position text based on its cooldown duration
  if timeLeftBig > 9 then
    cooldownWatchSlot.targetSpellTimeBig:SetPoint("LEFT", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_HIGH, 0)
  else
    cooldownWatchSlot.targetSpellTimeBig:SetPoint("LEFT", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_LOW, 0)
  end

  cooldownWatchSlot.targetSpellTimeBig:SetText(string.format("%.1f", timeLeftBig))
  if timeLeftSmall ~= nil and timeLeftSmall >= 0 then
    cooldownWatchSlot.targetSpellTimeSmall:SetText(string.format("%.1f", timeLeftSmall))
  else
    cooldownWatchSlot.targetSpellTimeSmall:SetText("")
  end

  local _, _, iconTexture = GetSpellInfo(cooldown.spell.spellId)
  cooldownWatchSlot.iconHolderTexture:SetTexture(iconTexture)

  if not cooldownWatchSlot.targetCooldownOverlay.cooldownStarted then
    cooldownWatchSlot.targetCooldownOverlay:SetCooldown(cooldown.spell.castTime, cooldown.spell.cooldown)
    cooldownWatchSlot.targetCooldownOverlay.cooldownStarted = true
  end

  cooldownWatchSlot:Show()
end

--[[
  @param {number} cooldown
  @param {number} timeLeft

  @return {boolean}
    true - if the treshold was breached
    false - if the treshold was not breached
]]--
function me.IsWarningTresholdBreached(cooldown, timeLeft)
  return me.IsTresholdBreached(cooldown, timeLeft, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WARN_TRESHOLD)
end

--[[
  @param {number} cooldown
  @param {number} timeLeft

  @return {boolean}
    true - if the treshold was breached
    false - if the treshold was not breached
]]--
function me.IsAlertTresholdBreached(cooldown, timeLeft)
  return me.IsTresholdBreached(cooldown, timeLeft, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_ALERT_TRESHOLD)
end

--[[
  @param {number} cooldown
  @param {number} timeLeft
  @param {number} treshold

  @return {boolean}
    true - if the treshold was breached
    false - if the treshold was not breached
]]--
function me.IsTresholdBreached(cooldown, timeLeft, treshold)
  return 100 / cooldown * timeLeft <= treshold
end

--[[
  Delayed removal of an expired cooldown. Remove a cooldown step by step.

  Step 1 - Hide cooldowntexts
  Step 2 - Start animating fade alpha
  Step 3 - Execute cleanup script once animation is done

  @param {table} cooldownWatchSlot
  @param {table} cooldow
]]--
function me.ClearCooldownWatchSlotAnimated(cooldownWatchSlot, cooldown)
  cooldownWatchSlot.targetSpellTimeBig:SetText("")
  cooldownWatchSlot.targetSpellTimeSmall:SetText("")
  cooldownWatchSlot.targetCooldownOverlay.cooldownStarted = false

  local animationGroup = cooldownWatchSlot:GetAnimationGroups()
  animationGroup:SetScript("OnFinished", function()
    mod.cooldownQueue.RemoveCooldown(cooldown.caster, cooldown.spell.spellId)
    cooldownWatchSlot.iconHolderTexture:SetTexture(nil)
    cooldownWatchSlot.innerGlowFrame:Hide()
    cooldownWatchSlot:SetAlpha(1)
    cooldownWatchSlot:Hide()
  end)

  if not animationGroup:IsPlaying() then
    animationGroup:Play()
  end
end

--[[
  Clear a cooldownWatchSlot without any animation

  @param {table} cooldownWatchSlot
]]--
function me.ClearCooldownWatchSlot(cooldownWatchSlot)
  cooldownWatchSlot.targetSpellTimeBig:SetText("")
  cooldownWatchSlot.targetSpellTimeSmall:SetText("")
  cooldownWatchSlot.iconHolderTexture:SetTexture(nil)
  cooldownWatchSlot.innerGlowFrame:Hide()
  cooldownWatchSlot.targetCooldownOverlay.cooldownStarted = false

  cooldownWatchSlot:Hide()
end

--[[
  Interrupt regular onUpdate for the TargetCooldownBar and show example cooldowns to the player
]]--
function me.ShowExampleTargetCooldownBar()
  mod.ticker.StopTickerTargetCooldownBar() -- stop regular updates
  mod.cooldownQueue.ClearCooldownQueue() -- drop all current cooldowns

  local cooldownSlots = {targetCooldownBarFrame:GetChildren()}
  local cooldowns = {}

  for i = 1, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT do
    cooldowns[i] = {
      ["caster"] = "dummytarget",
      ["casterName"] = "casterName",
      ["spell"] = {
        ["spellId"] = 2094,
        ["spellName"] = "spellname",
        ["rank"] = nil,
        ["castTime"] = GetTime(),
        ["cooldown"] = 10,
        ["cooldownWorstCase"] = 5,
        ["active"] = true
      }
    }
    me.UpdateCooldownWatchSlot(cooldownSlots[i], cooldowns[i])
  end

  targetCooldownBarFrame:Show()
end

--[[
  Restart regular onUpdate ticks for the TargetCooldownBar
]]--
function me.HideExampleTargetCooldownBar()
  local cooldownSlots = {targetCooldownBarFrame:GetChildren()}

  for i = 1, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT do
    cooldownSlots[i]:Hide()
  end

  targetCooldownBarFrame:Show()

  mod.ticker.StartTickerTargetCooldownBar() -- restart regular updates
end
