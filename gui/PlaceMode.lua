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

-- luacheck: globals CreateFrame Settings SettingsPanel HideUIPanel

--[[
  Parameterized builder of a test/place mode SHELL: the transient mode
  lifecycle every placeable render surface shares - close the Settings window
  on entry (it overlaps the surfaces' default center positions), show a
  floating "Apply" button anchored to the surface, and on Apply finish the
  mode and reopen the Settings window at the surface's own options category.
  What is actually previewed is the spec's business, injected as a
  StartPreview/StopPreview pair - the proximity windows drive their row pools
  with example entries (gui/ProximityPlaceMode.lua layers that on top of this
  shell), the target cooldown bar reuses its existing example mode
  (gui/TargetCooldownBarPlaceMode.lua).

  Apply is a finish action, not a deferred commit - every surface persists its
  dragged position on drag-stop like it always does.

  A mode is never persisted: it always reverts on /reload, force-exits when
  combat starts (without reopening the Settings window mid-fight), and ends
  itself when the Settings window is opened through any other path while it
  runs - which also makes all modes mutually exclusive: entering one requires
  the open Settings window, whose show ends every other.
]]--

local mod = rgcw
local me = {}

mod.placeMode = me

me.tag = "PlaceMode"

--[[
  Create one place mode shell instance. Everything is created lazily on the
  first mode entry - an instance whose mode is never used costs no frames.

  @param {table} spec
    tag {string}
      Log tag identifying the mode's surface
    GetAnchorFrame {function -> table}
      The frame the floating apply button anchors to (and is parented to, so
      it follows every drag and inherits the surface's scale)
    applyButtonName {string}
      Global frame name of the floating apply button
    applyButtonLabel {string}
      Localized text of the floating apply button
    settingsCategoryKey {string}
      AddonConfiguration.GetCategoryId key of the options panel the apply
      button returns to
    StartPreview {function}
      Take over the surface with preview content; invoked with the mode flag
      already up
    StopPreview {function}
      Hand the surface back to its live rendering; invoked with the mode flag
      already down. Must be idempotent - the combat safeguard, the Settings
      hook and the apply button can race on the same edge

  @return {table}
    The mode instance: IsPlaceModeActive, EnterPlaceMode, FinishPlaceMode
]]--
function me.CreateInstance(spec)
  local instance = {}

  --[[
    Whether the test/place mode is currently active. The surface's own preview
    state guards its render lifecycle; this flag guards the mode lifecycle
    around it (safeguards, the apply button, the settings close/reopen).
  ]]--
  local modeActive = false
  -- floating finish control, created lazily on first mode entry
  local applyButton
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
    Create the floating apply button. Parented to the anchor frame so it
    follows every drag and inherits the surface's scale; shown only while the
    mode runs.
  ]]--
  local function CreateApplyButton()
    local anchorFrame = spec.GetAnchorFrame()

    applyButton = mod.guiHelper.CreateTextButton(
      spec.applyButtonName,
      anchorFrame,
      {"TOP", anchorFrame, "BOTTOM", 0, -8},
      function()
        instance.FinishPlaceMode(true)
      end,
      spec.applyButtonLabel
    )
  end

  --[[
    Enter the test/place mode: close the Settings window and take over the
    surface with the spec's preview.
  ]]--
  function instance.EnterPlaceMode()
    if modeActive then return end

    modeActive = true

    if combatSafeguardFrame == nil then
      RegisterCombatSafeguard()
    end
    -- retry the hook - the Settings window may not have existed at earlier attempts
    HookSettingsShow()

    spec.StartPreview()

    if applyButton == nil then
      CreateApplyButton()
    end
    applyButton:Show()

    if SettingsPanel ~= nil then
      HideUIPanel(SettingsPanel)
    end

    mod.logger.LogInfo(spec.tag, "Entered test/place mode")
  end

  --[[
    Finish the test/place mode: hand the surface back to its live rendering
    and optionally reopen the Settings window at the spec's category.
    Idempotent - the combat safeguard, the Settings hook and the apply button
    can race on the same edge.

    @param {boolean} reopenOptions
      true reopens the Settings window at the spec's category - the apply
      button's path. The safeguards pass false: combat must not open the
      panel, and the Settings hook fires while the panel is already opening.
  ]]--
  function instance.FinishPlaceMode(reopenOptions)
    if not modeActive then return end

    modeActive = false

    if applyButton ~= nil then
      applyButton:Hide()
    end

    spec.StopPreview()

    if reopenOptions == true then
      local categoryId = mod.addonConfiguration.GetCategoryId(spec.settingsCategoryKey)

      if categoryId ~= nil then
        Settings.OpenToCategory(categoryId)
      end
    end

    mod.logger.LogInfo(spec.tag, "Finished test/place mode")
  end

  return instance
end
