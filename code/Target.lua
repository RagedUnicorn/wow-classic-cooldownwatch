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

-- luacheck: globals UnitIsEnemy UnitGUID UnitName UnitPlayerControlled UnitOwnerGUID GetPlayerInfoByGUID

local mod = rgcw
local me = {}

mod.target = me

me.tag = "Target"

local currentTargetGuid = ""
local currentTargetName = ""

--[[
  Resolve a targeted hostile player pet to its owning player. Cooldowns are
  keyed by the owner's guid (pet guids change on every resummon), so targeting
  the pet renders the owner's full cooldown bucket - which includes the
  pet-cast entries the pet itself queued (see PetOwner). The sighting is
  recorded either way, flushing any casts parked while the owner was unknown.

  @param {string} targetId
  @param {string} targetName

  @return ({string} {string})
    ownerGuid/ownerName when the target is a player pet with a resolvable
    owner; the passed target identity otherwise.
]]--
local function ResolvePetTarget(targetId, targetName)
  if targetId == nil then return targetId, targetName end
  if string.find(targetId, "^Pet%-") == nil then return targetId, targetName end
  if not UnitPlayerControlled(RGCW_CONSTANTS.UNIT_ID_TARGET) then return targetId, targetName end
  if UnitOwnerGUID == nil then return targetId, targetName end

  local ownerGuid = UnitOwnerGUID(RGCW_CONSTANTS.UNIT_ID_TARGET)

  if ownerGuid == nil then return targetId, targetName end

  -- may return nothing for players the client has not met yet
  local ownerName = select(6, GetPlayerInfoByGUID(ownerGuid))

  mod.petOwner.RecordSighting(targetId, ownerGuid, ownerName)

  if ownerName == nil then
    local _, recordedName = mod.petOwner.GetOwner(targetId)
    ownerName = recordedName
  end

  mod.logger.LogDebug(me.tag, "Redirecting pet target " .. targetId .. " to owner " .. ownerGuid)

  return ownerGuid, ownerName or targetName
end

--[[
  Returns the players current target uid or an empty string if the player has no target.

  @return {string}
]]--
function me.GetCurrentTargetGuid()
  return currentTargetGuid
end

--[[
  Returns the players current target name or an empty string if the player has no target.

  @return {string}
]]--
function me.GetCurrentTargetName()
  return currentTargetName
end

--[[
  Get players current target (if enemy) in the form of the targets unique id and update the currentTarget.
]]--
function me.UpdateCurrentTarget()
  local targetId
  local targetName

  --[[
    For debugging purpose allow friendly target in debug mode
  ]]--
  if UnitIsEnemy(RGCW_CONSTANTS.UNIT_ID_PLAYER, RGCW_CONSTANTS.UNIT_ID_TARGET) or RGCW_ENVIRONMENT.DEBUG then
    targetId = UnitGUID(RGCW_CONSTANTS.UNIT_ID_TARGET)
    targetName = UnitName(RGCW_CONSTANTS.UNIT_ID_TARGET)
    targetId, targetName = ResolvePetTarget(targetId, targetName)
  end

  if targetId == nil then
    currentTargetGuid = ""
    mod.logger.LogDebug(me.tag, "Update players targetGUID: [Empty-target]")
  else
    currentTargetGuid = targetId
    mod.logger.LogDebug(me.tag, "Update players targetGUID: " .. currentTargetGuid)
  end

  if targetName == nil then
    currentTargetName = ""
    mod.logger.LogDebug(me.tag, "Update players targetName: [Empty-target]")
  else
    currentTargetName = targetName
    mod.logger.LogDebug(me.tag, "Update players targetName: " .. currentTargetName)
  end
end
