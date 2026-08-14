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

-- luacheck: globals CreateFrame UIParent STANDARD_TEXT_FONT GetTime

--[[
  The proximity cooldown window: a movable vertical list of the active cooldowns of
  every tracked hostile caster EXCEPT the current target (the target bar already shows
  that one). One row per cooldown - a category-colored progress bar that empties as the
  cooldown elapses, the spell icon, the caster's name and the remaining time - ordered
  newest detection first (CooldownQueue.GetAllCooldowns).

  The exclusion is evaluated against the live target guid on every render pass, so a
  target change needs no special handling: the old target's still-running cooldowns
  appear in the list by themselves and the new target's rows vanish (they render on the
  target bar instead).

  Lifecycle mirrors the target bar's on-demand render ticker: the single start edge is
  WakeRenderTicker (enqueue, target change, options changes, login), the stop edge lives
  in ProximityCooldownBarOnUpdate after a pass that rendered nothing - that pass doubles
  as the final clear pass, so a stopped ticker implies cleared rows. The whole surface
  is opt-in: while the enabled option is off the window is hidden and WakeRenderTicker
  no-ops, so the ticker never runs.
]]--

local mod = rgcw
local me = {}

mod.proximityCooldownBar = me

me.tag = "ProximityCooldownBar"

--[[
  Local references to ui elements
]]--
local proximityCooldownWindow
--[[
  Cached row frames in creation order. Populated once in CreateProximityRows and never
  mutated afterwards (the row pool is fixed for the lifetime of the addon). Read from
  the hot OnUpdate path instead of allocating per tick.
]]--
local proximityRows = {}

--[[
  Build initial proximityCooldownWindow ui. The window starts hidden - whether it shows
  is the enabled option's call, applied in ProximityCooldownBarUiUpdate after the saved
  configuration was loaded.
]]--
function me.BuildUi()
  proximityCooldownWindow = me.CreateProximityCooldownWindow()
  me.SetupDragFrame(proximityCooldownWindow)
  me.CreateProximityRows(proximityCooldownWindow)
end

--[[
  Create the proximityCooldownWindow

  @return {table}
    The created frame
]]--
function me.CreateProximityCooldownWindow()
  local frame = CreateFrame(
    "Frame", RGCW_CONSTANTS.ELEMENT_PROXIMITY_COOLDOWN_WINDOW_FRAME, UIParent, "BackdropTemplate")
  local rowAmount = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT

  frame:SetWidth(RGCW_CONSTANTS.PROXIMITY_COOLDOWN_WINDOW_WIDTH)
  frame:SetHeight(
    RGCW_CONSTANTS.PROXIMITY_COOLDOWN_WINDOW_PADDING * 2
      + rowAmount * RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_HEIGHT
      + (rowAmount - 1) * RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_SPACING
  )
  frame:SetBackdropColor(0, 0, 0, .5)
  frame:SetBackdropBorderColor(0, 0, 0, .8)
  frame:SetPoint("CENTER", 0, 0)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:Hide()

  return frame
end

--[[
  Create all rows of the fixed pool and attach them to the proximityCooldownWindow

  @param {table} frame
]]--
function me.CreateProximityRows(frame)
  for i = 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
    proximityRows[i] = me.CreateProximityRow(frame, i)
  end
end

--[[
  Create a single row: spell icon on the left, a StatusBar filling the rest whose value
  is the remaining cooldown (full right after the cast, empty when the spell is ready),
  the caster's name overlaid on the left of the bar and the remaining time on its right.

  @param {table} frame
  @param {number} position

  @return {table}
    The created row frame
]]--
function me.CreateProximityRow(frame, position)
  local rowHeight = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_HEIGHT
  local padding = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_WINDOW_PADDING
  local offsetY = padding
    + (position - 1) * (rowHeight + RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_SPACING)

  local row = CreateFrame(
    "Frame", RGCW_CONSTANTS.ELEMENT_PROXIMITY_COOLDOWN_ROW .. position, frame)
  row:SetHeight(rowHeight)
  row:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -offsetY)
  row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padding, -offsetY)

  row.iconTexture = row:CreateTexture(nil, "ARTWORK")
  row.iconTexture:SetSize(rowHeight, rowHeight)
  row.iconTexture:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  row.statusBar = CreateFrame("StatusBar", nil, row)
  row.statusBar:SetPoint("TOPLEFT", row.iconTexture, "TOPRIGHT", 2, 0)
  row.statusBar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
  row.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  row.statusBar:SetMinMaxValues(0, 1)
  row.statusBar:SetValue(0)

  local barBackground = row.statusBar:CreateTexture(nil, "BACKGROUND")
  barBackground:SetAllPoints(row.statusBar)
  barBackground:SetColorTexture(0.05, 0.04, 0.03, 0.9)

  row.remainingText = row.statusBar:CreateFontString(nil, "OVERLAY")
  row.remainingText:SetFont(
    STANDARD_TEXT_FONT, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_TEXT_SIZE, "OUTLINE")
  row.remainingText:SetPoint("RIGHT", row.statusBar, "RIGHT", -4, 0)
  row.remainingText:SetJustifyH("RIGHT")

  row.casterName = row.statusBar:CreateFontString(nil, "OVERLAY")
  row.casterName:SetFont(
    STANDARD_TEXT_FONT, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_TEXT_SIZE, "OUTLINE")
  row.casterName:SetPoint("LEFT", row.statusBar, "LEFT", 4, 0)
  row.casterName:SetPoint("RIGHT", row.remainingText, "LEFT", -2, 0)
  row.casterName:SetJustifyH("LEFT")
  row.casterName:SetWordWrap(false)

  -- a fresh row matches the cleared state ClearProximityRow produces
  row.isCleared = true
  row:Hide()

  return row
