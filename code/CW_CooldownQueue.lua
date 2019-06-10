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
      - {string} a unique identification for a caster (player or npc)
    ["casterName"] = casterName,
      - {string} actual name of the caster
    ["spell"] = {
      ["spellName"] = spellName,
        - {string} name of the spell
      ["spellId"] = spellId,
        - {number} id of the spell
      ["castTime"] = castTime,
        - {number} time at which the spell was detected
      ["cooldown"] cooldown,
        - {number} cooldown of the spell
      ["cooldownWorstCase"] = cooldownWorstCase,
        - {number} Worst case cooldown for the cooldown. Assuming the enemy player has its spell
        fully reduces with either a talent or an item.
        Note: if an item is unlikely to be worn by players it might get ommited here
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

  local cooldownEvent = {
    ["caster"] = caster,
    ["casterName"] = casterName,
    ["spell"] = spell
  }

  tinsert(cooldownQueue, cooldownEvent)
  mod.logger.LogDebug(me.tag, "Added new cooldown - '" .. spell.spellName .. "' for player: " .. caster)
end

--[[
  Remove a cooldown from the queue

  @param {string} caster
    A unique identification for a caster (player or npc)
  @param {number} spellId
]]--
function me.RemoveCooldown(caster, spellId)
  -- TODO what if we have multiple unknown
end

--[[
  Retrieve a cast for a specific target
  @param {string} target
    A unique identification for a target (player or npc)
  @return {table | nil}
    table - the castEvent that was found for the target
    nil   - if no cast for the target could be found
]]--
function me.GetCastByTarget(target)
  for i = 1, table.getn(castQueue) do
    if castQueue[i].caster == target then
      return castQueue[i]
    end
  end
  -- no cast for target found
  return nil
end
