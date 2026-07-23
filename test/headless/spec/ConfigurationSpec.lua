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
      SetupConfiguration never runs headless (it reaches for C_AddOns.GetAddOnMetadata),
      so cooldownOverrides starts nil - the exact state the accessors must
      survive. Reset between scenarios, globalAssumeWorstCase included.
    ]]--
    CooldownWatchConfiguration.cooldownOverrides = nil
    CooldownWatchConfiguration.globalAssumeWorstCase = nil
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

  it("GetCooldownWorstCaseOverride is nil while cooldownOverrides is nil", function()
    assert.is_nil(configuration.GetCooldownWorstCaseOverride("paladin", 1022))
  end)

  it("GetCooldownWorstCaseOverride is nil for a never-configured spell in a known category", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    assert.is_nil(configuration.GetCooldownWorstCaseOverride("paladin", 853))
  end)

  it("GetCooldownWorstCaseOverride surfaces an explicit opt-in", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    assert.is_true(configuration.GetCooldownWorstCaseOverride("paladin", 1022))
  end)

  it("GetCooldownWorstCaseOverride keeps an explicit opt-out distinct from never-configured", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)
    configuration.UpdateCooldownWorstCaseState(false, "paladin", 1022)

    assert.is_false(configuration.GetCooldownWorstCaseOverride("paladin", 1022))
  end)

  it("GetCooldownManualOverride is nil while cooldownOverrides is nil", function()
    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("GetCooldownManualOverride is nil for a never-configured spell in a known category", function()
    configuration.UpdateCooldownManualOverride(42, "paladin", 1022)

    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 853))
  end)

  it("UpdateCooldownManualOverride round-trips a value and returns it", function()
    local storedValue = configuration.UpdateCooldownManualOverride(42, "paladin", 1022)

    assert.equal(42, storedValue)
    assert.equal(42, configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride clears the override when passed nil", function()
    configuration.UpdateCooldownManualOverride(42, "paladin", 1022)

    local storedValue = configuration.UpdateCooldownManualOverride(nil, "paladin", 1022)

    assert.is_nil(storedValue)
    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride clearing a never-configured spell leaves the store untouched", function()
    configuration.UpdateCooldownManualOverride(nil, "paladin", 1022)

    -- the clear path must not fabricate the table chain it found missing
    assert.is_nil(CooldownWatchConfiguration.cooldownOverrides)
  end)

  it("UpdateCooldownManualOverride rejects non-numeric values without touching the store", function()
    local storedValue = configuration.UpdateCooldownManualOverride("fast", "paladin", 1022)

    assert.is_nil(storedValue)
    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride rejects zero, negative and NaN values", function()
    assert.is_nil(configuration.UpdateCooldownManualOverride(0, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownManualOverride(-30, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownManualOverride(0 / 0, "paladin", 1022))

    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride caps the value at the spell's base cooldown", function()
    -- base cooldown read from SpellMap rather than restated (see CLAUDE.md)
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    local storedValue = configuration.UpdateCooldownManualOverride(spell.cooldown + 100, category, spellId)

    assert.equal(spell.cooldown, storedValue)
    assert.equal(spell.cooldown, configuration.GetCooldownManualOverride(category, spellId))
  end)

  it("UpdateCooldownManualOverride stores a value below the base cooldown unchanged", function()
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    local storedValue = configuration.UpdateCooldownManualOverride(spell.cooldown - 1, category, spellId)

    assert.equal(spell.cooldown - 1, storedValue)
  end)

  it("UpdateCooldownManualOverride stores values uncapped for spells unknown to SpellMap", function()
    local storedValue = configuration.UpdateCooldownManualOverride(9999, "paladin", 999999)

    assert.equal(9999, storedValue)
  end)

  it("UpdateCooldownManualOverride preserves the worst-case toggle on the per-spell entry", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    configuration.UpdateCooldownManualOverride(42, "paladin", 1022)
    configuration.UpdateCooldownManualOverride(nil, "paladin", 1022)

    assert.is_true(configuration.GetCooldownWorstCaseOverride("paladin", 1022))
  end)

  it("UpdateCooldownWorstCaseState preserves a manual override on the per-spell entry", function()
    configuration.UpdateCooldownManualOverride(42, "paladin", 1022)

    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)
    configuration.UpdateCooldownWorstCaseState(false, "paladin", 1022)

    assert.equal(42, configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("IsGlobalWorstCaseAssumed is false while globalAssumeWorstCase is nil", function()
    assert.is_false(configuration.IsGlobalWorstCaseAssumed())
  end)

  it("UpdateGlobalWorstCaseState round-trips an enabled default", function()
    configuration.UpdateGlobalWorstCaseState(true)

    assert.is_true(configuration.IsGlobalWorstCaseAssumed())
  end)

  it("UpdateGlobalWorstCaseState round-trips a disabled default", function()
    configuration.UpdateGlobalWorstCaseState(true)
    configuration.UpdateGlobalWorstCaseState(false)

    assert.is_false(configuration.IsGlobalWorstCaseAssumed())
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

describe("Configuration cooldown enabled state", function()
  local configuration

  before_each(function()
    configuration = rgcw.configuration
    --[[
      SetupConfiguration never runs headless, so cooldownConfiguration starts
      nil - the accessor must survive that. Reset between scenarios.
    ]]--
    CooldownWatchConfiguration.cooldownConfiguration = nil
  end)

  it("GetCooldownConfigurationState is false while cooldownConfiguration is nil and no default is passed", function()
    assert.is_false(configuration.GetCooldownConfigurationState("priest", 10947))
  end)

  it("GetCooldownConfigurationState falls back to a true catalog default while cooldownConfiguration is nil", function()
    assert.is_true(configuration.GetCooldownConfigurationState("priest", 10947, true))
  end)

  it("GetCooldownConfigurationState falls back to the catalog default for a never-configured category", function()
    CooldownWatchConfiguration.cooldownConfiguration = {}

    assert.is_true(configuration.GetCooldownConfigurationState("priest", 10947, true))
    assert.is_false(configuration.GetCooldownConfigurationState("priest", 10947, false))
  end)

  it("GetCooldownConfigurationState falls back for a never-configured spell in a known category", function()
    CooldownWatchConfiguration.cooldownConfiguration = {}
    configuration.UpdateCooldownConfigurationState(true, "priest", 10890)

    assert.is_true(configuration.GetCooldownConfigurationState("priest", 10947, true))
    assert.is_false(configuration.GetCooldownConfigurationState("priest", 10947, false))
  end)

  it("an explicit enable wins over a false catalog default", function()
    CooldownWatchConfiguration.cooldownConfiguration = {}
    configuration.UpdateCooldownConfigurationState(true, "priest", 10947)

    assert.is_true(configuration.GetCooldownConfigurationState("priest", 10947, false))
  end)

  it("an explicit disable wins over a true catalog default", function()
    CooldownWatchConfiguration.cooldownConfiguration = {}
    configuration.UpdateCooldownConfigurationState(false, "priest", 10947)

    assert.is_false(configuration.GetCooldownConfigurationState("priest", 10947, true))
  end)

  it("a non-boolean catalog default is treated as disabled", function()
    assert.is_false(configuration.GetCooldownConfigurationState("priest", 10947, "yes"))
  end)
end)
