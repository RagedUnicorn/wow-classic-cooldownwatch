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

--[[
  ["class"] = {
    The idea behind using spellId is to have the easiest way to find a casted spell in the list.
    This should be faster than searching through the list until a match is found.
    [spellId] = {
      ["spellName"] = spellName,
        - {string} Name of the spell how it shows in the spellbook
      ["rank"] = rank,
        - {number | nil} The rank of the spell often not available
      ["cooldown"] = cooldown,
        - {number} Cooldown of the spell in seconds without any modifiers such as talent or items
      ["cooldownWorstCase"] = cooldownWorstCase,
        - {number} Optional worst case cooldown for the cooldown. Assuming the enemy player has its spell fully reduced with either a talent or an item.
        Note: if an item is unlikely to be worn by players it might get omitted here
      ["active"] = true
        - {boolean} Whether the spell is active and tracked or not
    }
  }
]]--
local spellMap = {
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
  ["warlock"] = {
    [18288] = {
      ["spellName"] = "Amplify Curse",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [6789] = {
      ["spellName"] = "Death Coil",
      ["rank"] = 1,
      ["cooldown"] = 120,
      ["active"] = true
    },
    [17925] = {
      ["spellName"] = "Death Coil",
      ["rank"] = 2,
      ["cooldown"] = 120,
      ["active"] = true
    },
    [17926] = {
      ["spellName"] = "Death Coil",
      ["rank"] = 3,
      ["cooldown"] = 120,
      ["active"] = true
    },
    [5484] = {
      ["spellName"] = "Howl of Terror",
      ["rank"]  = 1,
      ["cooldown"] = 40,
      ["active"] = true
    },
    [17928] = {
      ["spellName"] = "Howl of Terror",
      ["rank"]  = 1,
      ["cooldown"] = 40,
      ["active"] = true
    },
    [6229] = {
      ["spellName"] = "Shadow Ward",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [11739] = {
      ["spellName"] = "Shadow Ward",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [11740] = {
      ["spellName"] = "Shadow Ward",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [28610] = {
      ["spellName"] = "Shadow Ward",
      ["rank"] = 4,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [6353] = {
      ["spellName"] = "Soul Fire",
      ["rank"] = 1,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [17924] = {
      ["spellName"] = "Soul Fire",
      ["rank"] = 2,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [18708] = {
      ["spellName"] = "Fel Domination",
      ["cooldown"] = 900,
      ["active"] = true
    },
    [17877] = {
      ["spellName"] = "Shadowburn",
      ["rank"] = 1,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [18867] = {
      ["spellName"] = "Shadowburn",
      ["rank"] = 2,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [18868] = {
      ["spellName"] = "Shadowburn",
      ["rank"] = 3,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [18869] = {
      ["spellName"] = "Shadowburn",
      ["rank"] = 4,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [18870] = {
      ["spellName"] = "Shadowburn",
      ["rank"] = 5,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [18871] = {
      ["spellName"] = "Shadowburn",
      ["rank"] = 6,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [17962] = {
      ["spellName"] = "Conflagrate",
      ["rank"] = 1,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [18930] = {
      ["spellName"] = "Conflagrate",
      ["rank"] = 2,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [18931] = {
      ["spellName"] = "Conflagrate",
      ["rank"] = 3,
      ["cooldown"] = 10,
      ["active"] = true
    },
    [18932] = {
      ["spellName"] = "Conflagrate",
      ["rank"] = 4,
      ["cooldown"] = 10,
      ["active"] = true
    }
  },
  ["paladin"] = {
    [1044] = {
      ["spellName"] = "Blessing of Freedom",
      ["cooldown"] = 20,
      ["active"] = true
    },
    [1022] = {
      ["spellName"] = "Blessing of Protection",
      ["rank"] = 1,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [5599] = {
      ["spellName"] = "Blessing of Protection",
      ["rank"] = 2,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [10278] = {
      ["spellName"] = "Blessing of Protection",
      ["rank"] = 3,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [642] = {
      ["spellName"] = "Divine Shield",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [1020] = {
      ["spellName"] = "Divine Shield",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [498] = {
      ["spellName"] = "Divine Protection",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [5573] = {
      ["spellName"] = "Divine Protection",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [853] = {
      ["spellName"] = "Hammer of Justice",
      ["rank"] = 1,
      ["cooldown"] = 60,
      ["cooldownWorstCase"] = 45,
      ["active"] = true
    },
    [5588] = {
      ["spellName"] = "Hammer of Justice",
      ["rank"] = 2,
      ["cooldown"] = 60,
      ["cooldownWorstCase"] = 45,
      ["active"] = true
    },
    [5589] = {
      ["spellName"] = "Hammer of Justice",
      ["rank"] = 3,
      ["cooldown"] = 60,
      ["cooldownWorstCase"] = 45,
      ["active"] = true
    },
    [10308] = {
      ["spellName"] = "Hammer of Justice",
      ["rank"] = 4,
      ["cooldown"] = 60,
      ["cooldownWorstCase"] = 45,
      ["active"] = true
    },
    [20066] = {
      ["spellName"] = "Repentance",
      ["cooldown"] = 60,
      ["active"] = true
    },
    [20216] = {
      ["spellName"] = "Divine Favor",
      ["cooldown"] = 120,
      ["active"] = true
    },
    [24275] = {
      ["spellName"] = "Hammer of Wrath",
      ["rank"] = 1,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [24274] = {
      ["spellName"] = "Hammer of Wrath",
      ["rank"] = 2,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [24239] = {
      ["spellName"] = "Hammer of Wrath",
      ["rank"] = 3,
      ["cooldown"] = 6,
      ["active"] = true
    },
    [20473] = {
      ["spellName"] = "Holy Shock",
      ["rank"] = 1,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [20929] = {
      ["spellName"] = "Holy Shock",
      ["rank"] = 2,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [20930] = {
      ["spellName"] = "Holy Shock",
      ["rank"] = 3,
      ["cooldown"] = 30,
      ["active"] = true
    },
    [633] = {
      ["spellName"] = "Lay on Hands",
      ["rank"] = 1,
      ["cooldown"] = 3600,
      ["cooldownWorstCase"] = 2400,
      ["active"] = true
    },
    [2800] = {
      ["spellName"] = "Lay on Hands",
      ["rank"] = 2,
      ["cooldown"] = 3600,
      ["cooldownWorstCase"] = 2400,
      ["active"] = true
    },
    [10310] = {
      ["spellName"] = "Lay on Hands",
      ["rank"] = 3,
      ["cooldown"] = 3600,
      ["cooldownWorstCase"] = 2400,
      ["active"] = true
    }
  },
  ["druid"] = {
    [5211] = {
      ["spellName"] = "Bash",
      ["rank"] = 1,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [6798] = {
      ["spellName"] = "Bash",
      ["rank"] = 2,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [8983] = {
      ["spellName"] = "Bash",
      ["rank"] = 3,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [16979] = {
      ["spellName"] = "Feral Charge",
      ["cooldown"] = 15,
      ["active"] = true
    },
    [22842] = {
      ["spellName"] = "Frenzied Regeneration",
      ["rank"] = 1,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [22895] = {
      ["spellName"] = "Frenzied Regeneration",
      ["rank"] = 2,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [22896] = {
      ["spellName"] = "Frenzied Regeneration",
      ["rank"] = 3,
      ["cooldown"] = 180,
      ["active"] = true
    },
    [17116] = {
      ["spellName"] = "Nature's Swiftness",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [29166] = {
      ["spellName"] = "Innervate",
      ["cooldown"] = 360,
      ["active"] = true
    },
    [18562] = {
      ["spellName"] = "Swiftmend",
      ["cooldown"] = 15,
      ["active"] = true
    },
    [22812] = {
      ["spellName"] = "Barkskin",
      ["cooldown"] = 60,
      ["active"] = true
    },
    [1850] = {
      ["spellName"] = "Dash",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [9821] = {
      ["spellName"] = "Dash",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [5229] = {
      ["spellName"] = "Enrage",
      ["cooldown"] = 60,
      ["active"] = true
    },
    [20484] = {
      ["spellName"] = "Rebirth",
      ["rank"] = 1,
      ["cooldown"] = 1800,
      ["active"] = true
    },
    [20739] = {
      ["spellName"] = "Rebirth",
      ["rank"] = 2,
      ["cooldown"] = 1800,
      ["active"] = true
    },
    [20742] = {
      ["spellName"] = "Rebirth",
      ["rank"] = 3,
      ["cooldown"] = 1800,
      ["active"] = true
    },
    [20747] = {
      ["spellName"] = "Rebirth",
      ["rank"] = 4,
      ["cooldown"] = 1800,
      ["active"] = true
    },
    [20748] = {
      ["spellName"] = "Rebirth",
      ["rank"] = 5,
      ["cooldown"] = 1800,
      ["active"] = true
    },
    [740] = {
      ["spellName"] = "Tranquility",
      ["rank"] = 1,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [8918] = {
      ["spellName"] = "Tranquility",
      ["rank"] = 2,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [9862] = {
      ["spellName"] = "Tranquility",
      ["rank"] = 3,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [9863] = {
      ["spellName"] = "Tranquility",
      ["rank"] = 4,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [16689] = {
      ["spellName"] = "Nature's Grasp",
      ["rank"] = 1,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [16810] = {
      ["spellName"] = "Nature's Grasp",
      ["rank"] = 2,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [16811] = {
      ["spellName"] = "Nature's Grasp",
      ["rank"] = 3,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [16812] = {
      ["spellName"] = "Nature's Grasp",
      ["rank"] = 4,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [16813] = {
      ["spellName"] = "Nature's Grasp",
      ["rank"] = 5,
      ["cooldown"] = 60,
      ["active"] = true
    },
    [17329] = {
      ["spellName"] = "Nature's Grasp",
      ["rank"] = 6,
      ["cooldown"] = 60,
      ["active"] = true
    }
  },
  -- TODO link shock spells together on same cooldown
  ["shaman"] = {
    [8042] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 1,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8044] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 2,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8045] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 3,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8046] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 4,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10412] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 5,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10413] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 6,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10414] = {
      ["spellName"] = "Earth Shock",
      ["rank"]  = 7,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8056] = {
      ["spellName"] = "Frost Shock",
      ["rank"] = 1,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8058] = {
      ["spellName"] = "Frost Shock",
      ["rank"] = 2,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10472] = {
      ["spellName"] = "Frost Shock",
      ["rank"] = 3,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10473] = {
      ["spellName"] = "Frost Shock",
      ["rank"] = 4,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8050] = {
      ["spellName"] = "Flame Shock",
      ["rank"] = 1,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8052] = {
      ["spellName"] = "Flame Shock",
      ["rank"] = 2,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [8053] = {
      ["spellName"] = "Flame Shock",
      ["rank"] = 3,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10447] = {
      ["spellName"] = "Flame Shock",
      ["rank"] = 4,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [10448] = {
      ["spellName"] = "Flame Shock",
      ["rank"] = 5,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [29228] = {
      ["spellName"] = "Flame Shock",
      ["rank"] = 6,
      ["cooldown"] = 6,
      ["cooldownWorstCase"] = 5,
      ["active"] = true
    },
    [16166] = {
      ["spellName"] = "Elemental Mastery",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [1535] = {
      ["spellName"] = "Fire Nova Totem",
      ["rank"] = 1,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [8498] = {
      ["spellName"] = "Fire Nova Totem",
      ["rank"] = 2,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [8499] = {
      ["spellName"] = "Fire Nova Totem",
      ["rank"] = 3,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [11314] = {
      ["spellName"] = "Fire Nova Totem",
      ["rank"] = 4,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [11315] = {
      ["spellName"] = "Fire Nova Totem",
      ["rank"] = 5,
      ["cooldown"] = 15,
      ["active"] = true
    },
    [8177] = {
      ["spellName"] = "Grounding Totem",
      ["cooldown"] = 15,
      ["active"] = true
    },
    [2484] = {
      ["spellName"] = "Earthbind Totem",
      ["cooldown"] = 15,
      ["active"] = true
    },
    [16188] = {
      ["spellName"] = "Nature's Swiftness",
      ["cooldown"] = 180,
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
  },
  ["racials"] = {
    [20589] = {
      ["spellName"] = "Escape Artist",
      ["cooldown"] = 60,
      ["active"] = true
    },
    [20600] = {
      ["spellName"] = "Perception",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [20594] = {
      ["spellName"] = "Stoneform",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [7744] = {
      ["spellName"] = "Will of the Forsaken",
      ["cooldown"] = 120,
      ["active"] = true
    },
    [20549] = {
      ["spellName"] = "War Stomp",
      ["cooldown"] = 120,
      ["active"] = true
    },
    [20572] = {
      ["spellName"] = "Blood Fury",
      ["cooldown"] = 120,
      ["active"] = true
    },
    -- TODO same spell different ids because of what is required to activate
    -- probably okay to treat as 3 different spells
    [26296] = {
      ["spellName"] = "Berserking",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [26297] = {
      ["spellName"] = "Berserking",
      ["cooldown"] = 180,
      ["active"] = true
    },
    [20554] = {
      ["spellName"] = "Berserking",
      ["cooldown"] = 180,
      ["active"] = true
    }
  },
  --[[
    TODO might need an additonal property here for the item icon because the spell
    itself might not give it away which item was used
  ]]--
  ["items"] = {
    [23132] = {
      ["spellName"] = "Ultra-Flash Shadow Reflector",
      ["itemId"] = 18639,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [23131] = {
      ["spellName"] = "Gyrofreeze Ice Reflector",
      ["itemId"] = 18634,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [23097] = {
      ["spellName"] = "Hyper-Radiant Flame Reflector",
      ["itemId"] = 18638,
      ["cooldown"] = 300,
      ["active"] = true
    },
    -- used 22641 by both goblin and viking helmet
    [22641] = {
      ["spellName"] = "Goblin Rocket Helmet",
      ["itemId"] = 10588,
      ["cooldown"] = 1200,
      ["active"] = true
    },
    [13141] = {
      ["spellName"] = "Gnomish Rocket Boots",
      ["itemId"] = 10724,
      ["cooldown"] = 1800,
      ["active"] = true
    },
    [8892] = {
      ["spellName"] = "Goblin Rocket Boots",
      ["itemId"] = 7189,
      ["cooldown"] = 300,
      ["active"] = true
    },
    [13120] = {
      ["spellName"] = "Gnomish Net-o-Matic Projector",
      ["itemId"] = 10720,
      ["cooldown"] = 600,
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

--[[
  Get list for a certain category

  @param {string} category

  @return {table | nil}
    table - The category that was found in the list
    nil - if no category was found in the list
]]--
function me.GetAllForCategory(category)
  if not category then return nil end

  return spellMap[category]
end
