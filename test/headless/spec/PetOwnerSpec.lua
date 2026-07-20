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
  Runtime behavior of the pet-cast attribution path (CombatLog + PetOwner):
  hostile pet casts pass the widened combat-log gate, resolve their owner
  through the layered PetOwner resolution (SPELL_SUMMON map, tooltip-scanned
  name + player directory, sightings) and land in the queue under the OWNER's
  guid - or park until a layer supplies it.

  PetOwner.lua is re-dofiled per test for fresh session state (the CommSpec
  pattern), and its single WoW-api seam - ScanOwnerName - is stubbed. Spell
  identities are resolved from SpellMap (Spell Lock, the petCast reference
  entry), never restated. The combat-log unit-flag globals are installed with
  their real Blizzard values so the gate arithmetic is exercised for real.

  All globals - including the CooldownWatchConfiguration SavedVariable - go
  through WowStubs.install: busted insulates spec files, so a plain global
  assignment lands in the insulated environment and production code (dofiled
  by the Bootstrap against the real _G) would never see it.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it before_each after_each rgcw bit
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Pet-cast cooldown attribution", function()
  local SPELL_LOCK_PRIMARY = 19647
  local SPELL_LOCK_RANK_ONE = 19244
  local DEATH_COIL = 17926

  local PET_GUID = "Pet-0-4234-0-6610-417-0202F859E9"
  local PET_NAME = "Zhakrin"
  local OWNER_GUID = "Player-4234-000000AB"
  local OWNER_NAME = "Testwarlock"
  local VICTIM_GUID = "Player-4234-000000FF"

  -- real Blizzard combat-log object flag values, so the band checks run for real
  local HOSTILE_PLAYER_FLAGS = 0x548 -- outsider + hostile + player-controlled + player
  local HOSTILE_PET_FLAGS = 0x1148 -- outsider + hostile + player-controlled + pet
  local FRIENDLY_PLAYER_FLAGS = 0x511 -- mine + friendly + player-controlled + player

  local restoreStubs

  --[[
    Feed one synthetic CLEU line through the production entry point.
  ]]--
  local function processEvent(event, srcGuid, srcName, srcFlags, dstGuid, dstFlags, spellId)
    rgcw.combatLog.ProcessUnfilteredCombatLogEvent(
      0, event, false, srcGuid, srcName, srcFlags, 0,
      dstGuid, "Victim", dstFlags, 0, spellId, "TestSpell", 32)
  end

  local function processPetCast(spellId)
    processEvent("SPELL_CAST_SUCCESS", PET_GUID, PET_NAME, HOSTILE_PET_FLAGS,
      VICTIM_GUID, FRIENDLY_PLAYER_FLAGS, spellId)
  end

  local function processPlayerCast(spellId)
    processEvent("SPELL_CAST_SUCCESS", OWNER_GUID, OWNER_NAME, HOSTILE_PLAYER_FLAGS,
      VICTIM_GUID, FRIENDLY_PLAYER_FLAGS, spellId)
  end

  --[[
    Set of primary spellIds currently queued for a caster.
  ]]--
  local function queuedSpellIds(casterGuid)
    local queued = {}

    for _, cooldownEvent in ipairs(rgcw.cooldownQueue.GetCooldownsByTarget(casterGuid)) do
      queued[cooldownEvent.spellData.spellId] = true
    end

    return queued
  end

  before_each(function()
    -- fresh PetOwner session state per test (pet-owner map, directory, parked casts)
    dofile("code/PetOwner.lua")
    -- the tooltip scan is PetOwner's only WoW-api seam; default to "client does
    -- not know the guid", individual tests override with a name
    rgcw.petOwner.ScanOwnerName = function() return nil end

    restoreStubs = wowStubs.install({
      CooldownWatchConfiguration = {
        cooldownConfiguration = {
          warlock = {
            [SPELL_LOCK_PRIMARY] = true,
            [DEATH_COIL] = true,
          },
        },
      },
      CombatLog_Object_IsA = function(unitFlags, mask)
        return bit.band(unitFlags, mask) == mask
      end,
      COMBATLOG_FILTER_HOSTILE_PLAYERS = 0x548,
      COMBATLOG_OBJECT_TYPE_PET = 0x1000,
      COMBATLOG_OBJECT_CONTROL_PLAYER = 0x100,
      COMBATLOG_OBJECT_REACTION_HOSTILE = 0x40,
    })
  end)

  after_each(function()
    restoreStubs()
    rgcw.cooldownQueue.ClearCooldownQueue()
  end)

  it("queues a pet cast under the owner recorded by SPELL_SUMMON", function()
    processEvent("SPELL_SUMMON", OWNER_GUID, OWNER_NAME, HOSTILE_PLAYER_FLAGS,
      PET_GUID, HOSTILE_PET_FLAGS, 691)

    -- rank 1 cast: exercises the alias -> primary resolution and the
    -- primary-keyed enabled gate on the pet path
    processPetCast(SPELL_LOCK_RANK_ONE)

    assert.same({ [SPELL_LOCK_PRIMARY] = true }, queuedSpellIds(OWNER_GUID))
    assert.is_false(rgcw.cooldownQueue.HasCooldowns(PET_GUID))
  end)

  it("ignores summons of non-pet units and non-player summoners", function()
    processEvent("SPELL_SUMMON", OWNER_GUID, OWNER_NAME, HOSTILE_PLAYER_FLAGS,
      "Creature-0-4234-0-6610-15439-0000000001", 0x1148, 2894)
    processEvent("SPELL_SUMMON", "Creature-0-4234-0-6610-4277-0000000002", "Eye of Kilrogg", 0x1148,
      PET_GUID, HOSTILE_PET_FLAGS, 126)

    assert.is_nil((rgcw.petOwner.GetOwner(PET_GUID)))
  end)

  it("parks an unattributable cast and flushes it when the pet is sighted", function()
    processPetCast(SPELL_LOCK_PRIMARY)

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(OWNER_GUID))
    assert.is_false(rgcw.cooldownQueue.HasCooldowns(PET_GUID))

    -- the player targets the pet: Target.lua reads the owner guid off the unit
    rgcw.petOwner.RecordSighting(PET_GUID, OWNER_GUID, OWNER_NAME)

    assert.same({ [SPELL_LOCK_PRIMARY] = true }, queuedSpellIds(OWNER_GUID))
  end)

  it("attributes at cast time when the scanned owner name is in the player directory", function()
    -- any hostile player event feeds the directory, tracked spell or not
    processPlayerCast(999999)

    rgcw.petOwner.ScanOwnerName = function() return OWNER_NAME end

    processPetCast(SPELL_LOCK_PRIMARY)

    assert.same({ [SPELL_LOCK_PRIMARY] = true }, queuedSpellIds(OWNER_GUID))
  end)

  it("parks a name-grade cast until the owner's guid surfaces in the log", function()
    rgcw.petOwner.ScanOwnerName = function() return OWNER_NAME end

    processPetCast(SPELL_LOCK_PRIMARY)

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(OWNER_GUID))

    -- the owner shows up in the combat log: name promotes to guid, cast flushes
    processPlayerCast(999999)

    assert.same({ [SPELL_LOCK_PRIMARY] = true }, queuedSpellIds(OWNER_GUID))
  end)

  it("drops pet-sourced casts of player spells and player-sourced casts of petCast spells", function()
    processEvent("SPELL_SUMMON", OWNER_GUID, OWNER_NAME, HOSTILE_PLAYER_FLAGS,
      PET_GUID, HOSTILE_PET_FLAGS, 691)

    processPetCast(DEATH_COIL)
    processPlayerCast(SPELL_LOCK_PRIMARY)

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(OWNER_GUID))
    assert.is_false(rgcw.cooldownQueue.HasCooldowns(PET_GUID))
  end)

  it("drops a parked cast whose cooldown already ran out at flush time", function()
    processPetCast(SPELL_LOCK_PRIMARY)

    -- Spell Lock's cooldown has fully elapsed before the pet is ever sighted
    local _, _, spell = rgcw.spellMapHelper.GetSpellById(SPELL_LOCK_PRIMARY)
    local restoreTime = wowStubs.install({
      GetTime = function() return spell.cooldown + 1 end,
    })

    rgcw.petOwner.RecordSighting(PET_GUID, OWNER_GUID, OWNER_NAME)
    restoreTime()

    assert.is_false(rgcw.cooldownQueue.HasCooldowns(OWNER_GUID))
  end)
end)
