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

mod.testRogueSpells = me

me.tag = "TestRogueSpells"

local CATEGORY = "rogue"

--[[
  Build a stable test name from a spell name (strips spaces and punctuation).

  @param {string} spellName

  @return {string}
]]--
local function TestNameFor(spellName)
  return "TestRogue_" .. (spellName:gsub("[^%w]", ""))
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

  if not casterData then
    mod.testLogger.EndTest(testName, false, "Failed to get player data")
    return
  end

  local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(testSpell.spellId, trackedEvent)

  if not spell then
    mod.testLogger.EndTest(testName, false,
      string.format("SearchBySpellId returned nil for spellId %d (event %s)",
        testSpell.spellId, trackedEvent))
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
        string.format("Tracked '%s' (id %d, event %s, cooldown %ss)",
          testSpell.name, testSpell.spellId, trackedEvent, tostring(cd.spellData.cooldown)))
      return
    end
  end

  mod.testLogger.EndTest(testName, false, "Cooldown not found in queue after AddCooldown")
end

--[[
  Test that a non-primary rank (Kick rank 1, spellId 1766) resolves through the
  refId chain to the primary spellId (1769). Kick has the most directly
  Wowhead-verified rank chain among the rogue multi-rank spells.
]]--
function me.TestKickRankResolution()
  local rankSpellId = 1766
  local expectedPrimary = 1769
  local primary = mod.spellMap.GetSpellMap()[CATEGORY][expectedPrimary]

  for _, trackedEvent in ipairs(primary.trackedEvents) do
    local testName = "TestRogue_KickRankResolution_" .. trackedEvent
    mod.testLogger.StartTest(testName)

    local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(rankSpellId, trackedEvent)

    if not spell then
      mod.testLogger.EndTest(testName, false,
        string.format("SearchBySpellId returned nil for rank spellId %d (event %s)",
          rankSpellId, trackedEvent))
    elseif category ~= CATEGORY then
      mod.testLogger.EndTest(testName, false,
        string.format("category '%s' (expected '%s')", tostring(category), CATEGORY))
    elseif realSpellId ~= expectedPrimary then
      mod.testLogger.EndTest(testName, false,
        string.format("realSpellId %s (expected %d)", tostring(realSpellId), expectedPrimary))
    elseif spell.name ~= "Kick" then
      mod.testLogger.EndTest(testName, false,
        string.format("spell.name '%s' (expected 'Kick')", tostring(spell.name)))
    else
      mod.testLogger.EndTest(testName, true,
        string.format("Rank spellId %d resolved to primary %d ('%s') via event %s",
          rankSpellId, realSpellId, spell.name, trackedEvent))
    end
  end
end

--[[
  Run all rogue spell tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("RogueSpells", "=== Running Rogue Spell Tests ===")

  for _, testSpell in ipairs(mod.testHelper.GetSpellsForCategory(CATEGORY)) do
    for _, trackedEvent in ipairs(testSpell.trackedEvents) do
      VerifySpellTracking(testSpell, trackedEvent)
    end
  end

  me.TestKickRankResolution()

  mod.cooldownQueue.ClearCooldownQueue()

  mod.testLogger.LogInfo("RogueSpells", "=== Rogue Spell Tests Complete ===")
end
