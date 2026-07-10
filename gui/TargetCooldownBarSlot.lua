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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT GetTime GetSpellInfo

--[[
  Per-slot construction and update logic for the TargetCooldownBar. Every function operates on an explicit
  cooldownWatchSlot frame passed by the caller; this module owns no shared state. Slot lifecycle (the array
  of slots, the parent bar frame) is owned by mod.targetCooldownBar.
]]--

local mod = rgcw
local me = {}

mod.targetCooldownBarSlot = me

me.tag = "TargetCooldownBarSlot"

--[[
  Create a cooldown slot and attach it to the cooldown frame

  @param {table} frame
  @param {number} position

  @return {table}
    The created cooldownWatchSlot
]]--
function me.CreateCooldownSlot(frame, position)
  local cooldownWatchSlot = CreateFrame(
    "FRAME",
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_SLOT .. position,
    frame,
    "BackdropTemplate"
  )

  cooldownWatchSlot:SetFrameLevel(1)
  cooldownWatchSlot:SetSize(
    RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_DEFAULT_SIZE,
    RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_DEFAULT_SIZE
  )
  cooldownWatchSlot:SetPoint(
    "LEFT",
    frame,
    "LEFT",
    RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_X
      + (position -1) * RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_DEFAULT_SIZE,
    RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_Y
  )

  local backdrop = mod.guiHelper.MakeSlotBackdrop(
    "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    RGCW_CONSTANTS.SLOT_BACKDROP
  )

  cooldownWatchSlot:SetBackdrop(backdrop)
  cooldownWatchSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  cooldownWatchSlot:SetBackdropBorderColor(0, 0, 0, 1)

  cooldownWatchSlot.highlightFrame = me.CreateHighlightFrame(cooldownWatchSlot)
  cooldownWatchSlot.iconHolderTexture = me.CreateIconHolder(cooldownWatchSlot)
  cooldownWatchSlot.targetCooldownOverlay = me.CreateCooldownOverlay(cooldownWatchSlot)
  cooldownWatchSlot.targetSpellTimeBig = me.CreateBigTimerCooldown(cooldownWatchSlot)
  cooldownWatchSlot.targetSpellTimeSmall = me.CreateSmallTimerCooldown(cooldownWatchSlot)

  me.CreateAnimation(cooldownWatchSlot)
  -- initially hide slots
  cooldownWatchSlot:Hide()

  return cooldownWatchSlot
end

--[[
  Create an animation for a cooldownWatchSlot. The OnFinished cleanup is installed once
  here; the cooldown it removes is handed over via cooldownWatchSlot.fadingCooldown when
  ClearCooldownSlotAnimated starts the fade.

  @param {table} cooldownWatchSlot
]]--
function me.CreateAnimation(cooldownWatchSlot)
  local animationGroup = cooldownWatchSlot:CreateAnimationGroup(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_SLOT_ANIMATION
  )

  local animation = animationGroup:CreateAnimation("Alpha")
  animation:SetDuration(RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_FADE_DURATION)
  animation:SetFromAlpha(1)
  animation:SetToAlpha(0)
  animation:SetSmoothing("OUT")

  animationGroup:SetScript("OnFinished", function()
    local cooldown = cooldownWatchSlot.fadingCooldown
    cooldownWatchSlot.fadingCooldown = nil

    --[[
      The fade races cooldown refreshes: UpdateCooldownWatchSlot cancels a playing fade,
      but only on its next tick. If the entry was refreshed (AddCooldown swaps spellData
      in place, so reading it here sees the fresh timing) and the fade completed inside
      that window, the cooldown is live again - hand the slot back to the update path
      untouched instead of destroying fresh state.
    ]]--
    local spellData = cooldown.spellData
    local timeLeft = spellData.cooldown - (GetTime() - spellData.castTime)

    if timeLeft > 0 then
      cooldownWatchSlot:SetAlpha(1)
      return
    end

    mod.cooldownQueue.RemoveCooldown(cooldown.sourceGuid, spellData.spellId)

    --[[
      A non-nil overlay spellId means the update path rebound this slot to another live
      cooldown while the fade was playing. The expired queue entry is removed above, but
      the slot visuals now belong to that other cooldown - don't blank them.
    ]]--
    if cooldownWatchSlot.targetCooldownOverlay.spellId ~= nil then
      cooldownWatchSlot:SetAlpha(1)
      return
    end

    cooldownWatchSlot.iconHolderTexture:SetTexture(nil)
    cooldownWatchSlot.iconHolderTexture.spellId = nil
    cooldownWatchSlot.highlightFrame:Hide()
    cooldownWatchSlot:SetAlpha(1)
    cooldownWatchSlot:Hide()
  end)
