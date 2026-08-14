--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

--[[
  Runtime behavior of the friendly-side combat-log path: with the
  trackFriendlyCooldowns option off (the default) friendly casts are ignored
  entirely; with it on, friendly players and their pets dispatch through the
  same ProcessNormal pipeline as hostiles, gate against the FRIENDLY side of
  the per-side configuration store, and land in the shared caster-keyed queue
  with the per-entry friendly marker.

  Follows the PetOwnerSpec pattern: PetOwner.lua is re-dofiled per test for
  fresh session state, all globals - including the CooldownWatchConfiguration
  SavedVariable - go through WowStubs.install (busted insulates spec files, so
  plain global assignments would be invisible to production code), and the
  combat-log unit-flag globals carry their real Blizzard values so the flag
  arithmetic is exercised for real.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it before_each after_each rgcw bit
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Friendly cooldown detection", function()
  local MIND_BLAST = 10947
  local INNER_FOCUS = 14751
  local SPELL_LOCK = 19647

  local FRIEND_GUID = "Player-4234-000000C1"
  local FRIEND_NAME = "Testfriend"
  local ENEMY_GUID = "Player-4234-000000AB"
  local ENEMY_NAME = "Testenemy"
  local PET_GUID = "Pet-0-4234-0-6610-417-0303F859E9"
  local PET_NAME = "Zhakrin"

  -- real Blizzard combat-log object flag values, so the band checks run for real
  local HOSTILE_PLAYER_FLAGS = 0x548 -- outsider + hostile + player-controlled + player
  local FRIENDLY_PLAYER_FLAGS = 0x512 -- party + friendly + player-controlled + player
  local FRIENDLY_PET_FLAGS = 0x1112 -- party + friendly + player-controlled + pet

  local restoreStubs

  --[[
    Feed one synthetic CLEU line through the production entry point.
  ]]--
  local function processEvent(event, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, spellId)
    rgcw.combatLog.ProcessUnfilteredCombatLogEvent(
      0, event, false, srcGuid, srcName, srcFlags, 0,
      dstGuid, dstName, dstFlags, 0, spellId, "TestSpell", 32)
  end

  local function processFriendlyCast(spellId)
    processEvent("SPELL_CAST_SUCCESS", FRIEND_GUID, FRIEND_NAME, FRIENDLY_PLAYER_FLAGS,
      ENEMY_GUID, ENEMY_NAME, HOSTILE_PLAYER_FLAGS, spellId)
  end

  local function processHostileCast(spellId)
    processEvent("SPELL_CAST_SUCCESS", ENEMY_GUID, ENEMY_NAME, HOSTILE_PLAYER_FLAGS,
      FRIEND_GUID, FRIEND_NAME, FRIENDLY_PLAYER_FLAGS, spellId)
  end

  --[[
    Queued entries for a caster, keyed by primary spellId.
  ]]--
  local function queuedEntries(casterGuid)
    local queued = {}

    for _, cooldownEvent in ipairs(rgcw.cooldownQueue.GetCooldownsByTarget(casterGuid)) do
      queued[cooldownEvent.spellData.spellId] = cooldownEvent
    end

    return queued
  end

  before_each(function()
    -- fresh PetOwner session state per test (pet-owner map, directory, parked casts)
    dofile("code/PetOwner.lua")
    rgcw.petOwner.ScanOwnerName = function() return nil end

    --[[
      A fresh, empty SavedVariable per test: the accessors lazily create every
      store they touch, and each scenario opts spells in per side through the
      production accessors instead of hand-writing store tables.
    ]]--
    restoreStubs = wowStubs.install({
      CooldownWatchConfiguration = {},
      CombatLog_Object_IsA = function(unitFlags, mask)
        return bit.band(unitFlags, mask) == mask
      end,
      COMBATLOG_FILTER_HOSTILE_PLAYERS = 0x548,
      COMBATLOG_OBJECT_TYPE_PLAYER = 0x400,
      COMBATLOG_OBJECT_TYPE_PET = 0x1000,
      COMBATLOG_OBJECT_CONTROL_PLAYER = 0x100,
      COMBATLOG_OBJECT_REACTION_HOSTILE = 0x40,
      COMBATLOG_OBJECT_REACTION_FRIENDLY = 0x10,
    })
  end)

  after_each(function()
    restoreStubs()
    rgcw.cooldownQueue.ClearCooldownQueue()
  end)

  it("ignores a friendly player's cast while friendly tracking is off (the default)", function()
    rgcw.configuration.UpdateCooldownConfigurationState(true, "priest", MIND_BLAST, true)

    processFriendlyCast(MIND_BLAST)

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(FRIEND_GUID))
  end)

  it("queues a friendly cast under the caster's guid with the friendly marker", function()
    rgcw.configuration.UpdateTrackFriendlyCooldownsState(true)
    rgcw.configuration.UpdateCooldownConfigurationState(true, "priest", MIND_BLAST, true)
    rgcw.configuration.UpdateCooldownConfigurationState(true, "priest", MIND_BLAST)

    processFriendlyCast(MIND_BLAST)
    processHostileCast(MIND_BLAST)

    local friendlyEntry = queuedEntries(FRIEND_GUID)[MIND_BLAST]
    local hostileEntry = queuedEntries(ENEMY_GUID)[MIND_BLAST]

    assert.is_true(friendlyEntry.spellData.friendly)
    assert.equal(FRIEND_NAME, friendlyEntry.sourceName)
    -- hostile entries never carry the field, flag on or off
    assert.is_nil(hostileEntry.spellData.friendly)
  end)

  it("gates each side against its own per-spell state", function()
    rgcw.configuration.UpdateTrackFriendlyCooldownsState(true)

    -- enabled for enemies, disabled for friendlies
    rgcw.configuration.UpdateCooldownConfigurationState(true, "priest", MIND_BLAST)
    rgcw.configuration.UpdateCooldownConfigurationState(false, "priest", MIND_BLAST, true)

    processFriendlyCast(MIND_BLAST)
    processHostileCast(MIND_BLAST)

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(FRIEND_GUID))
    assert.is_true(rgcw.cooldownQueue.HasCooldowns(ENEMY_GUID))

    rgcw.cooldownQueue.ClearCooldownQueue()

    -- the inverse: disabled for enemies, enabled for friendlies
    rgcw.configuration.UpdateCooldownConfigurationState(false, "priest", MIND_BLAST)
    rgcw.configuration.UpdateCooldownConfigurationState(true, "priest", MIND_BLAST, true)

    processFriendlyCast(MIND_BLAST)
    processHostileCast(MIND_BLAST)

    assert.is_true(rgcw.cooldownQueue.HasCooldowns(FRIEND_GUID))
    assert.is_false(rgcw.cooldownQueue.HasCooldowns(ENEMY_GUID))
  end)

  it("attributes a friendly aura-tracked event by the dest unit with the friendly marker", function()
    rgcw.configuration.UpdateTrackFriendlyCooldownsState(true)
    rgcw.configuration.UpdateCooldownConfigurationState(true, "priest", INNER_FOCUS, true)

    -- the tracked event comes from the catalog entry, never restated
    local _, _, innerFocus = rgcw.spellMapHelper.GetSpellById(INNER_FOCUS)
    assert.is_not_nil(innerFocus)

    -- aura events describe the dest unit (the buff owner) and may carry no source
    processEvent(innerFocus.trackedEvents[1], "", "", 0,
      FRIEND_GUID, FRIEND_NAME, FRIENDLY_PLAYER_FLAGS, INNER_FOCUS)

    local entry = queuedEntries(FRIEND_GUID)[INNER_FOCUS]

    assert.is_not_nil(entry)
    assert.is_true(entry.spellData.friendly)
  end)

  it("attributes a friendly pet's cast to the owning friendly player", function()
    rgcw.configuration.UpdateTrackFriendlyCooldownsState(true)
    rgcw.configuration.UpdateCooldownConfigurationState(true, "warlock", SPELL_LOCK, true)

    processEvent("SPELL_SUMMON", FRIEND_GUID, FRIEND_NAME, FRIENDLY_PLAYER_FLAGS,
      PET_GUID, PET_NAME, FRIENDLY_PET_FLAGS, 691)
    processEvent("SPELL_CAST_SUCCESS", PET_GUID, PET_NAME, FRIENDLY_PET_FLAGS,
      ENEMY_GUID, ENEMY_NAME, HOSTILE_PLAYER_FLAGS, SPELL_LOCK)

    local entry = queuedEntries(FRIEND_GUID)[SPELL_LOCK]

    assert.is_not_nil(entry)
    assert.is_true(entry.spellData.friendly)
    assert.is_false(rgcw.cooldownQueue.HasCooldowns(PET_GUID))
  end)

  it("keeps the friendly marker on a cast parked until the pet is sighted", function()
    rgcw.configuration.UpdateTrackFriendlyCooldownsState(true)
    rgcw.configuration.UpdateCooldownConfigurationState(true, "warlock", SPELL_LOCK, true)

    -- no summon seen: the cast parks with the marker already stamped
    processEvent("SPELL_CAST_SUCCESS", PET_GUID, PET_NAME, FRIENDLY_PET_FLAGS,
      ENEMY_GUID, ENEMY_NAME, HOSTILE_PLAYER_FLAGS, SPELL_LOCK)

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(FRIEND_GUID))

    rgcw.petOwner.RecordSighting(PET_GUID, FRIEND_GUID, FRIEND_NAME)

    local entry = queuedEntries(FRIEND_GUID)[SPELL_LOCK]

    assert.is_not_nil(entry)
    assert.is_true(entry.spellData.friendly)
  end)

  it("ignores friendly summons and pet casts while friendly tracking is off", function()
    rgcw.configuration.UpdateCooldownConfigurationState(true, "warlock", SPELL_LOCK, true)

    processEvent("SPELL_SUMMON", FRIEND_GUID, FRIEND_NAME, FRIENDLY_PLAYER_FLAGS,
      PET_GUID, PET_NAME, FRIENDLY_PET_FLAGS, 691)
    processEvent("SPELL_CAST_SUCCESS", PET_GUID, PET_NAME, FRIENDLY_PET_FLAGS,
      ENEMY_GUID, ENEMY_NAME, HOSTILE_PLAYER_FLAGS, SPELL_LOCK)

    assert.is_nil((rgcw.petOwner.GetOwner(PET_GUID)))
    assert.is_false(rgcw.cooldownQueue.HasCooldowns(FRIEND_GUID))
  end)

  it("fans a friendly shared-cooldown cast out to its siblings on the friendly side", function()
    rgcw.configuration.UpdateTrackFriendlyCooldownsState(true)

    -- members come from the catalog group, never restated
    local groupMembers = rgcw.spellMap.GetSharedCooldownGroup("shaman_shocks")
    assert.is_not_nil(groupMembers)

    local castSpellId = groupMembers[1]
    local category = rgcw.spellMapHelper.GetSpellById(castSpellId)

    rgcw.configuration.UpdateCooldownConfigurationState(true, category, castSpellId, true)

    processFriendlyCast(castSpellId)

    local entries = queuedEntries(FRIEND_GUID)

    for _, memberSpellId in ipairs(groupMembers) do
      assert.is_not_nil(entries[memberSpellId])
      assert.is_true(entries[memberSpellId].spellData.friendly)
    end
  end)
end)
