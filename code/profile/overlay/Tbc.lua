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
mod.profileOverlayTbc = me

me.tag = "ProfileOverlayTbc"

--[[
  Burning Crusade overlay of the curated default-enabled profile: the
  TBC-only spells important enough to track out of the box. Every id must be
  a PRIMARY spellId that exists in the tbc-assembled spellmap (enforced by
  ValidateDefaultProfileIdsArePrimaries). No base-curated id disappears on
  tbc, so there are no remove ops - the mage id remaps (11958 Cold Snap,
  12472 Icy Veins on tbc) deliberately stay curated under their new meaning.

  @return {table}
    Overlay table consumed by mod.profile.BuildDefaultEnabledSets:
    { [category] = { remove = { spellId, ... }, add = { spellId, ... } } }
]]--
function me.GetOverlay()
  return {
    ["priest"] = {
      add = {
        33206, -- Pain Suppression
      },
    },
    ["rogue"] = {
      add = {
        31224, -- Cloak of Shadows
        36554, -- Shadowstep
      },
    },
    ["shaman"] = {
      add = {
        2825, -- Bloodlust
        32182, -- Heroism
        30823, -- Shamanistic Rage
      },
    },
    ["mage"] = {
      add = {
        45438, -- Ice Block (trainable tbc id)
      },
    },
    ["warrior"] = {
      add = {
        23920, -- Spell Reflection
      },
    },
    ["hunter"] = {
      add = {
        34490, -- Silencing Shot
      },
    },
    ["warlock"] = {
      add = {
        30414, -- Shadowfury
      },
    },
    ["paladin"] = {
      add = {
        31884, -- Avenging Wrath
      },
    },
    ["druid"] = {
      add = {
        22570, -- Maim
      },
    },
    ["racials"] = {
      add = {
        28730, -- Arcane Torrent
      },
    },
    ["items"] = {
      add = {
        42292, -- PvP Trinket (tbc medallions)
      },
    },
  }
end
