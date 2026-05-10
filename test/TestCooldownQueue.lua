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

mod.testCooldownQueue = me

me.tag = "TestCooldownQueue"

--[[
  Test adding a cooldown to the queue

  @param {boolean} skipHint - Optional flag to skip showing targeting hint
]]--
function me.TestAddCooldown(skipHint)
  mod.testLogger.StartTest("TestAddCooldown")
  mod.testLogger.LogInfo("TestAddCooldown", "Testing: Add cooldown to queue")

  if not skipHint then
    mod.testHelper.ShowTargetingHint()
  end

  local casterData = mod.testHelper.GetTestCasterData()

  if not casterData then
    mod.testLogger.LogError("TestAddCooldown", "Failed to get player data")
    mod.testLogger.EndTest("TestAddCooldown", false, "Failed to get player data")
    return
  end

  local spell = mod.testHelper.CreateTestSpell(10947, "Mind Blast", 8, 8)

  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, "priest", spell)

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local found = false

  for _, cooldown in pairs(cooldowns) do
    if cooldown.spellData.spellId == spell.spellId then
      found = true
      mod.testLogger.LogInfo("TestAddCooldown", "Cooldown found in queue", {
        caster = cooldown.casterName,
        spell = cooldown.spellData.name,
        cooldown = cooldown.spellData.cooldown .. "s"
      })
      break
    end
  end

  if found then
    mod.testLogger.EndTest("TestAddCooldown", true, "Cooldown added successfully")
  else
    mod.testLogger.EndTest("TestAddCooldown", false, "Failed to add cooldown")
  end
end

--[[
  Test adding multiple cooldowns

  @param {boolean} skipHint - Optional flag to skip showing targeting hint
]]--
function me.TestAddMultipleCooldowns(skipHint)
  mod.testLogger.StartTest("TestAddMultipleCooldowns")
  mod.testLogger.LogInfo("TestAddMultipleCooldowns", "Testing: Add multiple cooldowns")

  if not skipHint then
    mod.testHelper.ShowTargetingHint()
  end

  local casterData = mod.testHelper.GetTestCasterData()

  if not casterData then
    mod.testLogger.LogError("TestAddMultipleCooldowns", "Failed to get player data")
    mod.testLogger.EndTest("TestAddMultipleCooldowns", false, "Failed to get player data")
    return
  end

  local testSpells = {
    mod.testHelper.CreateTestSpell(
      122,
      "Frost Nova",
      25,
      21,
      0
    ),
    mod.testHelper.CreateTestSpell(
      2139,
      "Counterspell",
      24,
      20,
      1
    ),
    mod.testHelper.CreateTestSpell(
      120,
      "Cone of Cold",
      10,
      10,
      2
    )
  }

  -- Add all cooldowns using player's GUID
  for _, spell in ipairs(testSpells) do
    mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, "mage", spell)
  end

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local foundCount = 0

  for _, spell in ipairs(testSpells) do
    for _, cooldown in pairs(cooldowns) do
      if cooldown.spellData.spellId == spell.spellId then
        foundCount = foundCount + 1
        break
      end
    end
  end

  if foundCount == #testSpells then
    mod.testLogger.EndTest("TestAddMultipleCooldowns", true,
      "All " .. foundCount .. " cooldowns added successfully")
  else
    mod.testLogger.EndTest("TestAddMultipleCooldowns", false,
      "Only " .. foundCount .. "/" .. #testSpells .. " cooldowns were added")
  end
end

--[[
  Test duplicate cooldown handling

  @param {boolean} skipHint - Optional flag to skip showing targeting hint
]]--
function me.TestDuplicateCooldown(skipHint)
  mod.testLogger.StartTest("TestDuplicateCooldown")
  mod.testLogger.LogInfo("TestDuplicateCooldown", "Testing: Duplicate cooldown handling")

  if not skipHint then
    mod.testHelper.ShowTargetingHint()
  end

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    mod.testLogger.LogError("TestDuplicateCooldown", "Failed to get player data")
    mod.testLogger.EndTest("TestDuplicateCooldown", false, "Failed to get player data")
    return
  end

  local spell = mod.testHelper.CreateTestSpell(
    5484,
    "Howl of Terror",
    40,
    40
  )

  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, "warlock", spell)

  local updatedSpell = mod.testHelper.CreateTestSpell(
    5484,
    "Howl of Terror",
    40,
    40,
    5
  )
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, "warlock", updatedSpell)

  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local count = 0
  local lastCastTime = nil

  for _, cooldown in pairs(cooldowns) do
    if cooldown.spellData.spellId == spell.spellId then
      count = count + 1
      lastCastTime = cooldown.spellData.castTime
    end
  end

  if count == 1 then
    mod.testLogger.LogInfo(
      "TestDuplicateCooldown",
      "Duplicate prevented - only 1 instance exists"
    )

    if lastCastTime == updatedSpell.castTime then
      mod.testLogger.LogInfo(
        "TestDuplicateCooldown",
        "Cooldown was updated with new cast time"
      )
    end

    mod.testLogger.EndTest(
      "TestDuplicateCooldown",
      true,
      "Duplicate cooldown handling working correctly"
    )
  else
    mod.testLogger.EndTest(
      "TestDuplicateCooldown",
      false,
      "Found " .. count .. " instances (expected 1)"
    )
  end
