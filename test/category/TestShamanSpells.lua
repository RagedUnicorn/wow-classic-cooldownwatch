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

mod.testShamanSpells = me

me.tag = "TestShamanSpells"

local CATEGORY = "shaman"
local TRACKED_EVENT = "SPELL_CAST_SUCCESS"

local SHAMAN_BASE_SPELLS = {
  { spellId = 10414, name = "Earth Shock" },
  { spellId = 10473, name = "Frost Shock" },
  { spellId = 29228, name = "Flame Shock" },
  { spellId = 16166, name = "Elemental Mastery" },
  { spellId = 11315, name = "Fire Nova Totem" },
  { spellId = 8177,  name = "Grounding Totem" },
  { spellId = 2484,  name = "Earthbind Totem" },
  { spellId = 16188, name = "Nature's Swiftness" },
}

--[[
  Build a stable test name from a spell name (strips spaces and punctuation).

  @param {string} spellName

  @return {string}
]]--
local function TestNameFor(spellName)
  return "TestShaman_" .. (spellName:gsub("[^%w]", ""))
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
  Test that a non-primary rank (Earth Shock rank 1, spellId 8042) resolves
  through the refId chain to the primary spellId (10414).
]]--
function me.TestEarthShockRankResolution()
  local testName = "TestShaman_EarthShockRankResolution"
  mod.testLogger.StartTest(testName)

  local rankSpellId = 8042
  local expectedPrimary = 10414

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

  if spell.name ~= "Earth Shock" then
    mod.testLogger.EndTest(testName, false,
      string.format("spell.name '%s' (expected 'Earth Shock')", tostring(spell.name)))
    return
  end

  mod.testLogger.EndTest(testName, true,
    string.format("Rank spellId %d resolved to primary %d ('%s')",
      rankSpellId, realSpellId, spell.name))
end

--[[
  Test that casting one shock queues all three shocks via the shared-cooldown
  group. Drives CombatLog.TrackCooldown to exercise the production fan-out path.
]]--
function me.TestShockSharedCooldown()
  local testName = "TestShaman_ShockSharedCooldown"
  mod.testLogger.StartTest(testName)

  mod.cooldownQueue.ClearCooldownQueue()

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    mod.testLogger.EndTest(testName, false, "Failed to get player data")
    return
  end

  local _, _, frostShock = mod.spellMapHelper.SearchBySpellId(10473, TRACKED_EVENT)
  if not frostShock then
    mod.testLogger.EndTest(testName, false, "Frost Shock not found in spellMap")
    return
  end

  local castTime = GetTime()
  mod.combatLog.TrackCooldown(casterData.guid, casterData.name, frostShock, castTime, CATEGORY, nil)

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local seen = {}
  for _, cd in pairs(cooldowns) do
    seen[cd.spellData.spellId] = true
  end

  local expected = { 10414, 10473, 29228 }
  local missing = {}
  for _, spellId in ipairs(expected) do
    if not seen[spellId] then
      table.insert(missing, tostring(spellId))
    end
  end

  if #missing == 0 then
    mod.testLogger.EndTest(testName, true,
      "Frost Shock fan-out queued all three shocks (10414, 10473, 29228)")
  else
    mod.testLogger.EndTest(testName, false,
      "Missing shock(s) after fan-out: " .. table.concat(missing, ", "))
  end
end

--[[
  Run all shaman spell tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("ShamanSpells", "=== Running Shaman Spell Tests ===")

  for _, testSpell in ipairs(SHAMAN_BASE_SPELLS) do
    VerifySpellTracking(testSpell)
  end

  me.TestEarthShockRankResolution()
  me.TestShockSharedCooldown()

  mod.cooldownQueue.ClearCooldownQueue()

  mod.testLogger.LogInfo("ShamanSpells", "=== Shaman Spell Tests Complete ===")
end