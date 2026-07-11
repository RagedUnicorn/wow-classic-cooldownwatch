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

-- luacheck: globals CombatLog_Object_IsA COMBATLOG_FILTER_HOSTILE_PLAYERS GetTime

local mod = rgcw
local me = {}
mod.combatLog = me

me.tag = "CombatLog"

--[[
  Processing the details of the current combat log event. Invoked when 'COMBAT_LOG_EVENT_UNFILTERED' is fired

  @param {vararg} ...
]]--
function me.ProcessUnfilteredCombatLogEvent(...)
  -- direct destructuring instead of a helper — this runs for every CLEU line and must not allocate
  local _, event, _, _, _, sourceFlags = ...

  -- TODO [FEATURE]: Might want to filter events in specific zones

  --[[
    Filter for hostile player events only
  ]]--
  if CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) then
    me.ProcessEventHostilePlayers(event, ...)
  end
  -- TODO [FEATURE]: We could track friendly cooldowns as well and put it behind a configuration flag
end

--[[
  @param {string} event
  @param {vararg} ...
]]--
function me.ProcessEventHostilePlayers(event, ...)
  if event ~= "SPELL_CAST_SUCCESS" then
    if mod.logger.IsDebugEnabled() then
      mod.logger.LogDebug(me.tag, "Ignore unsupported event: " .. event)
    end
    return
  end

  me.ProcessNormal(event, ...)
end

--[[
  @param {string} event
  @param {vararg} ...
]]--
function me.ProcessNormal(event, ...)
  if RGCW_ENVIRONMENT.DEBUG then
    mod.debug.TrackLogNormalEvent(...)
  end

  local castTime = GetTime()
  local sourceGuid, sourceName = select(4, ...)
  local spellId = select(12, ...)
  local category, _, spell = mod.spellMapHelper.SearchBySpellId(spellId, event)

  if not spell then
    if mod.logger.IsDebugEnabled() then
      mod.logger.LogDebug(me.tag, "SpellId " .. spellId .. " not found in spellMap - aborting...")
    end
    return
  end

  if spell.cooldownResets then
    me.ResetTargetedCooldowns(sourceGuid, spell)
  end

  if not me.IsCooldownTracked(category, spellId) then
    mod.logger.LogDebug(me.tag, "Spell is not enabled - aborting...")
    return
  end

  me.TrackCooldown(sourceGuid, sourceName, spell, castTime, category)
end

--[[
  Remove every cooldown listed in the spell's cooldownResets from the caster's
  queue (e.g. rogue Preparation, mage Cold Snap). Runs before the per-spell
  enabled gate on purpose: a reset corrects cooldowns the queue already shows,
  so it must apply even when the player never enabled tracking for the trigger
  spell itself - otherwise the bar keeps showing cooldowns the enemy no longer
  has. It never adds tracking the player opted out of; the trigger's own
  cooldown still only queues when enabled.

  RemoveCooldown is a no-op for unknown keys, which covers targets that were
  never queued before the trigger fired.

  @param {string} sourceGuid
  @param {table} spell
    A primary spell entry carrying a cooldownResets array of primary spellIds.
]]--
function me.ResetTargetedCooldowns(sourceGuid, spell)
  for _, targetSpellId in ipairs(spell.cooldownResets) do
    mod.cooldownQueue.RemoveCooldown(sourceGuid, targetSpellId)
  end
end

--[[
  @param {string} category
  @param {number} spellId

  @return {boolean}
    true  - If the cooldown is enabled
    false - If the cooldown is disabled
]]--
function me.IsCooldownTracked(category, spellId)
  assert(type(category) == "string",
    string.format("bad argument #1 to `IsCooldownTracked` (expected string got %s)", type(category)))

  assert(type(spellId) == "number",
    string.format("bad argument #2 to `IsCooldownTracked` (expected number got %s)", type(spellId)))

  return mod.configuration.GetCooldownConfigurationState(category, spellId)
end

--[[
  Add a cooldown to the cooldownqueue. If the spell belongs to a shared-cooldown
  group every sibling in that group is queued with the same castTime so the UI
  reflects the in-game shared cooldown.

  @param {string} sourceGuid
  @param {string} sourceName
  @param {table} spell
  @param {number} castTime
  @param {string} category
]]--
function me.TrackCooldown(sourceGuid, sourceName, spell, castTime, category)
  spell.castTime = castTime -- add time when spell was detected
  mod.cooldownQueue.AddCooldown(sourceGuid, sourceName, category, spell)

  if spell.sharedCooldownGroup then
    me.TrackSharedCooldownSiblings(sourceGuid, sourceName, spell, castTime, category)
  end
end

--[[
  Queue every sibling of a shared-cooldown group with the same castTime as the
  spell that actually fired. Fan-out is unconditional: shared cooldowns are a
  game-mechanics fact, so once the originating spell is tracked, every sibling
  is on cooldown too and must surface in the queue regardless of the user's
  per-sibling enabled flag — otherwise the UI would falsely show a sibling as
  available.

  Each sibling passes through AddCooldown individually, so its cooldown value
  resolves against its own worst-case configuration (CooldownQueue.ResolveCooldown)
  — one member's toggle never propagates to the others.

  @param {string} sourceGuid
  @param {string} sourceName
  @param {table} originalSpell
  @param {number} castTime
  @param {string} category
]]--
function me.TrackSharedCooldownSiblings(sourceGuid, sourceName, originalSpell, castTime, category)
  local siblingIds = mod.spellMap.GetSharedCooldownGroup(originalSpell.sharedCooldownGroup)

  if not siblingIds then return end

  for _, siblingSpellId in ipairs(siblingIds) do
    if siblingSpellId ~= originalSpell.spellId then
      local _, _, siblingSpell = mod.spellMapHelper.GetSpellById(siblingSpellId)

      if siblingSpell then
        siblingSpell.castTime = castTime
        mod.cooldownQueue.AddCooldown(sourceGuid, sourceName, category, siblingSpell)
      end
    end
  end
end
