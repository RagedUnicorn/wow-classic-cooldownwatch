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
-- luacheck: globals describe it before_each
-- luacheck: ignore 143

--[[
  Cross-caster aggregation: GetAllCooldowns / HasAnyCooldowns read the queue
  across every caster bucket - the data foundation the proximity cooldown
  window renders from. The per-caster accessors are covered by
  CooldownQueueSpec; these specs pin the aggregate view's ordering, the
  per-call exclude filter, and the separate snapshot contract.
]]--
describe("CooldownQueue cross-caster aggregation", function()
  local queue

  -- Build a minimal spellData in the shape AddCooldown reads (spellId / name)
  -- plus the timing fields a queue entry carries. Kept inline rather than
  -- pulled from SpellMap: these specs exercise the queue's bookkeeping, not
  -- spell identity, so synthetic ids keep each scenario self-contained.
  local function makeSpell(spellId, name, castTime, cooldown)
    return {
      ["spellId"] = spellId,
      ["name"] = name,
      ["castTime"] = castTime,
      ["cooldown"] = cooldown or 30,
      ["active"] = true
    }
  end

  before_each(function()
    queue = rgcw.cooldownQueue
    -- The queue keeps module-level state; reset between scenarios so each `it`
    -- starts from an empty queue.
    queue.ClearCooldownQueue()
    -- AddCooldown resolves against the worst-case toggles and the global
    -- default; reset both so no scenario inherits another's configuration.
    CooldownWatchConfiguration.cooldownOverrides = nil
    CooldownWatchConfiguration.globalAssumeWorstCase = nil
  end)

  it("GetAllCooldowns returns an empty table for an empty queue", function()
    assert.same({}, queue.GetAllCooldowns())
  end)

  it("GetAllCooldowns returns every caster's entries with their caster identity", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 200))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 300))

    local cooldowns = queue.GetAllCooldowns()

    assert.equal(3, #cooldowns)
    for _, cooldownEvent in ipairs(cooldowns) do
      if cooldownEvent.spellData.spellId == 1766 then
        assert.equal("guid-2", cooldownEvent.sourceGuid)
        assert.equal("Bob", cooldownEvent.sourceName)
        assert.equal("rogue", cooldownEvent.categoryName)
      else
        assert.equal("guid-1", cooldownEvent.sourceGuid)
        assert.equal("Alice", cooldownEvent.sourceName)
        assert.equal("mage", cooldownEvent.categoryName)
      end
    end
  end)

  it("GetAllCooldowns keeps one entry per (sourceGuid, spellId) pair across refreshes", function()
    queue.AddCooldown("guid-1", "Alice", "rogue", makeSpell(1766, "Kick", 100))
    queue.AddCooldown("guid-1", "Alice", "rogue", makeSpell(1766, "Kick", 250))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 100))

    local cooldowns = queue.GetAllCooldowns()

    assert.equal(2, #cooldowns)
    -- the refreshed entry carries the newest castTime and leads the list
    assert.equal("guid-1", cooldowns[1].sourceGuid)
    assert.equal(250, cooldowns[1].spellData.castTime)
  end)

  it("GetAllCooldowns orders entries newest detection first across casters", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 300))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 200))

    local cooldowns = queue.GetAllCooldowns()

    assert.equal(1766, cooldowns[1].spellData.spellId)
    assert.equal(2139, cooldowns[2].spellData.spellId)
    assert.equal(122, cooldowns[3].spellData.spellId)
  end)

  it("GetAllCooldowns breaks castTime ties by ascending spellId", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 100))
    queue.AddCooldown("guid-2", "Bob", "mage", makeSpell(122, "Frost Nova", 100))

    local cooldowns = queue.GetAllCooldowns()

    assert.equal(122, cooldowns[1].spellData.spellId)
    assert.equal(2139, cooldowns[2].spellData.spellId)
  end)

  it("GetAllCooldowns breaks full castTime and spellId ties by sourceGuid", function()
    -- two casters detected with the same spell in the same combat-log tick
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 100))
    queue.AddCooldown("guid-1", "Alice", "rogue", makeSpell(1766, "Kick", 100))

    local cooldowns = queue.GetAllCooldowns()

    assert.equal("guid-1", cooldowns[1].sourceGuid)
    assert.equal("guid-2", cooldowns[2].sourceGuid)
  end)

  it("GetAllCooldowns omits the excluded caster's entries", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 200))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 300))

    local cooldowns = queue.GetAllCooldowns("guid-1")

    assert.equal(1, #cooldowns)
    assert.equal("guid-2", cooldowns[1].sourceGuid)
  end)

  it("GetAllCooldowns returns an empty table when the only caster is excluded", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))

    assert.same({}, queue.GetAllCooldowns("guid-1"))
  end)

  it("GetAllCooldowns evaluates the exclusion per call - a target change needs no handling", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 200))

    -- guid-1 is the current target
    local cooldowns = queue.GetAllCooldowns("guid-1")
    assert.equal(1, #cooldowns)
    assert.equal("guid-2", cooldowns[1].sourceGuid)

    -- the player targets guid-2: the previous target's entries surface again
    cooldowns = queue.GetAllCooldowns("guid-2")
    assert.equal(1, #cooldowns)
    assert.equal("guid-1", cooldowns[1].sourceGuid)
  end)

  it("GetAllCooldowns reuses one snapshot table without leaking stale entries", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 200))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 300))

    local first = queue.GetAllCooldowns()
    assert.equal(3, #first)

    -- The snapshot is a module-owned scratch array refilled per call: a smaller
    -- result must not retain entries from the previous, larger snapshot.
    queue.ClearCooldownQueue()
    queue.AddCooldown("guid-3", "Carol", "priest", makeSpell(10890, "Psychic Scream", 400))

    local second = queue.GetAllCooldowns()
    assert.equal(first, second)
    assert.equal(1, #second)
    assert.equal("guid-3", second[1].sourceGuid)
  end)

  it("GetAllCooldowns owns a snapshot separate from GetCooldownsByTarget's", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 200))

    local aggregate = queue.GetAllCooldowns()
    local byTarget = queue.GetCooldownsByTarget("guid-1")

    -- both accessors can feed concurrently running render tickers; sharing one
    -- scratch array would let either call invalidate the other's snapshot
    assert.is_not.equal(aggregate, byTarget)
    assert.equal(2, #aggregate)
    assert.equal(1, #byTarget)
  end)

  it("HasAnyCooldowns reflects overall queue presence through add, remove and clear", function()
    assert.is_false(queue.HasAnyCooldowns())

    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 200))
    assert.is_true(queue.HasAnyCooldowns())

    -- one caster emptied, the other still queued
    queue.RemoveCooldown("guid-1", 122)
    assert.is_true(queue.HasAnyCooldowns())

    queue.RemoveCooldown("guid-2", 1766)
    assert.is_false(queue.HasAnyCooldowns())

    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.ClearCooldownQueue()
    assert.is_false(queue.HasAnyCooldowns())
  end)

  it("HasAnyCooldowns counts entries inside the post-expiry prune grace", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))

    -- expired (cooldown of 30 has passed) but still inside the grace window -
    -- the render layer is still fading the entry, so it is something to render
    queue.PruneExpiredCooldowns(100 + 30 + RGCW_CONSTANTS.COOLDOWN_QUEUE_PRUNE_GRACE)
    assert.is_true(queue.HasAnyCooldowns())

    queue.PruneExpiredCooldowns(100 + 30 + RGCW_CONSTANTS.COOLDOWN_QUEUE_PRUNE_GRACE + 1)
    assert.is_false(queue.HasAnyCooldowns())
  end)
end)