end

--[[
  Callback that should be invoked if anything related to the ui has to be updated.
  Should not be invoked for regular ui updates - only for single time changes, usually
  after the configuration changed (options panel, applied profile, login).

  Owns the enabled edge in both directions: enabling shows the window and wakes the
  ticker; disabling stops the ticker, clears every row (upholding the stopped-ticker-
  implies-cleared-rows invariant) and hides the window.
]]--
function me.ProximityCooldownBarUiUpdate()
  me.UpdateProximityWindowPosition()
  me.UpdateProximityWindowLockedState()
  proximityCooldownWindow:SetScale(mod.configuration.GetProximityCooldownsScale())

  if mod.configuration.IsProximityCooldownsEnabled() then
    proximityCooldownWindow:Show()
    me.WakeRenderTicker()
  else
    mod.ticker.StopTickerProximityCooldownBar()

    for i = 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
      me.ClearProximityRow(proximityRows[i])
    end

    proximityCooldownWindow:Hide()
  end
end

--[[
  Update the locked/unlocked state of the proximityCooldownWindow. Like the target bar
  the backdrop only shows while the window is unlocked - a positioning aid, not part of
  the combat look.
]]--
function me.UpdateProximityWindowLockedState()
  if mod.configuration.IsProximityCooldownsLocked() then
    proximityCooldownWindow:SetBackdrop(nil)
  else
    proximityCooldownWindow:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
    })
  end
end

--[[
  Update the proximityCooldownWindow frame position
]]--
function me.UpdateProximityWindowPosition()
  local framePosition =
    mod.configuration.GetUserPlacedFramePosition(RGCW_CONSTANTS.ELEMENT_PROXIMITY_COOLDOWN_WINDOW_FRAME)

  if framePosition ~= nil then
    proximityCooldownWindow:ClearAllPoints() -- very important to clear all points first
    proximityCooldownWindow:SetPoint(
      framePosition.point,
      framePosition.relativeTo,
      framePosition.relativePoint,
      framePosition.posX,
      framePosition.posY
    )
  else
    -- initial position for first time use
    proximityCooldownWindow:SetPoint("CENTER", 0, 0)
  end
end

--[[
  Start the render ticker if the window could have anything to render: the feature is
  enabled and any caster has a queued cooldown. The single start edge for the ticker -
  invoked on enqueue (CooldownQueue.AddCooldown), on target change (Core.OnTargetChanged,
  entries can move into the list when their caster stops being the target) and on ui
  updates (login, options changes) - so callers never start it unconditionally.

  Deliberately does NOT pre-apply the per-row filters (target exclusion, hide-long,
  expired): when everything queued is filtered out the first render pass finds nothing,
  doubles as the clear pass and stops the ticker again - one cheap tick instead of
  duplicating the filter walk on every enqueue. Safe to skip the start when the queue is
  empty: the ticker only ever stops right after a full clear pass (see
  ProximityCooldownBarOnUpdate), so a stopped ticker implies cleared rows.
]]--
function me.WakeRenderTicker()
  if not mod.configuration.IsProximityCooldownsEnabled() then return end

  if mod.cooldownQueue.HasAnyCooldowns() then
    mod.ticker.StartTickerProximityCooldownBar()
  end
end

--[[
  Whether a queue entry renders in the proximity window.

  Expired-flagged entries never render: the flag only survives on entries of a caster
  who was the current target when their expiry timer fired and was then targeted away
  from - their cooldown has run out, so there is nothing left to show and the next
  target-change sweep removes them (see CooldownQueue.PruneExpiredCooldowns).

  The hide-long filter compares the RESOLVED cooldown the entry runs with (a manual
  override or an assumed worst case may have pulled a long base cooldown under the
  threshold - what the row renders is what the filter judges). At exactly the threshold
  a cooldown still shows; only values above it are "long".

  @param {table} cooldownEvent
    A queue entry (see the CooldownQueue storage layout)
  @param {boolean} hideLongCooldowns
    The player's hide-long option, resolved once per render pass

  @return {boolean}
    true - if the entry should be rendered
]]--
function me.IsRenderableCooldown(cooldownEvent, hideLongCooldowns)
  if cooldownEvent.expired then return false end

  return not hideLongCooldowns
    or cooldownEvent.spellData.cooldown <= RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
