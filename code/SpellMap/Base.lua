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
mod.spellMapBase = me

me.tag = "SpellMapBase"

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

--[[
  The catalog itself lives in the per-category slice files under
  code/SpellMap/Base/ (loaded before this file), each registering its
  category on mod.spellMapBaseClasses. Assembling them here keeps a single
  ownership point for the full base map.
]]--
local spellMap = {}

for category, spells in pairs(mod.spellMapBaseClasses) do
  spellMap[category] = spells
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
  Get the raw base spellMap. Callers must not mutate the returned table; the
  assembler clones it when building the assembled per-branch map.

  @return {table}
    The base spellMap
]]--
function me.GetMap()
  return spellMap
end

--[[
  Get the raw shared-cooldown groups keyed by group name. Branch overlays do
  not edit groups yet, so the orchestrator serves this table unchanged for
  every branch. Callers must not mutate the returned table.

  @return {table}
    Table of groupName -> list of primary spellIds
]]--
function me.GetSharedCooldownGroups()
  return sharedCooldownGroups
end
