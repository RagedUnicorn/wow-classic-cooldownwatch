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
  Druid slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["druid"] = {
  [8983] = {
    name = "Bash",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 8983, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 5211, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6798, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [16979] = {
    name = "Feral Charge",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 15,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 16979, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [22896] = {
    name = "Frenzied Regeneration",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 22896, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 22842, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 22895, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [17116] = {
    name = "Nature's Swiftness",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 17116, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [29166] = {
    name = "Innervate",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 360,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 29166, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [18562] = {
    name = "Swiftmend",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 15,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 18562, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [22812] = {
    name = "Barkskin",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 22812, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [9821] = {
    name = "Dash",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 9821, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1850, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [5229] = {
    name = "Enrage",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 5229, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [20748] = {
    name = "Rebirth",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 1800,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 20748, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20484, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20739, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20742, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20747, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [9863] = {
    name = "Tranquility",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 9863, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 740, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8918, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 9862, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [17329] = {
    name = "Nature's Grasp",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 17329, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 16689, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 16810, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 16811, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 16812, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 16813, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
}
