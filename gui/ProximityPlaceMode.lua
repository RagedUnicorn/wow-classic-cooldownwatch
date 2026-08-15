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
  Parameterized builder of a PROXIMITY WINDOW test/place mode: the preview
  content layer - synthetic example cooldowns driving a window's row pool -
  on top of the generic mode shell (gui/PlaceMode.lua), which owns the
  settings close/reopen flow, the floating apply button and the safeguards.

  The enemy mode (gui/ProximityCooldownBarPreview.lua) and the friendly mode
  (gui/FriendlyProximityCooldownBarPreview.lua) instantiate the same machinery
  here and differ only in what their spec supplies: the window wrapper, the
  preview ticker pair, the apply button identity and the settings category to
  reopen.

  The window shows example rows and becomes draggable via the window builder's
  preview seam (gui/ProximityWindow.lua) - the only context it ever moves in,
  there is deliberately no lock option - and the enabled option is not
  written. The example entries are derived through the SpellMap accessors -
  one primary per catalog category - and never enter the cooldown queue, so
  they schedule no expiry timers and cannot leak into live rendering (target
  bar preview parity).
]]--

local mod = rgcw
local me = {}

mod.proximityPlaceMode = me

me.tag = "ProximityPlaceMode"

--[[
  Create one proximity place mode instance.

  @param {table} spec
    tag {string}
      Log tag identifying the mode's window
    bar {table}
      The window wrapper module (gui/ProximityCooldownBar.lua or its friendly
      twin) - the mode drives its preview seam: ShowPreview, HidePreview,
      RenderPreviewEntries, GetWindowFrame
    applyButtonName {string}
      Global frame name of the floating apply button
    applyButtonLabel {string}
      Localized text of the floating apply button
    settingsCategoryKey {string}
      AddonConfiguration.GetCategoryId key of the options panel the apply
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
  --[[
    Synthetic entries currently driving the preview. Seeded on mode entry,
    restamped in place by the preview tick when they run out (this is what
    loops the preview), emptied on mode exit.
  ]]--
  local exampleCooldowns = {}

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

    local names = RGCW_CONSTANTS.PROXIMITY_EXAMPLE_CASTER_NAMES

    return {
      ["sourceGuid"] = "preview" .. position,
      ["sourceName"] = names[(position - 1) % #names + 1],
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

  local instance = mod.placeMode.CreateInstance({
    tag = spec.tag,
    GetAnchorFrame = function() return spec.bar.GetWindowFrame() end,
    applyButtonName = spec.applyButtonName,
    applyButtonLabel = spec.applyButtonLabel,
    settingsCategoryKey = spec.settingsCategoryKey,
    StartPreview = function()
      exampleCooldowns = BuildExampleCooldowns()
      spec.bar.ShowPreview()
      -- one immediate frame, then the preview ticker animates
      spec.bar.RenderPreviewEntries(exampleCooldowns)
      spec.StartPreviewTicker()
    end,
    StopPreview = function()
      spec.StopPreviewTicker()
      exampleCooldowns = {}
      spec.bar.HidePreview()
    end
  })

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

  return instance
end
