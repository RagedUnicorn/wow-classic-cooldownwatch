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

-- luacheck: globals GetTime

local mod = rgcw
local me = {}

mod.testMageSpells = me

me.tag = "TestMageSpells"

local CATEGORY = "mage"

--[[
  Build a stable test name from a spell name (strips spaces and punctuation).

  @param {string} spellName

  @return {string}
]]--
local function TestNameFor(spellName)
  return "TestMage_" .. (spellName:gsub("[^%w]", ""))
end

--[[
  Run the SearchBySpellId -> AddCooldown -> GetCooldownsByTarget round-trip
  for one spell and assert the cooldown lands in the queue with the expected
  resolved spellId and name.

  Clears the cooldown queue first so each spell's test is isolated.

  @param {table} testSpell
    { spellId = number, name = string, trackedEvents = table }
  @param {string} trackedEvent
    One of the events declared on the spell entry in SpellMap.
]]--
local function VerifySpellTracking(testSpell, trackedEvent)
  local testName = TestNameFor(testSpell.name) .. "_" .. trackedEvent
  mod.testLogger.StartTest(testName)

  local casterData = mod.testHelper.GetTestCasterData()

  if not mod.testAssert.NotNil(testName, casterData, "Failed to get player data") then return end

  local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(testSpell.spellId, trackedEvent)

  if not mod.testAssert.NotNil(testName, spell,
    string.format("SearchBySpellId returned nil for spellId %d (event %s)",
      testSpell.spellId, trackedEvent)) then return end
  if not mod.testAssert.Equal(testName, category, CATEGORY, "category") then return end
  if not mod.testAssert.Equal(testName, realSpellId, testSpell.spellId, "realSpellId") then return end
  if not mod.testAssert.Equal(testName, spell.name, testSpell.name, "spell.name") then return end

  spell.castTime = GetTime()
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, category, spell)

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)

  for _, cd in pairs(cooldowns) do
    if cd.spellData.spellId == testSpell.spellId then
      mod.testLogger.EndTest(testName, true,
        string.format("Tracked '%s' (id %d, event %s, cooldown %ss)",
          testSpell.name, testSpell.spellId, trackedEvent, tostring(cd.spellData.cooldown)))
      return
    end
  end

  mod.testLogger.EndTest(testName, false, "Cooldown not found in queue after AddCooldown")
end

--[[
  Verify a non-primary rank resolves through the refId chain to the expected
  primary spellId. Pulled out as a local so the per-event loop in the public
  test function can early-return on assertion failure.

  @param {string} testName
  @param {number} rankSpellId
  @param {number} expectedPrimary
  @param {string} expectedName
  @param {string} trackedEvent
]]--
local function CheckRankResolution(testName, rankSpellId, expectedPrimary, expectedName, trackedEvent)
  local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(rankSpellId, trackedEvent)

  if not mod.testAssert.NotNil(testName, spell,
    string.format("SearchBySpellId returned nil for rank spellId %d (event %s)",
      rankSpellId, trackedEvent)) then return end
  if not mod.testAssert.Equal(testName, category, CATEGORY, "category") then return end
  if not mod.testAssert.Equal(testName, realSpellId, expectedPrimary, "realSpellId") then return end
  if not mod.testAssert.Equal(testName, spell.name, expectedName, "spell.name") then return end

  mod.testLogger.EndTest(testName, true,
    string.format("Rank spellId %d resolved to primary %d ('%s') via event %s",
      rankSpellId, realSpellId, spell.name, trackedEvent))
end

--[[
  Test that a non-primary rank (Fire Blast rank 1, spellId 2136) resolves through
  the refId chain to the primary spellId (10199). Fire Blast has the longest rank
  chain among the mage multi-rank spells (7 ranks).
]]--
function me.TestFireBlastRankResolution()
  local rankSpellId = 2136
  local expectedPrimary = 10199
  local primary = mod.spellMap.GetSpellMap()[CATEGORY][expectedPrimary]

  for _, trackedEvent in ipairs(primary.trackedEvents) do
    local testName = "TestMage_FireBlastRankResolution_" .. trackedEvent
    mod.testLogger.StartTest(testName)
    CheckRankResolution(testName, rankSpellId, expectedPrimary, "Fire Blast", trackedEvent)
  end
end

