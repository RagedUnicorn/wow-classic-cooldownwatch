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
  Headless spec for the target gate in code/Target.lua - which unit's cooldown
  bucket the target cooldown bar renders. Bootstrap stubs rgcw.target because
  the module reads WoW unit APIs at call time; this spec dofiles the production
  file per test against stubbed unit APIs (fresh module state each time) and
  restores the Bootstrap stub in teardown so later spec files keep the harness
  default.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot know that, so field accesses on assert are ignored (143)
-- luacheck: globals describe it teardown before_each after_each RGCW_ENVIRONMENT
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Target", function()
  local bootstrapTarget = rgcw.target
  local restore
  -- mutable per-test view of the single stubbed target unit
  local unit

  before_each(function()
    unit = {
      isEnemy = false,
      isFriend = false,
      playerControlled = false,
      guid = nil,
      name = nil,
      ownerGuid = nil,
      ownerName = nil
    }

    restore = wowStubs.install({
      UnitIsEnemy = function() return unit.isEnemy end,
      UnitIsFriend = function() return unit.isFriend end,
      UnitPlayerControlled = function() return unit.playerControlled end,
      UnitGUID = function() return unit.guid end,
      UnitName = function() return unit.name end,
      UnitOwnerGUID = function() return unit.ownerGuid end,
      GetPlayerInfoByGUID = function()
        return nil, nil, nil, nil, nil, unit.ownerName
      end
    })

    dofile("code/Target.lua")
  end)

  after_each(function()
    restore()
    -- the debug bypass test flips it; the Bootstrap harness never sets it
    RGCW_ENVIRONMENT.DEBUG = nil
    rgcw.configuration.UpdateShowFriendlyTargetCooldownsState(false)
  end)

  teardown(function()
    -- hand later spec files the Bootstrap stub back
    rgcw.target = bootstrapTarget
  end)

  it("accepts an enemy target while the friendly display flag is off", function()
    unit.isEnemy = true
    unit.guid = "Player-1234-000000EE"
    unit.name = "Enemyrogue"

    rgcw.target.UpdateCurrentTarget()

    assert.equal("Player-1234-000000EE", rgcw.target.GetCurrentTargetGuid())
    assert.equal("Enemyrogue", rgcw.target.GetCurrentTargetName())
  end)

  it("ignores a friendly player while showFriendlyTargetCooldowns is off - the display is opt-in", function()
    unit.isFriend = true
    unit.playerControlled = true
    unit.guid = "Player-1234-000000AA"
    unit.name = "Friendlymage"

    rgcw.target.UpdateCurrentTarget()

    assert.equal("", rgcw.target.GetCurrentTargetGuid())
    assert.equal("", rgcw.target.GetCurrentTargetName())
  end)

  it("accepts a friendly player while showFriendlyTargetCooldowns is on", function()
    rgcw.configuration.UpdateShowFriendlyTargetCooldownsState(true)
    unit.isFriend = true
    unit.playerControlled = true
    unit.guid = "Player-1234-000000AA"
    unit.name = "Friendlymage"

    rgcw.target.UpdateCurrentTarget()

    assert.equal("Player-1234-000000AA", rgcw.target.GetCurrentTargetGuid())
    assert.equal("Friendlymage", rgcw.target.GetCurrentTargetName())
  end)

  it("rejects a friendly npc even while the flag is on - player-controlled units only", function()
    rgcw.configuration.UpdateShowFriendlyTargetCooldownsState(true)
    unit.isFriend = true
    unit.playerControlled = false
    unit.guid = "Creature-0-1234-5-6789-4949-0000AAAA"
    unit.name = "Stormwind Guard"

    rgcw.target.UpdateCurrentTarget()

    assert.equal("", rgcw.target.GetCurrentTargetGuid())
    assert.equal("", rgcw.target.GetCurrentTargetName())
  end)

  it("redirects a friendly player pet to its owner while the flag is on", function()
    rgcw.configuration.UpdateShowFriendlyTargetCooldownsState(true)
    unit.isFriend = true
    unit.playerControlled = true
    unit.guid = "Pet-0-1234-5-6789-165189-0102030405"
    unit.name = "Ziljin"
    unit.ownerGuid = "Player-1234-000000BB"
    unit.ownerName = "Friendlylock"

    rgcw.target.UpdateCurrentTarget()

    assert.equal("Player-1234-000000BB", rgcw.target.GetCurrentTargetGuid())
    assert.equal("Friendlylock", rgcw.target.GetCurrentTargetName())
    -- the redirect records the sighting, so parked pet casts can flush
    assert.equal("Player-1234-000000BB", (rgcw.petOwner.GetOwner("Pet-0-1234-5-6789-165189-0102030405")))
  end)

  it("keeps the debug-mode bypass independent of the flag", function()
    RGCW_ENVIRONMENT.DEBUG = true
    unit.guid = "Player-1234-000000CC"
    unit.name = "Debugtarget"

    rgcw.target.UpdateCurrentTarget()

    assert.equal("Player-1234-000000CC", rgcw.target.GetCurrentTargetGuid())
    assert.equal("Debugtarget", rgcw.target.GetCurrentTargetName())
  end)

  it("clears the target when nothing passes the gate anymore", function()
    unit.isEnemy = true
    unit.guid = "Player-1234-000000EE"
    unit.name = "Enemyrogue"

    rgcw.target.UpdateCurrentTarget()

    unit.isEnemy = false
    unit.guid = nil
    unit.name = nil

    rgcw.target.UpdateCurrentTarget()

    assert.equal("", rgcw.target.GetCurrentTargetGuid())
    assert.equal("", rgcw.target.GetCurrentTargetName())
  end)
end)
