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

-- luacheck: globals CombatLog_Object_IsA COMBATLOG_FILTER_HOSTILE_PLAYERS GetTime bit
-- luacheck: globals COMBATLOG_OBJECT_TYPE_PET COMBATLOG_OBJECT_CONTROL_PLAYER COMBATLOG_OBJECT_REACTION_HOSTILE

local mod = rgcw
local me = {}
mod.combatLog = me

me.tag = "CombatLog"

--[[
  CLEU sub-events the addon reacts to, keyed by event name. `useDestUnit`
  selects which unit triple attributes the event: cast events act from the
  source unit; aura events describe the dest unit (the buff owner) and may
  carry no source unit at all.

  SPELL_AURA_REMOVED exists for buff-then-consume spells (Cold Blood, Presence
  of Mind, Inner Focus, ...): the game starts their cooldown when the buff is
  consumed/cancelled/purged, not when it is cast, so their SpellMap entries
  track the removal instead of the cast.

  SPELL_AURA_APPLIED exists for debuff-tracked lockouts (Recently Bandaged):
  the lockout lives on the unit that received the debuff, not on a caster
  cooldown, so the entry tracks the application on the dest unit - correct
  even when one enemy bandages another.
]]--
local supportedEvents = {
  ["SPELL_CAST_SUCCESS"] = { useDestUnit = false },
  ["SPELL_AURA_REMOVED"] = { useDestUnit = true },
  ["SPELL_AURA_APPLIED"] = { useDestUnit = true },
}

--[[
  The CLEU sub-events CombatLog dispatches on. Consumed by the trackedEvents
  validator so SpellMap entries cannot reference events that would never fire.

  @return {table}
    Read-only - returned directly, not cloned, because it feeds the combat-log
    hot path. Clone explicitly if you need to mutate.
]]--
function me.GetSupportedEvents()
  return supportedEvents
end

--[[
  Whether the acting unit's flags describe a hostile player's pet: pet-type,
  player-controlled, hostile. Totems and other guardian npcs carry different
  type bits and stay excluded; wild npcs fail the player-control check.

  @param {number} unitFlags

  @return {boolean}
]]--
local function IsHostilePlayerPet(unitFlags)
  return bit.band(unitFlags, COMBATLOG_OBJECT_TYPE_PET) > 0
    and bit.band(unitFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0
    and bit.band(unitFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
end

--[[
  Processing the details of the current combat log event. Invoked when 'COMBAT_LOG_EVENT_UNFILTERED' is fired

  @param {vararg} ...
]]--
function me.ProcessUnfilteredCombatLogEvent(...)
  -- direct destructuring instead of a helper — this runs for every CLEU line and must not allocate
  local _, event, _, _, _, sourceFlags, _, _, _, destFlags = ...
  local eventProperties = supportedEvents[event]

  if not eventProperties then
    --[[
      SPELL_SUMMON is infrastructure, not a trackable cooldown event: a hostile
      player summoning a pet reveals the pet -> owner mapping the pet-cast
      attribution needs. Deliberately NOT in supportedEvents - spells must never
      declare it in trackedEvents (ValidateTrackedEventsSupported).
    ]]--
    if event == "SPELL_SUMMON" then
      me.ProcessSummon(...)
    end

    return
  end

  -- TODO [FEATURE]: Might want to filter events in specific zones

  --[[
    Filter for hostile player events - and their pets, whose casts are
    attributed to the owning player (petCast entries). Aura events are
    attributed to the dest unit (the buff owner); cast events to the source unit.
  ]]--
  local unitFlags = eventProperties.useDestUnit and destFlags or sourceFlags

  if CombatLog_Object_IsA(unitFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) then
    me.ProcessNormal(event, eventProperties, false, ...)
  elseif IsHostilePlayerPet(unitFlags) then
    me.ProcessNormal(event, eventProperties, true, ...)
  end
  -- TODO [FEATURE]: We could track friendly cooldowns as well and put it behind a configuration flag
end

--[[
  Record the pet -> owner mapping a SPELL_SUMMON event reveals (source is the
  summoning owner, dest the freshly summoned unit). Only hostile player sources
  matter, and only actual pets - totems and guardian npcs arrive with
  Creature- guids and are not queue keys.

  @param {vararg} ...
]]--
function me.ProcessSummon(...)
  local _, _, _, sourceGuid, sourceName, sourceFlags, _, destGuid = ...

  if not CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) then return end
  if type(destGuid) ~= "string" or string.find(destGuid, "^Pet%-") == nil then return end

  mod.petOwner.RecordSummon(destGuid, sourceGuid, sourceName)
end

--[[
  @param {string} event
  @param {table} eventProperties
    The supportedEvents entry for the event; useDestUnit picks which unit
    triple the acting player is read from.
  @param {boolean} isPetSource
    Whether the acting unit is a hostile player's pet rather than the player.
  @param {vararg} ...
]]--
function me.ProcessNormal(event, eventProperties, isPetSource, ...)
  if RGCW_ENVIRONMENT.DEBUG then
    mod.debug.TrackLogNormalEvent(...)
  end

  local castTime = GetTime()
  local sourceGuid, sourceName

  if eventProperties.useDestUnit then
    sourceGuid, sourceName = select(8, ...)
  else
    sourceGuid, sourceName = select(4, ...)
  end

  if not isPetSource then
    -- directory feed for the pet-owner name -> guid promotion (see PetOwner)
    mod.petOwner.NotePlayer(sourceGuid, sourceName)
  end

  local spellId = select(12, ...)
  local category, realSpellId, spell = mod.spellMapHelper.SearchBySpellId(spellId, event)

  if not spell then
    if mod.logger.IsDebugEnabled() then
      mod.logger.LogDebug(me.tag, "SpellId " .. spellId .. " not found in spellMap - aborting...")
    end
    return
  end

  --[[
    petCast entries and pet sources must pair up: a pet-cast spell arriving
    from a player would be an npc lookalike, and a player spell arriving from
    a pet would attribute a cooldown the owner does not have.
  ]]--
  if isPetSource ~= (spell.petCast == true) then
    mod.logger.LogDebug(me.tag, "Source unit kind does not match petCast - aborting...")
    return
  end

  if spell.cooldownResets then
    me.ResetTargetedCooldowns(sourceGuid, spell)
  end

  --[[
    The enabled state is keyed by the PRIMARY spellId (the config ui only ever
    writes primaries) - gate on realSpellId so a lower-rank cast of an enabled
    spell tracks like its max rank.
  ]]--
  if not me.IsCooldownTracked(category, realSpellId) then
    mod.logger.LogDebug(me.tag, "Spell is not enabled - aborting...")
    return
  end

  if spell.petCast then
    mod.petOwner.AttributeCast(sourceGuid, category, spell, castTime)
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
    The time the cooldown started. For cast-tracked spells that is the cast
    itself; for buff-then-consume spells it is the buff removal.
  @param {string} category
]]--
function me.TrackCooldown(sourceGuid, sourceName, spell, castTime, category)
  spell.castTime = castTime -- add time when the cooldown was detected as started
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
