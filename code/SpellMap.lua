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

-- luacheck: globals GetLocale

local mod = rgcw
local me = {}
mod.spellMap = me

me.tag = "SpellMap"

--[[
  Each primary entry can declare an optional `sharedCooldownGroup = "<name>"`
  field. Spells in the same group trigger one another's cooldowns (e.g. Shaman
  shocks). Group membership is enumerated in `sharedCooldownGroups` below so the
  combat-log handler can find sibling spellIds in O(1).
]]--
local spellMap = {
  ["priest"] = {
    [10890] = {
      name = "Psychic Scream",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 30,
      cooldownWorstCase = 26,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10890, 8122, 8124, 10888
      }
    },
    [8122] = { refId = 10890 },
    [8124] = { refId = 10890 },
    [10888] = { refId = 10890 },
    [19280] = {
      name = "Devouring Plague",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        19280, 2944, 19276, 19277, 19278, 19279, 25467
      }
    },
    [2944] = { refId = 19280 },
    [19276] = { refId = 19280 },
    [19277] = { refId = 19280 },
    [19278] = { refId = 19280 },
    [19279] = { refId = 19280 },
    [25467] = { refId = 19280 },
    [19293] = {
      name = "Elune's Grace",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        19293
      }
    },
    [6346] = {
      name = "Fear Ward",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 30,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        6346
      }
    },
    [14751] = {
      name = "Inner Focus",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        14751
      }
    },
    [10947] = {
      name = "Mind Blast",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 8,
      cooldownWorstCase = 5.5,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10947, 585, 591, 8092, 8102, 8103, 8104, 8105, 8106, 10945
      }
    },
    [585] = { refId = 10947 },
    [591] = { refId = 10947 },
    [8092] = { refId = 10947 },
    [8102] = { refId = 10947 },
    [8103] = { refId = 10947 },
    [8104] = { refId = 10947 },
    [8105] = { refId = 10947 },
    [8106] = { refId = 10947 },
    [10945] = { refId = 10947 },
    [10060] = {
      name = "Power Infusion",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10060
      }
    },
    [10901] = {
      name = "Power Word: Shield",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 4,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10901, 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900
      }
    },
    [17] = { refId = 10901 },
    [592] = { refId = 10901 },
    [600] = { refId = 10901 },
    [3747] = { refId = 10901 },
    [6065] = { refId = 10901 },
    [6066] = { refId = 10901 },
    [10898] = { refId = 10901 },
    [10899] = { refId = 10901 },
    [10900] = { refId = 10901 },
    [15487] = {
      name = "Silence",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 45,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        15487
      }
    }
  },
  ["rogue"] = {
    [13750] = {
      name = "Adrenaline Rush",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        13750
      }
    },
    [13877] = {
      name = "Blade Flurry",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 120,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        13877
      }
    },
    [2094] = {
      name = "Blind",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        2094
      }
    },
    [14177] = {
      name = "Cold Blood",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        14177
      }
    },
    [5277] = {
      name = "Evasion",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        5277
      }
    },
    [11286] = {
      name = "Gouge",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 10,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        11286, 1776, 1777, 8629, 11285
      }
    },
    [1776] = { refId = 11286 },
    [1777] = { refId = 11286 },
    [8629] = { refId = 11286 },
    [11285] = { refId = 11286 },
    [1769] = {
      name = "Kick",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 10,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        1769, 1766, 1767, 1768
      }
    },
    [1766] = { refId = 1769 },
    [1767] = { refId = 1769 },
    [1768] = { refId = 1769 },
    [8643] = {
      name = "Kidney Shot",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 20,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        8643, 408
      }
    },
    [408] = { refId = 8643 },
    [14251] = {
      name = "Riposte",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 6,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        14251
      }
    },
    [11305] = {
      name = "Sprint",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        11305, 2983, 8696
      }
    },
    [2983] = { refId = 11305 },
    [8696] = { refId = 11305 },
    [1857] = {
      name = "Vanish",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        1857, 1856
      }
    },
    [1856] = { refId = 1857 }
  },
  ["shaman"] = {
    [10414] = {
      name = "Earth Shock",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 6,
      cooldownWorstCase = 5,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      sharedCooldownGroup = "shaman_shocks",
      allRanks = {
        10414, 8042, 8044, 8045, 8046, 10412, 10413
      }
    },
    [8042] = { refId = 10414 },
    [8044] = { refId = 10414 },
    [8045] = { refId = 10414 },
    [8046] = { refId = 10414 },
    [10412] = { refId = 10414 },
    [10413] = { refId = 10414 },
    [10473] = {
      name = "Frost Shock",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 6,
      cooldownWorstCase = 5,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      sharedCooldownGroup = "shaman_shocks",
      allRanks = {
        10473, 8056, 8058, 10472
      }
    },
    [8056] = { refId = 10473 },
    [8058] = { refId = 10473 },
    [10472] = { refId = 10473 },
    [29228] = {
      name = "Flame Shock",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 6,
      cooldownWorstCase = 5,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      sharedCooldownGroup = "shaman_shocks",
      allRanks = {
        29228, 8050, 8052, 8053, 10447, 10448
      }
    },
    [8050] = { refId = 29228 },
    [8052] = { refId = 29228 },
    [8053] = { refId = 29228 },
    [10447] = { refId = 29228 },
    [10448] = { refId = 29228 },
    [16166] = {
      name = "Elemental Mastery",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        16166
      }
    },
    [11315] = {
      name = "Fire Nova Totem",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 15,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        11315, 1535, 8498, 8499, 11314
      }
    },
    [1535] = { refId = 11315 },
    [8498] = { refId = 11315 },
    [8499] = { refId = 11315 },
    [11314] = { refId = 11315 },
    [8177] = {
      name = "Grounding Totem",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 15,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        8177
      }
    },
    [2484] = {
      name = "Earthbind Totem",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 15,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        2484
      }
    },
    [16188] = {
      name = "Nature's Swiftness",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        16188
      }
    }
  },
  ["mage"] = {
    [11129] = {
      name = "Combustion",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        11129
      }
    },
    [10161] = {
      name = "Cone of Cold",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 10,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10161, 120, 8492, 10159, 10160
      }
    },
    [120] = { refId = 10161 },
    [8492] = { refId = 10161 },
    [10159] = { refId = 10161 },
    [10160] = { refId = 10161 },
    [2139] = {
      name = "Counterspell",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 30,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        2139
      }
    },
    [12043] = {
      name = "Presence of Mind",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        12043
      }
    },
    [1953] = {
      name = "Blink",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 15,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        1953
      }
    },
    [10199] = {
      name = "Fire Blast",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 8,
      cooldownWorstCase = 6.5,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10199, 2136, 2137, 2138, 8412, 8413, 10197
      }
    },
    [2136] = { refId = 10199 },
    [2137] = { refId = 10199 },
    [2138] = { refId = 10199 },
    [8412] = { refId = 10199 },
    [8413] = { refId = 10199 },
    [10197] = { refId = 10199 },
    [10225] = {
      name = "Fire Ward",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 30,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        10225, 543, 8457, 8458, 10223
      }
    },
    [543] = { refId = 10225 },
    [8457] = { refId = 10225 },
    [8458] = { refId = 10225 },
    [10223] = { refId = 10225 },
    [28609] = {
      name = "Frost Ward",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 30,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        28609, 6143, 8461, 8462, 10177
      }
    },
    [6143] = { refId = 28609 },
    [8461] = { refId = 28609 },
    [8462] = { refId = 28609 },
    [10177] = { refId = 28609 },
    [13033] = {
      name = "Ice Barrier",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 30,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        13033, 11426, 13031, 13032
      }
    },
    [11426] = { refId = 13033 },
    [13031] = { refId = 13033 },
    [13032] = { refId = 13033 },
    [11958] = {
      name = "Ice Block",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        11958
      }
    },
    [12472] = {
      name = "Cold Snap",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 600,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        12472
      }
    }
  }
}

--[[
  Lookup table of shared-cooldown groups. Each value is a list of primary
  spellIds that share their cooldown.
]]--
local sharedCooldownGroups = {
  ["shaman_shocks"] = { 10414, 10473, 29228 } -- Earth Shock / Frost Shock / Flame Shock
}

--[[
  Get the spellMap

  @return {table}
    The spellMap
]]--
function me.GetSpellMap()
  return mod.common.Clone(spellMap)
end

--[[
  Get the list of primary spellIds belonging to a shared-cooldown group.

  @param {string} groupName

  @return {table|nil}
    Cloned list of primary spellIds, or nil if the group is unknown
]]--
function me.GetSharedCooldownGroup(groupName)
  if not groupName then return nil end

  local group = sharedCooldownGroups[groupName]
  if not group then return nil end

  return mod.common.Clone(group)
end

--[[
  Get all shared-cooldown groups keyed by group name.

  @return {table}
    Cloned table of groupName -> list of primary spellIds
]]--
function me.GetAllSharedCooldownGroups()
  return mod.common.Clone(sharedCooldownGroups)
end
