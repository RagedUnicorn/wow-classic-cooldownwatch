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
  End-to-end proof of the SoD overlay path: a synthetic SoD overlay
  stubbed onto mod.spellMapOverlaySod flows through the orchestrator - branch
  detection via the mod.testHelper.GetActiveBranch seam, overlay pickup,
  assembly, and post-assembly normalizedSpellName decoration - and surfaces
  only on the "sod" branch. The per-op assembler matrix (remove/add/replace/
  appendRanks against Apply directly), branch precedence, and the per-branch
  cache belong to a dedicated assembler spec, not here.

  The "sod" entry of the orchestrator's per-branch cache is built from the
  synthetic overlay and stays cached for the rest of the busted run; no other
  spec requests the sod branch.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup teardown
-- luacheck: ignore 143

describe("SpellMap SoD overlay assembly path", function()
  -- deliberately outside any real spellId range - asserted absent from the base in setup
  local FAKE_SOD_SPELL_ID = 999001
  local FAKE_SOD_SPELL_NAME = "Busted Sod Test Spell"

  local realGetOverlay
  local previousTestHelper
  local reworkedPrimaryId
  local reworkedPrimaryBaseCooldown
  local sodCooldown

  setup(function()
    local base = rgcw.spellMapBase.GetMap()

    assert.is_nil(base.priest[FAKE_SOD_SPELL_ID])

    -- lowest priest primary as the SoD-rework fixture - deterministic, no hardcoded spellId
    for spellId, entry in pairs(base.priest) do
      if type(entry.name) == "string" and (reworkedPrimaryId == nil or spellId < reworkedPrimaryId) then
        reworkedPrimaryId = spellId
      end
    end

    reworkedPrimaryBaseCooldown = base.priest[reworkedPrimaryId].cooldown
    sodCooldown = reworkedPrimaryBaseCooldown + 17

    local reworkedEntry = rgcw.common.Clone(base.priest[reworkedPrimaryId])
    reworkedEntry.type = RGCW_CONSTANTS.SPELL_TYPE_SOD
    reworkedEntry.cooldown = sodCooldown

    realGetOverlay = rgcw.spellMapOverlaySod.GetOverlay
    rgcw.spellMapOverlaySod.GetOverlay = function()
      return {
        priest = {
          add = {
            [FAKE_SOD_SPELL_ID] = {
              name = FAKE_SOD_SPELL_NAME,
              type = RGCW_CONSTANTS.SPELL_TYPE_SOD,
              cooldown = 42,
              active = true,
              trackedEvents = {
                "SPELL_CAST_SUCCESS"
              },
              allRanks = {
                { spellId = FAKE_SOD_SPELL_ID, type = RGCW_CONSTANTS.SPELL_TYPE_SOD },
              }
            }
          },
          replace = {
            [reworkedPrimaryId] = reworkedEntry
          }
        }
      }
    end

    previousTestHelper = rgcw.testHelper
  end)

  teardown(function()
    rgcw.spellMapOverlaySod.GetOverlay = realGetOverlay
    rgcw.testHelper = previousTestHelper
  end)

  it("keeps SoD overlay entries out of the classic branch", function()
    rgcw.testHelper = { GetActiveBranch = function() return "classic" end }

    local classicMap = rgcw.spellMap.GetSpellMap()

    assert.is_nil(classicMap.priest[FAKE_SOD_SPELL_ID])
    assert.equal(reworkedPrimaryBaseCooldown, classicMap.priest[reworkedPrimaryId].cooldown)
  end)

  it("surfaces overlay add and replace ops on the sod branch", function()
    rgcw.testHelper = { GetActiveBranch = function() return "sod" end }

    local sodMap = rgcw.spellMap.GetSpellMap()
    local added = sodMap.priest[FAKE_SOD_SPELL_ID]

    assert.is_table(added)
    assert.equal(RGCW_CONSTANTS.SPELL_TYPE_SOD, added.type)
    -- post-assembly decoration must cover overlay-added entries (runs in the
    -- orchestrator, not in Base, for exactly this reason)
    assert.equal(rgcw.common.NormalizeSpellName(FAKE_SOD_SPELL_NAME), added.normalizedSpellName)
    assert.equal(sodCooldown, sodMap.priest[reworkedPrimaryId].cooldown)
  end)

  it("leaves the base catalog untouched by sod assembly", function()
    local base = rgcw.spellMapBase.GetMap()

    assert.is_nil(base.priest[FAKE_SOD_SPELL_ID])
    assert.equal(reworkedPrimaryBaseCooldown, base.priest[reworkedPrimaryId].cooldown)
  end)
end)
