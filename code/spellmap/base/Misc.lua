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
  Misc slice of the Classic Era base spell catalog. Each slice file
  registers exactly one category on the shared spellMapBaseClasses table;
  code/spellmap/Base.lua assembles the slices into the base map.
]]--
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

--[[
  Taxonomy (aligned with PVPWarn): "misc" holds consumables - potions,
  bandages, healthstones and their kin. Actual items (engineering gadgets,
  trinkets, insignias) live in the "items" category.

  Every entry is item-triggered: the combat log fires with the consumable's
  effect spell, but players recognize these by the item icon, so `itemId`
  points at the triggering item (GuiHelper.GetIconId). Spell names often
  differ from item names ("Speed" for Swiftness Potion, "Invulnerability"
  for Limited Invulnerability Potion) - `name` must stay the GetSpellInfo
  name; the icon carries the recognition.

  Cooldowns here live on the ITEM, not the spell (wowhead spell pages show
  unrelated per-spell recovery values - never copy those). In-game these
  consumables sit on shared cooldown buckets: one 2 min bucket for all
  potions, a second 2 min bucket for Whipper Root Tuber / Night Dragon's
  Breath / healthstones, and the 60 s Recently Bandaged debuff for bandages.
  The buckets are deliberately NOT encoded as sharedCooldownGroups: the
  shared cooldown guarantees at most one live entry per bucket anyway, and
  the unconditional fan-out would flood the target bar with every sibling
  on a single drink. Only the consumable actually used is queued, with its
  own icon.

  All entries default to active = false: consumables fire frequently and
  would clutter the bar for users who don't opt in.
]]--
mod.spellMapBaseClasses["misc"] = {
  --[[
    Potions. One entry per potion family; the healing and mana chains are
    modeled as ranks (every rank's use spell shares one GetSpellInfo name).
  ]]--
  [17534] = {
    name = "Healing Potion", -- every healing potion rank casts this name
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 13446, -- Major Healing Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 439, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Minor Healing Potion (118)
      { spellId = 440, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Lesser Healing Potion (858)
      { spellId = 441, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Healing Potion (929)
      { spellId = 2024, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Greater Healing Potion (1710)
      { spellId = 4042, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Superior Healing Potion (3928)
      { spellId = 17534, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Major Healing Potion (13446)
    }
  },
  [17531] = {
    name = "Restore Mana", -- every mana potion rank casts this name
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 13444, -- Major Mana Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 437, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Minor Mana Potion (2455)
      { spellId = 438, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Lesser Mana Potion (3385)
      { spellId = 2023, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Mana Potion (3827)
      { spellId = 11903, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Greater Mana Potion (6149)
      { spellId = 17530, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Superior Mana Potion (13443)
      { spellId = 17531, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Major Mana Potion (13444)
    }
  },
  [6615] = {
    name = "Free Action",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 5634, -- Free Action Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 6615, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [24364] = {
    name = "Living Free Action",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 20008, -- Living Action Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 24364, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [3169] = {
    name = "Invulnerability",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 3387, -- Limited Invulnerability Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 3169, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [2379] = {
    name = "Speed",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 2459, -- Swiftness Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 2379, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [11359] = {
    name = "Restoration",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 9030, -- Restorative Potion
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 11359, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  --[[
    Bandages have no item cooldown; the lockout is the 60 s Recently Bandaged
    debuff on the bandaged unit (applied even when the channel is interrupted).
    Tracking the debuff application covers every bandage rank including the
    Alterac battleground variant with one entry, and attributes the lockout to
    the unit that can no longer be bandaged - no bandage cast spells are
    encoded.
  ]]--
  [11196] = {
    name = "Recently Bandaged",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 60,
    itemId = 14530, -- Heavy Runecloth Bandage
    active = false,
    trackedEvents = {
      "SPELL_AURA_APPLIED",
    },
    allRanks = {
      { spellId = 11196, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  --[[
    The tuber/healthstone bucket (disjoint from the potion bucket).
  ]]--
  [15700] = {
    name = "Whipper Root Tuber",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 11951, -- Whipper Root Tuber
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 15700, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  [15701] = {
    name = "Night Dragon's Breath",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 11952, -- Night Dragon's Breath
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 15701, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    }
  },
  --[[
    Healthstones: one logical cooldown behind fifteen item/spell pairs - each
    tier exists as three distinct items AND use spells (base + two Improved
    Healthstone talent variants). Modeled as one rank chain; the icon is the
    base Major Healthstone item.
  ]]--
  [11732] = {
    name = "Major Healthstone",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE,
    cooldown = 120,
    itemId = 9421, -- Major Healthstone
    active = false,
    trackedEvents = {
      "SPELL_CAST_SUCCESS",
    },
    allRanks = {
      { spellId = 6262, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Minor Healthstone (5512)
      { spellId = 23468, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Minor Healthstone, Improved r1 (19004)
      { spellId = 23469, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Minor Healthstone, Improved r2 (19005)
      { spellId = 6263, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Lesser Healthstone (5511)
      { spellId = 23470, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Lesser Healthstone, Improved r1 (19006)
      { spellId = 23471, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Lesser Healthstone, Improved r2 (19007)
      { spellId = 5720, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Healthstone (5509)
      { spellId = 23472, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Healthstone, Improved r1 (19008)
      { spellId = 23473, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Healthstone, Improved r2 (19009)
      { spellId = 5723, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Greater Healthstone (5510)
      { spellId = 23474, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Greater Healthstone, Improved r1 (19010)
      { spellId = 23475, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Greater Healthstone, Improved r2 (19011)
      { spellId = 11732, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Major Healthstone (9421)
      { spellId = 23476, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Major Healthstone, Improved r1 (19012)
      { spellId = 23477, type = RGCW_CONSTANTS.SPELL_TYPE_BASE }, -- Major Healthstone, Improved r2 (19013)
    }
  }
}
