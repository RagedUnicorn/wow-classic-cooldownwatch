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

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup
-- luacheck: ignore 143

describe("SpellMap data integrity", function()
  local spellMap
  local groups
  local getSpellById

  setup(function()
    spellMap     = rgcw.spellMap.GetSpellMap()
    groups       = rgcw.spellMap.GetAllSharedCooldownGroups()
    getSpellById = rgcw.spellMapHelper.GetSpellById
  end)

  it("every refId resolves to a primary entry", function()
    assert.same({}, rgcw.spellMapValidation.ValidateRefIdsResolve(spellMap))
  end)

  it("every allRanks entry is a structured { spellId, type } table", function()
    assert.same({}, rgcw.spellMapValidation.ValidateAllRanksStructured(spellMap))
  end)

  it("every primary appears in its own allRanks", function()
    assert.same({}, rgcw.spellMapValidation.ValidatePrimaryAllRanksContainsSelf(spellMap))
  end)

  it("allRanks members refId back to their primary", function()
    assert.same({}, rgcw.spellMapValidation.ValidateAllRanksConsistent(spellMap))
  end)

  it("no spellId is primary in more than one category", function()
    assert.same({}, rgcw.spellMapValidation.ValidateNoDuplicatePrimaryAcrossCategories(spellMap))
  end)

  it("shared-cooldown groups are internally consistent", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateSharedCooldownGroupsConsistent(spellMap, groups, getSpellById))
  end)

  it("SearchBySpellId returns nil for an unknown spellId", function()
    assert.same({}, rgcw.spellMapValidation.ValidateUnknownSpellIdReturnsNil(rgcw.spellMapHelper))
  end)

  it("alias entries return nil for an event not in their primary's trackedEvents", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateAliasRejectsMismatchedEvent(spellMap, rgcw.spellMapHelper))
  end)

  it("GetSharedCooldownGroup returns nil for an unknown group name", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateUnknownSharedCooldownGroupReturnsNil(rgcw.spellMap.GetSharedCooldownGroup))
  end)

  it("category catalog and SpellMap categories are in one-to-one correspondence", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateCategoriesMatchSpellMap(rgcw.categories.GetCategories(), spellMap))
  end)

  it("every cooldownWorstCase is strictly below its base cooldown", function()
    assert.same({}, rgcw.spellMapValidation.ValidateCooldownWorstCaseSane(spellMap))
  end)

  it("every cooldown and cooldownWorstCase is positive and at most 60 minutes", function()
    assert.same({}, rgcw.spellMapValidation.ValidateCooldownsWithinLimit(spellMap))
  end)

  it("every itemId is a positive integer on a primary entry", function()
    assert.same({}, rgcw.spellMapValidation.ValidateItemIdSane(spellMap))
  end)

  it("every petCast entry is a primary tracking exactly SPELL_CAST_SUCCESS", function()
    assert.same({}, rgcw.spellMapValidation.ValidatePetCastTrackedEvents(spellMap))
  end)

  it("every cooldownResets target is a primary and not the trigger itself", function()
    assert.same({}, rgcw.spellMapValidation.ValidateCooldownResetTargets(spellMap))
  end)

  it("every trackedEvents entry is an event CombatLog dispatches on", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateTrackedEventsSupported(spellMap, rgcw.combatLog.GetSupportedEvents()))
  end)

  it("base catalog carries only SPELL_TYPE_BASE entries (branch spells live in overlays)", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateBaseEntriesAreBaseType(rgcw.spellMapBase.GetMap()))
  end)

  it("base catalog carries no hand-written rank alias stubs (aliases are synthesized)", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateBaseHasNoHandWrittenRankAliases(rgcw.spellMapBase.GetMap()))
  end)
end)

