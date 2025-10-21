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

mod.testCooldownQueue = me

me.tag = "TestCooldownQueue"

--[[
  Test adding a cooldown to the queue
]]--
function me.TestAddCooldown()
  mod.testLogger.LogInfo("TestAddCooldown", "Testing: Add cooldown to queue")

  -- Show targeting hint
  mod.testHelper.ShowTargetingHint()

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    mod.testLogger.LogError("TestAddCooldown", "Failed to get player data")
    return
  end

  local spell = mod.testHelper.CreateTestSpell(2094, "Blind", 120, 90)

  -- Add the cooldown
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, spell)

  -- Verify it was added
  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local found = false

  for _, cooldown in pairs(cooldowns) do
    if cooldown.spell.spellId == spell.spellId then
      found = true
      mod.testLogger.LogSuccess("TestAddCooldown", "Cooldown added successfully", {
        caster = cooldown.casterName,
        spell = cooldown.spell.spellName,
        cooldown = cooldown.spell.cooldown .. "s"
      })
      break
    end
  end

  if not found then
    mod.testLogger.LogFail("TestAddCooldown", "Failed to add cooldown")
  end
end

--[[
  Test adding multiple cooldowns
]]--
function me.TestAddMultipleCooldowns()
  print("|cFFFFFF00Testing: Add multiple cooldowns|r")

  -- Show targeting hint
  mod.testHelper.ShowTargetingHint()

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    print("|cFFFF0000Failed to get player data|r")
    return
  end

  local testSpells = {
    mod.testHelper.CreateTestSpell(122, "Frost Nova", 25, 21, 0),
    mod.testHelper.CreateTestSpell(6789, "Death Coil", 120, 120, 1),
    mod.testHelper.CreateTestSpell(8122, "Psychic Scream", 30, 26, 2)
  }

  -- Add all cooldowns using player's GUID
  for _, spell in ipairs(testSpells) do
    mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, spell)
  end

  -- Verify they were added
  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local foundCount = 0

  for _, spell in ipairs(testSpells) do
    for _, cooldown in pairs(cooldowns) do
      if cooldown.spell.spellId == spell.spellId then
        foundCount = foundCount + 1
        print("|cFF00FF00  [PASS] Found: " .. cooldown.casterName .. " - " .. cooldown.spell.spellName .. "|r")
        break
      end
    end
  end

  if foundCount == #testSpells then
    print("|cFF00FF00  All " .. foundCount .. " cooldowns added successfully|r")
  else
    print("|cFFFF0000  [FAIL] Only " .. foundCount .. "/" .. #testSpells .. " cooldowns were added|r")
  end
end

--[[
  Test duplicate cooldown handling
]]--
-- TODO This is not yet implemented in CooldownQueue could be the next step to go for
function me.TestDuplicateCooldown()
  print("|cFFFFFF00Testing: Duplicate cooldown handling|r")

  -- Show targeting hint
  mod.testHelper.ShowTargetingHint()

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    print("|cFFFF0000Failed to get player data|r")
    return
  end

  local spell = mod.testHelper.CreateTestSpell(5484, "Howl of Terror", 40, 40)

  -- Add the cooldown
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, spell)

  -- Add same cooldown again with updated time
  local updatedSpell = mod.testHelper.CreateTestSpell(5484, "Howl of Terror", 40, 40, 5)
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, updatedSpell)

  -- Check how many instances exist
  local cooldowns = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local count = 0
  local lastCastTime = nil

  for _, cooldown in pairs(cooldowns) do
    if cooldown.spell.spellId == spell.spellId then
      count = count + 1
      lastCastTime = cooldown.spell.castTime
    end
  end

  if count == 1 then
    print("|cFF00FF00  [PASS] Duplicate prevented - only 1 instance exists|r")
    if lastCastTime == updatedSpell.castTime then
      print("|cFF00FF00  [PASS] Cooldown was updated with new cast time|r")
    end
  else
    print("|cFFFF0000  [FAIL] Found " .. count .. " instances (expected 1)|r")
  end
end

--[[
  Test removing specific cooldowns
]]--
function me.TestRemoveCooldown()
  print("|cFFFFFF00Testing: Remove specific cooldown|r")

  -- Show targeting hint
  mod.testHelper.ShowTargetingHint()

  local casterData = mod.testHelper.GetTestCasterData()
  if not casterData then
    print("|cFFFF0000Failed to get player data|r")
    return
  end

  local spell = mod.testHelper.CreateTestSpell(1766, "Kick", 10, 10)

  -- Add the cooldown
  mod.cooldownQueue.AddCooldown(casterData.guid, casterData.name, spell)

  -- Verify it was added
  local cooldownsBefore = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
  local foundBefore = false

  for _, cooldown in pairs(cooldownsBefore) do
    if cooldown.spell.spellId == spell.spellId then
      foundBefore = true
      break
    end
  end

  if foundBefore then
    print("  Added cooldown to queue")

    -- Remove the cooldown
    mod.cooldownQueue.RemoveCooldown(casterData.guid, spell.spellId)

    -- Check if it was removed
    local cooldownsAfter = mod.cooldownQueue.GetCooldownsByTarget(casterData.guid)
    local foundAfter = false

    for _, cooldown in pairs(cooldownsAfter) do
      if cooldown.spell.spellId == spell.spellId then
        foundAfter = true
        break
      end
    end

    if not foundAfter then
      print("|cFF00FF00  [PASS] Cooldown removed successfully|r")
    else
      print("|cFFFF0000  [FAIL] Failed to remove cooldown|r")
    end
  else
    print("|cFFFF0000  [FAIL] Failed to add test cooldown|r")
  end
end

--[[
  Clear all test cooldowns from the queue
]]--
function me.ClearTestCooldowns()
  print("|cFFFFFF00Clearing all cooldowns|r")

  local cooldownsBefore = mod.cooldownQueue.GetCooldownsByTarget(mod.testHelper.GetPlayerGUID() or "unknown")
  local initialCount = #cooldownsBefore

  -- Clear the entire queue
  mod.cooldownQueue.ClearCooldownQueue()

  -- Count remaining
  local cooldownsAfter = mod.cooldownQueue.GetCooldownsByTarget(mod.testHelper.GetPlayerGUID() or "unknown")
  local remainingCount = #cooldownsAfter

  print("  Cooldowns before: " .. initialCount)
  print("  Cooldowns after: " .. remainingCount)
end

--[[
  Run all cooldown queue tests
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("CooldownQueue", "=== Running CooldownQueue Tests ===")

  -- Show targeting hint
  mod.testHelper.ShowTargetingHint()

  me.TestAddCooldown()
  me.TestAddMultipleCooldowns()
  me.TestDuplicateCooldown()
  me.TestRemoveCooldown()
  me.ClearTestCooldowns()

  mod.testLogger.LogInfo("CooldownQueue", "=== CooldownQueue Tests Complete ===")
end
