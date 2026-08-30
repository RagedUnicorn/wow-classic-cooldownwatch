--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

--[[
  Curated default-enabled profile (code/profile/): data integrity per branch
  plus the IsDefaultEnabled behavior. The validator runs build each branch's
  spellMap directly via the assembler (plus SynthesizeRankAliases, the same
  post-assembly decoration the orchestrator applies) so the orchestrator's
  per-branch cache stays untouched; the behavior cases go through the
  mod.testHelper.GetActiveBranch seam and derive their expectations from the
  REAL profile Tbc overlay's own ops, so overlay blocks added later are
  covered without spec edits.
]]--

-- luacheck: globals describe it setup teardown
-- luacheck: ignore 143

describe("Curated default-enabled profile", function()
  local profileOverlays
  local previousTestHelper

  --[[
    Build the assembled spellMap for a branch without touching the
    orchestrator's per-branch cache (SpellMapSpec pattern).

    @param {string} branch

    @return {table}
  ]]--
  local function BuildSpellMapForBranch(branch)
    local overlays = {}

    if branch == "sod" then
      table.insert(overlays, rgcw.spellMapOverlaySod.GetOverlay())
    elseif branch == "tbc" then
      table.insert(overlays, rgcw.spellMapOverlayTbc.GetOverlay())
    end

    local assembled = rgcw.spellMapAssembler.Apply(rgcw.spellMapBase.GetMap(), overlays)

    rgcw.spellMap.SynthesizeRankAliases(assembled)

    return assembled
  end

  setup(function()
    profileOverlays = {
      sod = rgcw.profileOverlaySod.GetOverlay(),
      tbc = rgcw.profileOverlayTbc.GetOverlay()
    }

    -- the tbc overlay curates at least one add; an emptied overlay would turn
    -- the branch-behavior loops below into silent no-op passes
    local hasAdd = false

    for _, ops in pairs(profileOverlays.tbc) do
      if ops.add and #ops.add > 0 then hasAdd = true end
    end

    assert.is_true(hasAdd)

    previousTestHelper = rgcw.testHelper
  end)

  teardown(function()
    rgcw.testHelper = previousTestHelper
  end)

  it("has base slices in one-to-one correspondence with the category catalog", function()
    assert.same({}, rgcw.spellMapValidation.ValidateDefaultProfileCategoriesKnown(
      rgcw.categories.GetCategories(), rgcw.profileBaseClasses, profileOverlays))
  end)

  it("carries no duplicate ids or dead overlay ops", function()
    assert.same({}, rgcw.spellMapValidation.ValidateDefaultProfileNoDuplicateIds(
      rgcw.profileBaseClasses, profileOverlays))
  end)

  for _, branch in ipairs({ "classic", "sod", "tbc" }) do
    it("curates only primary ids present on the " .. branch .. " branch", function()
      assert.same({}, rgcw.spellMapValidation.ValidateDefaultProfileIdsArePrimaries(
        rgcw.profile.BuildDefaultEnabledSets(branch), BuildSpellMapForBranch(branch)))
    end)
  end

  it("enables every base-curated id and no others on the classic branch", function()
    rgcw.testHelper = { GetActiveBranch = function() return "classic" end }

    for categoryName, spellIds in pairs(rgcw.profileBaseClasses) do
      for _, spellId in ipairs(spellIds) do
        assert.is_true(rgcw.profile.IsDefaultEnabled(categoryName, spellId))
      end
    end

    assert.is_false(rgcw.profile.IsDefaultEnabled("rogue", 99999))
    assert.is_false(rgcw.profile.IsDefaultEnabled("this_category_should_not_exist", 2094))
  end)

  it("applies the tbc overlay's ops on the tbc branch only", function()
    for categoryName, ops in pairs(profileOverlays.tbc) do
      for _, spellId in ipairs(ops.add or {}) do
        rgcw.testHelper = { GetActiveBranch = function() return "tbc" end }
        assert.is_true(rgcw.profile.IsDefaultEnabled(categoryName, spellId))

        rgcw.testHelper = { GetActiveBranch = function() return "classic" end }
        assert.is_false(rgcw.profile.IsDefaultEnabled(categoryName, spellId))
      end

      for _, spellId in ipairs(ops.remove or {}) do
        rgcw.testHelper = { GetActiveBranch = function() return "tbc" end }
        assert.is_false(rgcw.profile.IsDefaultEnabled(categoryName, spellId))

        rgcw.testHelper = { GetActiveBranch = function() return "classic" end }
        assert.is_true(rgcw.profile.IsDefaultEnabled(categoryName, spellId))
      end
    end
  end)

  it("keeps the data-empty sod branch identical to classic", function()
    rgcw.testHelper = { GetActiveBranch = function() return "sod" end }

    local sodSets = rgcw.profile.BuildDefaultEnabledSets("sod")

    for categoryName, spellIds in pairs(rgcw.profileBaseClasses) do
      for _, spellId in ipairs(spellIds) do
        assert.is_true(rgcw.profile.IsDefaultEnabled(categoryName, spellId))
      end

      local count = 0

      for _ in pairs(sodSets[categoryName]) do
        count = count + 1
      end

      assert.equal(#spellIds, count)
    end
  end)
end)
