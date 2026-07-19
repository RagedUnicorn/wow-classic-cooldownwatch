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
  Mage slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["mage"] = {
  [11129] = {
    name = "Combustion",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 11129, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  --[[
    Not a rank: casting Combustion (11129) triggers buff 28682, and the
    SPELL_AURA_REMOVED event carries the buff's id, so it aliases back to
    the primary (verified on the wowhead spell=11129 effects list).
  ]]--
  [28682] = { refId = 11129 },
  [10161] = {
    name = "Cone of Cold",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 10,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 10161, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 120, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8492, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10159, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10160, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 2139, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [12043] = {
    name = "Presence of Mind",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 180,
    active = true,
    trackedEvents = {
      "SPELL_AURA_REMOVED",
    },
    allRanks = {
      { spellId = 12043, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 1953, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 10199, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2136, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2137, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 2138, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8412, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8413, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10197, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
    sharedCooldownGroup = "mage_wards",
    allRanks = {
      { spellId = 10225, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 543, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8457, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8458, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10223, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
    sharedCooldownGroup = "mage_wards",
    allRanks = {
      { spellId = 28609, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6143, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8461, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8462, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10177, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [6143] = { refId = 28609 },
  [8461] = { refId = 28609 },
  [8462] = { refId = 28609 },
  [10177] = { refId = 28609 },
  [10230] = {
    name = "Frost Nova",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 25,
    cooldownWorstCase = 21,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 10230, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 122, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 865, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 6131, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [122] = { refId = 10230 },
  [865] = { refId = 10230 },
  [6131] = { refId = 10230 },
  [13033] = {
    name = "Ice Barrier",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 30,
    active = true,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 13033, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 11426, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 13031, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 13032, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 11958, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
      { spellId = 12472, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    },
    --[[
      Vanilla/Classic Era behavior: finishes the cooldown on all Frost
      spells. Fire Ward is included because the wards share one cooldown
      timer (patch 1.11 note) and patch 2.3.2's "no longer resets Fire Ward"
      confirms the pre-TBC behavior. The TBC-final variant (480s cooldown,
      no Fire Ward) belongs in the future Tbc overlay (CWI-0027).
    ]]--
    cooldownResets = {
      10230, -- Frost Nova
      10161, -- Cone of Cold
      11958, -- Ice Block
      13033, -- Ice Barrier
      28609, -- Frost Ward
      10225, -- Fire Ward
    }
  }
}