--[[
  The same consistency checks, but run against the map assembled for EVERY
  branch, not just the active one - an overlay op that breaks a shared-cooldown
  group, drops a rank alias, or smuggles a wrong-branch type only surfaces in
  the branch it targets. Maps are assembled directly via the assembler (not the
  orchestrator) so the orchestrator's per-branch cache stays untouched - the
  sod cache entry is owned by SpellMapSodOverlaySpec.

  The event-aware helper validators (unknown-spellId / alias-event) stay in the
  active-map describe above: they go through mod.spellMapHelper, which always
  resolves against the active branch.
]]--
describe("SpellMap data integrity per assembled branch", function()
  local BRANCHES = { "classic", "sod", "tbc" }

  local function OverlaysForBranch(branch)
    if branch == "sod" then return { rgcw.spellMapOverlaySod.GetOverlay() } end
    if branch == "tbc" then return { rgcw.spellMapOverlayTbc.GetOverlay() } end

    return {}
  end

  --[[
    Branch-local stand-in for mod.spellMapHelper.GetSpellById: same
    category/realSpellId/entry contract, but resolving against the passed
    assembled map instead of the active branch's (and without season-gating,
    which would reject TBC-typed entries outside a TBC client).
  ]]--
  local function BuildGetSpellById(assembledMap)
    return function(spellId)
      for category, spells in pairs(assembledMap) do
        local entry = spells[spellId]

        if type(entry) == "table" then
          if type(entry.name) == "string" then
            return category, spellId, entry
          elseif type(entry.refId) == "number" and spells[entry.refId] ~= nil then
            return category, entry.refId, spells[entry.refId]
          end
        end
      end

      return nil
    end
  end

  for _, branch in ipairs(BRANCHES) do
    describe("branch " .. branch, function()
      local assembled
      local getSpellById

      setup(function()
        assembled = rgcw.spellMapAssembler.Apply(rgcw.spellMapBase.GetMap(), OverlaysForBranch(branch))
        -- mirror BuildAssembledMap: rank aliases are synthesized post-assembly,
        -- so the consistency validators below see what production sees
        rgcw.spellMap.SynthesizeRankAliases(assembled)
        getSpellById = BuildGetSpellById(assembled)
      end)

      it("every refId resolves to a primary entry", function()
        assert.same({}, rgcw.spellMapValidation.ValidateRefIdsResolve(assembled))
      end)

      it("every allRanks entry is a structured { spellId, type } table", function()
        assert.same({}, rgcw.spellMapValidation.ValidateAllRanksStructured(assembled))
      end)

      it("every primary appears in its own allRanks", function()
        assert.same({}, rgcw.spellMapValidation.ValidatePrimaryAllRanksContainsSelf(assembled))
      end)

      it("allRanks members refId back to their primary", function()
        assert.same({}, rgcw.spellMapValidation.ValidateAllRanksConsistent(assembled))
      end)

      it("no spellId is primary in more than one category", function()
        assert.same({}, rgcw.spellMapValidation.ValidateNoDuplicatePrimaryAcrossCategories(assembled))
      end)

      it("shared-cooldown groups are internally consistent", function()
        assert.same({}, rgcw.spellMapValidation.ValidateSharedCooldownGroupsConsistent(
          assembled, rgcw.spellMap.GetAllSharedCooldownGroups(), getSpellById))
      end)

      it("category catalog and SpellMap categories are in one-to-one correspondence", function()
        assert.same({}, rgcw.spellMapValidation.ValidateCategoriesMatchSpellMap(
          rgcw.categories.GetCategories(), assembled))
      end)

      it("every cooldownWorstCase is strictly below its base cooldown", function()
        assert.same({}, rgcw.spellMapValidation.ValidateCooldownWorstCaseSane(assembled))
      end)

      it("every cooldown and cooldownWorstCase is positive and at most 60 minutes", function()
        assert.same({}, rgcw.spellMapValidation.ValidateCooldownsWithinLimit(assembled))
      end)

      it("every cooldownResets target is a primary and not the trigger itself", function()
        assert.same({}, rgcw.spellMapValidation.ValidateCooldownResetTargets(assembled))
      end)

      it("every itemId is a positive integer on a primary entry", function()
        assert.same({}, rgcw.spellMapValidation.ValidateItemIdSane(assembled))
      end)

      it("every petCast entry is a primary tracking exactly SPELL_CAST_SUCCESS", function()
        assert.same({}, rgcw.spellMapValidation.ValidatePetCastTrackedEvents(assembled))
      end)

      it("every trackedEvents entry is an event CombatLog dispatches on", function()
        assert.same({}, rgcw.spellMapValidation.ValidateTrackedEventsSupported(
          assembled, rgcw.combatLog.GetSupportedEvents()))
      end)

      it("every spell type is allowed on the branch", function()
        assert.same({}, rgcw.spellMapValidation.ValidateSpellTypesMatchBranch(assembled, branch))
      end)
    end)
  end
end)

--[[
  Negative fixtures for ValidateSpellTypesMatchBranch. The per-branch runs
  above can only ever pass while the overlays are data-empty, so these
  synthetic maps prove the validator actually rejects wrong-branch types.
]]--
describe("ValidateSpellTypesMatchBranch rejections", function()
  local function BuildMap(primaryType, rankType)
    return {
      priest = {
        [999001] = {
          name = "Branch Fixture Spell",
          type = primaryType,
          cooldown = 30,
          active = true,
          trackedEvents = { "SPELL_CAST_SUCCESS" },
          allRanks = {
            { spellId = 999001, type = rankType }
          }
        }
      }
    }
  end

  it("rejects a SoD-typed primary on the classic branch", function()
    local failures = rgcw.spellMapValidation.ValidateSpellTypesMatchBranch(
      BuildMap(RGCW_CONSTANTS.SPELL_TYPE_SOD, RGCW_CONSTANTS.SPELL_TYPE_BASE), "classic")

    assert.equal(1, #failures)
    assert.matches("type SPELL_TYPE_SOD is not allowed on the classic branch", failures[1])
  end)

  it("rejects a TBC-typed rank on the sod branch", function()
    local failures = rgcw.spellMapValidation.ValidateSpellTypesMatchBranch(
      BuildMap(RGCW_CONSTANTS.SPELL_TYPE_BASE, RGCW_CONSTANTS.SPELL_TYPE_TBC), "sod")

    assert.equal(1, #failures)
    assert.matches("allRanks%[1%].type SPELL_TYPE_TBC is not allowed on the sod branch", failures[1])
  end)

  it("rejects a primary with an unknown type on every branch", function()
    local failures = rgcw.spellMapValidation.ValidateSpellTypesMatchBranch(
      BuildMap("SPELL_TYPE_BOGUS", RGCW_CONSTANTS.SPELL_TYPE_BASE), "tbc")

    assert.equal(1, #failures)
    assert.matches("type SPELL_TYPE_BOGUS is not allowed on the tbc branch", failures[1])
  end)

  it("accepts branch-typed entries on their own branch", function()
    assert.same({}, rgcw.spellMapValidation.ValidateSpellTypesMatchBranch(
      BuildMap(RGCW_CONSTANTS.SPELL_TYPE_SOD, RGCW_CONSTANTS.SPELL_TYPE_SOD), "sod"))
  end)

  it("reports an unknown branch instead of validating against nothing", function()
    local failures = rgcw.spellMapValidation.ValidateSpellTypesMatchBranch(
      BuildMap(RGCW_CONSTANTS.SPELL_TYPE_BASE, RGCW_CONSTANTS.SPELL_TYPE_BASE), "wrath")

    assert.equal(1, #failures)
    assert.matches("unknown branch 'wrath'", failures[1])
  end)
end)
