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

mod.testPriestSpells = me

me.tag = "TestPriestSpells"

local CATEGORY = "priest"

--[[
  Build a stable test name from a spell name (strips spaces and punctuation).

  @param {string} spellName

  @return {string}
]]--
local function TestNameFor(spellName)
  return "TestPriest_" .. (spellName:gsub("[^%w]", ""))
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

  mod.cooldownQueue.ClearCooldownQueue()

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
  Test that a non-primary rank (Mind Blast rank 1, spellId 585) resolves through
  the refId chain to the primary spellId (10947) when SearchBySpellId is called.
]]--
function me.TestMindBlastRankResolution()
  local rankSpellId = 585
  local expectedPrimary = 10947
  local primary = mod.spellMap.GetSpellMap()[CATEGORY][expectedPrimary]

  for _, trackedEvent in ipairs(primary.trackedEvents) do
    local testName = "TestPriest_MindBlastRankResolution_" .. trackedEvent
    mod.testLogger.StartTest(testName)
    CheckRankResolution(testName, rankSpellId, expectedPrimary, "Mind Blast", trackedEvent)
  end
end

--[[
  Run all priest spell tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("PriestSpells", "=== Running Priest Spell Tests ===")

  for _, testSpell in ipairs(mod.testHelper.GetSpellsForCategory(CATEGORY)) do
    for _, trackedEvent in ipairs(testSpell.trackedEvents) do
      VerifySpellTracking(testSpell, trackedEvent)
    end
  end

  me.TestMindBlastRankResolution()

  mod.cooldownQueue.ClearCooldownQueue()

  mod.testLogger.LogInfo("PriestSpells", "=== Priest Spell Tests Complete ===")
end

mod.testRunner.Register("priestspells", "priest spell tracking suite", me.RunAllTests)
