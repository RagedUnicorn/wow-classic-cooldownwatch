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
  Headless spec for the per-op assembler matrix (code/spellmap/Assemble.lua),
  branch determination, and the orchestrator's per-branch assembly cache
  (code/SpellMap.lua). The assembler tests use small synthetic base/overlay
  fixtures instead of the production Base.lua; mod.logger.LogError is replaced
  with a capturing stub per test to assert the logged-and-skipped error
  branches without reaching the chat-frame printer.

  Branch determination is asserted through rgcw.spellMap.GetActiveBranch, which
  never builds a map - the sod branch is never requested through the
  orchestrator here, because SpellMapSodOverlaySpec owns the sod cache entry.
  The cache tests request only the classic and tbc branches; the tbc entry is
  built from the real (data-empty) TBC overlay and stays cached for the rest of
  the busted run.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

describe("spellMapAssembler ops", function()
  local assembler
  local loggedErrors
  local originalLogError

  local function BuildBase()
    return {
      mage = {
        [12472] = {
          name = "Cold Snap",
          allRanks = {
            { spellId = 12472, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }
          }
        },
        [11129] = {
          name = "Combustion"
        }
      },
      priest = {
        [8122] = {
          name = "Psychic Scream"
        }
      }
    }
  end

  before_each(function()
    assembler = rgcw.spellMapAssembler
    loggedErrors = {}
    originalLogError = rgcw.logger.LogError
    rgcw.logger.LogError = function(tag, message)
      table.insert(loggedErrors, { tag = tag, message = message })
    end
  end)

  after_each(function()
    rgcw.logger.LogError = originalLogError
  end)

  describe("Apply", function()
    it("returns a clone of the base map when overlays is nil", function()
      local base = BuildBase()
      local result = assembler.Apply(base, nil)

      assert.are.same(base, result)
      assert.are_not.equal(base, result)
      assert.are_not.equal(base.mage[12472], result.mage[12472])
    end)

    it("returns a clone of the base map when overlays is empty", function()
      local base = BuildBase()
      local result = assembler.Apply(base, {})

      assert.are.same(base, result)
      assert.are_not.equal(base, result)
    end)

    it("leaves the base content intact for a no-op overlay", function()
      local base = BuildBase()
      local result = assembler.Apply(base, { {}, { mage = {} } })

      assert.are.equal(0, #loggedErrors)
      assert.are.same(BuildBase(), result)
    end)

    it("applies overlays in the order given", function()
      local base = BuildBase()
      local overlays = {
        { mage = { add = { [999001] = { name = "First" } } } },
        { mage = { replace = { [999001] = { name = "Second" } } } }
      }
      local result = assembler.Apply(base, overlays)

      assert.are.equal(0, #loggedErrors)
      assert.are.equal("Second", result.mage[999001].name)
    end)

    it("does not mutate base or overlay tables", function()
      local function BuildOverlays()
        return {
          {
            mage = {
              remove = { 11129 },
              add = { [999001] = { name = "New Spell" } },
              replace = { [12472] = { name = "Replaced Cold Snap" } },
              appendRanks = {
                [12472] = { { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_BASE } }
              }
            }
          }
        }
      end
      local base = BuildBase()
      local overlays = BuildOverlays()

      assembler.Apply(base, overlays)

      assert.are.equal(0, #loggedErrors)
      assert.are.same(BuildBase(), base)
      assert.are.same(BuildOverlays(), overlays)
    end)

    it("clones added spellData instead of aliasing the overlay", function()
      local spellData = { name = "New Spell" }
      local result = assembler.Apply(BuildBase(), { { mage = { add = { [999001] = spellData } } } })

      assert.are_not.equal(spellData, result.mage[999001])

      spellData.name = "Mutated"

      assert.are.equal("New Spell", result.mage[999001].name)
    end)

    it("clones replaced spellData instead of aliasing the overlay", function()
      local spellData = { name = "Replaced Cold Snap" }
      local result = assembler.Apply(BuildBase(), { { mage = { replace = { [12472] = spellData } } } })

      assert.are_not.equal(spellData, result.mage[12472])

      spellData.name = "Mutated"

      assert.are.equal("Replaced Cold Snap", result.mage[12472].name)
    end)
  end)

  describe("ApplyOne remove", function()
    it("removes an existing spellId from the category", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { mage = { remove = { 11129 } } })

      assert.are.equal(0, #loggedErrors)
      assert.is_nil(map.mage[11129])
      assert.is_table(map.mage[12472])
    end)

    it("logs and skips a remove for a missing spellId", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { mage = { remove = { 424242 } } })

      assert.are.equal(1, #loggedErrors)
      assert.matches("remove failed: spellId 424242 not present in category mage", loggedErrors[1].message)
      assert.are.same(BuildBase(), map)
    end)
  end)

  describe("ApplyOne add", function()
    it("adds a new spellId to the category", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { mage = { add = { [999001] = { name = "New Spell" } } } })

      assert.are.equal(0, #loggedErrors)
      assert.are.equal("New Spell", map.mage[999001].name)
    end)

    it("creates the category when adding into one absent from the map", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { warlock = { add = { [5782] = { name = "Fear" } } } })

      assert.are.equal(0, #loggedErrors)
      assert.are.equal("Fear", map.warlock[5782].name)
    end)

    it("logs and skips an add for an already existing spellId", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { mage = { add = { [12472] = { name = "Duplicate" } } } })

      assert.are.equal(1, #loggedErrors)
      assert.matches("add failed: spellId 12472 already exists in category mage", loggedErrors[1].message)
      assert.are.equal("Cold Snap", map.mage[12472].name)
    end)
  end)

  describe("ApplyOne replace", function()
    it("replaces an existing spellId in the category", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { mage = { replace = { [12472] = { name = "Replaced Cold Snap" } } } })

      assert.are.equal(0, #loggedErrors)
      assert.are.equal("Replaced Cold Snap", map.mage[12472].name)
    end)

    it("logs and skips a replace for a missing spellId", function()
      local map = BuildBase()

      assembler.ApplyOne(map, { mage = { replace = { [424242] = { name = "Ghost" } } } })

      assert.are.equal(1, #loggedErrors)
      assert.matches("replace failed: spellId 424242 not present in category mage", loggedErrors[1].message)
      assert.are.same(BuildBase(), map)
    end)
  end)

  describe("ApplyOne appendRanks", function()
    it("appends new ranks onto an existing base entry", function()
      local map = BuildBase()

      assembler.ApplyOne(map, {
        mage = {
          appendRanks = { [12472] = { { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_TBC } } }
        }
      })

      assert.are.equal(0, #loggedErrors)
      assert.are.equal(2, #map.mage[12472].allRanks)
      assert.are.equal(999002, map.mage[12472].allRanks[2].spellId)
      assert.are.equal(RGCW_CONSTANTS.SPELL_TYPE_TBC, map.mage[12472].allRanks[2].type)
    end)

    it("clones appended rank entries instead of aliasing the overlay", function()
      local map = BuildBase()
      local rank = { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }

      assembler.ApplyOne(map, { mage = { appendRanks = { [12472] = { rank } } } })

      assert.are_not.equal(rank, map.mage[12472].allRanks[2])

      rank.spellId = 424242

      assert.are.equal(999002, map.mage[12472].allRanks[2].spellId)
    end)

    it("creates allRanks when the base entry has none", function()
      local map = BuildBase()

      assembler.ApplyOne(map, {
        mage = {
          appendRanks = { [11129] = { { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_BASE } } }
        }
      })

      assert.are.equal(0, #loggedErrors)
      assert.are.equal(1, #map.mage[11129].allRanks)
      assert.are.equal(999002, map.mage[11129].allRanks[1].spellId)
    end)

    it("logs and skips appendRanks for a missing base entry", function()
      local map = BuildBase()

      assembler.ApplyOne(map, {
        mage = {
          appendRanks = { [424242] = { { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_BASE } } }
        }
      })

      assert.are.equal(1, #loggedErrors)
      assert.matches("appendRanks failed: spellId 424242 not present in category mage", loggedErrors[1].message)
      assert.are.same(BuildBase(), map)
    end)

    it("logs and skips a rank already present in allRanks but keeps appending others", function()
      local map = BuildBase()

      assembler.ApplyOne(map, {
        mage = {
          appendRanks = {
            [12472] = {
              { spellId = 12472, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
              { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }
            }
          }
        }
      })

      assert.are.equal(1, #loggedErrors)
      assert.matches("appendRanks failed: spellId 12472 already in allRanks of 12472 in category mage",
        loggedErrors[1].message)
      assert.are.equal(2, #map.mage[12472].allRanks)
      assert.are.equal(999002, map.mage[12472].allRanks[2].spellId)
    end)

    it("logs and skips a malformed rank entry", function()
      local map = BuildBase()

      assembler.ApplyOne(map, {
        mage = {
          appendRanks = { [12472] = { { type = RGCW_CONSTANTS.SPELL_TYPE_BASE } } }
        }
      })

      assert.are.equal(1, #loggedErrors)
      assert.matches("appendRanks failed: malformed rank entry under spellId 12472 in category mage",
        loggedErrors[1].message)
      assert.are.equal(1, #map.mage[12472].allRanks)
    end)
  end)

  describe("Validate", function()
    it("returns ok for nil overlays", function()
      local ok, errs = assembler.Validate(BuildBase(), nil)

      assert.is_true(ok)
      assert.is_nil(errs)
    end)

    it("returns ok for overlays that only use valid ops", function()
      local overlays = {
        { mage = { add = { [999001] = { name = "New Spell" } } } },
        { mage = { replace = { [999001] = { name = "Second" } }, remove = { 11129 } } }
      }
      local ok, errs = assembler.Validate(BuildBase(), overlays)

      assert.is_true(ok)
      assert.is_nil(errs)
    end)

    it("collects every violation instead of stopping at the first", function()
      local overlays = {
        { mage = { remove = { 424242 }, add = { [12472] = { name = "Duplicate" } } } },
        {
          mage = {
            replace = { [424242] = { name = "Ghost" } },
            appendRanks = {
              [424243] = { { spellId = 999002 } },
              [12472] = {
                { spellId = 12472, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
                { type = RGCW_CONSTANTS.SPELL_TYPE_BASE }
              }
            }
          }
        }
      }
      local ok, errs = assembler.Validate(BuildBase(), overlays)

      assert.is_false(ok)
      assert.are.equal(6, #errs)

      local joined = table.concat(errs, "\n")

      assert.matches("overlay #1 mage.remove: spellId 424242 not present", joined)
      assert.matches("overlay #1 mage.add: spellId 12472 already exists", joined)
      assert.matches("overlay #2 mage.replace: spellId 424242 not present", joined)
      assert.matches("overlay #2 mage.appendRanks: spellId 424243 not present", joined)
      assert.matches("overlay #2 mage.appendRanks: spellId 12472 already in allRanks of 12472", joined)
      assert.matches("overlay #2 mage.appendRanks: malformed rank entry under spellId 12472", joined)
    end)

    it("does not mutate base or overlay tables", function()
      -- appendRanks deliberately targets both an added and a replaced spellId:
      -- those working-map entries came out of the overlay itself, so an
      -- un-cloned insert would stamp allRanks onto the overlay's own data
      local function BuildOverlays()
        return {
          {
            mage = {
              remove = { 11129 },
              add = { [999001] = { name = "New Spell" } },
              replace = { [12472] = { name = "Replaced Cold Snap" } },
              appendRanks = {
                [12472] = { { spellId = 999002, type = RGCW_CONSTANTS.SPELL_TYPE_BASE } },
                [999001] = { { spellId = 999003, type = RGCW_CONSTANTS.SPELL_TYPE_BASE } }
              }
            }
          }
        }
      end
      local base = BuildBase()
      local overlays = BuildOverlays()

      local ok = assembler.Validate(base, overlays)

      assert.is_true(ok)
      assert.are.same(BuildBase(), base)
      assert.are.same(BuildOverlays(), overlays)
    end)
  end)
end)

describe("SpellMap branch determination", function()
  local originalIsSodActive
  local originalIsTbcActive
  local previousTestHelper

  before_each(function()
    originalIsSodActive = rgcw.season.IsSodActive
    originalIsTbcActive = rgcw.season.IsTbcActive
    previousTestHelper = rgcw.testHelper
  end)

  after_each(function()
    rgcw.season.IsSodActive = originalIsSodActive
    rgcw.season.IsTbcActive = originalIsTbcActive
    rgcw.testHelper = previousTestHelper
  end)

  it("prefers the TEST-mode helper override over season detection", function()
    rgcw.season.IsTbcActive = function() return true end
    rgcw.season.IsSodActive = function() return true end
    rgcw.testHelper = { GetActiveBranch = function() return "classic" end }

    assert.are.equal("classic", rgcw.spellMap.GetActiveBranch())
  end)

  it("resolves tbc before sod when both seasons report active", function()
    rgcw.testHelper = nil
    rgcw.season.IsTbcActive = function() return true end
    rgcw.season.IsSodActive = function() return true end

    assert.are.equal("tbc", rgcw.spellMap.GetActiveBranch())
  end)

  it("resolves sod when only Season of Discovery is active", function()
    rgcw.testHelper = nil
    rgcw.season.IsSodActive = function() return true end

    assert.are.equal("sod", rgcw.spellMap.GetActiveBranch())
  end)

  it("falls back to classic when no branch season is active", function()
    rgcw.testHelper = nil

    assert.are.equal("classic", rgcw.spellMap.GetActiveBranch())
  end)
end)

describe("SpellMap per-branch assembly cache", function()
  local previousTestHelper
  local originalApply
  local originalGetTbcOverlay

  before_each(function()
    previousTestHelper = rgcw.testHelper
    originalApply = nil
    originalGetTbcOverlay = nil
  end)

  after_each(function()
    rgcw.testHelper = previousTestHelper

    if originalApply ~= nil then
      rgcw.spellMapAssembler.Apply = originalApply
    end

    if originalGetTbcOverlay ~= nil then
      rgcw.spellMapOverlayTbc.GetOverlay = originalGetTbcOverlay
    end
  end)

  it("builds a branch once and serves the cached map afterwards", function()
    rgcw.testHelper = { GetActiveBranch = function() return "classic" end }

    -- first access guarantees the classic entry is cached regardless of which
    -- specs ran before this one
    local first = rgcw.spellMap.GetSpellMap()
    local applyCalls = 0

    originalApply = rgcw.spellMapAssembler.Apply
    rgcw.spellMapAssembler.Apply = function(...)
      applyCalls = applyCalls + 1

      return originalApply(...)
    end

    local second = rgcw.spellMap.GetSpellMap()

    assert.are.equal(0, applyCalls)
    assert.are.equal(first, second)
  end)

  it("caches per branch and consults the branch overlay only on first build", function()
    -- first tbc request in the whole suite: the wrapped getter still returns
    -- the real (data-empty) overlay, so the cached tbc map matches production
    local overlayCalls = 0

    originalGetTbcOverlay = rgcw.spellMapOverlayTbc.GetOverlay
    rgcw.spellMapOverlayTbc.GetOverlay = function()
      overlayCalls = overlayCalls + 1

      return originalGetTbcOverlay()
    end

    rgcw.testHelper = { GetActiveBranch = function() return "tbc" end }

    local tbcFirst = rgcw.spellMap.GetSpellMap()
    local tbcSecond = rgcw.spellMap.GetSpellMap()

    rgcw.testHelper = { GetActiveBranch = function() return "classic" end }

    local classicMap = rgcw.spellMap.GetSpellMap()

    assert.are.equal(1, overlayCalls)
    assert.are.equal(tbcFirst, tbcSecond)
    assert.are_not.equal(classicMap, tbcFirst)
  end)
end)
