--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

--[[
  Hunter slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["hunter"] = {
  [20904] = {
    name = "Aimed Shot",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 6,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 20904, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19434, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20900, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20901, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20902, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20903, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [14287] = {
    name = "Arcane Shot",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 6,
    cooldownWorstCase = 5,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 14287, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 3044, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14281, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14282, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14283, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14284, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14285, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14286, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [19574] = {
    name = "Bestial Wrath",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 19574, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [5116] = {
    name = "Concussive Shot",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 12,
    cooldownWorstCase = 11,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 5116, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [20910] = {
    name = "Counterattack",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 5,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 20910, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19306, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20909, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [3045] = {
    name = "Rapid Fire",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 3045, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [19503] = {
    name = "Scatter Shot",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 30,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 19503, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [19263] = {
    name = "Deterrence",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 19263, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [24133] = {
    name = "Wyvern Sting",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 24133, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19386, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 24132, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  --[[
    Intimidation is a hunter spellbook talent: SPELL_CAST_SUCCESS 19577 fires
    from the HUNTER (8% base mana cost; the DB2 "Wearer Casts Proc Trigger"
    attribute pins only the delayed stun 24394 to the pet), so the entry tracks
    like any other hunter spell - no petCast.
  ]]--
  [19577] = {
    name = "Intimidation",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 19577, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [1543] = {
    name = "Flare",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 15,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 1543, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [25294] = {
    name = "Multi-Shot",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 10,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 25294, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2643, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14288, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14289, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14290, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [14295] = {
    name = "Volley",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 14295, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1510, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 14294, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
}
