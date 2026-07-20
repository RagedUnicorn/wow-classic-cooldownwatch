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
  Warrior slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["warrior"] = {
  [18499] = {
    name = "Berserker Rage",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 30,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 18499, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [2687] = {
    name = "Bloodrage",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 2687, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [23894] = {
    name = "Bloodthirst",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 6,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 23894, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 23881, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 23892, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 23893, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [12328] = {
    name = "Death Wish",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 12328, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [20617] = {
    name = "Intercept",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 30,
    cooldownWorstCase = 20,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 20617, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20252, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20616, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [11578] = {
    name = "Charge",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 15,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 11578, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 100, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6178, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [6554] = {
    name = "Pummel",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 10,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 6554, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6552, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [1672] = {
    name = "Shield Bash",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 12,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 1672, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 72, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1671, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
}
