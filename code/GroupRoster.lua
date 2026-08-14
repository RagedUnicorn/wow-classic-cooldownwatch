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

-- luacheck: globals UnitGUID IsInRaid

--[[
  Guid sets of the player's current group, refreshed on the roster edges
  (PLAYER_ENTERING_WORLD / GROUP_ROSTER_UPDATE, wired in Core.OnLoad) so scope
  membership is an O(1) set lookup on the render path instead of a per-row walk
  of the unit ids - the friendly proximity window asks IsGuidInScope for up to
  every row of every render tick.

  Two sets, matching the two narrow scopes: the party set holds the player and
  their party units (in a raid those are the player's subgroup), the raid set
  the raid units. Membership is resolved by caster guid, which is also what
  pet-cast attribution keys queue entries by - a party member's pet cast is
  parked under the owning player's guid and scopes like the owner (see
  PetOwner).
]]--

local mod = rgcw
local me = {}

mod.groupRoster = me

me.tag = "GroupRoster"

local partyGuids = {}
local raidGuids = {}

--[[
  Rebuild both guid sets from the current group composition. The walk is
  bounded by the fixed unit-id ranges rather than GetNumGroupMembers - empty
  unit ids simply resolve to no guid, and forty UnitGUID calls on a roster
  edge are cheaper than being clever.
]]--
function me.RefreshRoster()
  partyGuids = {}
  raidGuids = {}

  local playerGuid = UnitGUID(RGCW_CONSTANTS.UNIT_ID_PLAYER)

  if playerGuid then
    partyGuids[playerGuid] = true
  end

  for i = 1, RGCW_CONSTANTS.MAX_PARTY_MEMBERS do
    local guid = UnitGUID("party" .. i)

    if guid then
      partyGuids[guid] = true
    end
  end

  if IsInRaid() then
    for i = 1, RGCW_CONSTANTS.MAX_RAID_MEMBERS do
      local guid = UnitGUID("raid" .. i)

      if guid then
        raidGuids[guid] = true
      end
    end
  end

  mod.logger.LogDebug(me.tag, "Refreshed group roster guid sets")
end

--[[
  Whether a caster falls inside a friendly proximity scope:

  - "group": the player and their party (in a raid: their subgroup)
  - "raid": the group plus every raid member
  - "all": every caster - and deliberately also the fallback for an unknown
    scope value, so a stale saved value degrades to showing more rather than
    silently hiding teammates (the configuration accessor refuses to store
    unknown scopes in the first place)

  Membership reflects the sets of the last roster refresh; a caster who left
  the group stays in scope until the GROUP_ROSTER_UPDATE that reported the
  leave has fired - the same event edge Blizzard's own raid frames update on.

  @param {string} guid
    A caster guid (queue entries key friendly pet casts by the owner's guid)
  @param {string} scope
    One of RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP / _RAID / _ALL

  @return {boolean}
    true - if the caster is inside the scope
]]--
function me.IsGuidInScope(guid, scope)
  if scope == RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP then
    return partyGuids[guid] == true
  end

  if scope == RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_RAID then
    return partyGuids[guid] == true or raidGuids[guid] == true
  end

  return true
end