end

--[[
  Test removing specific cooldowns

  @param {boolean} skipHint - Optional flag to skip showing targeting hint
]]--
function me.TestRemoveCooldown(skipHint)
  mod.testLogger.StartTest("TestRemoveCooldown")
  mod.testLogger.LogInfo("TestRemoveCooldown", "Testing: Remove specific cooldown")

  if not skipHint then
    mod.testHelper.ShowTargetingHint()
  end

  local casterData = mod.testHelper.GetTestCasterData()

  if not casterData then
    mod.testLogger.LogError("TestRemoveCooldown", "Failed to get player data")
    mod.testLogger.EndTest("TestRemoveCooldown", false, "Failed to get player data")
    return
  end

  local spell = mod.testHelper.CreateTestSpell(1766, "Kick", 10, 10)

  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, "rogue", spell)

  local cooldownsBefore = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local foundBefore = false

  for _, cooldown in pairs(cooldownsBefore) do
    if cooldown.spellData.spellId == spell.spellId then
      foundBefore = true
      break
    end
  end

  if foundBefore then
    mod.cooldownQueue.RemoveCooldown(casterData.guid, spell.spellId)

    local cooldownsAfter = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
    local foundAfter = false

    for _, cooldown in pairs(cooldownsAfter) do
      if cooldown.spellData.spellId == spell.spellId then
        foundAfter = true
        break
      end
    end

    if not foundAfter then
      mod.testLogger.EndTest("TestRemoveCooldown", true, "Cooldown removed successfully")
    else
      mod.testLogger.EndTest("TestRemoveCooldown", false, "Failed to remove cooldown")
    end
  else
    mod.testLogger.EndTest("TestRemoveCooldown", false, "Failed to add test cooldown")
  end
end

--[[
  Clear all test cooldowns from the queue
]]--
function me.ClearTestCooldowns()
  mod.logger.LogDebug(me.tag, "Clearing all cooldowns from the queue")

  local cooldownsBefore = mod.cooldownQueue.GetCooldownsByTarget(mod.testHelper.GetPlayerGUID() or "unknown")
  local initialCount = #cooldownsBefore

  mod.cooldownQueue.ClearCooldownQueue()

  local cooldownsAfter = mod.cooldownQueue.GetCooldownsByTarget(mod.testHelper.GetPlayerGUID() or "unknown")
  local remainingCount = #cooldownsAfter

  mod.logger.LogDebug(me.tag, "Cooldowns before: " .. initialCount .. ", after: " .. remainingCount)
end

--[[
  Run all cooldown queue tests
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("CooldownQueue", "=== Running CooldownQueue Tests ===")

  mod.testHelper.ShowTargetingHint()

  me.TestAddCooldown(true)
  me.TestAddMultipleCooldowns(true)
  me.TestDuplicateCooldown(true)
  me.TestRemoveCooldown(true)
  me.ClearTestCooldowns()

  mod.testLogger.LogInfo("CooldownQueue", "=== CooldownQueue Tests Complete ===")
end

mod.testRunner.Register("cooldownqueue", "cooldown queue suite", me.RunAllTests)