end

--[[
  Create a highlight frame

  @param {table} cooldownWatchSlot

  @return {table}
    The created highlightFrame
]]--
function me.CreateHighlightFrame(cooldownWatchSlot)
  local highlightFrame = CreateFrame("FRAME", nil, cooldownWatchSlot, "BackdropTemplate")
  highlightFrame:SetFrameLevel(2)
  highlightFrame:SetPoint("TOPLEFT", cooldownWatchSlot, "TOPLEFT")
  highlightFrame:SetPoint("BOTTOMRIGHT", cooldownWatchSlot, "BOTTOMRIGHT")

  local innerBackdrop = mod.guiHelper.MakeSlotBackdrop(
    "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_inner_glow",
    RGCW_CONSTANTS.HIGHLIGHT_BACKDROP
  )

  highlightFrame:SetBackdrop(innerBackdrop)
  highlightFrame:SetBackdropColor(1, 1, 1, 0)
  highlightFrame:Hide()

  return highlightFrame
end

--[[
  Create an icon texture holder and attach it to the cooldown slot

  @param {table} frame

  @return {table}
    The created texture
]]--
function me.CreateIconHolder(frame)
  local iconHolderTexture = frame:CreateTexture(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_SLOT_ICON_TEXTURE_NAME,
    "ARTWORK",
    nil,
    -8
  )
  iconHolderTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
  iconHolderTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
  iconHolderTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  return iconHolderTexture
end

--[[
  Create a cooldown overlay and attach it to the cooldown slot

  @param {table} frame

  @return {table}
    The created cooldown overlay
]]--
function me.CreateCooldownOverlay(frame)
  local cooldownOverlay = CreateFrame(
    "Cooldown",
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BAR_SLOT_COOLDOWN_FRAME,
    frame,
    "CooldownFrameTemplate"
  )
  cooldownOverlay:SetSize(
    RGCW_CONSTANTS.COOLDOWN_SPELL_DEFAULT_SIZE,
    RGCW_CONSTANTS.COOLDOWN_SPELL_DEFAULT_SIZE
  )
  cooldownOverlay:SetAllPoints()
  cooldownOverlay:SetFrameLevel(cooldownOverlay:GetFrameLevel() - 1)

  return cooldownOverlay
end

--[[
  Create a big timer cooldown and attach it to the cooldown slot

  @param {table} frame

  @return {table}
    The created fontString
]]--
function me.CreateBigTimerCooldown(frame)
  local bigTimerFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT, "OVERLAY")
  bigTimerFontString:SetFont(STANDARD_TEXT_FONT, RGCW_CONSTANTS.TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_SIZE)
  bigTimerFontString:SetTextColor(unpack(RGCW_CONSTANTS.COLORS.TIMER_BIG_TEXT))
  bigTimerFontString:SetJustifyH("LEFT")

  return bigTimerFontString
end

--[[
  Create a small timer cooldown and attach it to the cooldown slot

  @param {table} frame

  @return {table}
    The created fontString
]]--
function me.CreateSmallTimerCooldown(frame)
  local smallTimerFontString = frame:CreateFontString(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT,
    "OVERLAY"
  )
  smallTimerFontString:SetFont(STANDARD_TEXT_FONT, RGCW_CONSTANTS.TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT_SIZE)
  smallTimerFontString:SetPoint("TOPLEFT", 5, -5)
  smallTimerFontString:SetTextColor(unpack(RGCW_CONSTANTS.COLORS.TIMER_SMALL_TEXT))
  smallTimerFontString:SetJustifyH("LEFT")

  return smallTimerFontString
