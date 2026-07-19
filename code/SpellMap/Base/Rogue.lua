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
  Rogue slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/SpellMap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["rogue"] = {
  [13750] = {
    name = "Adrenaline Rush",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 13750, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 13877, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 2094, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [14177] = {
    name = "Cold Blood",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 14177, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 5277, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 11286, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1776, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1777, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8629, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 11285, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 1769, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1766, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1767, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1768, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 8643, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 408, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [408] = { refId = 8643 },
  [14185] = {
    name = "Preparation",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 600,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 14185, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    },
    --[[
      Vanilla/Classic Era behavior: finishes the cooldown on ALL other rogue
      abilities. The narrow Evasion/Sprint/Vanish/Cold Blood/Adrenaline
      Rush/Premeditation list is a TBC change (patch 2.0.3, "Now only
      resets...") and belongs in the future Tbc overlay (CWI-0027).
      Premeditation is reset in-game too but is not a tracked spell, so it is
      intentionally absent - targets are limited to tracked primaries.
    ]]--
    cooldownResets = {
      13750, -- Adrenaline Rush
      13877, -- Blade Flurry
      2094,  -- Blind
      14177, -- Cold Blood
      5277,  -- Evasion
      11286, -- Gouge
      1769,  -- Kick
      8643,  -- Kidney Shot
      14251, -- Riposte
      11305, -- Sprint
      1857,  -- Vanish
    }
  },
  [14251] = {
    name = "Riposte",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 6,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 14251, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 11305, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2983, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8696, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 1857, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1856, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [1856] = { refId = 1857 }
}
