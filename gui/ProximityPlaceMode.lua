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

-- luacheck: globals CreateFrame GetTime Settings SettingsPanel HideUIPanel

--[[
  Parameterized builder of a proximity window test/place mode. Fills a
  window's rows with synthetic example cooldowns so the player can position
  and inspect it without waiting for tracked casters to cast something.

  The enemy mode (gui/ProximityCooldownBarPreview.lua) and the friendly mode
  (gui/FriendlyProximityCooldownBarPreview.lua) instantiate the same machinery
  here and differ only in what their spec supplies: the window wrapper, the
  preview ticker pair, the save button identity and the settings category to
  reopen. Everything a spec does not parameterize - the example entries, the
  safeguards, the settings close/reopen flow - is deliberately identical
  across the modes.

  Entering a mode (button in the window's options panel) closes the Settings
  window - it overlaps the windows' default center position - and shows the
  window in its positioning look via the shared window builder's preview seam
  (gui/ProximityWindow.lua): live rendering is suspended, the window becomes
  draggable (the only context it ever moves in - there is deliberately no
  lock option), and the enabled option is not written. A floating "Save"
  button below the window finishes the
  mode and reopens the Settings window at the spec's category. Save is a
  finish action, not a commit - the dragged position persists on every
  drag-stop like it always does.

  A mode is never persisted: it always reverts on /reload, force-exits when
  combat starts (without reopening the Settings window mid-fight), and ends
  itself when the Settings window is opened through any other path while it
  runs - which also makes the two modes mutually exclusive: entering one
  requires the open Settings window, whose show ends the other.

  The example entries are derived through the SpellMap accessors - one primary
  per catalog category - and never enter the cooldown queue, so they schedule
  no expiry timers and cannot leak into live rendering (target bar preview
  parity).
]]--

local mod = rgcw
local me = {}

mod.proximityPlaceMode = me

me.tag = "ProximityPlaceMode"

--[[
  Create one place mode instance. Everything is created lazily on the first
  mode entry - an instance whose mode is never used costs no frames.

  @param {table} spec
    tag {string}
      Log tag identifying the mode's window
    bar {table}
      The window wrapper module (gui/ProximityCooldownBar.lua or its friendly
      twin) - the mode drives its preview seam: ShowPreview, HidePreview,
      RenderPreviewEntries, GetWindowFrame
    saveButtonName {string}
      Global frame name of the floating save button
    saveButtonLabel {string}
      Localized text of the floating save button
    settingsCategoryKey {string}
      AddonConfiguration.GetCategoryId key of the options panel the save
      button returns to
    StartPreviewTicker {function}
    StopPreviewTicker {function}
      The mode's preview ticker pair (see code/Ticker.lua)
    flagFriendly {boolean}
      Whether the example entries carry the friendly marker - the friendly
      window's examples resolve caster-relative icons (own-faction insignia,
      see GuiHelper.GetIconId) exactly like its live entries

  @return {table}
    The mode instance: IsPlaceModeActive, EnterPlaceMode,
    FinishPlaceMode, OnUpdate
]]--
function me.CreateInstance(spec)
  local instance = {}

  --[[
    Synthetic entries currently driving the preview. Seeded on mode entry,
    restamped in place by the preview tick when they run out (this is what
    loops the preview), emptied on mode exit.
  ]]--
  local exampleCooldowns = {}
  --[[
    Whether the test/place mode is currently active. The window builder's
    preview flag guards the render lifecycle; this one guards the mode
    lifecycle around it (safeguards, the save button, the settings
    close/reopen).
  ]]--
  local modeActive = false
  -- floating finish control, created lazily on first mode entry
  local saveButton
  -- combat safeguard event frame, created lazily on first mode entry
  local combatSafeguardFrame
  -- tracks whether the Settings window OnShow hook was already installed
  local settingsShowHooked = false

  --[[
    @return {boolean}
      Whether the test/place mode is currently active
  ]]--
  function instance.IsPlaceModeActive()
    return modeActive
  end

  --[[
    Build one synthetic queue-entry-shaped example from a catalog entry.

    The spell identity (spellId, itemId for the icon, category color) is real
    catalog data pulled through the SpellMap accessors; the timing is
    synthetic - short, per-row staggered cooldowns so the bars visibly run and
    loop while the player positions the window, where real catalog cooldowns
    can be minutes long (target bar preview parity, see
    CooldownQueue.BuildExampleCooldown).

    @param {string} categoryName
    @param {table} spellData
      A cloned primary entry (see SpellMapHelper.GetAllForCategory) - safe to
      stamp the synthetic timing onto
    @param {number} now
    @param {number} position

    @return {table}
      A queue-entry-shaped table (see the CooldownQueue storage layout)
  ]]--
  local function BuildExampleEntry(categoryName, spellData, now, position)
    -- slight stagger so no two rows empty in lockstep
    spellData.castTime = now - position
    spellData.cooldown = 10 + position * 5

    if spec.flagFriendly then
      spellData.friendly = true
    end

    return {
      ["sourceGuid"] = "preview" .. position,
      ["sourceName"] = "Example " .. position,
      ["categoryName"] = categoryName,
      ["spellData"] = spellData
    }
  end

  --[[
    Build the example entry list: one entry per catalog category - every row a
    different class color and icon - capped at the window's row pool.

    @return {table}
  ]]--
  local function BuildExampleCooldowns()
    local entries = {}
    local now = GetTime()

    for _, category in ipairs(mod.categories.GetCategories()) do
      if #entries >= RGCW_CONSTANTS.PROXIMITY_COOLDOWN_ROW_AMOUNT then break end

      local spells = mod.spellMapHelper.GetAllForCategory(category.categoryName)

      if spells ~= nil and spells[1] ~= nil then
        table.insert(
          entries,
          BuildExampleEntry(category.categoryName, spells[1], now, #entries + 1)
        )
      end
    end

    return entries
  end

  --[[
    Register an event frame that forces the mode off when combat starts. A
    deliberately separate frame instead of the addon event bus - the bus holds
    exactly one handler per event and this safeguard must never displace (or
    be displaced by) another consumer.
  ]]--
  local function RegisterCombatSafeguard()
    combatSafeguardFrame = CreateFrame("Frame")
    combatSafeguardFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatSafeguardFrame:SetScript("OnEvent", function()
      if modeActive then
        -- no settings reopen mid-fight - the mode just ends
        instance.FinishPlaceMode(false)
      end
    end)
  end

  --[[
    End the mode whenever the Settings window is opened through any other path
    while it runs - the mode's whole premise is that the panel is out of the
    way. The reopen in FinishPlaceMode cannot recurse here: by the time it
    fires the mode flag is already down.
  ]]--
  local function HookSettingsShow()
    if settingsShowHooked then return end
    if SettingsPanel == nil then return end

    SettingsPanel:HookScript("OnShow", function()
      if modeActive then
        -- the panel is already opening - finish without reopening it
        instance.FinishPlaceMode(false)
      end
    end)

    settingsShowHooked = true
  end

  --[[
    Create the floating save button. Parented to the window frame so it
    follows every drag and inherits the window's scale; shown only while the
    mode runs.
  ]]--
  local function CreateSaveButton()
    local window = spec.bar.GetWindowFrame()

    saveButton = mod.guiHelper.CreateTextButton(
      spec.saveButtonName,
      window,
      {"TOP", window, "BOTTOM", 0, -8},
      function()
        instance.FinishPlaceMode(true)
      end,
      spec.saveButtonLabel
    )
  end

  --[[
    Enter the test/place mode: close the Settings window, take over the window
    rows with example cooldowns and start the preview ticker.
  ]]--
  function instance.EnterPlaceMode()
    if modeActive then return end

    modeActive = true

    if combatSafeguardFrame == nil then
      RegisterCombatSafeguard()
    end
    -- retry the hook - the Settings window may not have existed at earlier attempts
    HookSettingsShow()

    exampleCooldowns = BuildExampleCooldowns()

    spec.bar.ShowPreview()

    if saveButton == nil then
      CreateSaveButton()
    end
    saveButton:Show()

    -- one immediate frame, then the preview ticker animates
    spec.bar.RenderPreviewEntries(exampleCooldowns)
    spec.StartPreviewTicker()

    if SettingsPanel ~= nil then
      HideUIPanel(SettingsPanel)
    end

    mod.logger.LogInfo(spec.tag, "Entered proximity window test/place mode")
  end

  --[[
    GUI callback for animating the preview - invoked regularly by the preview
    ticker while the mode is active. An entry that ran out is restamped to now
    so the preview loops; rows in these windows expire without a fade, so
    there is no fade-out to wait for (contrast the target bar preview).
  ]]--
  function instance.OnUpdate()
    local now = GetTime()

    for i = 1, #exampleCooldowns do
      local spellData = exampleCooldowns[i].spellData

      if now - spellData.castTime >= spellData.cooldown then
        spellData.castTime = now
      end
    end

    spec.bar.RenderPreviewEntries(exampleCooldowns)
  end

  --[[
    Finish the test/place mode: stop the preview, hand the rows back to the
    live render lifecycle and optionally reopen the Settings window at the
    spec's category. Idempotent - the combat safeguard, the Settings hook and
    the save button can race on the same edge.

    @param {boolean} reopenOptions
      true reopens the Settings window at the spec's category - the save
      button's path. The safeguards pass false: combat must not open the
      panel, and the Settings hook fires while the panel is already opening.
  ]]--
  function instance.FinishPlaceMode(reopenOptions)
    if not modeActive then return end

    modeActive = false

    spec.StopPreviewTicker()

    if saveButton ~= nil then
      saveButton:Hide()
    end

    exampleCooldowns = {}

    spec.bar.HidePreview()

    if reopenOptions == true then
      local categoryId = mod.addonConfiguration.GetCategoryId(spec.settingsCategoryKey)

      if categoryId ~= nil then
        Settings.OpenToCategory(categoryId)
      end
    end

    mod.logger.LogInfo(spec.tag, "Finished proximity window test/place mode")
  end

  return instance
end
