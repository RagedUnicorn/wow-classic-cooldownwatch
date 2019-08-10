--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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
        - {number} Worst case cooldown for the cooldown. Assuming the enemy player has its spell fully reduces with either a talent or an item.
        Note: If an item is unlikely to be worn by players it might get omitted here
      ["active"] = boolean
        - {boolean} Whether the spell is active and tracked or not
    }
  }
]]--
local cooldownQueue = {}

--[[
  Add a cooldown to the queue

  @param {string} caster
    A unique identification for a caster (player or npc).
  @param {string} casterName
    Actual name of the caster
  @param {table} spell
    A spell with all its relevant information
]]--
function me.AddCooldown(caster, casterName, spell)
  assert(type(caster) == "string",
    string.format("bad argument #1 to `AddCooldown` (expected string got %s)", type(caster)))

  assert(type(casterName) == "string",
    string.format("bad argument #2 to `AddCooldown` (expected string got %s)", type(casterName)))

  assert(type(spell) == "table",
    string.format("bad argument #3 to `AddCooldown` (expected table got %s)", type(spell)))

  if not spell.active then
    mod.logger.LogWarn(me.tag, "Ignored inactive spell: " .. spell.spellName)
    return -- abort
  end

  local cooldownEvent = {
    ["caster"] = caster,
    ["casterName"] = casterName,
    ["spell"] = spell
  }

  tinsert(cooldownQueue, cooldownEvent)
  mod.logger.LogDebug(me.tag, "Added new cooldown - '" .. spell.spellName .. "' for player: " .. caster)
end

--[[
  Remove a cooldown for a specific caster from the queue

  @param {string} caster
    A unique identification for a caster
  @param {number} spellId
]]--
function me.RemoveCooldown(caster, spellId)
  for i = 1, table.getn(cooldownQueue) do
    if cooldownQueue[i].caster == caster and cooldownQueue[i].spell.spellId == spellId then
      tremove(cooldownQueue, i)
      mod.logger.LogDebug(me.tag, "Removed cooldown - '" .. spellId .. "' for player: " .. caster)
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

  @param {string} caster
    A unique identification for a caster

  @return {table}
    The castEvents that were found for the caste
    Note: May be an empty table
]]--
function me.GetCooldownsByTarget(caster)
  local cooldowns = {}

  for i = 1, table.getn(cooldownQueue) do
    if cooldownQueue[i].caster == caster then
      tinsert(cooldowns, cooldownQueue[i])
    end
  end

  return cooldowns
end
