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
local me = {}
mod.spellMapOverlayTbc = me

me.tag = "SpellMapOverlayTbc"

--[[
  Branch overlay applied when the Burning Crusade Classic client is active.
  Changed cooldown values express as replace ops, new TBC reranks as
  appendRanks ops, and TBC-only spells as add ops against the Classic Era
  base catalog - op semantics in docs/DEVELOPMENT.md.

  @return {table}
    Overlay table consumed by mod.spellMapAssembler.Apply
]]--
function me.GetOverlay()
  return {
    hunter = {
      appendRanks = {
        [20904] = { -- Aimed Shot
          { spellId = 27065, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [14287] = { -- Arcane Shot
          { spellId = 27019, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [25294] = { -- Multi-Shot
          { spellId = 27021, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [14295] = { -- Volley
          { spellId = 27022, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [20910] = { -- Counterattack
          { spellId = 27067, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [24133] = { -- Wyvern Sting
          { spellId = 27068, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [34490] = {
          name = "Silencing Shot",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 20,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 34490, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        [1543] = { -- Flare: 15s in Classic Era, 20s in TBC
          name = "Flare",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 20,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 1543, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
          }
        },
      },
    },
    paladin = {
      appendRanks = {
        [20930] = { -- Holy Shock
          { spellId = 27174, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 33072, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [10310] = { -- Lay on Hands
          { spellId = 27154, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [31884] = {
          name = "Avenging Wrath",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 31884, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [31842] = {
          name = "Divine Illumination",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 31842, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [31935] = {
          name = "Avenger's Shield",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 30,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 31935, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        -- cooldown-value changes only: the replaced primary carries the
        -- branch type, classic ranks in allRanks stay SPELL_TYPE_BASE
        [20930] = { -- Holy Shock: 30s in Classic Era, 15s since TBC 2.3
          name = "Holy Shock",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 15,
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
        [1044] = { -- Blessing of Freedom: 20s in Classic Era, 25s in TBC
          name = "Blessing of Freedom",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 25,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 1044, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
          }
        },
      },
    },
    priest = {
      -- Elune's Grace was reworked for TBC under a new single-rank spellId:
      -- the Classic Era chain (primary 19293) does not exist on a TBC client,
      -- so the rework is remove + add (2651 below)
      remove = {
        19293,
      },
      appendRanks = {
        [10947] = { -- Mind Blast
          { spellId = 25372, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 25375, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [10901] = { -- Power Word: Shield
          { spellId = 25217, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 25218, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [19280] = { -- Devouring Plague
          { spellId = 25467, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [2651] = {
          name = "Elune's Grace",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 2651, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [33206] = {
          name = "Pain Suppression",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 120,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 33206, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [34433] = {
          name = "Shadowfiend",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 34433, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [32379] = {
          name = "Shadow Word: Death",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 12,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 32379, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [44041] = {
          name = "Chastise",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 30,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 44041, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 44043, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 44044, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 44045, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 44046, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 44047, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [32548] = {
          name = "Symbol of Hope",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 32548, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [32676] = {
          name = "Consume Magic",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 120,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 32676, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        [6346] = { -- Fear Ward: 30s in Classic Era, 3 min since TBC 2.3
          name = "Fear Ward",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 6346, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
          }
        },
      },
    },
    rogue = {
      appendRanks = {
        [5277] = { -- Evasion
          { spellId = 26669, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [11286] = { -- Gouge
          { spellId = 38764, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [1769] = { -- Kick
          { spellId = 38768, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [1857] = { -- Vanish
          { spellId = 26889, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [31224] = {
          name = "Cloak of Shadows",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 60,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 31224, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [36554] = {
          name = "Shadowstep",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 30,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 36554, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        [2094] = { -- Blind: 5 min in Classic Era, 3 min in TBC
          name = "Blind",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 2094, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
          }
        },
        --[[
          Preparation's cooldown is unchanged in TBC; the replace narrows the
          reset list to the patch 2.0.3 set (see the base slice comment):
          Evasion, Sprint, Vanish, Cold Blood, Adrenaline Rush - plus
          Premeditation, which is not a tracked spell and stays absent
          (targets are limited to tracked primaries).
        ]]--
        [14185] = {
          name = "Preparation",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 600,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 14185, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
          },
          cooldownResets = {
            5277,  -- Evasion
            11305, -- Sprint
            1857,  -- Vanish
            14177, -- Cold Blood
            13750, -- Adrenaline Rush
          }
        },
      },
    },
    warrior = {
      appendRanks = {
        [23894] = { -- Bloodthirst
          { spellId = 25251, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 30335, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [20617] = { -- Intercept
          { spellId = 25272, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 25275, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [1672] = { -- Shield Bash
          { spellId = 29704, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [23920] = {
          name = "Spell Reflection",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 10,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 23920, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [3411] = {
          name = "Intervene",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 30,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 3411, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
    },
  }
end
