--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

local mod = rgcw
local me = {}

mod.cooldownQueue = me

me.tag = "CooldownQueue"

--[[
  {
    ["caster"] = caster,
      - {string} A unique identification for a caster
    ["casterName"] = casterName,
      - {string} Actual name of the caster
    ["spell"] = {
      ["spellId"] = spellId,
        - {number} SpellId of the spell
      ["iconId"] = iconId,
        - {number} Icon id of the spell
      ["spellName"] = spellName,
        - {string} Name of the spell
      ["castTime"] = castTime,
        - {number} Time at which the spell was detected
      ["cooldown"] cooldown,
        - {number} Cooldown of the spell
      ["cooldownWorstCase"] = cooldownWorstCase,
        - {number} Worst case cooldown for the cooldown.
        Assuming the enemy player has its spell fully reduced with either a talent or an item.
        Note: If an item is unlikely to be worn by players it might get omitted here
      ["active"] = boolean
        - {boolean} Whether the spell is active and tracked or not
    }
  }
]]--
local cooldownQueue = {}

--[[
  Add a cooldown to the queue

  @param {string} sourceGuid
    A unique identification for a caster (player or npc).
  @param {string} sourceName
    Actual name of the caster
  @param {string} category
    The category the spell belongs to
  @param {table} spellData
    A spellData with all its relevant information
]]--
function me.AddCooldown(sourceGuid, sourceName, category, spellData)
  assert(type(sourceGuid) == "string",
    string.format("bad argument #1 to `AddCooldown` (expected string got %s)", type(sourceGuid)))

  assert(type(sourceName) == "string",
    string.format("bad argument #2 to `AddCooldown` (expected string got %s)", type(sourceName)))

  assert(type(category) == "string",
    string.format("bad argument #3 to `AddCooldown` (expected string got %s)", type(category)))

  assert(type(spellData) == "table",
    string.format("bad argument #4 to `AddCooldown` (expected table got %s)", type(spellData)))

  if not spellData.active then
    mod.logger.LogWarn(me.tag, "Ignored inactive spell: " .. spellData.name)
    return -- abort
  end

  local cooldownEvent = {
    ["sourceGuid"] = sourceGuid,
    ["sourceName"] = sourceName,
    ["category"] = category,
    ["spellData"] = spellData
  }

  table.insert(cooldownQueue, cooldownEvent)
  mod.logger.LogDebug(
    me.tag,
    "Added new cooldown - '" .. spellData.name .. "' for player (" .. category .. "): "
      .. sourceName .. " (" .. sourceGuid .. ") "
  )
end

--[[
  Remove a cooldown for a specific caster from the queue

  @param {string} sourceGuid
    A unique identification for a sourceGuid
  @param {number} spellId
]]--
function me.RemoveCooldown(sourceGuid, spellId)
  for i = 1, #cooldownQueue do
    if cooldownQueue[i].sourceGuid == sourceGuid and cooldownQueue[i].spellData.spellId == spellId then
      table.remove(cooldownQueue, i)
      mod.logger.LogDebug(me.tag, "Removed cooldown - '" .. spellId .. "' for player: " .. sourceGuid)
      return
    end
  end
end

--[[
  Remove all cooldowns from queue
]]--
function me.ClearCooldownQueue()
  cooldownQueue = {}
end

--[[
  Retrieve cooldowns for a specific caster

  @param {string} sourceGuid
    A unique identification for a caster

  @return {table}
    The castEvents that were found for the caster
    Note: May be an empty table
]]--
function me.GetCooldownsByTarget(sourceGuid)
  local cooldowns = {}

  for i = 1, #cooldownQueue do
    if cooldownQueue[i].sourceGuid == sourceGuid then
      table.insert(cooldowns, cooldownQueue[i])
    end
  end

  return cooldowns
end
