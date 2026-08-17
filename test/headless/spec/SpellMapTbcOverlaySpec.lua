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
  End-to-end proof of the REAL TBC overlay: the shipped
  code/spellmap/overlay/Tbc.lua data (no synthetic stub) flows through the
  orchestrator - branch detection via the mod.testHelper.GetActiveBranch seam,
  overlay pickup, assembly, rank-alias synthesis, and normalizedSpellName
  decoration - and surfaces only on the "tbc" branch. Every expectation is
  derived from the overlay's own add/replace/appendRanks ops, so overlay
  blocks added for further categories are covered without spec edits. The per-op assembler
  matrix and the per-branch cache belong to SpellMapAssemblerSpec, the
  per-branch consistency validators to SpellMapSpec.

  The orchestrator's "tbc" cache entry is shared with SpellMapAssemblerSpec:
  both build it from the real overlay, so the cached map is identical no
  matter which spec builds it first. (Busted loads spec files sorted, so the
  assembler spec's "first tbc request in the whole suite" counter still holds.)
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup teardown
-- luacheck: ignore 143

describe("SpellMap TBC overlay assembly path", function()
  local overlay
  local previousTestHelper

  --[[
    Whether an allRanks list contains a rank entry for the passed spellId.

    @param {table} allRanks
    @param {number} spellId

    @return {boolean}
  ]]--
  local function HasRank(allRanks, spellId)
    for _, rank in ipairs(allRanks) do
      if rank.spellId == spellId then return true end
    end

    return false
  end

  setup(function()
    overlay = rgcw.spellMapOverlayTbc.GetOverlay()

    -- the pilot populated the warrior block; an emptied overlay would turn
    -- every loop below into a silent no-op pass
    assert.is_table(overlay.warrior)

    previousTestHelper = rgcw.testHelper
  end)

  teardown(function()
    rgcw.testHelper = previousTestHelper
  end)

  it("keeps TBC overlay entries out of the classic branch", function()
    rgcw.testHelper = { GetActiveBranch = function() return "classic" end }

    local classicMap = rgcw.spellMap.GetSpellMap()

    for category, ops in pairs(overlay) do
      for spellId in pairs(ops.add or {}) do
        assert.is_nil(classicMap[category][spellId])
      end

      for spellId in pairs(ops.replace or {}) do
        assert.equal(RGCW_CONSTANTS.SPELL_TYPE_BASE, classicMap[category][spellId].type)
        assert.equal(
          rgcw.spellMapBase.GetMap()[category][spellId].cooldown,
          classicMap[category][spellId].cooldown
        )
      end

      for baseSpellId, ranks in pairs(ops.appendRanks or {}) do
        for _, rank in ipairs(ranks) do
          assert.is_false(HasRank(classicMap[category][baseSpellId].allRanks, rank.spellId))
          assert.is_nil(classicMap[category][rank.spellId])
        end
      end
    end
  end)

  it("surfaces overlay add and replace ops on the tbc branch with decoration", function()
    rgcw.testHelper = { GetActiveBranch = function() return "tbc" end }

    local tbcMap = rgcw.spellMap.GetSpellMap()

    for category, ops in pairs(overlay) do
      for _, opName in ipairs({ "add", "replace" }) do
        for spellId, overlayEntry in pairs(ops[opName] or {}) do
          local assembled = tbcMap[category][spellId]

          assert.is_table(assembled)
          assert.equal(RGCW_CONSTANTS.SPELL_TYPE_TBC, assembled.type)
          assert.equal(overlayEntry.cooldown, assembled.cooldown)
          -- post-assembly decoration must cover overlay-added entries (runs
          -- in the orchestrator, not in Base, for exactly this reason)
          assert.equal(rgcw.common.NormalizeSpellName(overlayEntry.name), assembled.normalizedSpellName)
        end
      end
    end
  end)

  it("appends TBC reranks and synthesizes their rank aliases on the tbc branch", function()
    rgcw.testHelper = { GetActiveBranch = function() return "tbc" end }

    local tbcMap = rgcw.spellMap.GetSpellMap()

    for category, ops in pairs(overlay) do
      for baseSpellId, ranks in pairs(ops.appendRanks or {}) do
        for _, rank in ipairs(ranks) do
          assert.is_true(HasRank(tbcMap[category][baseSpellId].allRanks, rank.spellId))
          -- SynthesizeRankAliases runs post-assembly, so appended ranks gain
          -- their { refId } alias like any base rank
          assert.same({ refId = baseSpellId }, tbcMap[category][rank.spellId])
        end
      end
    end
  end)

  it("leaves the base catalog untouched by tbc assembly", function()
    local base = rgcw.spellMapBase.GetMap()

    for category, ops in pairs(overlay) do
      for spellId in pairs(ops.add or {}) do
        assert.is_nil(base[category][spellId])
      end

      -- a replaced primary carries SPELL_TYPE_TBC in the overlay; the base
      -- entry keeping SPELL_TYPE_BASE proves Apply cloned instead of mutating
      for spellId in pairs(ops.replace or {}) do
        assert.equal(RGCW_CONSTANTS.SPELL_TYPE_BASE, base[category][spellId].type)
      end

      for baseSpellId, ranks in pairs(ops.appendRanks or {}) do
        for _, rank in ipairs(ranks) do
          assert.is_false(HasRank(base[category][baseSpellId].allRanks, rank.spellId))
        end
      end
    end
  end)
end)
