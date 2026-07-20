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

-- luacheck: globals C_Timer GetTime

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
    ["expired"] = expired,
      - {boolean} Optional, set by the entry's one-shot expiry timer when the caster is
      the current target. The render pass reacts to the flag by playing the expiry fade;
      the fade's OnFinished removes the entry. Cleared on refresh - a recast makes the
      entry live again
    ["spellData"] = {
      ["spellId"] = spellId,
        - {number} SpellId of the spell
      ["name"] = name,
        - {string} Name of the spell
      ["castTime"] = castTime,
        - {number} Time at which the spell was detected
      ["cooldown"] = cooldown,
        - {number} Cooldown of the spell. The resolved value: when the player set a
        manual override or opted into assuming the worst case for the spell,
        ResolveCooldown already promoted that value into this field before the
        entry was written
      ["cooldownWorstCase"] = cooldownWorstCase,
        - {number} Worst case cooldown for the cooldown.
        Assuming the enemy player has its spell fully reduced with either a talent or an item.
        Note: If an item is unlikely to be worn by players it might get omitted here
        Note: nil when the worst case was promoted into cooldown (see ResolveCooldown)
      ["itemId"] = itemId,
        - {number} Optional, item-triggered cooldowns only. The item whose "Use" effect
        casts the tracked spell; the ui resolves the icon through it (GuiHelper.GetIconId)
      ["active"] = boolean
        - {boolean} Whether the spell is active and tracked or not
    }
  }
]]--
local cooldownQueue = {}

--[[
  Resolve which cooldown value a spell should run with before it is queued.
  Resolution order:

  1. Manual override (CooldownMenu) — an explicit numeric value replaces the
     cooldown entirely, worst-case settings included
  2. Per-spell toggle (CooldownMenu) — an explicit opt-in or opt-out always wins
  3. Global default (GeneralMenu) — applies to spells the player never configured
  4. Base cooldown

  When the manual override or the worst case applies its value is promoted into
  `cooldown` and `cooldownWorstCase` is cleared, so the bar shows a single
  authoritative timer (the small hint timer hides itself when the field is nil).

  Mutates spellData in place — safe because every enqueue path hands over a
  clone (SearchBySpellId / GetSpellById), never the SpellMap base entry.
  Resolution happens once per enqueue: toggling a setting off leaves in-flight
  entries untouched and takes effect on the next cast.

  @param {string} category
    The category the spell belongs to
  @param {table} spellData
    A spellData with all its relevant information
]]--
function me.ResolveCooldown(category, spellData)
  local manualCooldown = mod.configuration.GetCooldownManualOverride(category, spellData.spellId)

  if manualCooldown ~= nil then
    spellData.cooldown = manualCooldown
    spellData.cooldownWorstCase = nil

    return
  end

  if spellData.cooldownWorstCase == nil then return end

  local override = mod.configuration.GetCooldownWorstCaseOverride(category, spellData.spellId)

  if override == false then return end
  if override == nil and not mod.configuration.IsGlobalWorstCaseAssumed() then return end

  spellData.cooldown = spellData.cooldownWorstCase
  spellData.cooldownWorstCase = nil
end

--[[
  Schedule the one-shot timer that ends a queued cooldown. Expiry is an event the
  data layer owns - the render tick only draws; it never computes whether a cooldown
  ran out.

  C_Timer.After cannot be cancelled, so a refresh simply schedules a newer timer and
  orphans the old one: the callback validates its generation token (the castTime
  captured at scheduling) against the live entry and bails out when it lost the race
  (the entry was refreshed, removed or pruned in the meantime).

  On a valid fire the entry's fate depends on the caster:
  - current target: flag the entry expired and leave it queued. The render pass reacts
    to the flag by playing the expiry fade; the fade's OnFinished removes the entry
  - anyone else: remove immediately - the data-layer prune that keeps buckets of
    casters who are never (re)targeted from accumulating for the length of a session

  Entries flagged while they cannot be rendered (preview mode owns the slots, or the
  target changes away before the fade ran) are covered by the PruneExpiredCooldowns
  backstop on the next target change.

  @param {string} sourceGuid
    A unique identification for a caster
  @param {table} spellData
    The queued entry's spellData (cooldown already resolved, castTime stamped)
]]--
local function ScheduleExpiryTimer(sourceGuid, spellData)
  local spellId = spellData.spellId
  local castTime = spellData.castTime

  C_Timer.After(castTime + spellData.cooldown - GetTime(), function()
    local casterBucket = cooldownQueue[sourceGuid]
    local entry = casterBucket and casterBucket[spellId]

    if not entry or entry.spellData.castTime ~= castTime then return end -- orphaned timer

    if mod.target.GetCurrentTargetGuid() == sourceGuid then
      entry.expired = true
    else
      me.RemoveCooldown(sourceGuid, spellId)
    end
  end)
end

