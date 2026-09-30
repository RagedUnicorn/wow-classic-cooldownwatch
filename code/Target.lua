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

-- luacheck: read globals UnitIsEnemy UnitIsFriend UnitGUID UnitPlayerControlled UnitOwnerGUID
-- luacheck: read globals GetPlayerInfoByGUID

local mod = rgcw
local me = {}

mod.target = me

me.tag = "Target"

local currentTargetGuid = ""

--[[
  Resolve a targeted player pet to its owning player. Cooldowns are keyed by
  the owner's guid (pet guids change on every resummon), so targeting the pet
  renders the owner's full cooldown bucket - which includes the pet-cast
  entries the pet itself queued (see PetOwner). The sighting is recorded
  either way, flushing any casts parked while the owner was unknown.
  Side-agnostic: hostile pets arrive via the enemy gate, friendly pets via the
  showFriendlyTargetCooldowns gate in UpdateCurrentTarget.

  @param {string} targetId

  @return {string}
    the owner's guid when the target is a player pet with a resolvable owner;
    the passed targetId otherwise.
]]--
local function ResolvePetTarget(targetId)
  if targetId == nil then return targetId end
  if string.find(targetId, "^Pet%-") == nil then return targetId end
  if not UnitPlayerControlled(RGCW_CONSTANTS.UNIT_ID_TARGET) then return targetId end
  if UnitOwnerGUID == nil then return targetId end

  local ownerGuid = UnitOwnerGUID(RGCW_CONSTANTS.UNIT_ID_TARGET)

  if ownerGuid == nil then return targetId end

  -- may return nothing for players the client has not met yet; the sighting keeps
  -- a name it already knows
  local ownerName = select(6, GetPlayerInfoByGUID(ownerGuid))

  mod.petOwner.RecordSighting(targetId, ownerGuid, ownerName)

  mod.logger.LogDebug(me.tag, "Redirecting pet target " .. targetId .. " to owner " .. ownerGuid)

  return ownerGuid
end

--[[
  Returns the players current target uid or an empty string if the player has no target.

  @return {string}
]]--
function me.GetCurrentTargetGuid()
  return currentTargetGuid
end

--[[
  Whether the current target is a friendly unit whose cooldowns should show on
  the target bar: the opt-in showFriendlyTargetCooldowns flag must be on and
  the target must be player-controlled - a friendly player or a friendly
  player's pet (ResolvePetTarget redirects the pet to its owner), never an
  npc. Deliberately independent of trackFriendlyCooldowns: with tracking off
  the queue holds no friendly entries and the bar simply stays empty.

  @return {boolean}
]]--
local function IsShowableFriendlyTarget()
  if not mod.configuration.IsShowFriendlyTargetCooldownsEnabled() then
    return false
  end

  -- truthiness, not `== true`: robust should a client return the legacy 1/nil
  if UnitIsFriend(RGCW_CONSTANTS.UNIT_ID_PLAYER, RGCW_CONSTANTS.UNIT_ID_TARGET)
    and UnitPlayerControlled(RGCW_CONSTANTS.UNIT_ID_TARGET) then
    return true
  end

  return false
end

--[[
  Get players current target (if enemy, or friendly behind the
  showFriendlyTargetCooldowns flag) in the form of the targets unique id and
  update the currentTarget.
]]--
function me.UpdateCurrentTarget()
  local targetId

  --[[
    For debugging purpose allow any target in debug mode
  ]]--
  if UnitIsEnemy(RGCW_CONSTANTS.UNIT_ID_PLAYER, RGCW_CONSTANTS.UNIT_ID_TARGET)
    or IsShowableFriendlyTarget()
    or RGCW_ENVIRONMENT.DEBUG then
    targetId = ResolvePetTarget(UnitGUID(RGCW_CONSTANTS.UNIT_ID_TARGET))
  end

  if targetId == nil then
    currentTargetGuid = ""
    mod.logger.LogDebug(me.tag, "Update players targetGUID: [Empty-target]")
  else
    currentTargetGuid = targetId
    mod.logger.LogDebug(me.tag, "Update players targetGUID: " .. currentTargetGuid)
  end
end
