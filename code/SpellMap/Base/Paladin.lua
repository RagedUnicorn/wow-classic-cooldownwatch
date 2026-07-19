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
  Paladin slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/SpellMap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["paladin"] = {
  [1044] = {
    name = "Blessing of Freedom",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 20,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 1044, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [10278] = {
    name = "Blessing of Protection",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    cooldownWorstCase = 180,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 10278, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 1022, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 5599, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [1022] = { refId = 10278 },
  [5599] = { refId = 10278 },
  [1020] = {
    name = "Divine Shield",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 1020, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 642, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [642] = { refId = 1020 },
  [5573] = {
    name = "Divine Protection",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 300,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 5573, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 498, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [498] = { refId = 5573 },
  [10308] = {
    name = "Hammer of Justice",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    cooldownWorstCase = 45,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 10308, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 853, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 5588, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 5589, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [853] = { refId = 10308 },
  [5588] = { refId = 10308 },
  [5589] = { refId = 10308 },
  [20066] = {
    name = "Repentance",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 20066, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [20216] = {
    name = "Divine Favor",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 20216, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [20930] = {
    name = "Holy Shock",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 30,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 20930, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20473, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 20929, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [20473] = { refId = 20930 },
  [20929] = { refId = 20930 },
  [10310] = {
    name = "Lay on Hands",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 3600,
    cooldownWorstCase = 2400,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 10310, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 633, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2800, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [633] = { refId = 10310 },
  [2800] = { refId = 10310 }
}
