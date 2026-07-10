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

mod.cooldownQueue = me

me.tag = "CooldownQueue"

--[[
  Internal storage keyed by caster, then by spellId, for O(1) per-target lookups.

  cooldownQueue[sourceGuid][spellId] = {
    ["sourceGuid"] = sourceGuid,
      - {string} A unique identification for a caster (player or npc)
    ["sourceName"] = sourceName,
      - {string} Actual name of the caster
    ["categoryName"] = categoryName,
      - {string} The category the spell belongs to (e.g. "priest")
    ["spellData"] = {
      ["spellId"] = spellId,
        - {number} SpellId of the spell
      ["name"] = name,
        - {string} Name of the spell
      ["castTime"] = castTime,
        - {number} Time at which the spell was detected
      ["cooldown"] = cooldown,
        - {number} Cooldown of the spell
      ["cooldownWorstCase"] = cooldownWorstCase,
        - {number} Worst case cooldown for the cooldown.
        Assuming the enemy player has its spell fully reduced with either a talent or an item.
        Note: If an item is unlikely to be worn by players it might get omitted here
      ["active"] = boolean
        - {boolean} Whether the spell is active and tracked or not
    }
  }
]]--
local cooldownQueue = {}

--[[
  Add a cooldown to the queue. If a cooldown for the same (sourceGuid, spellId)
  already exists it is refreshed in place rather than duplicated.

  @param {string} sourceGuid
    A unique identification for a caster (player or npc).
  @param {string} sourceName
    Actual name of the caster
  @param {string} category
    The category the spell belongs to
  @param {table} spellData
    A spellData with all its relevant information
]]--
function me.AddCooldown(sourceGuid, sourceName, category, spellData)
  assert(type(sourceGuid) == "string",
    string.format("bad argument #1 to `AddCooldown` (expected string got %s)", type(sourceGuid)))

  assert(#sourceGuid > 0, "bad argument #1 to `AddCooldown` (sourceGuid must not be empty)")

  assert(type(sourceName) == "string",
    string.format("bad argument #2 to `AddCooldown` (expected string got %s)", type(sourceName)))

  assert(type(category) == "string",
    string.format("bad argument #3 to `AddCooldown` (expected string got %s)", type(category)))

  assert(type(spellData) == "table",
    string.format("bad argument #4 to `AddCooldown` (expected table got %s)", type(spellData)))

  if not spellData.active then
    mod.logger.LogWarn(me.tag, "Ignored inactive spell: " .. spellData.name)
    return -- abort
  end

  local casterBucket = cooldownQueue[sourceGuid]

  if casterBucket and casterBucket[spellData.spellId] then
    casterBucket[spellData.spellId].spellData = spellData
    mod.logger.LogDebug(
      me.tag,
      "Refreshed cooldown - '" .. spellData.name .. "' for player (" .. category .. "): "
        .. sourceName .. " (" .. sourceGuid .. ") "
    )
    return
  end

  if not casterBucket then
    casterBucket = {}
    cooldownQueue[sourceGuid] = casterBucket
  end

  casterBucket[spellData.spellId] = {
    ["sourceGuid"] = sourceGuid,
    ["sourceName"] = sourceName,
    ["categoryName"] = category,
    ["spellData"] = spellData
  }

  mod.logger.LogDebug(
    me.tag,
    "Added new cooldown - '" .. spellData.name .. "' for player (" .. category .. "): "
      .. sourceName .. " (" .. sourceGuid .. ") "
  )
end

--[[
  Remove a cooldown for a specific caster from the queue

  @param {string} sourceGuid
    A unique identification for a sourceGuid
  @param {number} spellId
]]--
function me.RemoveCooldown(sourceGuid, spellId)
  local casterBucket = cooldownQueue[sourceGuid]
  if not casterBucket or not casterBucket[spellId] then return end

  casterBucket[spellId] = nil

  if next(casterBucket) == nil then
    cooldownQueue[sourceGuid] = nil
  end

  mod.logger.LogDebug(me.tag, "Removed cooldown - '" .. spellId .. "' for player: " .. sourceGuid)
end

--[[
  Whether an entry expired longer than the prune grace ago. The grace keeps entries
  alive through the render fade (see COOLDOWN_QUEUE_PRUNE_GRACE) so pruning never
  removes an entry the renderer is still fading out.

  @param {table} cooldownEvent
    A queue entry (see the storage layout above)
  @param {number} now
    The current timestamp

  @return {boolean}
]]--
local function IsPrunable(cooldownEvent, now)
  local spellData = cooldownEvent.spellData

  return now - spellData.castTime > spellData.cooldown + RGCW_CONSTANTS.COOLDOWN_QUEUE_PRUNE_GRACE
end

--[[
  Remove long-expired cooldowns for a single caster. Cheap enough for the render
  hot path (buckets hold a handful of entries); invoked per tick for the current
  target so entries beyond the visible slots don't outlive their expiry.

  `now` is taken as a parameter (rather than calling GetTime internally) to keep
  this module free of WoW APIs and unit-testable under the headless harness.

  @param {string} sourceGuid
    A unique identification for a caster
  @param {number} now
    The current timestamp (production passes GetTime())
]]--
function me.PruneCooldownsByTarget(sourceGuid, now)
  local casterBucket = cooldownQueue[sourceGuid]
  if not casterBucket then return end

  for spellId, cooldownEvent in pairs(casterBucket) do
    if IsPrunable(cooldownEvent, now) then
      casterBucket[spellId] = nil
      mod.logger.LogDebug(me.tag, "Pruned expired cooldown - '" .. spellId .. "' for player: " .. sourceGuid)
    end
  end

  if next(casterBucket) == nil then
    cooldownQueue[sourceGuid] = nil
  end
end

--[[
  Remove long-expired cooldowns across all casters. The data-layer backstop for
  entries the renderer never visits (casters that are never retargeted); invoked
  on PLAYER_TARGET_CHANGED rather than per tick.

  @param {number} now
    The current timestamp (production passes GetTime())
]]--
function me.PruneExpiredCooldowns(now)
  for sourceGuid in pairs(cooldownQueue) do
    me.PruneCooldownsByTarget(sourceGuid, now)
  end
end

--[[
  Remove all cooldowns from queue
]]--
function me.ClearCooldownQueue()
  cooldownQueue = {}
end

--[[
  Build a single synthetic cooldown entry for the configuration preview
  (`/rgcw conf enable` -> TargetCooldownBar.ShowExampleTargetCooldownBar).

  The entry mirrors the real queue-entry shape (see the storage layout above) so
  the preview exercises the exact contract UpdateCooldownWatchSlot reads. The
  spell identity (spellId / name / icon) is resolved from SpellMap rather than
  restated; only the timing is synthetic - short, demo-friendly values so the
  preview animates both the primary and worst-case timers regardless of the
  spell's real cooldown.

  castTime is taken as a parameter (rather than calling GetTime internally) to
  keep this function free of WoW APIs and unit-testable under the headless harness.

  @param {number} castTime
    The cast timestamp to stamp on the entry (production passes GetTime()).

  @return {table}
    A cooldown entry shaped like a real queue entry.
]]--
function me.BuildExampleCooldown(castTime)
  local category, _, spellData = mod.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

  spellData.castTime = castTime
  spellData.cooldown = 10
  spellData.cooldownWorstCase = 5

  return {
    ["sourceGuid"] = "preview",
    ["sourceName"] = "Example",
    ["categoryName"] = category,
    ["spellData"] = spellData
  }
end

--[[
  Retrieve cooldowns for a specific caster

  @param {string} sourceGuid
    A unique identification for a caster

  @return {table}
    The castEvents that were found for the caster
    Note: May be an empty table
]]--
function me.GetCooldownsByTarget(sourceGuid)
  local cooldowns = {}
  local casterBucket = cooldownQueue[sourceGuid]
  if not casterBucket then return cooldowns end

  for _, cooldownEvent in pairs(casterBucket) do
    table.insert(cooldowns, cooldownEvent)
  end

  return cooldowns
end
