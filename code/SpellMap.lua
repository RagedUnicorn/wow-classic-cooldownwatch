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

-- luacheck: globals GetLocale UnitFactionGroup

local mod = rgcw
local me = {}
mod.spellMap = me

me.tag = "SpellMap"

--[[
  Resolve the insignia itemId for the player's own faction. Each PvP insignia
  Use-effect spell is cast by two faction-mirrored items; the player's own
  variant is the icon they recognize best (they equip and press it themselves).
  Mirrors PVPWarn's insignia handling. Resolved once at file load - faction
  never changes within a session.

  @param {number} allianceItemId
  @param {number} hordeItemId

  @return {number}
]]--
local function InsigniaItemId(allianceItemId, hordeItemId)
  if UnitFactionGroup(RGCW_CONSTANTS.UNIT_ID_PLAYER) == "Horde" then
    return hordeItemId
  end

  return allianceItemId
end

--[[
  Each primary entry can declare an optional `sharedCooldownGroup = "<name>"`
  field. Spells in the same group trigger one another's cooldowns (e.g. Shaman
  shocks). Group membership is enumerated in `sharedCooldownGroups` below so the
  combat-log handler can find sibling spellIds in O(1).

  A primary can also declare an optional `cooldownResets = { spellId, ... }`
  array: when the spell fires, every listed cooldown is removed from the
  caster's queue (e.g. rogue Preparation, mage Cold Snap). The asymmetric
  counterpart to sharedCooldownGroup - targets must be primary spellIds and may
  live in a different category (see CombatLog.ResetTargetedCooldowns).
]]--
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
  },
  ["rogue"] = {
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
  },
  ["shaman"] = {
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
  },
  ["mage"] = {
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
  },
  ["warrior"] = {
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
    [23881] = { refId = 23894 },
    [23892] = { refId = 23894 },
    [23893] = { refId = 23894 },
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
    [20252] = { refId = 20617 },
    [20616] = { refId = 20617 },
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
    [100] = { refId = 11578 },
    [6178] = { refId = 11578 }
  },
  ["hunter"] = {
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
    [19434] = { refId = 20904 },
    [20900] = { refId = 20904 },
    [20901] = { refId = 20904 },
    [20902] = { refId = 20904 },
    [20903] = { refId = 20904 },
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
    [3044] = { refId = 14287 },
    [14281] = { refId = 14287 },
    [14282] = { refId = 14287 },
    [14283] = { refId = 14287 },
    [14284] = { refId = 14287 },
    [14285] = { refId = 14287 },
    [14286] = { refId = 14287 },
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
    [19306] = { refId = 20910 },
    [20909] = { refId = 20910 },
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
    [19386] = { refId = 24133 },
    [24132] = { refId = 24133 },
    -- Intimidation is cast by the hunter's pet, so SPELL_CAST_SUCCESS fires from
    -- the pet's GUID, not the hunter's. The entry tracks but won't currently
    -- credit the hunter target.
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
    [2643] = { refId = 25294 },
    [14288] = { refId = 25294 },
    [14289] = { refId = 25294 },
    [14290] = { refId = 25294 },
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
    [1510] = { refId = 14295 },
    [14294] = { refId = 14295 }
  },
  ["warlock"] = {
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
    [6789] = { refId = 17926 },
    [17925] = { refId = 17926 },
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
    [5484] = { refId = 17928 },
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
    [6229] = { refId = 28610 },
    [11739] = { refId = 28610 },
    [11740] = { refId = 28610 },
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
    [6353] = { refId = 17924 },
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
    [17877] = { refId = 18871 },
    [18867] = { refId = 18871 },
    [18868] = { refId = 18871 },
    [18869] = { refId = 18871 },
    [18870] = { refId = 18871 },
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
    [17962] = { refId = 18932 },
    [18930] = { refId = 18932 },
    [18931] = { refId = 18932 }
  },
  ["paladin"] = {
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
  },
  ["druid"] = {
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
    [5211] = { refId = 8983 },
    [6798] = { refId = 8983 },
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
    [22842] = { refId = 22896 },
    [22895] = { refId = 22896 },
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
    [1850] = { refId = 9821 },
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
    [20484] = { refId = 20748 },
    [20739] = { refId = 20748 },
    [20742] = { refId = 20748 },
    [20747] = { refId = 20748 },
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
    [740] = { refId = 9863 },
    [8918] = { refId = 9863 },
    [9862] = { refId = 9863 },
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
    [16689] = { refId = 17329 },
    [16810] = { refId = 17329 },
    [16811] = { refId = 17329 },
    [16812] = { refId = 17329 },
    [16813] = { refId = 17329 }
  },
  ["racials"] = {
    [20589] = {
      name = "Escape Artist",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 60,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 20589, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [20600] = {
      name = "Perception",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 20600, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [20594] = {
      name = "Stoneform",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 20594, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [7744] = {
      name = "Will of the Forsaken",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 120,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 7744, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [20549] = {
      name = "War Stomp",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 120,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 20549, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [20572] = {
      name = "Blood Fury",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 120,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 20572, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [26296] = {
      name = "Berserking",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 26296, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    }
  },
  --[[
    Every items entry is an item-triggered cooldown: the combat log fires with the
    item's "Use" effect spell, but players recognize these by the item icon, not
    the spell icon. `itemId` points at the triggering item so the ui can resolve
    the icon via GetItemIcon (see GuiHelper.GetIconId).

    Taxonomy (aligned with PVPWarn): "items" holds actual items — engineering
    gadgets, trinkets, insignias. Consumables (potions, bandages, elixirs) will
    live in a separate "misc" category once CWI-0011 lands.
  ]]--
  ["items"] = {
    [23132] = {
      name = "Shadow Reflector",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = 18639, -- Ultra-Flash Shadow Reflector
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23132, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [23131] = {
      name = "Frost Reflector",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = 18634, -- Gyrofreeze Ice Reflector
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23131, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [23097] = {
      name = "Fire Reflector",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = 18638, -- Hyper-Radiant Flame Reflector
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23097, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [22641] = {
      name = "Reckless Charge",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 1200,
      -- Horned Viking Helmet (9394, 30 min) casts the same spell; the 20 min
      -- cooldown above already commits this entry to the Goblin Rocket Helmet
      itemId = 10588, -- Goblin Rocket Helmet
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 22641, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [13141] = {
      name = "Gnomish Rocket Boots",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 1800,
      itemId = 10724, -- Gnomish Rocket Boots
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 13141, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [8892] = {
      name = "Goblin Rocket Boots",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = 7189, -- Goblin Rocket Boots
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 8892, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [13120] = {
      name = "Net-o-Matic",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 600,
      itemId = 10720, -- Gnomish Net-o-Matic Projector
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 13120, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    --[[
      PvP insignia trinkets (Insignia of the Alliance / Horde). One Use-effect
      spell per class group, shared by both factions' items; the spell names
      are the real GetSpellInfo names and describe which effects each class's
      insignia dispels. Icon resolves to the player's own faction's item via
      InsigniaItemId.
    ]]--
    [5579] = {
      name = "Immune Root/Snare/Stun", -- warrior / hunter / shaman insignia
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = InsigniaItemId(18854, 18834),
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 5579, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [23273] = {
      name = "Immune Charm/Fear/Polymorph", -- warlock / rogue insignia
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = InsigniaItemId(18858, 18852),
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23273, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [23274] = {
      name = "Immune Fear/Polymorph/Snare", -- mage insignia
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = InsigniaItemId(18859, 18850),
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23274, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [23276] = {
      name = "Immune Fear/Polymorph/Stun", -- priest / paladin insignia
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = InsigniaItemId(18862, 18851),
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23276, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [23277] = {
      name = "Immune Charm/Fear/Stun", -- druid insignia
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 300,
      itemId = InsigniaItemId(18863, 18853),
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 23277, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [24499] = {
      name = "Energized Shield", -- shaman: Lightning Shield damage +100%
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      itemId = 19956, -- Wushoolay's Charm of Spirits
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 24499, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [24532] = {
      name = "Burst of Energy", -- rogue: +60 energy
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      itemId = 19954, -- Renataki's Charm of Trickery
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 24532, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    },
    [24571] = {
      -- shares its name with the orc racial (different spellId, racials category)
      name = "Blood Fury", -- warrior: +30 rage
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
      cooldown = 180,
      itemId = 19951, -- Gri'lek's Charm of Might
      active = true,
      trackedEvents = {
        "SPELL_CAST_SUCCESS",
      },
      allRanks = {
        { spellId = 24571, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      }
    }
  }
}

--[[
  Decorate every primary entry with its normalizedSpellName once, at load time.
]]--
for _, spells in pairs(spellMap) do
  for _, spellData in pairs(spells) do
    if type(spellData.name) == "string" then
      spellData.normalizedSpellName = mod.common.NormalizeSpellName(spellData.name)
    end
  end
end

--[[
  Lookup table of shared-cooldown groups. Each value is a list of primary
  spellIds that share their cooldown.
]]--
local sharedCooldownGroups = {
  ["shaman_shocks"] = { 10414, 10473, 29228 }, -- Earth Shock / Frost Shock / Flame Shock
  ["mage_wards"] = { 10225, 28609 } -- Fire Ward / Frost Ward
}

--[[
  Get the spellMap. Callers MUST treat the result as read-only and never mutate it.

  @return {table}
    The spellMap (read-only — do not mutate)
]]--
function me.GetSpellMap()
  return spellMap
end

--[[
  Get the list of primary spellIds belonging to a shared-cooldown group.

  @param {string} groupName

  @return {table|nil}
    The list of primary spellIds (read-only — do not mutate), or nil if the
    group is unknown. Called on every shared-cooldown sibling fan-out, so it
    returns the internal list directly rather than cloning.
]]--
function me.GetSharedCooldownGroup(groupName)
  if not groupName then return nil end

  return sharedCooldownGroups[groupName]
end

--[[
  Get all shared-cooldown groups keyed by group name.

  @return {table}
    Table of groupName -> list of primary spellIds (read-only — do not mutate)
]]--
function me.GetAllSharedCooldownGroups()
  return sharedCooldownGroups
end
