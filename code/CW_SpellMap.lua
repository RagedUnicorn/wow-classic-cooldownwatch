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
mod.spellMap = me

me.tag = "SpellMap"

local spellMap = {
  --[[
    ["class"] = {
      The idea behind using spellId is to have the easiest way to find a casted spell in the list.
      This should be faster than searching through the list until a match is found.
      [spellId] = {
        ["spellName"] = {string},
          Name of the spell how it shows in the spellbook
        ["cooldown"] = {number},
          Cooldown of the spell without any modifiers such as talent or items
        ["cooldownWorstCase"] = {number},
          Worst case cooldown for the cooldown. Assuming the enemy player has its spell
          fully reduces with either a talent or an item.
          Note: if an item is unlikely to be worn by players it might get ommited
          here
        ["active"] = {boolean}
          Whether the spell is active and tracked or not
      }
    }
  ]]--
  ["priest"] = {
    [8122] = {
      ["spellName"] = "Psychic Scream",
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 26,
      ["active"] = true
    }
  },
  ["rogue"] = {

  },
  ["warrior"] = {

  },
}

function me.GetSpellById()

end

--[[
  Find a spell by its spellId and optionally by a className. Knowing the className
  narrows the search down and thus speeds up the process but is not required.

  Note: Spells are only returned if they are also active. Inactive spells are ignored
  and will be returned even though they might be found in the spellmap.

  @param {number} spellId
  @param {string} className
    Optional classname in english

  @return {table | nil}
    table - if a spell could be found
    nil - if no matching spell was found in the list
]]--
function me.FindSpell(spellId, className)

  assert(type(spellId) == "number",
    string.format("bad argument #1 to `FindSpell` (expected number got %s)", type(spellId)))

  if className ~= nil then
    local className = strlower(className)
    if spellMap[className][spellId] ~= nil and spellMap[className][spellId].active then
      return spellMap[className][spellId]
    end
  else
    for index, value in pairs(spellMap) do
        if spellMap[index][spellId] ~= nil and spellMap[index][spellId].active then
          return spellMap[index][spellId]
        end
    end

    return nil
  end

  return nil -- no spell found
end
