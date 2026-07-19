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
  Shaman slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/SpellMap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["shaman"] = {
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
      { spellId = 10414, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8042, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8044, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8045, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8046, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10412, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10413, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 10473, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8056, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8058, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10472, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 29228, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8050, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8052, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8053, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10447, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10448, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 16166, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 11315, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1535, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8498, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8499, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 11314, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 8177, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 2484, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [16188] = {
    name = "Nature's Swiftness",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 16188, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  }
}
