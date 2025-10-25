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
  }
}

--[[
  Get the spellMap

  @return {table}
    The spellMap
]]--
function me.GetSpellMap()
  return mod.common.Clone(spellMap)
end
