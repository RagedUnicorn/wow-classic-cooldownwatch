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
    druid = {
      appendRanks = {
        [20748] = { -- Rebirth
          { spellId = 26994, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [9863] = { -- Tranquility
          { spellId = 26983, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [17329] = { -- Nature's Grasp
          { spellId = 27009, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [22896] = { -- Frenzied Regeneration
          { spellId = 26999, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [9821] = { -- Dash
          { spellId = 33357, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [22570] = {
          name = "Maim",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 10,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 22570, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [33831] = {
          name = "Force of Nature",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 33831, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        [20748] = { -- Rebirth: 30 min in Classic Era, 20 min in TBC
          name = "Rebirth",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 1200,
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
        [9863] = { -- Tranquility: 5 min in Classic Era, 10 min in TBC
          name = "Tranquility",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 600,
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
      },
    },
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
    --[[
      Classic items verdicts for TBC (no remove ops): the per-class insignias
      still exist with their classic use-effect spells on a TBC client, the
      engineering gadgets are unchanged, and Zul'Gurub stays open through TBC
      so the charm trinkets remain obtainable.
    ]]--
    items = {
      add = {
        -- Medallion of the Alliance (37864) / Horde (37865): both cast the
        -- same use-effect spell; icon resolution is caster-relative exactly
        -- like the classic insignias (helpers shared from the base slice)
        [42292] = {
          name = "PvP Trinket",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 120,
          itemId = mod.spellMapItemHelper.OpposingInsigniaItemId(37864, 37865),
          friendlyItemId = mod.spellMapItemHelper.OwnInsigniaItemId(37864, 37865),
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 42292, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [51582] = {
          name = "Rocket Boots Engaged",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          itemId = 23824, -- Rocket Boots Xtreme
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 51582, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [30507] = {
          name = "Poultryizer",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          itemId = 23835, -- Gnomish Poultryizer
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 30507, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [46567] = {
          name = "Rocket Launch",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 120,
          itemId = 23836, -- Goblin Rocket Launcher
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 46567, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [30458] = {
          name = "Nigh Invulnerability",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          itemId = 23825, -- Nigh Invulnerability Belt
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 30458, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
    },
    mage = {
      appendRanks = {
        [10161] = { -- Cone of Cold
          { spellId = 27087, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [10199] = { -- Fire Blast
          { spellId = 27078, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 27079, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [10230] = { -- Frost Nova
          { spellId = 27088, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [13033] = { -- Ice Barrier
          { spellId = 27134, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 33405, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        -- appended ward ranks alias to the group-carrying primaries, so the
        -- mage_wards fan-out needs no group change
        [10225] = { -- Fire Ward
          { spellId = 27128, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [28609] = { -- Frost Ward
          { spellId = 32796, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        --[[
          ID-collision: spell ID 11958 means "Ice Block" in
          Classic Era but "Cold Snap" in TBC, and 12472 means "Cold Snap" in
          Classic Era but "Icy Veins" in TBC. Both classic keys are remapped
          by the replace ops below; Ice Block itself lives under its TBC
          trainable id 45438 here.
        ]]--
        [45438] = {
          name = "Ice Block",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 45438, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [66] = {
          name = "Invisibility",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 300,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 66, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [31661] = {
          name = "Dragon's Breath",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 20,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 31661, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 33041, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 33042, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 33043, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        [2139] = { -- Counterspell: 30s in Classic Era, 24s in TBC
          name = "Counterspell",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 24,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 2139, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
          }
        },
        --[[
          ID-collision remaps (see the add-op comment above). The single rank
          of each remapped entry is typed SPELL_TYPE_TBC - the id exists on
          Classic Era but means a DIFFERENT spell there, so the usual
          classic-ranks-stay-BASE replace rule does not apply.

          TBC Cold Snap (patch 2.3.2 final): 8 min cooldown, resets all
          Frost-school cooldowns - including the new Ice Block id and Icy
          Veins - but no longer Fire Ward.
        ]]--
        [11958] = {
          name = "Cold Snap",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 480,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 11958, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          },
          cooldownResets = {
            10230, -- Frost Nova
            10161, -- Cone of Cold
            45438, -- Ice Block
            13033, -- Ice Barrier
            28609, -- Frost Ward
            12472, -- Icy Veins
          }
        },
        [12472] = {
          name = "Icy Veins",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 12472, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
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
    racials = {
      appendRanks = {
        -- TBC splits Blood Fury into per-class variants (33697 shaman,
        -- 33702 caster); all three ids share the one tracked cooldown
        [20572] = { -- Blood Fury
          { spellId = 33697, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 33702, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        -- Arcane Torrent has one spellId per resource type (28730 mana,
        -- 25046 energy) - one entry with the variants as ranks, the same
        -- modeling as Berserking in the base
        [28730] = {
          name = "Arcane Torrent",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 120,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 28730, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 25046, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [28880] = {
          name = "Gift of the Naaru",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 180,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 28880, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        [20589] = { -- Escape Artist: 60s in Classic Era, 105s in TBC
          name = "Escape Artist",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 105,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 20589, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
    shaman = {
      appendRanks = {
        -- appended shock ranks resolve through their synthesized aliases to
        -- the primaries carrying sharedCooldownGroup, so the shaman_shocks
        -- fan-out needs no group change
        [10414] = { -- Earth Shock
          { spellId = 25454, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [10473] = { -- Frost Shock
          { spellId = 25464, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [29228] = { -- Flame Shock
          { spellId = 25457, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [11315] = { -- Fire Nova Totem
          { spellId = 25546, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 25547, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        -- Bloodlust (Horde) and Heroism (Alliance) are deliberately two
        -- independent entries, not one entry with a faction alias: each
        -- caster shows the correct name and icon, and hand-written aliases
        -- stay reserved for non-derivable aura ids
        [2825] = {
          name = "Bloodlust",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 600,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 2825, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [32182] = {
          name = "Heroism",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 600,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 32182, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [30823] = {
          name = "Shamanistic Rage",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 120,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 30823, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [2894] = {
          name = "Fire Elemental Totem",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 1200,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 2894, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
        [2062] = {
          name = "Earth Elemental Totem",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 1200,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 2062, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
    },
    warlock = {
      appendRanks = {
        [17926] = { -- Death Coil
          { spellId = 27223, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [17924] = { -- Soul Fire
          { spellId = 27211, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [18871] = { -- Shadowburn
          { spellId = 27263, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 30546, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        [18932] = { -- Conflagrate
          { spellId = 27266, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 30912, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
        -- appended felhunter ranks alias to the petCast primary, so the
        -- pet-owner attribution pairing keeps working for TBC casts
        [19736] = { -- Devour Magic
          { spellId = 27276, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          { spellId = 27277, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
        },
      },
      add = {
        [30414] = {
          name = "Shadowfury",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 20,
          active = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 30414, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 30283, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
            { spellId = 30413, type = RGCW_CONSTANTS.SPELL_TYPE_TBC },
          }
        },
      },
      replace = {
        -- Spell Lock: 30s in Classic Era, 24s in TBC. The replace must keep
        -- petCast - the felhunter attribution pairing rides on the entry
        [19647] = {
          name = "Spell Lock",
          type = RGCW_CONSTANTS.SPELL_TYPE_TBC,
          cooldown = 24,
          active = true,
          petCast = true,
          trackedEvents = {
            "SPELL_CAST_SUCCESS",
          },
          allRanks = {
            { spellId = 19647, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
            { spellId = 19244, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
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