end

--[[
  @param {table} cooldownWatchSlot
  @param {table} cooldown
]]--
function me.UpdateCooldownWatchSlot(cooldownWatchSlot, cooldown)
  local timePassed = (GetTime() - cooldown.spellData.castTime)
  local timeLeftBig = cooldown.spellData.cooldown - timePassed
  local timeLeftSmall

  if cooldown.spellData.cooldownWorstCase ~= nil then
    timeLeftSmall = cooldown.spellData.cooldownWorstCase - timePassed
  end

  if timeLeftBig <= 0 then
    me.ClearCooldownSlotAnimated(cooldownWatchSlot, cooldown)
    return
  end

  --[[
    The slot is live (again). If an expiry fade is still playing - the enemy recast the
    spell mid-fade (AddCooldown refreshes castTime in place) or a different active cooldown
    was rebound into this slot - it must be cancelled here: its OnFinished would otherwise
    remove the live cooldown from the queue and blank the slot.
  ]]--
  me.CancelCooldownSlotFade(cooldownWatchSlot)

  me.UpdateCooldownSlotHighlightFrame(cooldownWatchSlot, cooldown.spellData.cooldown, timeLeftBig)
  me.UpdateCooldownSlotBigCooldownTextPosition(cooldownWatchSlot, timeLeftBig)
  me.UpdateCooldownSlotCooldownText(cooldownWatchSlot, timeLeftBig, timeLeftSmall)
  me.UpdateCooldownSlotTexture(cooldownWatchSlot, cooldown.spellData.spellId)

  --[[
    Key the sweep init on the slot's currently applied spellId rather than a "once per cooldown" flag.
    Slots are bound to cooldowns positionally over a compacting queue array (deterministically ordered,
    but entries still shift left on removal), so a slot can be reassigned to a different spell without
    passing through a Clear. Comparing the applied spellId (mirroring UpdateCooldownSlotTexture)
    re-initializes the sweep on reassignment instead of keeping the stale timer.
  ]]--
  if cooldownWatchSlot.targetCooldownOverlay.spellId ~= cooldown.spellData.spellId then
    me.InitCooldownSlotCooldownOverlay(cooldownWatchSlot, cooldown)
  end

  cooldownWatchSlot:Show()
end

--[[
  Update the highlight frame of a cooldownWatchSlot with is current state
  e.g. warn, alert or normal

  @param {table} cooldownWatchSlot
  @param {number} cooldownDuration
]]--
function me.UpdateCooldownSlotHighlightFrame(cooldownWatchSlot, cooldownDuration, timeLeftBig)
  local highlightFrame = cooldownWatchSlot.highlightFrame

  if me.IsThresholdBreached(cooldownDuration, timeLeftBig, RGCW_CONSTANTS.TARGET_COOLDOWN_ALERT_THRESHOLD) then
    highlightFrame:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.ALERT_BORDER))
    highlightFrame:Show()

    return
  end

  if me.IsThresholdBreached(cooldownDuration, timeLeftBig, RGCW_CONSTANTS.TARGET_COOLDOWN_WARN_THRESHOLD) then
    highlightFrame:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.WARN_BORDER))
    highlightFrame:Show()

    return
  end

  highlightFrame:SetBackdropColor(1, 1, 1, 0)
  highlightFrame:Hide()
end

--[[
  Update the cooldown text position of a cooldownWatchSlot. Position text based on its cooldown duration

  @param {table} cooldownWatchSlot
  @param {number} timeLeftBig
]]--
function me.UpdateCooldownSlotBigCooldownTextPosition(cooldownWatchSlot, timeLeftBig)
  local position

  if timeLeftBig >= 10 then
    position = RGCW_CONSTANTS.TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_HIGH
  else
    position = RGCW_CONSTANTS.TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_LOW
  end

  cooldownWatchSlot.targetSpellTimeBig:SetPoint(
    "LEFT",
    position,
    0
  )
end

