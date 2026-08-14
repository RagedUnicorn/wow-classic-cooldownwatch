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
-- luacheck: globals describe it setup teardown before_each after_each CooldownWatchConfiguration RGCW_CONSTANTS
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

--[[
  Render-policy coverage for the FRIENDLY proximity cooldown window, mirroring
  ProximityCooldownBarSpec for the shared machinery and adding what makes this
  window the friendly one: the friendly-marker eligibility (hostile entries
  never render here), the roster scope filter, and the friendly-side option
  block driving the wake gate.

  gui/ProximityWindow.lua and gui/FriendlyProximityCooldownBar.lua are
  load-safe headless (all WoW API usage lives inside functions), but
  dofile-ing the bar replaces the no-op WakeRenderTicker stub Bootstrap
  installed for every other spec - the teardown puts the stub back.
]]--
describe("FriendlyProximityCooldownBar render policy", function()
  local friendlyProximityCooldownBar
  local originalFriendlyProximityCooldownBar
  local originalTicker
  local restoreRoster

  setup(function()
    originalFriendlyProximityCooldownBar = rgcw.friendlyProximityCooldownBar

    dofile("gui/ProximityWindow.lua")
    dofile("gui/FriendlyProximityCooldownBar.lua")
    friendlyProximityCooldownBar = rgcw.friendlyProximityCooldownBar
  end)

  teardown(function()
    rgcw.friendlyProximityCooldownBar = originalFriendlyProximityCooldownBar
  end)

  before_each(function()
    -- SetupConfiguration never runs headless - start from the never-configured state
    CooldownWatchConfiguration.friendlyProximityCooldowns = nil
    rgcw.cooldownQueue.ClearCooldownQueue()

    -- code/Ticker.lua is not loaded headless (it reaches for C_Timer.NewTicker);
    -- install a counting stand-in for the wake-gate scenarios
    originalTicker = rgcw.ticker
    rgcw.ticker = {
      startCalls = 0,
      StartTickerFriendlyProximityCooldownBar = function()
        rgcw.ticker.startCalls = rgcw.ticker.startCalls + 1
      end,
    }
  end)

  after_each(function()
    rgcw.ticker = originalTicker
    CooldownWatchConfiguration.friendlyProximityCooldowns = nil
    rgcw.cooldownQueue.ClearCooldownQueue()

    if restoreRoster then
      restoreRoster()
      restoreRoster = nil

      -- empty the roster sets again so no membership leaks into later specs
      local clear = wowStubs.install(wowStubs.stubs.GroupRosterUnits({}, false))
      rgcw.groupRoster.RefreshRoster()
      clear()
    end
  end)

  --[[
    Install the unit stubs and refresh the roster guid sets

    @param {table} unitGuids
    @param {boolean} inRaid
  ]]--
  local function installRoster(unitGuids, inRaid)
    restoreRoster = wowStubs.install(wowStubs.stubs.GroupRosterUnits(unitGuids, inRaid))
    rgcw.groupRoster.RefreshRoster()
  end

  --[[
    Build a queue-entry lookalike carrying only the fields the render filter
    reads. Friendly by default - this is the friendly window's spec; hostile
    entries are built explicitly where their exclusion is the point.

    @param {table} opts
      cooldown {number}, expired {boolean}, friendly {boolean, default true},
      sourceGuid {string, default "Friendly-1"}
    @return {table}
  ]]--
  local function makeEntry(opts)
    opts = opts or {}

    return {
      ["expired"] = opts.expired,
      ["sourceGuid"] = opts.sourceGuid or "Friendly-1",
      ["spellData"] = {
        ["cooldown"] = opts.cooldown or 30,
        ["friendly"] = opts.friendly ~= false or nil,
      },
    }
  end

  describe("IsRenderableCooldown", function()
    it("renders a friendly entry with the default scope of all - no roster needed", function()
      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(makeEntry(), false))
    end)

    it("never renders a hostile entry - those belong to the enemy window", function()
      local hostileEntry = makeEntry({ friendly = false })

      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(hostileEntry, false))
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(hostileEntry, true))
    end)

    it("never renders an expired-flagged entry, filter on or off", function()
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(makeEntry({ expired = true }), true))
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(makeEntry({ expired = true }), false))
    end)

    it("applies the hide-long threshold like the enemy window - only above is long", function()
      local threshold = RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
      local boundaryEntry = makeEntry({ cooldown = threshold })
      local longEntry = makeEntry({ cooldown = threshold + 1 })

      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(boundaryEntry, true))
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(longEntry, true))
      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(longEntry, false))
    end)

    it("scope group renders only party members", function()
      installRoster({ player = "Player-1", party1 = "Friendly-1" }, false)
      rgcw.configuration.UpdateFriendlyProximityCooldownsScope(RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP)

      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(
        makeEntry({ sourceGuid = "Friendly-1" }), false))
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(
        makeEntry({ sourceGuid = "Friendly-99" }), false))
    end)

    it("scope raid renders party and raid members but no outsider", function()
      installRoster({ player = "Player-1", party1 = "Friendly-1", raid3 = "Friendly-30" }, true)
      rgcw.configuration.UpdateFriendlyProximityCooldownsScope(RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_RAID)

      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(
        makeEntry({ sourceGuid = "Friendly-1" }), false))
      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(
        makeEntry({ sourceGuid = "Friendly-30" }), false))
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(
        makeEntry({ sourceGuid = "Friendly-99" }), false))
    end)

    it("a scope change takes effect on the next filter evaluation - no rebuild needed", function()
      installRoster({ player = "Player-1" }, false)
      local outsiderEntry = makeEntry({ sourceGuid = "Friendly-99" })

      rgcw.configuration.UpdateFriendlyProximityCooldownsScope(RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP)
      assert.is_false(friendlyProximityCooldownBar.IsRenderableCooldown(outsiderEntry, false))

      rgcw.configuration.UpdateFriendlyProximityCooldownsScope(RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_ALL)
      assert.is_true(friendlyProximityCooldownBar.IsRenderableCooldown(outsiderEntry, false))
    end)
  end)

  describe("WakeRenderTicker", function()
    local function enqueueOne()
      rgcw.cooldownQueue.AddCooldown("Friendly-1", "Alice", "priest", {
        ["spellId"] = 10890,
        ["name"] = "Psychic Scream",
        ["castTime"] = 100,
        ["cooldown"] = 30,
        ["friendly"] = true,
      })
      -- AddCooldown itself wakes the (real, just dofile-d) friendly module -
      -- only the explicit wake below should count
      rgcw.ticker.startCalls = 0
    end

    it("never starts the ticker while the friendly window is disabled - the shipped default", function()
      enqueueOne()

      friendlyProximityCooldownBar.WakeRenderTicker()

      assert.equal(0, rgcw.ticker.startCalls)
    end)

    it("starts the ticker when enabled and any caster has a queued cooldown", function()
      rgcw.configuration.UpdateProximityCooldownsEnabled(true, true)
      enqueueOne()

      friendlyProximityCooldownBar.WakeRenderTicker()

      assert.equal(1, rgcw.ticker.startCalls)
    end)

    it("the ENEMY window's enabled option never opens the friendly wake gate", function()
      CooldownWatchConfiguration.proximityCooldowns = nil
      rgcw.configuration.UpdateProximityCooldownsEnabled(true)
      enqueueOne()

      friendlyProximityCooldownBar.WakeRenderTicker()

      assert.equal(0, rgcw.ticker.startCalls)
      CooldownWatchConfiguration.proximityCooldowns = nil
    end)

    it("skips the start when enabled but the queue is empty", function()
      rgcw.configuration.UpdateProximityCooldownsEnabled(true, true)

      friendlyProximityCooldownBar.WakeRenderTicker()

      assert.equal(0, rgcw.ticker.startCalls)
    end)
  end)
end)
