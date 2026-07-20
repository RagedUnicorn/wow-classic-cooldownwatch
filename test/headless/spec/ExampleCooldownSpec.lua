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

-- busted extends `assert` with .same / .is_not_nil / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup
-- luacheck: ignore 143

--[[
  Guards the configuration preview data. The preview is rendered from frame code
  that cannot run headlessly, but the example entry it builds is pure - these tests
  pin that data to the shape UpdateCooldownWatchSlot reads.
]]--

-- spellData fields UpdateCooldownWatchSlot (and its helpers) dereference. Hand-
-- maintained mirror of the reader, which lives in frame code we cannot load here.
local READER_REQUIRES_SPELLDATA = { "castTime", "cooldown", "cooldownWorstCase", "spellId" }

local function SortedKeys(t)
  local keys = {}
  for key in pairs(t) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

describe("Example cooldown preview", function()
  local example

  setup(function()
    example = rgcw.cooldownQueue.BuildExampleCooldown(0)
  end)

  it("EXAMPLE_COOLDOWN_SPELL_ID resolves to a real SpellMap entry", function()
    local category = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)
    assert.is_not_nil(category)
  end)

  it("has the same envelope shape as a real queue entry", function()
    -- Derive the contract from a real entry rather than restating it, so a rename of
    -- the entry keys breaks both sides together.
    local category, _, spellData =
      rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    -- every production enqueue path stamps castTime before AddCooldown (the entry
    -- contract; the expiry timer schedules against it)
    spellData.castTime = 0

    rgcw.cooldownQueue.ClearCooldownQueue()
    rgcw.cooldownQueue.AddCooldown("real-guid", "RealCaster", category, spellData)
    local realEntry = rgcw.cooldownQueue.GetCooldownsByTarget("real-guid")[1]

    assert.is_not_nil(realEntry)
    assert.same(SortedKeys(realEntry), SortedKeys(example))
  end)

  it("supplies every spellData field UpdateCooldownWatchSlot reads", function()
    assert.is_not_nil(example.spellData)

    for _, field in ipairs(READER_REQUIRES_SPELLDATA) do
      assert.is_not_nil(example.spellData[field],
        "example spellData is missing reader-required field: " .. field)
    end
  end)

  it("supplies the top-level sourceGuid the animated-clear path reads", function()
    assert.is_not_nil(example.sourceGuid)
  end)

  it("stamps the castTime it is given", function()
    assert.equal(123, rgcw.cooldownQueue.BuildExampleCooldown(123).spellData.castTime)
  end)
end)
