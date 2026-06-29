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
  local function makeSpell(spellId, name, castTime, active)
    return {
      ["spellId"] = spellId,
      ["name"] = name,
      ["castTime"] = castTime,
      ["cooldown"] = 30,
      ["cooldownWorstCase"] = 20,
      ["active"] = active == nil and true or active
    }
  end

  before_each(function()
    queue = rgcw.cooldownQueue
    -- The queue keeps module-level state; reset between scenarios so each `it`
    -- starts from an empty queue.
    queue.ClearCooldownQueue()
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
end)
