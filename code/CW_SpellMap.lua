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

-- /run t = {GetSpellInfo(2687)};/dump t TODO
--[[
  Some of the spells do no longer return anything because they were removed. We should write a script that
  we can try out on the beta and verify the spells
]]--


--[[
  Need to try here with all the ranks because we have to assume the we get a different id for a different rank
  unlike when parsing the plain text of the combatlog
]]--

local spellMap = {
  --[[
    ["class"] = {
      The idea behind using spellId is to have the easiest way to find a casted spell in the list.
      This should be faster than searching through the list until a match is found.
      [spellId] = {
        ["spellName"] = {string},
          Name of the spell how it shows in the spellbook
        ["rank"] = {number},
          The rank of the spell often not available
        ["cooldown"] = {number},
          Cooldown of the spell in seconds without any modifiers such as talent or items
        ["cooldownWorstCase"] = {number},
          Optional worst case cooldown for the cooldown. Assuming the enemy player has its spell
          fully reduced with either a talent or an item.
          Note: if an item is unlikely to be worn by players it might get ommited here
        ["active"] = {boolean}
          Whether the spell is active and tracked or not
      }
    }
  ]]--
  ["priest"] = {
    [8122] = {
      ["spellName"] = "Psychic Scream",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 26,
      ["active"] = true
    },
    [8124] = {
      ["spellName"] = "Psychic Scream",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 26,
      ["active"] = true
    },
    [10888] = {
      ["spellName"] = "Psychic Scream",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 26,
      ["active"] = true
    },
    [10890] = {
      ["spellName"] = "Psychic Scream",
      ["rank"] = 4,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 26,
      ["active"] = true
    },
    [2944] = {
      ["spellName"] = "Devouring Plague",
      ["rank"] = 1,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [19276] = {
      ["spellName"] = "Devouring Plague",
      ["rank"] = 2,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [19277] = {
      ["spellName"] = "Devouring Plague",
      ["rank"] = 3,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [19278] = {
      ["spellName"] = "Devouring Plague",
      ["rank"] = 4,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [19279] = {
      ["spellName"] = "Devouring Plague",
      ["rank"] = 5,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [19280] = {
      ["spellName"] = "Devouring Plague",
      ["rank"] = 6,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [2651] = {
      ["spellName"] = "Elune's Grace",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [19289] = {
      ["spellName"] = "Elune's Grace",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [19291] = {
      ["spellName"] = "Elune's Grace",
      ["rank"] = 3,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [19292] = {
      ["spellName"] = "Elune's Grace",
      ["rank"] = 4,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [19293] = {
      ["spellName"] = "Elune's Grace",
      ["rank"] = 5,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [6346] = {
      ["spellName"] = "Fear Ward",
      ["cooldown"] = 30,
      ["active"] = true
    },
    [14751] = {
      ["spellName"] = "Inner Focus",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [8092] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 1,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [8102] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 2,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [8103] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 3,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [8104] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 4,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [8105] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 5,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [8106] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 6,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [10945] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 7,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [10946] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 8,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [10947] = {
      ["spellName"] = "Mind Blast",
      ["rank"] = 9,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 5.5,
      ["active"] = true
    },
    [10060] = {
      ["spellName"] = "Power Infusion",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [17] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 1,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [592] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 2,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [600] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 3,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [3747] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 4,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [6065] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 5,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [6066] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 6,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [10898] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 7,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [10899] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 8,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [10900] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 9,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [10901] = {
      ["spellName"] = "Power Word: Shield",
      ["rank"] = 10,
      ["cooldown"] = 4,
      ["active"] = true
    },
    [15487] = {
      ["spellName"] = "Silence",
      ["cooldown"] = 45,
      ["active"] = true
    }
  },
  ["rogue"] = {
    [13750] = {
      ["spellName"] = "Adrenaline Rush",
      ["cooldown"] = 300,
      ["active"] = true
    },
    [13877] = {
      ["spellName"] = "Blade Flurry",
      ["cooldown"] = 120,
      ["active"] = true
    },
    [2094] = {
      ["spellName"] = "Blind",
      ["cooldown"] = 300,
      ["active"] = true
    },
    [14177] = {
      ["spellName"] = "Cold Blood",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [5277] = {
      ["spellName"] = "Evasion",
      ["cooldown"] = 300,
      ["active"] = true
    },
    [1776] = {
      ["spellName"] = "Gouge",
      ["rank"] = 1,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [1777] = {
      ["spellName"] = "Gouge",
      ["rank"] = 2,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [8629] = {
      ["spellName"] = "Gouge",
      ["rank"] = 3,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [11285] = {
      ["spellName"] = "Gouge",
      ["rank"] = 4,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [11286] = {
      ["spellName"] = "Gouge",
      ["rank"] = 5,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [1766] = {
      ["spellName"] = "Kick",
      ["rank"] = 1,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [1767] = {
      ["spellName"] = "Kick",
      ["rank"] = 2,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [1768] = {
      ["spellName"] = "Kick",
      ["rank"] = 3,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [1769] = {
      ["spellName"] = "Kick",
      ["rank"] = 4,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [408] = {
      ["spellName"] = "Kidney Shot",
      ["cooldown"] = 20,
      ["active"] = true
    },
    [8643] = {
      ["spellName"] = "Kidney Shot",
      ["cooldown"] = 20,
      ["active"] = true
    },
    [14251] = {
      ["spellName"] = "Riposte",
      ["cooldown"] = 6,
      ["active"] = true
    },
    [2983] = {
      ["spellName"] = "Sprint",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [8696] = {
      ["spellName"] = "Sprint",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [11305] = {
      ["spellName"] = "Sprint",
      ["rank"] = 3,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [1856] = {
      ["spellName"] = "Vanish",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [1857] = {
      ["spellName"] = "Vanish",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    }
  },
  ["mage"] = {
    [11129] = {
      ["spellName"] = "Combustion",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [120] = {
      ["spellName"] = "Cone of Cold",
      ["rank"] = 1,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [8492] = {
      ["spellName"] = "Cone of Cold",
      ["rank"] = 2,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [10159] = {
      ["spellName"] = "Cone of Cold",
      ["rank"] = 3,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [10160] = {
      ["spellName"] = "Cone of Cold",
      ["rank"] = 4,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [10161] = {
      ["spellName"] = "Cone of Cold",
      ["rank"] = 5,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [2139] = {
      ["spellName"] = "Counterspell",
      ["cooldown"] = 30,
      ["active"] = true
    },
    [12043] = {
      ["spellName"] = "Presence of Mind",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [1953] = {
      ["spellName"] = "Blink",
      ["cooldown"] = 15,
      ["cooldownWorstCase"] = 13,
      ["active"] = true
    },
    [2136] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 1,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [2137] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 2,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [2138] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 3,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [8412] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 4,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [8413] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 5,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [10197] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 6,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [10199] = {
      ["spellName"] = "Fire Blast",
      ["rank"] = 7,
      ["cooldown"] = 8,
      ["cooldownWorstCase"] = 6.5,
      ["active"] = true
    },
    [543] = {
      ["spellName"] = "Fire Ward",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [8457] = {
      ["spellName"] = "Fire Ward",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [8458] = {
      ["spellName"] = "Fire Ward",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [10223] = {
      ["spellName"] = "Fire Ward",
      ["rank"] = 4,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [10225] = {
      ["spellName"] = "Fire Ward",
      ["rank"] = 5,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [6143] = {
      ["spellName"] = "Frost Ward",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [8461] = {
      ["spellName"] = "Frost Ward",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [8462] = {
      ["spellName"] = "Frost Ward",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [10177] = {
      ["spellName"] = "Frost Ward",
      ["rank"] = 4,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [28609] = {
      ["spellName"] = "Frost Ward",
      ["rank"] = 5,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [11426] = {
      ["spellName"] = "Ice Barrier",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [13031] = {
      ["spellName"] = "Ice Barrier",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [13032] = {
      ["spellName"] = "Ice Barrier",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [13033] = {
      ["spellName"] = "Ice Barrier",
      ["rank"] = 4,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [11958] = {
      ["spellName"] = "Ice Block",
      ["cooldown"] = 300,
      ["active"] = true
    }
  },
  ["hunter"] = {
    [19434] = {
      ["spellName"] = "Aimed Shot",
      ["rank"] = 1,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [20900] = {
      ["spellName"] = "Aimed Shot",
      ["rank"] = 2,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [20901] = {
      ["spellName"] = "Aimed Shot",
      ["rank"] = 3,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [20902] = {
      ["spellName"] = "Aimed Shot",
      ["rank"] = 4,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [20903] = {
      ["spellName"] = "Aimed Shot",
      ["rank"] = 5,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [20904] = {
      ["spellName"] = "Aimed Shot",
      ["rank"] = 6,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [3044] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 1,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14281] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 2,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14282] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 3,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14283] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 4,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14284] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 5,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14285] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 6,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14286] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 7,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [14287] = {
      ["spellName"] = "Arcane Shot",
      ["rank"] = 8,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [19574] = {
      ["spellName"] = "Bestial Wrath",
      ["cooldown"] = 120,
      ["active"] = true
    },
    [5116] = {
      ["spellName"] = "Concussive Shot",
      ["cooldown"] = 12,
      ["active"] = true
    },
    [19306] = {
      ["spellName"] = "Counterattack",
      ["rank"] = 1,
      ["cooldown"] = 5,
      ["active"] = true
    },
    [20909] = {
      ["spellName"] = "Counterattack",
      ["rank"] = 2,
      ["cooldown"] = 5,
      ["active"] = true
    },
    [20910] = {
      ["spellName"] = "Counterattack",
      ["rank"] = 3,
      ["cooldown"] = 5,
      ["active"] = true
    },
    [3045] = {
      ["spellName"] = "Rapid Fire",
      ["cooldown"] = 300,
      ["active"] = true
    },
    [19503] = {
      ["spellName"] = "Scatter Shot",
      ["cooldown"] = 30,
      ["active"] = true
    },
    [19263] = {
      ["spellName"] = "Deterrence",
      ["cooldown"] = 300,
      ["active"] = true
    },
    [19386] = {
      ["spellName"] = "Wyvern Sting",
      ["rank"] = 1,
      ["cooldown"] = 120,
      ["active"] = true
    },
    [24132] = {
      ["spellName"] = "Wyvern Sting",
      ["rank"] = 2,
      ["cooldown"] = 120,
      ["active"] = true
    },
    [24133] = {
      ["spellName"] = "Wyvern Sting",
      ["rank"] = 3,
      ["cooldown"] = 120,
      ["active"] = true
    },
    [19577] = {
      ["spellName"] = "Intimidation",
      ["cooldown"] = 60,
      ["active"] = true
    },
    [1543] = {
      ["spellName"] = "Flare",
      ["cooldown"] = 15,
      ["active"] = true
    }
  },
  ["warrior"] = {
    [18499] = {
      ["spellName"] = "Berserker Rage",
      ["cooldown"] = 30,
      ["active"] = true
    },
    [2687] = {
      ["spellName"] = "Bloodrage",
      ["cooldown"] = 60,
      ["active"] = true
    },
    [23881] = {
      ["spellName"] = "Bloodthirst",
      ["rank"] = 1,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [23892] = {
      ["spellName"] = "Bloodthirst",
      ["rank"] = 2,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [23893] = {
      ["spellName"] = "Bloodthirst",
      ["rank"] = 3,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [23894] = {
      ["spellName"] = "Bloodthirst",
      ["rank"] = 4,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [12328] = {
      ["spellName"] = "Death Wish",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [20252] = {
      ["spellName"] = "Intercept",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 20,
      ["active"] = true
    },
    [20616] = {
      ["spellName"] = "Intercept",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 20,
      ["active"] = true
    },
    [20617] = {
      ["spellName"] = "Intercept",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 20,
      ["active"] = true
    },
    [100] = {
      ["spellName"] = "Charge",
      ["rank"] = 1,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [6178] = {
      ["spellName"] = "Charge",
      ["rank"] = 2,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [11578] = {
      ["spellName"] = "Charge",
      ["rank"] = 3,
      ["cooldown"] = 15,
      ["active"] = true
    }
  }
}

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
  end

  return nil -- no spell found
end
