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
  Priest slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/SpellMap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["priest"] = {
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
      { spellId = 10890, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8122, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8124, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10888, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 19280, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2944, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19276, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19277, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19278, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 19279, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 25467, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 19293, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 6346, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [14751] = {
    name = "Inner Focus",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 14751, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 10947, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 585, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 591, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8092, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8102, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8103, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8104, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8105, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8106, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10945, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 10060, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 10901, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 17, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 592, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 600, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 3747, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6065, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6066, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10898, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10899, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10900, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 15487, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  }
}
