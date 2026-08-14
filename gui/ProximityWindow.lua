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
  Parameterized builder of a proximity cooldown window: a movable vertical
  list of active cooldowns fed by CooldownQueue.GetAllCooldowns - one row per
  cooldown, a category-colored progress bar that empties as the cooldown
  elapses, the spell icon, the caster's name and the remaining time, ordered
  newest detection first.

  The enemy window (gui/ProximityCooldownBar.lua) and the friendly window
  (gui/FriendlyProximityCooldownBar.lua) instantiate the same machinery here
  and differ only in what their spec supplies: the frame name, the
  configuration accessors, the ticker pair, and which queue entries are
  eligible at all (caster side, and for the friendly window the roster scope).
  Everything a spec does not parameterize - row pool size, geometry, the
  render lifecycle - is deliberately identical across the windows.

  Lifecycle (shared by every instance): the single start edge is
  WakeRenderTicker (enqueue, target change, options changes, login), the stop
  edge lives in OnUpdate after a pass that rendered nothing - that pass
  doubles as the final clear pass, so a stopped ticker implies cleared rows.
  Each window is opt-in: while its enabled option is off it is hidden and
  WakeRenderTicker no-ops, so its ticker never runs.
]]--

local mod = rgcw
local me = {}

mod.proximityWindow = me

me.tag = "ProximityWindow"