end

--[[
  GUI callback for updating the proximity window - invoked regularly by the render
  ticker while there is something to render. Once a pass renders nothing - every queued
  cooldown expired, belongs to the current target or is filtered out - the pass doubles
  as the final clear pass and the ticker stops itself; one of the WakeRenderTicker edges
  brings it back up.

  Note: runs 20 times a second - abort early and keep the per-row work cheap.
]]--
function me.ProximityCooldownBarOnUpdate()
  local shownRows = 0

  if mod.configuration.IsProximityCooldownsEnabled() then
    local cooldowns = mod.cooldownQueue.GetAllCooldowns(mod.target.GetCurrentTargetGuid())
    local maxRows = math.min(
      RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT,
      mod.configuration.GetProximityCooldownsMaxDisplayed()
    )
    local hideLongCooldowns = mod.configuration.IsProximityCooldownsHideLongEnabled()

    --[[
      The snapshot is ordered newest detection first, so filling rows top-down keeps the
      most recent activity on top. When more eligible cooldowns exist than rows, the
      oldest detections fall off the bottom - the intended overflow for a list that is
      about what just happened.
    ]]--
    for i = 1, #cooldowns do
      if shownRows >= maxRows then break end

      if me.IsRenderableCooldown(cooldowns[i], hideLongCooldowns) then
        shownRows = shownRows + 1
        me.UpdateProximityRow(proximityRows[shownRows], cooldowns[i])
      end
    end
  end

  for i = shownRows + 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
    me.ClearProximityRow(proximityRows[i])
  end

  if shownRows == 0 then
    mod.ticker.StopTickerProximityCooldownBar()
  end
end

--[[
  Bind a queue entry to a row and render its current state. Rows bind positionally to
  the snapshot, so identity-dependent widget writes (icon texture, bar color, caster
  name) are keyed on the entry identity the row currently shows and only re-issued on
  rebinding; the per-tick writes are the bar value and the remaining-time text.

  @param {table} row
  @param {table} cooldown
    A queue entry (see the CooldownQueue storage layout)
]]--
function me.UpdateProximityRow(row, cooldown)
  row.isCleared = false

  local spellData = cooldown.spellData
  --[[
    Non-target entries leave the queue exactly at expiry (their one-shot timer removes
    them), so a negative remainder only ever spans the frames between the due time and
    the timer firing - clamp instead of rendering a nonsense value.
  ]]--
  local remaining = math.max(0, spellData.castTime + spellData.cooldown - GetTime())

  row.statusBar:SetMinMaxValues(0, spellData.cooldown)
  row.statusBar:SetValue(remaining)
  row.remainingText:SetText(mod.common.FormatCooldownTime(remaining))

  if row.iconTexture.spellId ~= spellData.spellId then
    row.iconTexture:SetTexture(mod.guiHelper.GetIconId(spellData))
    row.iconTexture.spellId = spellData.spellId
  end

  if row.categoryName ~= cooldown.categoryName then
    local color = mod.guiHelper.GetCategoryColor(cooldown.categoryName)
    row.statusBar:SetStatusBarColor(color[1], color[2], color[3], 0.9)
    row.categoryName = cooldown.categoryName
  end

  if row.sourceGuid ~= cooldown.sourceGuid then
    row.casterName:SetText(cooldown.sourceName)
    row.sourceGuid = cooldown.sourceGuid
  end

  row:Show()
end

--[[
  Clear a row without any animation - a cooldown that ran its bar visibly empty needs
  no fade on top.

  Idempotent: while the render ticker runs, the OnUpdate pass calls this for every row
  beyond the rendered cooldowns on every tick, so without the isCleared guard a
  partially filled window would re-issue the widget writes below 20 times a second.

  @param {table} row
]]--
function me.ClearProximityRow(row)
  if row.isCleared then return end

  row.iconTexture:SetTexture(nil)
  row.iconTexture.spellId = nil
  row.categoryName = nil
  row.sourceGuid = nil
  row.casterName:SetText("")
  row.remainingText:SetText("")
  row.statusBar:SetValue(0)
  row.isCleared = true

  row:Hide()
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
  if mod.configuration.IsProximityCooldownsLocked() then return end

  self:StartMoving()
end

--[[
  Frame callback to stop moving the passed (self) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  if mod.configuration.IsProximityCooldownsLocked() then return end

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint()

  mod.configuration.SaveUserPlacedFramePosition(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_COOLDOWN_WINDOW_FRAME,
    point,
    relativeTo,
    relativePoint,
    posX,
    posY
  )
end
