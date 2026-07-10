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

describe("Configuration cooldown overrides", function()
  local configuration

  before_each(function()
    configuration = rgcw.configuration
    --[[
      SetupConfiguration never runs headless (it reaches for GetAddOnMetadata),
      so cooldownOverrides starts nil - the exact state the accessors must
      survive. Reset between scenarios.
    ]]--
    CooldownWatchConfiguration.cooldownOverrides = nil
  end)

  it("IsCooldownWorstCaseAssumed is false while cooldownOverrides is nil", function()
    assert.is_false(configuration.IsCooldownWorstCaseAssumed("paladin", 1022))
  end)

  it("IsCooldownWorstCaseAssumed is false for a never-configured category", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    assert.is_false(configuration.IsCooldownWorstCaseAssumed("mage", 122))
  end)

  it("IsCooldownWorstCaseAssumed is false for a never-configured spell in a known category", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    assert.is_false(configuration.IsCooldownWorstCaseAssumed("paladin", 853))
  end)

  it("UpdateCooldownWorstCaseState round-trips an enabled toggle", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    assert.is_true(configuration.IsCooldownWorstCaseAssumed("paladin", 1022))
  end)

  it("UpdateCooldownWorstCaseState round-trips a disabled toggle", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)
    configuration.UpdateCooldownWorstCaseState(false, "paladin", 1022)

    assert.is_false(configuration.IsCooldownWorstCaseAssumed("paladin", 1022))
  end)

  it("UpdateCooldownWorstCaseState preserves sibling fields on the per-spell entry", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)
    -- forward seam: future override fields (e.g. a manual cooldown value) share the entry
    CooldownWatchConfiguration.cooldownOverrides["paladin"][1022].futureField = 42

    configuration.UpdateCooldownWorstCaseState(false, "paladin", 1022)

    assert.equal(42, CooldownWatchConfiguration.cooldownOverrides["paladin"][1022].futureField)
  end)

  it("GetDefaultCooldownOverrides carries one empty bucket per category", function()
    local defaults = rgcw.profile.GetDefaultCooldownOverrides()
    local categories = rgcw.categories.GetCategories()

    for _, category in ipairs(categories) do
      assert.same({}, defaults[category.categoryName])
    end

    local bucketCount = 0
    for _ in pairs(defaults) do
      bucketCount = bucketCount + 1
    end
    assert.equal(#categories, bucketCount)
  end)

  it("GetDefaultCooldownOverrides returns a fresh clone per call", function()
    local first = rgcw.profile.GetDefaultCooldownOverrides()
    first["paladin"][1022] = { worstCase = true }

    local second = rgcw.profile.GetDefaultCooldownOverrides()

    assert.is_nil(second["paladin"][1022])
  end)
end)
