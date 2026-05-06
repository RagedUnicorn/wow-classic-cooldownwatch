--[[
  MIT License

  Copyright (c) 2025 Michael Wiesendanger

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
local TRACKED_EVENT = "SPELL_CAST_SUCCESS"

local PRIEST_BASE_SPELLS = {
  { spellId = 10890, name = "Psychic Scream" },
  { spellId = 19280, name = "Devouring Plague" },
  { spellId = 19293, name = "Elune's Grace" },
  { spellId = 6346,  name = "Fear Ward" },
  { spellId = 14751, name = "Inner Focus" },
  { spellId = 10947, name = "Mind Blast" },
  { spellId = 10060, name = "Power Infusion" },
  { spellId = 10901, name = "Power Word: Shield" },
  { spellId = 15487, name = "Silence" },
}

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
    { spellId = number, name = string }
]]--
local function VerifySpellTracking(testSpell)
  local testName = TestNameFor(testSpell.name)
  mod.testLogger.StartTest(testName)

  mod.cooldownQueue.ClearCooldownQueue()

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    mod.testLogger.EndTest(testName, false, "Failed to get player data")
    return
  end

  local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(testSpell.spellId, TRACKED_EVENT)

  if not spell then
    mod.testLogger.EndTest(testName, false,
      string.format("SearchBySpellId returned nil for spellId %d", testSpell.spellId))
    return
  end

  if category ~= CATEGORY then
    mod.testLogger.EndTest(testName, false,
      string.format("category '%s' (expected '%s')", tostring(category), CATEGORY))
    return
  end

  if realSpellId ~= testSpell.spellId then
    mod.testLogger.EndTest(testName, false,
      string.format("realSpellId %s (expected %d)", tostring(realSpellId), testSpell.spellId))
    return
  end

  if spell.name ~= testSpell.name then
    mod.testLogger.EndTest(testName, false,
      string.format("spell.name '%s' (expected '%s')", tostring(spell.name), testSpell.name))
    return
  end

  spell.castTime = GetTime()
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, category, spell)

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  for _, cd in pairs(cooldowns) do
    if cd.spellData.spellId == testSpell.spellId then
      mod.testLogger.EndTest(testName, true,
        string.format("Tracked '%s' (id %d, cooldown %ss)",
          testSpell.name, testSpell.spellId, tostring(cd.spellData.cooldown)))
      return
    end
  end

  mod.testLogger.EndTest(testName, false, "Cooldown not found in queue after AddCooldown")
end

--[[
  Test that a non-primary rank (Mind Blast rank 1, spellId 585) resolves through
  the refId chain to the primary spellId (10947) when SearchBySpellId is called.
]]--
function me.TestMindBlastRankResolution()
  local testName = "TestPriest_MindBlastRankResolution"
  mod.testLogger.StartTest(testName)

  local rankSpellId = 585
  local expectedPrimary = 10947

  local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(rankSpellId, TRACKED_EVENT)

  if not spell then
    mod.testLogger.EndTest(testName, false,
      string.format("SearchBySpellId returned nil for rank spellId %d", rankSpellId))
    return
  end

  if category ~= CATEGORY then
    mod.testLogger.EndTest(testName, false,
      string.format("category '%s' (expected '%s')", tostring(category), CATEGORY))
    return
  end

  if realSpellId ~= expectedPrimary then
    mod.testLogger.EndTest(testName, false,
      string.format("realSpellId %s (expected %d)", tostring(realSpellId), expectedPrimary))
    return
  end

  if spell.name ~= "Mind Blast" then
    mod.testLogger.EndTest(testName, false,
      string.format("spell.name '%s' (expected 'Mind Blast')", tostring(spell.name)))
    return
  end

  mod.testLogger.EndTest(testName, true,
    string.format("Rank spellId %d resolved to primary %d ('%s')",
      rankSpellId, realSpellId, spell.name))
end

--[[
  Run all priest spell tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("PriestSpells", "=== Running Priest Spell Tests ===")

  for _, testSpell in ipairs(PRIEST_BASE_SPELLS) do
    VerifySpellTracking(testSpell)
  end

  me.TestMindBlastRankResolution()

  mod.cooldownQueue.ClearCooldownQueue()

  mod.testLogger.LogInfo("PriestSpells", "=== Priest Spell Tests Complete ===")
end