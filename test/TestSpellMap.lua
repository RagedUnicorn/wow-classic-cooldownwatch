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

local mod = rgcw
local me = {}

mod.testSpellMap = me

me.tag = "TestSpellMap"

--[[
  Run a validator and report the result through testLogger. Validators live in
  mod.spellMapValidation and return a list of failure description strings.

  @param {string} testName
  @param {function} getFailures - Closure that returns the failures list
  @param {string} successMsg
  @param {string} failurePrefix - Used in both the LogError header and the
    EndTest summary, e.g. "unresolved refId(s)"
]]--
local function RunValidator(testName, getFailures, successMsg, failurePrefix)
  mod.testLogger.StartTest(testName)

  local failures = getFailures()

  if #failures == 0 then
    mod.testLogger.EndTest(testName, true, successMsg)
  else
    mod.testLogger.LogError(testName, failurePrefix, failures)
    mod.testLogger.EndTest(testName, false,
      string.format("%d %s", #failures, failurePrefix))
  end
end

function me.TestRefIdsResolve()
  RunValidator("TestRefIdsResolve",
    function()
      return mod.spellMapValidation.ValidateRefIdsResolve(mod.spellMap.GetSpellMap())
    end,
    "All refIds resolve to primary entries",
    "unresolved refId(s)")
end

function me.TestPrimaryAllRanksContainsSelf()
  RunValidator("TestPrimaryAllRanksContainsSelf",
    function()
      return mod.spellMapValidation.ValidatePrimaryAllRanksContainsSelf(mod.spellMap.GetSpellMap())
    end,
    "All primary entries appear in their own allRanks",
    "primary(ies) missing from their own allRanks")
end

function me.TestAllRanksConsistent()
  RunValidator("TestAllRanksConsistent",
    function()
      return mod.spellMapValidation.ValidateAllRanksConsistent(mod.spellMap.GetSpellMap())
    end,
    "All allRanks entries are consistent with their primary",
    "inconsistent allRanks entry(ies)")
end

function me.TestNoDuplicatePrimaryAcrossCategories()
  RunValidator("TestNoDuplicatePrimaryAcrossCategories",
    function()
      return mod.spellMapValidation.ValidateNoDuplicatePrimaryAcrossCategories(mod.spellMap.GetSpellMap())
    end,
    "No primary spellId appears in more than one category",
    "duplicate primary spellId(s)")
end

function me.TestSharedCooldownGroupsConsistent()
  RunValidator("TestSharedCooldownGroupsConsistent",
    function()
      return mod.spellMapValidation.ValidateSharedCooldownGroupsConsistent(
        mod.spellMap.GetSpellMap(),
        mod.spellMap.GetAllSharedCooldownGroups(),
        mod.spellMapHelper.GetSpellById)
    end,
    "All shared-cooldown groups are internally consistent",
    "shared-cooldown inconsistency(ies)")
end

function me.TestUnknownSpellIdReturnsNil()
  RunValidator("TestUnknownSpellIdReturnsNil",
    function()
      return mod.spellMapValidation.ValidateUnknownSpellIdReturnsNil(mod.spellMapHelper)
    end,
    "SearchBySpellId returns nil for an unknown spellId",
    "negative-lookup failure(s)")
end

function me.TestAliasRejectsMismatchedEvent()
  RunValidator("TestAliasRejectsMismatchedEvent",
    function()
      return mod.spellMapValidation.ValidateAliasRejectsMismatchedEvent(
        mod.spellMap.GetSpellMap(), mod.spellMapHelper)
    end,
    "Every alias entry returns nil for an event not in its primary's trackedEvents",
    "alias mismatched-event failure(s)")
end

function me.TestUnknownSharedCooldownGroupReturnsNil()
  RunValidator("TestUnknownSharedCooldownGroupReturnsNil",
    function()
      return mod.spellMapValidation.ValidateUnknownSharedCooldownGroupReturnsNil(
        mod.spellMap.GetSharedCooldownGroup)
    end,
    "GetSharedCooldownGroup returns nil for an unknown group name",
    "unknown-group failure(s)")
end

function me.TestUnknownCategoryReturnsEmpty()
  RunValidator("TestUnknownCategoryReturnsEmpty",
    function()
      return mod.spellMapValidation.ValidateUnknownCategoryReturnsEmpty(
        mod.testHelper.GetSpellsForCategory)
    end,
    "GetSpellsForCategory returns an empty array for an unknown category",
    "unknown-category failure(s)")
end

--[[
  Run all spellMap data-integrity tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("SpellMap", "=== Running SpellMap Tests ===")

  me.TestRefIdsResolve()
  me.TestPrimaryAllRanksContainsSelf()
  me.TestAllRanksConsistent()
  me.TestNoDuplicatePrimaryAcrossCategories()
  me.TestSharedCooldownGroupsConsistent()
  me.TestUnknownSpellIdReturnsNil()
  me.TestAliasRejectsMismatchedEvent()
  me.TestUnknownSharedCooldownGroupReturnsNil()
  me.TestUnknownCategoryReturnsEmpty()

  mod.testLogger.LogInfo("SpellMap", "=== SpellMap Tests Complete ===")
end

mod.testRunner.Register("spellmap", "spellMap data-integrity suite", me.RunAllTests)