--[[
  Queue every cooldownResets target of a trigger spell, fire the reset, and
  assert every target is gone from the caster's queue. Targets are read from
  the trigger's SpellMap entry - never hardcoded. Pulled out as a local so the
  per-event loop in the public test function can early-return on assertion
  failure.

  @param {string} testName
  @param {number} triggerSpellId
  @param {string} trackedEvent
]]--
local function CheckCooldownResets(testName, triggerSpellId, trackedEvent)
  mod.cooldownQueue.ClearCooldownQueue()

  local casterData = mod.testHelper.GetTestCasterData()

  if not mod.testAssert.NotNil(testName, casterData, "Failed to get player data") then return end

  local _, _, triggerSpell = mod.spellMapHelper.SearchBySpellId(triggerSpellId, trackedEvent)

  if not mod.testAssert.NotNil(testName, triggerSpell,
    string.format("SearchBySpellId returned nil for spellId %d (event %s)",
      triggerSpellId, trackedEvent)) then return end
  if not mod.testAssert.NotNil(testName, triggerSpell.cooldownResets,
    string.format("Spell %d has no cooldownResets", triggerSpellId)) then return end

  for _, targetSpellId in ipairs(triggerSpell.cooldownResets) do
    local targetCategory, _, targetSpell = mod.spellMapHelper.GetSpellById(targetSpellId)

    if not mod.testAssert.NotNil(testName, targetSpell,
      string.format("GetSpellById returned nil for reset target %d", targetSpellId)) then return end

    targetSpell.castTime = GetTime()
    mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, targetCategory, targetSpell)
  end

  mod.combatLog.ResetTargetedCooldowns(casterData.guid, triggerSpell)

  local remaining = {}

  for _, cd in ipairs(mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)) do
    remaining[cd.spellData.spellId] = true
  end

  for _, targetSpellId in ipairs(triggerSpell.cooldownResets) do
    if remaining[targetSpellId] then
      mod.testLogger.EndTest(testName, false,
        string.format("Reset target %d is still in the queue after the reset", targetSpellId))
      return
    end
  end

  mod.testLogger.EndTest(testName, true,
    string.format("Reset %d queued cooldowns via '%s' (event %s)",
      #triggerSpell.cooldownResets, triggerSpell.name, trackedEvent))
end

--[[
  Test that Cold Snap clears the queued cooldowns of every spell listed in its
  cooldownResets (vanilla behavior: finishes the cooldown on all Frost spells,
  Fire Ward included via the shared ward cooldown timer).
]]--
function me.TestColdSnapResetsCooldowns()
  local coldSnapSpellId = 12472
  local primary = mod.spellMap.GetSpellMap()[CATEGORY][coldSnapSpellId]

  for _, trackedEvent in ipairs(primary.trackedEvents) do
    local testName = "TestMage_ColdSnap_ResetsCooldowns_" .. trackedEvent
    mod.testLogger.StartTest(testName)
    CheckCooldownResets(testName, coldSnapSpellId, trackedEvent)
  end
end

--[[
  Test that casting one ward queues both wards via the shared-cooldown group.
  Drives CombatLog.TrackCooldown to exercise the production fan-out path.
]]--
function me.TestWardSharedCooldown()
  local groupName = "mage_wards"
  local testName = "TestMage_WardSharedCooldown"
  mod.testLogger.StartTest(testName)

  local casterData = mod.testHelper.GetTestCasterData()

  if not mod.testAssert.NotNil(testName, casterData, "Failed to get player data") then return end

  local expected = mod.spellMap.GetSharedCooldownGroup(groupName)

  if not mod.testAssert.NotNil(testName, expected,
    string.format("Shared cooldown group '%s' missing in spellMap", groupName)) then return end
  if #expected == 0 then
    mod.testLogger.EndTest(testName, false,
      string.format("Shared cooldown group '%s' is empty", groupName))
    return
  end

  local triggerSpellId = expected[1]
  local triggerPrimary = mod.spellMap.GetSpellMap()[CATEGORY][triggerSpellId]

  if not mod.testAssert.NotNil(testName, triggerPrimary,
    string.format("Trigger spellId %d primary entry missing in spellMap", triggerSpellId)) then return end
  if not mod.testAssert.NotNil(testName, triggerPrimary.trackedEvents[1],
    string.format("Trigger spellId %d primary has no trackedEvents", triggerSpellId)) then return end

  local _, _, triggerSpell = mod.spellMapHelper.SearchBySpellId(triggerSpellId, triggerPrimary.trackedEvents[1])

  if not mod.testAssert.NotNil(testName, triggerSpell,
    string.format("Trigger spellId %d not found in spellMap", triggerSpellId)) then return end

  local castTime = GetTime()
  mod.combatLog.TrackCooldown(casterData.guid, casterData.name, triggerSpell, castTime, CATEGORY)

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local seen = {}

  for _, cd in pairs(cooldowns) do
    seen[cd.spellData.spellId] = true
  end

  local missing = {}

  for _, spellId in ipairs(expected) do
    if not seen[spellId] then
      table.insert(missing, tostring(spellId))
    end
  end

  if #missing == 0 then
    mod.testLogger.EndTest(testName, true,
      string.format("'%s' trigger %d fan-out queued all %d group members (%s)",
        groupName, triggerSpellId, #expected, table.concat(expected, ", ")))
  else
    mod.testLogger.EndTest(testName, false,
      string.format("'%s' missing member(s) after fan-out: %s", groupName, table.concat(missing, ", ")))
  end
end

--[[
  Run all mage spell tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("MageSpells", "=== Running Mage Spell Tests ===")

  for _, testSpell in ipairs(mod.testHelper.GetSpellsForCategory(CATEGORY)) do
    for _, trackedEvent in ipairs(testSpell.trackedEvents) do
      VerifySpellTracking(testSpell, trackedEvent)
    end
  end

  me.TestFireBlastRankResolution()
  me.TestColdSnapResetsCooldowns()
  me.TestWardSharedCooldown()

  mod.cooldownQueue.ClearCooldownQueue()

  mod.testLogger.LogInfo("MageSpells", "=== Mage Spell Tests Complete ===")
end

mod.testRunner.Register("magespells", "mage spell tracking suite", me.RunAllTests)