--[[
  Create one window instance. Nothing is rendered yet - the caller invokes
  instance.BuildUi during addon initialization.

  @param {table} spec
    frameName {string}
      Global frame name of the window; also the frames-map key its position
      persists under
    IsEnabled {function -> boolean}
      Whether the window renders at all (the opt-in option)
    GetScale {function -> number}
      Render scale of the window
    GetMaxDisplayed {function -> number}
      Upper bound of rendered rows (the render pass takes the minimum of this
      and the fixed row pool)
    IsHideLongEnabled {function -> boolean}
      Whether cooldowns above PROXIMITY_LONG_COOLDOWN_THRESHOLD are hidden
    StartTicker {function}
    StopTicker {function}
      The window's render ticker pair (see code/Ticker.lua)
    GetExcludeGuid {function -> string}
      Caster whose entries are omitted from the snapshot - both windows pass
      the current target guid (the target bar already shows that caster; for
      friendly targets the guid is only recorded while the target bar
      actually renders them, so the exclusion tracks the display for free)
    IsEligibleEntry {function(cooldownEvent) -> boolean}
      Which queue entries belong to this window at all - the caster-side
      filter (and the friendly window's roster scope). Evaluated per entry on
      every render pass, so flag and scope changes need no special handling

  @return {table}
    The window instance: BuildUi, UiUpdate, WakeRenderTicker, OnUpdate,
    IsRenderableCooldown, plus the preview seam (IsPreviewActive, ShowPreview,
    RenderPreviewEntries, HidePreview) and GetWindowFrame
]]--
function me.CreateInstance(spec)
  local instance = {}

  -- the window frame, created once in BuildUi
  local window
  --[[
    Cached row frames in creation order. Populated once in BuildUi and never
    mutated afterwards (the row pool is fixed for the lifetime of the addon).
    Read from the hot OnUpdate path instead of allocating per tick.
  ]]--
  local rows = {}
  --[[
    Whether preview ("test/place") mode currently owns the rows. While true the
    live render ticker must stay down: combat log events keep enqueueing during
    the preview, and their wake edge (CooldownQueue.AddCooldown ->
    WakeRenderTicker) would otherwise bring the live ticker up to fight the
    preview ticker over the rows. The flag is also the single thing that
    enables dragging and the positioning backdrop - outside the place mode the
    window never moves (there is deliberately no separate lock option). Never
    persisted; the mode lifecycle is owned by the wrapper's preview module.
  ]]--
  local previewActive = false

  --[[
    Create the window frame. It starts hidden - whether it shows is the
    enabled option's call, applied in UiUpdate after the saved configuration
    was loaded.

    @return {table}
      The created frame
  ]]--
  local function CreateWindow()
    local frame = CreateFrame("Frame", spec.frameName, UIParent, "BackdropTemplate")
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
    Create a single row: spell icon on the left, a StatusBar filling the rest
    whose value is the remaining cooldown (full right after the cast, empty
    when the spell is ready), the caster's name overlaid on the left of the
    bar and the remaining time on its right.

    @param {table} frame
    @param {number} position

    @return {table}
      The created row frame
  ]]--
  local function CreateRow(frame, position)
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

    -- a fresh row matches the cleared state ClearRow produces
    row.isCleared = true
    row:Hide()

    return row
  end

  --[[
    Clear a row without any animation - a cooldown that ran its bar visibly
    empty needs no fade on top.

    Idempotent: while the render ticker runs, the OnUpdate pass calls this for
    every row beyond the rendered cooldowns on every tick, so without the
    isCleared guard a partially filled window would re-issue the widget writes
    below 20 times a second.

    @param {table} row
  ]]--
  local function ClearRow(row)
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
    Bind a queue entry to a row and render its current state. Rows bind
    positionally to the snapshot, so identity-dependent widget writes (icon
    texture, bar color, caster name) are keyed on the entry identity the row
    currently shows and only re-issued on rebinding; the per-tick writes are
    the bar value and the remaining-time text.

    @param {table} row
    @param {table} cooldown
      A queue entry (see the CooldownQueue storage layout)
  ]]--
  local function UpdateRow(row, cooldown)
    row.isCleared = false

    local spellData = cooldown.spellData
    --[[
      Non-target entries leave the queue exactly at expiry (their one-shot
      timer removes them), so a negative remainder only ever spans the frames
      between the due time and the timer firing - clamp instead of rendering a
      nonsense value.
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
    Update the placement backdrop of the window. The backdrop is a positioning
    aid, not part of the combat look - it shows only while the test/place mode
    owns the window, the single context in which the window can move at all.
  ]]--
  local function UpdatePlacementBackdrop()
    if previewActive then
      window:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
      })
    else
      window:SetBackdrop(nil)
    end
  end

  --[[
    Update the window frame position from its persisted frames-map entry. The
    points are always cleared first: without a saved position (first use, or a
    settings reset that cleared it) the fallback would otherwise pile its CENTER
    anchor on top of whatever anchor a previous drag left behind.
  ]]--
  local function UpdatePosition()
    local framePosition = mod.configuration.GetUserPlacedFramePosition(spec.frameName)

    window:ClearAllPoints() -- very important to clear all points first

    if framePosition ~= nil then
      window:SetPoint(
        framePosition.point,
        framePosition.relativeTo,
        framePosition.relativePoint,
        framePosition.posX,
        framePosition.posY
      )
    else
      -- default position - first use, or a cleared saved position
      window:SetPoint("CENTER", 0, 0)
    end
  end

  --[[
    Frame callback to start moving the passed (self) frame. The window only
    ever moves inside the test/place mode - there is no lock option to gate on.

    @param {table} self
  ]]--
  local function StartDragFrame(self)
    if not previewActive then return end

    self:StartMoving()
  end

  --[[
    Frame callback to stop moving the passed (self) frame

    @param {table} self
  ]]--
  local function StopDragFrame(self)
    if not previewActive then return end

    self:StopMovingOrSizing()

    local point, relativeTo, relativePoint, posX, posY = self:GetPoint()

    mod.configuration.SaveUserPlacedFramePosition(
      spec.frameName,
      point,
      relativeTo,
      relativePoint,
      posX,
      posY
    )
  end

  --[[
    Build the window ui: the frame, its drag handlers and the fixed row pool
  ]]--
  function instance.BuildUi()
    window = CreateWindow()
    window:SetScript("OnMouseDown", StartDragFrame)
    window:SetScript("OnMouseUp", StopDragFrame)

    for i = 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
      rows[i] = CreateRow(window, i)
    end
  end

  --[[
    Callback that should be invoked if anything related to the ui has to be
    updated. Should not be invoked for regular ui updates - only for single
    time changes, usually after the configuration changed (options panel,
    applied profile, login).

    Owns the enabled edge in both directions: enabling shows the window and
    wakes the ticker; disabling stops the ticker, clears every row (upholding
    the stopped-ticker-implies-cleared-rows invariant) and hides the window.
  ]]--
  function instance.UiUpdate()
    UpdatePosition()
    UpdatePlacementBackdrop()
    window:SetScale(spec.GetScale())

    if spec.IsEnabled() then
      window:Show()
      instance.WakeRenderTicker()
    else
      spec.StopTicker()

      for i = 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
        ClearRow(rows[i])
      end

      window:Hide()
    end
  end

  --[[
    Start the render ticker if the window could have anything to render: the
    feature is enabled and any caster has a queued cooldown. The single start
    edge for the ticker - invoked on enqueue (CooldownQueue.AddCooldown), on
    target change (Core.OnTargetChanged, entries can move into the list when
    their caster stops being the target) and on ui updates (login, options
    changes) - so callers never start it unconditionally.

    Deliberately does NOT pre-apply the per-row filters (target exclusion,
    eligibility, hide-long, expired): when everything queued is filtered out
    the first render pass finds nothing, doubles as the clear pass and stops
    the ticker again - one cheap tick instead of duplicating the filter walk
    on every enqueue. Safe to skip the start when the queue is empty: the
    ticker only ever stops right after a full clear pass (see OnUpdate), so a
    stopped ticker implies cleared rows.
  ]]--
  function instance.WakeRenderTicker()
    --[[
      Preview mode owns the rows - live enqueues keep arriving while it runs
      and must not start the live ticker against the preview ticker. This flag
      guard, not caller discipline, is what upholds that (target bar parity).
    ]]--
    if previewActive then return end
    if not spec.IsEnabled() then return end

    if mod.cooldownQueue.HasAnyCooldowns() then
      spec.StartTicker()
    end
  end

  --[[
    @return {boolean}
      Whether preview ("test/place") mode currently owns the rows
  ]]--
  function instance.IsPreviewActive()
    return previewActive
  end

  --[[
    Hand the rows to preview mode: stop the live ticker and show the window in
    its positioning look (backdrop on, dragging allowed) regardless of the
    enabled option - the option is not written, the mode is purely transient.
    The caller renders synthetic entries through RenderPreviewEntries and ends
    the mode with HidePreview.
  ]]--
  function instance.ShowPreview()
    previewActive = true
    spec.StopTicker()

    -- headless specs create instances without BuildUi - only the flag matters there
    if window == nil then return end

    UpdatePosition()
    UpdatePlacementBackdrop()
    window:SetScale(spec.GetScale())
    window:Show()
  end

  --[[
    Bind a synthetic entry list to the rows - the preview counterpart of the
    live OnUpdate pass. Deliberately applies none of the per-row filters
    (eligibility, hide-long, expired): the entries exist to show the window,
    not to survive a tracking decision. The max-displayed option still caps the
    rows so the preview shows the layout the player configured.

    @param {table} previewEntries
      Array of queue-entry-shaped tables (see the CooldownQueue storage layout)
  ]]--
  function instance.RenderPreviewEntries(previewEntries)
    if not previewActive or window == nil then return end

    local shownRows = 0
    local maxRows = math.min(
      RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT,
      spec.GetMaxDisplayed()
    )

    for i = 1, #previewEntries do
      if shownRows >= maxRows then break end

      shownRows = shownRows + 1
      UpdateRow(rows[shownRows], previewEntries[i])
    end

    for i = shownRows + 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
      ClearRow(rows[i])
    end
  end

  --[[
    Hand the rows back to the live render lifecycle: clear every row, then let
    UiUpdate restore whatever the options say (hidden while disabled, live
    rendering - via the wake edge - while enabled).
  ]]--
  function instance.HidePreview()
    previewActive = false

    if window == nil then return end

    for i = 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
      ClearRow(rows[i])
    end

    instance.UiUpdate()
  end

  --[[
    @return {table | nil}
      The window frame, or nil before BuildUi ran. Read-only accessor for
      callers that anchor to the window (the place mode's floating apply button).
  ]]--
  function instance.GetWindowFrame()
    return window
  end

  --[[
    Whether a queue entry renders in this window.

    The eligibility filter is the spec's caster-side call (and for the
    friendly window its roster scope) - an entry of the other side never
    renders here regardless of every other setting.

    Expired-flagged entries never render: the flag only survives on entries of
    a caster who was the current target when their expiry timer fired and was
    then targeted away from - their cooldown has run out, so there is nothing
    left to show and the next target-change sweep removes them (see
    CooldownQueue.PruneExpiredCooldowns).

    The hide-long filter compares the RESOLVED cooldown the entry runs with (a
    manual override or an assumed worst case may have pulled a long base
    cooldown under the threshold - what the row renders is what the filter
    judges). At exactly the threshold a cooldown still shows; only values
    above it are "long".

    @param {table} cooldownEvent
      A queue entry (see the CooldownQueue storage layout)
    @param {boolean} hideLongCooldowns
      The player's hide-long option, resolved once per render pass

    @return {boolean}
      true - if the entry should be rendered
  ]]--
  function instance.IsRenderableCooldown(cooldownEvent, hideLongCooldowns)
    if cooldownEvent.expired then return false end
    if not spec.IsEligibleEntry(cooldownEvent) then return false end

    return not hideLongCooldowns
      or cooldownEvent.spellData.cooldown <= RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
  end

  --[[
    GUI callback for updating the window - invoked regularly by the render
    ticker while there is something to render. Once a pass renders nothing -
    every queued cooldown expired, belongs to the current target or is
    filtered out - the pass doubles as the final clear pass and the ticker
    stops itself; one of the WakeRenderTicker edges brings it back up.

    Note: runs 20 times a second - abort early and keep the per-row work cheap.
  ]]--
  function instance.OnUpdate()
    local shownRows = 0

    if spec.IsEnabled() then
      local cooldowns = mod.cooldownQueue.GetAllCooldowns(spec.GetExcludeGuid())
      local maxRows = math.min(
        RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT,
        spec.GetMaxDisplayed()
      )
      local hideLongCooldowns = spec.IsHideLongEnabled()

      --[[
        The snapshot is ordered newest detection first, so filling rows
        top-down keeps the most recent activity on top. When more eligible
        cooldowns exist than rows, the oldest detections fall off the bottom -
        the intended overflow for a list that is about what just happened.
      ]]--
      for i = 1, #cooldowns do
        if shownRows >= maxRows then break end

        if instance.IsRenderableCooldown(cooldowns[i], hideLongCooldowns) then
          shownRows = shownRows + 1
          UpdateRow(rows[shownRows], cooldowns[i])
        end
      end
    end

    for i = shownRows + 1, RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT do
      ClearRow(rows[i])
    end

    if shownRows == 0 then
      spec.StopTicker()
    end
  end

  return instance
end