--[[
  Update the cooldown text of a cooldownWatchSlot

  @param {table} cooldownWatchSlot
  @param {number} timeLeftBig
  @param {number} timeLeftSmall
]]--
function me.UpdateCooldownSlotCooldownText(cooldownWatchSlot, timeLeftBig, timeLeftSmall)
  if timeLeftBig > 0 then
    cooldownWatchSlot.targetSpellTimeBig:SetText(string.format("%.1f", timeLeftBig))
  else
    cooldownWatchSlot.targetSpellTimeBig:SetText("")
  end

  if timeLeftSmall ~= nil and timeLeftSmall >= 0 then
    cooldownWatchSlot.targetSpellTimeSmall:SetText(string.format("%.1f", timeLeftSmall))
  else
    cooldownWatchSlot.targetSpellTimeSmall:SetText("")
  end
end

--[[
  Update the texture of a cooldownWatchSlot

  @param {table} cooldownWatchSlot
  @param {number} spellId
]]--
function me.UpdateCooldownSlotTexture(cooldownWatchSlot, spellId)
  if cooldownWatchSlot.iconHolderTexture.spellId == spellId then return end

  local _, _, iconTexture = GetSpellInfo(spellId)
  cooldownWatchSlot.iconHolderTexture:SetTexture(iconTexture)
  cooldownWatchSlot.iconHolderTexture.spellId = spellId
end

--[[
  Initialize a cooldownWatchSlot with a cooldownOverlay

  @param {table} cooldownWatchSlot
  @param {table} cooldown
]]--
function me.InitCooldownSlotCooldownOverlay(cooldownWatchSlot, cooldown)
  cooldownWatchSlot.targetCooldownOverlay:SetCooldown(cooldown.spellData.castTime, cooldown.spellData.cooldown)
  -- hide default blizzard frames cooldown numbers
  cooldownWatchSlot.targetCooldownOverlay:SetHideCountdownNumbers(true)
  cooldownWatchSlot.targetCooldownOverlay.spellId = cooldown.spellData.spellId
end

--[[
  @param {number} cooldown
  @param {number} timeLeft
  @param {number} threshold

  @return {boolean}
    true - if the threshold was breached
    false - if the threshold was not breached
]]--
function me.IsThresholdBreached(cooldown, timeLeft, threshold)
  return 100 / cooldown * timeLeft <= threshold
end

--[[
  Delayed removal of an expired cooldown. Remove a cooldown step by step.

  Step 1 - Hide cooldown texts
  Step 2 - Start animating fade alpha
  Step 3 - Execute cleanup (installed once in CreateAnimation) once animation is done

  The update path re-enters here every tick while the cooldown stays expired; once the
  fade is playing there is nothing left to do, so re-entries are no-ops.

  @param {table} cooldownWatchSlot
  @param {table} cooldown
]]--
function me.ClearCooldownSlotAnimated(cooldownWatchSlot, cooldown)
  local animationGroup = cooldownWatchSlot:GetAnimationGroups()

  if animationGroup:IsPlaying() then return end

  cooldownWatchSlot.targetSpellTimeBig:SetText("")
  cooldownWatchSlot.targetSpellTimeSmall:SetText("")
  cooldownWatchSlot.targetCooldownOverlay.spellId = nil
  cooldownWatchSlot.fadingCooldown = cooldown

  animationGroup:Play()
end

--[[
  Cancel a playing expiry fade because the slot displays a live cooldown again.
  Stop() fires the group's OnStop, not OnFinished, so the deferred cleanup in
  ClearCooldownSlotAnimated does not run.

  @param {table} cooldownWatchSlot
]]--
function me.CancelCooldownSlotFade(cooldownWatchSlot)
  local animationGroup = cooldownWatchSlot:GetAnimationGroups()

  if animationGroup:IsPlaying() then
    animationGroup:Stop()
    cooldownWatchSlot.fadingCooldown = nil
    cooldownWatchSlot:SetAlpha(1)
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
  cooldownWatchSlot.iconHolderTexture.spellId = nil
  cooldownWatchSlot.highlightFrame:Hide()
  cooldownWatchSlot.targetCooldownOverlay.spellId = nil

  cooldownWatchSlot:Hide()
end
