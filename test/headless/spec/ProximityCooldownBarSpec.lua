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

--[[
  Render-policy coverage for the proximity cooldown window. The widget layer
  (BuildUi, the render pass, drag handling) needs a real WoW client; what IS
  headless-testable is the pure per-entry render filter and the ticker wake
  gate, and those carry the feature's behavioral contract: the opt-in gate,
  the hide-long threshold semantics and the expired-entry exclusion.

  gui/ProximityWindow.lua and gui/ProximityCooldownBar.lua are load-safe
  headless (all WoW API usage lives inside functions), but dofile-ing the bar
  replaces the no-op WakeRenderTicker stub Bootstrap installed for every other
  spec - the teardown puts the stub back.
]]--
describe("ProximityCooldownBar render policy", function()
  local proximityCooldownBar
  local originalProximityCooldownBar
  local originalTicker

  setup(function()
    originalProximityCooldownBar = rgcw.proximityCooldownBar

    dofile("gui/ProximityWindow.lua")
    dofile("gui/ProximityCooldownBar.lua")
    proximityCooldownBar = rgcw.proximityCooldownBar
  end)

  teardown(function()
    rgcw.proximityCooldownBar = originalProximityCooldownBar
  end)

  before_each(function()
    -- SetupConfiguration never runs headless - start from the never-configured state
    CooldownWatchConfiguration.proximityCooldowns = nil
    rgcw.cooldownQueue.ClearCooldownQueue()

    -- code/Ticker.lua is not loaded headless (it reaches for C_Timer.NewTicker);
    -- install a counting stand-in for the wake-gate scenarios
    originalTicker = rgcw.ticker
    rgcw.ticker = {
      startCalls = 0,
      StartTickerProximityCooldownBar = function()
        rgcw.ticker.startCalls = rgcw.ticker.startCalls + 1
      end,
      -- entering preview mode stops the live ticker - a no-op suffices here
      StopTickerProximityCooldownBar = function() end,
    }
  end)

  after_each(function()
    -- the preview flag lives on the module-level instance - never leak it across tests
    proximityCooldownBar.HidePreview()
    rgcw.ticker = originalTicker
    CooldownWatchConfiguration.proximityCooldowns = nil
    rgcw.cooldownQueue.ClearCooldownQueue()
  end)

  --[[
    Build a queue-entry lookalike carrying only the fields the render filter reads

    @param {number} cooldown
    @param {boolean} expired
    @return {table}
  ]]--
  local function makeEntry(cooldown, expired)
    return {
      ["expired"] = expired,
      ["spellData"] = { ["cooldown"] = cooldown },
    }
  end

  describe("IsRenderableCooldown", function()
    it("renders a short cooldown regardless of the hide-long filter", function()
      assert.is_true(proximityCooldownBar.IsRenderableCooldown(makeEntry(30), true))
      assert.is_true(proximityCooldownBar.IsRenderableCooldown(makeEntry(30), false))
    end)

    it("hides a cooldown above the threshold while the filter is on", function()
      local longEntry = makeEntry(RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD + 1)

      assert.is_false(proximityCooldownBar.IsRenderableCooldown(longEntry, true))
    end)

    it("renders a cooldown above the threshold once the filter is off", function()
      local longEntry = makeEntry(RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD + 1)

      assert.is_true(proximityCooldownBar.IsRenderableCooldown(longEntry, false))
    end)

    it("renders a cooldown sitting exactly on the threshold - only above is long", function()
      local boundaryEntry = makeEntry(RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD)

      assert.is_true(proximityCooldownBar.IsRenderableCooldown(boundaryEntry, true))
    end)

    it("never renders an expired-flagged entry, filter on or off", function()
      assert.is_false(proximityCooldownBar.IsRenderableCooldown(makeEntry(30, true), true))
      assert.is_false(proximityCooldownBar.IsRenderableCooldown(makeEntry(30, true), false))
    end)

    it("never renders a friendly-flagged entry - those belong to the friendly window", function()
      local friendlyEntry = makeEntry(30)
      friendlyEntry.spellData.friendly = true

      assert.is_false(proximityCooldownBar.IsRenderableCooldown(friendlyEntry, true))
      assert.is_false(proximityCooldownBar.IsRenderableCooldown(friendlyEntry, false))
    end)
  end)

  describe("WakeRenderTicker", function()
    local function enqueueOne()
      rgcw.cooldownQueue.AddCooldown("guid-1", "Alice", "rogue", {
        ["spellId"] = 1766,
        ["name"] = "Kick",
        ["castTime"] = 100,
        ["cooldown"] = 10,
      })
      -- AddCooldown itself wakes the (real, just dofile-d) proximity module -
      -- only the explicit wake below should count
      rgcw.ticker.startCalls = 0
    end

    it("never starts the ticker while the feature is disabled - the shipped default", function()
      enqueueOne()

      proximityCooldownBar.WakeRenderTicker()

      assert.equal(0, rgcw.ticker.startCalls)
    end)

    it("starts the ticker when enabled and any caster has a queued cooldown", function()
      rgcw.configuration.UpdateProximityCooldownsEnabled(true)
      enqueueOne()

      proximityCooldownBar.WakeRenderTicker()

      assert.equal(1, rgcw.ticker.startCalls)
    end)

    it("skips the start when enabled but the queue is empty", function()
      rgcw.configuration.UpdateProximityCooldownsEnabled(true)

      proximityCooldownBar.WakeRenderTicker()

      assert.equal(0, rgcw.ticker.startCalls)
    end)

    it("never starts the ticker while preview mode owns the rows - live enqueues keep arriving", function()
      rgcw.configuration.UpdateProximityCooldownsEnabled(true)
      enqueueOne()
      proximityCooldownBar.ShowPreview()

      proximityCooldownBar.WakeRenderTicker()

      assert.is_true(proximityCooldownBar.IsPreviewActive())
      assert.equal(0, rgcw.ticker.startCalls)
    end)

    it("wakes again once preview mode handed the rows back", function()
      rgcw.configuration.UpdateProximityCooldownsEnabled(true)
      enqueueOne()
      proximityCooldownBar.ShowPreview()
      proximityCooldownBar.HidePreview()

      proximityCooldownBar.WakeRenderTicker()

      assert.is_false(proximityCooldownBar.IsPreviewActive())
      assert.equal(1, rgcw.ticker.startCalls)
    end)
  end)
end)