--[[
  Add a cooldown to the queue. If a cooldown for the same (sourceGuid, spellId)
  already exists it is refreshed in place rather than duplicated.

  The spell's cooldown value is resolved here (see ResolveCooldown) so every
  enqueue path — combat log, shared-cooldown sibling fan-out, tests — applies
  the player's worst-case configuration consistently.

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

  me.ResolveCooldown(category, spellData)

  local casterBucket = cooldownQueue[sourceGuid]

  if casterBucket and casterBucket[spellData.spellId] then
    casterBucket[spellData.spellId].spellData = spellData
    -- a recast makes the entry live again; the replaced castTime orphans the old expiry timer
    casterBucket[spellData.spellId].expired = nil
    mod.logger.LogDebug(
      me.tag,
      "Refreshed cooldown - '" .. spellData.name .. "' for player (" .. category .. "): "
        .. sourceName .. " (" .. sourceGuid .. ") "
    )
  else
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

  ScheduleExpiryTimer(sourceGuid, spellData)

  --[[
    The render ticker only runs while there is something to render. An enqueue is one of
    its start edges: if the cooldown belongs to the current target while the bar is idle,
    the ticker has to come back up (WakeRenderTicker no-ops in every other situation).
  ]]--
  mod.targetCooldownBar.WakeRenderTicker()
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
  Remove long-expired cooldowns for a single caster. The per-caster worker behind
  PruneExpiredCooldowns; not part of the render path - expiry removal is owned by
  the one-shot timers (see ScheduleExpiryTimer).

  `now` is taken as a parameter (rather than calling GetTime internally) so the
  prune logic stays unit-testable with synthetic timestamps under the headless
  harness.

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
  Remove long-expired cooldowns across all casters; invoked on PLAYER_TARGET_CHANGED.
  The backstop behind the one-shot expiry timers: a timer that fired for the current
  target only flags its entry and relies on the render fade to remove it, so an entry
  flagged while it could not be rendered (preview mode owned the slots, or the target
  changed away before the fade ran) would otherwise linger. The prune grace keeps the
  sweep from racing a fade that is still playing.

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
  Whether any cooldown is queued for a caster. O(1): emptied buckets are removed
  eagerly (RemoveCooldown / PruneCooldownsByTarget), so bucket presence implies at
  least one entry. Entries in the post-expiry prune grace still count - the render
  layer is still fading them out, so they are something to render.

  @param {string} sourceGuid
    A unique identification for a caster

  @return {boolean}
]]--
function me.HasCooldowns(sourceGuid)
  return cooldownQueue[sourceGuid] ~= nil
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
  Comparator for GetCooldownsByTarget: soonest ready first (castTime + cooldown
  ascending), spellId as tiebreaker. The order must be a function of the entries
  themselves - never of Lua hash order - because the render layer binds the returned
  array positionally to fixed slots. Soonest-ready-first puts the most urgent threat
  in the first slot, and when more cooldowns are tracked than there are slots the
  truncation deterministically keeps the ones that come back soonest. Ready times are
  fixed per entry, so icons only shift when the tracked set itself changes (a new cast
  with a short cooldown inserts mid-bar).
]]--
local function CompareCooldowns(a, b)
  local aReadyTime = a.spellData.castTime + a.spellData.cooldown
  local bReadyTime = b.spellData.castTime + b.spellData.cooldown

  if aReadyTime ~= bReadyTime then
    return aReadyTime < bReadyTime
  end

  return a.spellData.spellId < b.spellData.spellId
end

--[[
  Reused snapshot array for GetCooldownsByTarget. The function is called 20 times
  per second from the render ticker (TargetCooldownBarOnUpdate) while it is running;
  refilling one module-local array instead of allocating a fresh table per call
  keeps the render path free of steady GC churn.
]]--
local cooldownSnapshot = {}

--[[
  Retrieve cooldowns for a specific caster, ordered soonest ready first
  (see CompareCooldowns)

  @param {string} sourceGuid
    A unique identification for a caster

  @return {table}
    The castEvents that were found for the caster
    Note: May be an empty table
    Note: A module-owned scratch array rebuilt on every call - only valid until
    the next call; do not retain or mutate it. The sole production caller
    (TargetCooldownBarOnUpdate) consumes it synchronously within the same tick.
]]--
function me.GetCooldownsByTarget(sourceGuid)
  local count = 0
  local casterBucket = cooldownQueue[sourceGuid]

  if casterBucket then
    for _, cooldownEvent in pairs(casterBucket) do
      count = count + 1
      cooldownSnapshot[count] = cooldownEvent
    end
  end

  -- truncate entries left over from a previous, larger snapshot
  for i = #cooldownSnapshot, count + 1, -1 do
    cooldownSnapshot[i] = nil
  end

  table.sort(cooldownSnapshot, CompareCooldowns)

  return cooldownSnapshot
end
