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

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

--[[
  Scope-membership coverage for the roster guid sets behind the friendly
  proximity window's scope filter. Every scenario installs the unit APIs via
  WowStubs, refreshes the roster and asserts IsGuidInScope - the exact call
  chain the production roster edges (Core.OnRosterChanged) and the render
  filter (FriendlyProximityCooldownBar) run.
]]--
describe("GroupRoster scope membership", function()
  local groupRoster = rgcw.groupRoster
  local restore

  local SCOPE_GROUP = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP
  local SCOPE_RAID = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_RAID
  local SCOPE_ALL = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_ALL

  --[[
    Install the unit stubs and refresh the roster in one step

    @param {table} unitGuids
    @param {boolean} inRaid
  ]]--
  local function refreshWithRoster(unitGuids, inRaid)
    restore = wowStubs.install(wowStubs.stubs.GroupRosterUnits(unitGuids, inRaid))
    groupRoster.RefreshRoster()
  end

  after_each(function()
    if restore then
      restore()
      restore = nil
    end

    --[[
      Empty the module's guid sets so no roster state leaks into later spec
      files: with no units resolvable the refresh clears both sets, which is
      also the state every other spec runs against.
    ]]--
    local clear = wowStubs.install(wowStubs.stubs.GroupRosterUnits({}, false))
    groupRoster.RefreshRoster()
    clear()
  end)

  it("solo: the player is in scope group and raid, a stranger only in all", function()
    refreshWithRoster({ player = "Player-1" }, false)

    assert.is_true(groupRoster.IsGuidInScope("Player-1", SCOPE_GROUP))
    assert.is_true(groupRoster.IsGuidInScope("Player-1", SCOPE_RAID))
    assert.is_true(groupRoster.IsGuidInScope("Player-1", SCOPE_ALL))

    assert.is_false(groupRoster.IsGuidInScope("Player-99", SCOPE_GROUP))
    assert.is_false(groupRoster.IsGuidInScope("Player-99", SCOPE_RAID))
    assert.is_true(groupRoster.IsGuidInScope("Player-99", SCOPE_ALL))
  end)

  it("party: every party member is in scope group and raid", function()
    refreshWithRoster({
      player = "Player-1",
      party1 = "Player-2",
      party2 = "Player-3"
    }, false)

    for _, guid in ipairs({ "Player-1", "Player-2", "Player-3" }) do
      assert.is_true(groupRoster.IsGuidInScope(guid, SCOPE_GROUP))
      assert.is_true(groupRoster.IsGuidInScope(guid, SCOPE_RAID))
    end
  end)

  it("raid: the subgroup is in scope group, other raid members only in raid", function()
    refreshWithRoster({
      player = "Player-1",
      -- the party units are the player's subgroup while in a raid
      party1 = "Player-2",
      raid1 = "Player-1",
      raid2 = "Player-2",
      raid3 = "Player-30"
    }, true)

    assert.is_true(groupRoster.IsGuidInScope("Player-2", SCOPE_GROUP))
    assert.is_true(groupRoster.IsGuidInScope("Player-2", SCOPE_RAID))

    assert.is_false(groupRoster.IsGuidInScope("Player-30", SCOPE_GROUP))
    assert.is_true(groupRoster.IsGuidInScope("Player-30", SCOPE_RAID))
    assert.is_true(groupRoster.IsGuidInScope("Player-30", SCOPE_ALL))
  end)

  it("ignores raid units while not in a raid - stale raid ids never widen the group scope", function()
    refreshWithRoster({
      player = "Player-1",
      raid1 = "Player-30"
    }, false)

    assert.is_false(groupRoster.IsGuidInScope("Player-30", SCOPE_RAID))
  end)

  it("a refresh replaces the sets - a member who left drops out of scope", function()
    refreshWithRoster({ player = "Player-1", party1 = "Player-2" }, false)
    assert.is_true(groupRoster.IsGuidInScope("Player-2", SCOPE_GROUP))

    restore()
    refreshWithRoster({ player = "Player-1" }, false)

    assert.is_false(groupRoster.IsGuidInScope("Player-2", SCOPE_GROUP))
    assert.is_false(groupRoster.IsGuidInScope("Player-2", SCOPE_RAID))
  end)

  it("an unknown scope value degrades to showing everyone, never to hiding teammates", function()
    refreshWithRoster({ player = "Player-1" }, false)

    assert.is_true(groupRoster.IsGuidInScope("Player-99", "everything"))
    assert.is_true(groupRoster.IsGuidInScope("Player-99", nil))
  end)
end)
