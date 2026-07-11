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

describe("CooldownQueue", function()
  local queue

  -- Build a minimal spellData in the shape AddCooldown reads (active / spellId /
  -- name) plus the timing fields a queue entry carries. Kept inline rather than
  -- pulled from SpellMap: these specs exercise the queue's bookkeeping, not spell
  -- identity, so synthetic ids keep each scenario self-contained.
  local function makeSpell(spellId, name, castTime, active, cooldown)
    return {
      ["spellId"] = spellId,
      ["name"] = name,
      ["castTime"] = castTime,
      ["cooldown"] = cooldown or 30,
      ["cooldownWorstCase"] = 20,
      ["active"] = active == nil and true or active
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

  it("AddCooldown creates a new entry", function()
    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10947, "Mind Blast", 100))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")

    assert.equal(1, #cooldowns)
    assert.equal(10947, cooldowns[1].spellData.spellId)
    assert.equal("Mind Blast", cooldowns[1].spellData.name)
    assert.equal("Alice", cooldowns[1].sourceName)
    assert.equal("priest", cooldowns[1].categoryName)
    assert.equal("guid-1", cooldowns[1].sourceGuid)
  end)

  it("AddCooldown refreshes an existing (sourceGuid, spellId) pair in place", function()
    queue.AddCooldown("guid-1", "Alice", "warlock", makeSpell(5484, "Howl of Terror", 100))
    queue.AddCooldown("guid-1", "Alice", "warlock", makeSpell(5484, "Howl of Terror", 250))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")

    assert.equal(1, #cooldowns)
    assert.equal(250, cooldowns[1].spellData.castTime)
  end)

  it("ResolveCooldown promotes the worst case and clears the field when assumed", function()
    rgcw.configuration.UpdateCooldownWorstCaseState(true, "priest", 10947)
    local spell = makeSpell(10947, "Mind Blast", 100)

    queue.ResolveCooldown("priest", spell)

    assert.equal(20, spell.cooldown)
    assert.is_nil(spell.cooldownWorstCase)
  end)

  it("ResolveCooldown is a no-op when the toggle is not assumed", function()
    local spell = makeSpell(10947, "Mind Blast", 100)

    queue.ResolveCooldown("priest", spell)

    assert.equal(30, spell.cooldown)
    assert.equal(20, spell.cooldownWorstCase)
  end)

  it("ResolveCooldown is a no-op for spells without a worst case", function()
    rgcw.configuration.UpdateCooldownWorstCaseState(true, "priest", 10947)
    local spell = makeSpell(10947, "Mind Blast", 100)
    spell.cooldownWorstCase = nil

    queue.ResolveCooldown("priest", spell)

    assert.equal(30, spell.cooldown)
  end)

  it("ResolveCooldown promotes the worst case for an unconfigured spell when the global default is on", function()
    rgcw.configuration.UpdateGlobalWorstCaseState(true)
    local spell = makeSpell(10947, "Mind Blast", 100)

    queue.ResolveCooldown("priest", spell)

    assert.equal(20, spell.cooldown)
    assert.is_nil(spell.cooldownWorstCase)
  end)

  it("ResolveCooldown lets an explicit per-spell opt-out beat the global default", function()
    rgcw.configuration.UpdateGlobalWorstCaseState(true)
    rgcw.configuration.UpdateCooldownWorstCaseState(false, "priest", 10947)
    local spell = makeSpell(10947, "Mind Blast", 100)

    queue.ResolveCooldown("priest", spell)

    assert.equal(30, spell.cooldown)
    assert.equal(20, spell.cooldownWorstCase)
  end)

  it("ResolveCooldown lets an explicit per-spell opt-in beat a disabled global default", function()
    rgcw.configuration.UpdateGlobalWorstCaseState(false)
    rgcw.configuration.UpdateCooldownWorstCaseState(true, "priest", 10947)
    local spell = makeSpell(10947, "Mind Blast", 100)

    queue.ResolveCooldown("priest", spell)

    assert.equal(20, spell.cooldown)
    assert.is_nil(spell.cooldownWorstCase)
  end)

  it("ResolveCooldown with the global default on is still a no-op for spells without a worst case", function()
    rgcw.configuration.UpdateGlobalWorstCaseState(true)
    local spell = makeSpell(10947, "Mind Blast", 100)
    spell.cooldownWorstCase = nil

    queue.ResolveCooldown("priest", spell)

    assert.equal(30, spell.cooldown)
  end)

  it("AddCooldown queues the resolved worst-case cooldown when assumed", function()
    rgcw.configuration.UpdateCooldownWorstCaseState(true, "priest", 10947)

    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10947, "Mind Blast", 100))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")
    assert.equal(20, cooldowns[1].spellData.cooldown)
    assert.is_nil(cooldowns[1].spellData.cooldownWorstCase)
  end)

  it("AddCooldown resolves each spell against its own toggle", function()
    -- only Mind Blast opts into the worst case; Psychic Scream keeps its base
    rgcw.configuration.UpdateCooldownWorstCaseState(true, "priest", 10947)

    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10947, "Mind Blast", 100))
    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10890, "Psychic Scream", 100))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")
    -- worst case (20) readies before base (30), so Mind Blast sorts first
    assert.equal(10947, cooldowns[1].spellData.spellId)
    assert.equal(20, cooldowns[1].spellData.cooldown)
    assert.equal(30, cooldowns[2].spellData.cooldown)
    assert.equal(20, cooldowns[2].spellData.cooldownWorstCase)
  end)

  it("AddCooldown silently drops inactive spells", function()
    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10947, "Mind Blast", 100, false))

    assert.same({}, queue.GetCooldownsByTarget("guid-1"))
  end)

  it("RemoveCooldown is a no-op for an unknown caster", function()
    assert.has_no.errors(function()
      queue.RemoveCooldown("guid-unknown", 10947)
    end)
    assert.same({}, queue.GetCooldownsByTarget("guid-unknown"))
  end)

  it("RemoveCooldown is a no-op for an unknown spellId on a known caster", function()
    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10947, "Mind Blast", 100))

    queue.RemoveCooldown("guid-1", 999999)

    local cooldowns = queue.GetCooldownsByTarget("guid-1")
    assert.equal(1, #cooldowns)
    assert.equal(10947, cooldowns[1].spellData.spellId)
  end)

  it("RemoveCooldown removes a single spell while leaving the caster's others", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 100))

    queue.RemoveCooldown("guid-1", 122)

    local cooldowns = queue.GetCooldownsByTarget("guid-1")
    assert.equal(1, #cooldowns)
    assert.equal(2139, cooldowns[1].spellData.spellId)
  end)

  it("RemoveCooldown empties the caster bucket when its last spell is removed", function()
    queue.AddCooldown("guid-1", "Alice", "rogue", makeSpell(1766, "Kick", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 100))

    queue.RemoveCooldown("guid-1", 1766)

    -- The emptied caster reports no cooldowns, and removing its last spell does
    -- not disturb an unrelated caster's bucket.
    assert.same({}, queue.GetCooldownsByTarget("guid-1"))
    assert.equal(1, #queue.GetCooldownsByTarget("guid-2"))
  end)

  it("ClearCooldownQueue empties everything", function()
    queue.AddCooldown("guid-1", "Alice", "priest", makeSpell(10947, "Mind Blast", 100))
    queue.AddCooldown("guid-2", "Bob", "mage", makeSpell(122, "Frost Nova", 100))

    queue.ClearCooldownQueue()

    assert.same({}, queue.GetCooldownsByTarget("guid-1"))
    assert.same({}, queue.GetCooldownsByTarget("guid-2"))
  end)

  it("GetCooldownsByTarget returns an empty table for an unknown sourceGuid", function()
    assert.same({}, queue.GetCooldownsByTarget("guid-nobody"))
  end)

  it("GetCooldownsByTarget orders cooldowns soonest ready first", function()
    -- ready times (castTime + cooldown): Counterspell 330, Frost Nova 130, Icy Veins 230
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 300))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(12472, "Icy Veins", 200))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")

    assert.equal(122, cooldowns[1].spellData.spellId)
    assert.equal(12472, cooldowns[2].spellData.spellId)
    assert.equal(2139, cooldowns[3].spellData.spellId)
  end)

  it("GetCooldownsByTarget ranks a later cast with a shorter cooldown first", function()
    -- Frost Nova is cast first but ready last: 100 + 30 = 130 vs 110 + 10 = 120
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100, nil, 30))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 110, nil, 10))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")

    assert.equal(2139, cooldowns[1].spellData.spellId)
    assert.equal(122, cooldowns[2].spellData.spellId)
  end)

  it("GetCooldownsByTarget breaks ready-time ties by ascending spellId", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))

    local cooldowns = queue.GetCooldownsByTarget("guid-1")

    assert.equal(122, cooldowns[1].spellData.spellId)
    assert.equal(2139, cooldowns[2].spellData.spellId)
  end)

  it("GetCooldownsByTarget reuses one snapshot table across calls", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 100))

    local first = queue.GetCooldownsByTarget("guid-1")
    assert.equal(2, #first)

    -- The snapshot is a module-owned scratch array refilled per call: a held
    -- reference is only valid until the next call. This pins the render-path
    -- allocation contract - callers must consume the result synchronously.
    local second = queue.GetCooldownsByTarget("guid-nobody")
    assert.equal(first, second)
    assert.same({}, second)
  end)

  it("GetCooldownsByTarget keeps the order stable when an entry is removed", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(12472, "Icy Veins", 200))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 300))

    queue.RemoveCooldown("guid-1", 12472)

    local cooldowns = queue.GetCooldownsByTarget("guid-1")

    -- remaining entries compact left but keep their relative order
    assert.equal(122, cooldowns[1].spellData.spellId)
    assert.equal(2139, cooldowns[2].spellData.spellId)
  end)

  -- makeSpell uses cooldown = 30, so an entry cast at time t is prunable once
  -- now > t + 30 + COOLDOWN_QUEUE_PRUNE_GRACE.
  local function pruneCutoff(castTime)
    return castTime + 30 + RGCW_CONSTANTS.COOLDOWN_QUEUE_PRUNE_GRACE
  end

  it("PruneCooldownsByTarget removes entries expired beyond the grace period", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(2139, "Counterspell", 500))

    queue.PruneCooldownsByTarget("guid-1", pruneCutoff(100) + 1)

    local cooldowns = queue.GetCooldownsByTarget("guid-1")
    assert.equal(1, #cooldowns)
    assert.equal(2139, cooldowns[1].spellData.spellId)
  end)

  it("PruneCooldownsByTarget keeps entries expired within the grace period", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))

    -- expired (cooldown of 30 has passed) but still inside the grace window
    queue.PruneCooldownsByTarget("guid-1", pruneCutoff(100) - 1)

    assert.equal(1, #queue.GetCooldownsByTarget("guid-1"))
  end)

  it("PruneCooldownsByTarget is a no-op for an unknown caster", function()
    assert.has_no.errors(function()
      queue.PruneCooldownsByTarget("guid-unknown", 1000)
    end)
  end)

  it("PruneCooldownsByTarget empties the caster bucket when its last entry is pruned", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))

    queue.PruneCooldownsByTarget("guid-1", pruneCutoff(100) + 1)

    assert.same({}, queue.GetCooldownsByTarget("guid-1"))
  end)

  it("PruneExpiredCooldowns sweeps long-expired entries across all casters", function()
    queue.AddCooldown("guid-1", "Alice", "mage", makeSpell(122, "Frost Nova", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(1766, "Kick", 100))
    queue.AddCooldown("guid-2", "Bob", "rogue", makeSpell(2094, "Blind", 500))

    queue.PruneExpiredCooldowns(pruneCutoff(100) + 1)

    assert.same({}, queue.GetCooldownsByTarget("guid-1"))

    local cooldowns = queue.GetCooldownsByTarget("guid-2")
    assert.equal(1, #cooldowns)
    assert.equal(2094, cooldowns[1].spellData.spellId)
  end)
end)
