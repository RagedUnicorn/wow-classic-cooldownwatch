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

-- luacheck: globals UnitGUID UnitName UnitExists GetTime

local mod = rgcw
local me = {}

mod.testHelper = me

me.tag = "TestHelper"

--[[
  Get the current player's GUID

  @return {string|nil} - Player GUID or nil if not available
]]--
function me.GetPlayerGUID()
  return UnitGUID("player")
end

--[[
  Get the current player's name

  @return {string|nil} - Player name or nil if not available
]]--
function me.GetPlayerName()
  return UnitName("player")
end

--[[
  Get the current target's GUID

  @return {string|nil} - Target GUID or nil if no target
]]--
function me.GetTargetGUID()
  if UnitExists("target") then
    return UnitGUID("target")
  end

  return nil
end

--[[
  Get the current target's name

  @return {string|nil} - Target name or nil if no target
]]--
function me.GetTargetName()
  if UnitExists("target") then
    return UnitName("target")
  end

  return nil
end

--[[
  Get test caster data using current player's information

  @return {table} - Table containing caster GUID and name
]]--
function me.GetTestCasterData()
  local playerGUID = me.GetPlayerGUID()
  local playerName = me.GetPlayerName()

  if not playerGUID or not playerName then
    mod.logger.LogError(me.tag, "Unable to get player information for test")
    return nil
  end

  return {
    guid = playerGUID,
    name = playerName
  }
end

--[[
  Create a test spell data structure

  @param {number} spellId - The spell ID
  @param {string} spellName - The spell name
  @param {number} cooldown - The cooldown duration in seconds
  @param {number} cooldownWorstCase - The worst case cooldown duration
  @param {number} castTimeOffset - Optional offset from current time (default: 0)

  @return {table} - Spell data structure
]]--
function me.CreateTestSpell(spellId, spellName, cooldown, cooldownWorstCase, castTimeOffset)
  castTimeOffset = castTimeOffset or 0

  return {
    ["spellId"] = spellId,
    ["name"] = spellName,
    ["rank"] = nil,
    ["castTime"] = GetTime() + castTimeOffset,
    ["cooldown"] = cooldown,
    ["cooldownWorstCase"] = cooldownWorstCase or cooldown,
    ["active"] = true
  }
end

--[[
  Check if the player is targeting themselves
  @return {boolean} - True if player is targeting themselves
]]--
function me.IsTargetingSelf()
  local playerGUID = me.GetPlayerGUID()
  local targetGUID = me.GetTargetGUID()

  return playerGUID ~= nil and targetGUID ~= nil and playerGUID == targetGUID
end

--[[
  Show targeting hint for cooldown tests (non-blocking)
]]--
function me.ShowTargetingHint()
  if not me.IsTargetingSelf() then
    print("|cFFFFFF00[HINT]|r Target yourself to see cooldowns in the UI")
    print("Use |cFFFFC300/target " .. (me.GetPlayerName() or "YourName") .. "|r or click on your character")
  else
    print("|cFF00FF00[INFO]|r Targeting self - cooldowns will be visible in UI")
  end
end

--[[
  Collect every primary spell entry for a category from the SpellMap. Primary
  entries carry a `name`; alias entries only carry `refId`. Output is sorted by
  spellId for deterministic test order.

  @param {string} category - e.g. "priest", "rogue", "shaman"

  @return {table} - Array of { spellId = number, name = string, trackedEvents = table }
]]--
function me.GetSpellsForCategory(category)
  local categoryMap = mod.spellMap.GetSpellMap()[category]
  local result = {}

  if not categoryMap then
    return result
  end

  for spellId, entry in pairs(categoryMap) do
    if entry.name then
      table.insert(result, {
        spellId = spellId,
        name = entry.name,
        trackedEvents = entry.trackedEvents
      })
    end
  end

  table.sort(result, function(a, b) return a.spellId < b.spellId end)

  return result
end
