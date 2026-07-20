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
  Warlock slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["warlock"] = {
  [18288] = {
    name = "Amplify Curse",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 18288, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [17926] = {
    name = "Death Coil",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 17926, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6789, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 17925, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [17928] = {
    name = "Howl of Terror",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 40,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 17928, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 5484, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [28610] = {
    name = "Shadow Ward",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 30,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 28610, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6229, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 11739, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 11740, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [17924] = {
    name = "Soul Fire",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 17924, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6353, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [18708] = {
    name = "Fel Domination",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 900,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 18708, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [18871] = {
    name = "Shadowburn",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 15,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 18871, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 17877, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 18867, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 18868, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 18869, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 18870, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [18932] = {
    name = "Conflagrate",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 10,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 18932, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 17962, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 18930, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 18931, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
}
