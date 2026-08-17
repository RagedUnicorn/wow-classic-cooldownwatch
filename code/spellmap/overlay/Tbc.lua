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
