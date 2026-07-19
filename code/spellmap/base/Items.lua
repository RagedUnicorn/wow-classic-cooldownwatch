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

-- luacheck: globals UnitFactionGroup

local mod = rgcw

--[[
  Items slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

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
  Every items entry is an item-triggered cooldown: the combat log fires with the
  item's "Use" effect spell, but players recognize these by the item icon, not
  the spell icon. `itemId` points at the triggering item so the ui can resolve
  the icon via GetItemIcon (see GuiHelper.GetIconId).

  Taxonomy (aligned with PVPWarn): "items" holds actual items — engineering
  gadgets, trinkets, insignias. Consumables (potions, bandages, elixirs) will
  live in a separate "misc" category once CWI-0011 lands.
]]--
mod.spellMapBaseClasses["items"] = {
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
