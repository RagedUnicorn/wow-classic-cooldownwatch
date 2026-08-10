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
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

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

  it("UpdateCooldownManualOverride rejects zero, negative, NaN and infinite values", function()
    assert.is_nil(configuration.UpdateCooldownManualOverride(0, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownManualOverride(-30, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownManualOverride(0 / 0, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownManualOverride(math.huge, "paladin", 1022))

    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride stores a value below the base cooldown unchanged", function()
    -- base cooldown read from SpellMap rather than restated (see CLAUDE.md)
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    local storedValue = configuration.UpdateCooldownManualOverride(spell.cooldown - 1, category, spellId)

    assert.equal(spell.cooldown - 1, storedValue)
  end)

  it("UpdateCooldownManualOverride stores a value above the base cooldown unchanged", function()
    --[[
      Deliberately uncapped: the player watching the enemy may know better than
      the catalog, and a silent clamp re-renders the pre-filled catalog value,
      which is indistinguishable from the edit having been ignored.
    ]]--
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    local storedValue = configuration.UpdateCooldownManualOverride(spell.cooldown + 100, category, spellId)

    assert.equal(spell.cooldown + 100, storedValue)
    assert.equal(spell.cooldown + 100, configuration.GetCooldownManualOverride(category, spellId))
  end)

  it("UpdateCooldownManualOverride stores a value for a spell unknown to SpellMap", function()
    local storedValue = configuration.UpdateCooldownManualOverride(120, "paladin", 999999)

    assert.equal(120, storedValue)
  end)

  it("UpdateCooldownManualOverride accepts a value exactly on the 60 minute limit", function()
    --[[
      Inclusive on purpose - paladin Lay on Hands sits exactly on the limit, so
      an exclusive comparison would refuse the spell's own catalog cooldown.
    ]]--
    local limit = RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS

    assert.equal(limit, configuration.UpdateCooldownManualOverride(limit, "paladin", 1022))
    assert.equal(limit, configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride rejects a value past the 60 minute limit", function()
    local storedValue = configuration.UpdateCooldownManualOverride(
      RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS + 0.5, "paladin", 1022
    )

    assert.is_nil(storedValue)
    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride rejecting a value leaves an existing override intact", function()
    configuration.UpdateCooldownManualOverride(42, "paladin", 1022)

    assert.is_nil(configuration.UpdateCooldownManualOverride(99999, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownManualOverride("fast", "paladin", 1022))

    assert.equal(42, configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownManualOverride round-trips a fractional value", function()
    -- the catalog itself holds fractional cooldowns, so overrides must carry them too
    assert.equal(12.5, configuration.UpdateCooldownManualOverride(12.5, "paladin", 1022))
    assert.equal(12.5, configuration.GetCooldownManualOverride("paladin", 1022))
  end)

  it("UpdateCooldownWorstCaseValue is held to the same limit and keeps fractions", function()
    --[[
      A spell unknown to SpellMap has no base cooldown to sit below, so it is
      the only way to exercise the shared limit on this field in isolation.
    ]]--
    local limit = RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS

    assert.equal(limit, configuration.UpdateCooldownWorstCaseValue(limit, "paladin", 999999))
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(limit + 1, "paladin", 999999))
    assert.equal(12.5, configuration.UpdateCooldownWorstCaseValue(12.5, "paladin", 999999))
    assert.equal(12.5, configuration.GetCooldownWorstCaseValue("paladin", 999999))
  end)

  it("UpdateCooldownWorstCaseValue rejects a value at or above the spell's base cooldown", function()
    -- base cooldown read from SpellMap rather than restated (see CLAUDE.md)
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(spell.cooldown, category, spellId))
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(spell.cooldown + 1, category, spellId))
    assert.is_nil(configuration.GetCooldownWorstCaseValue(category, spellId))

    -- strictly below is what a worst case means, and is accepted
    assert.equal(spell.cooldown - 0.5,
      configuration.UpdateCooldownWorstCaseValue(spell.cooldown - 0.5, category, spellId))
  end)

  it("UpdateCooldownWorstCaseValue compares against the catalog cooldown, not a manual override", function()
    --[[
      A manual override replaces the resolution wholesale, worst-case settings
      included, so it is not the value this field is a worst case of. Raising
      the override must not widen the range the worst-case field accepts.
    ]]--
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    configuration.UpdateCooldownManualOverride(spell.cooldown + 100, category, spellId)

    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(spell.cooldown + 50, category, spellId))
  end)

  it("UpdateCooldownWorstCaseValue rejecting a value leaves an existing one intact", function()
    local category, spellId, spell = rgcw.spellMapHelper.GetSpellById(RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID)

    configuration.UpdateCooldownWorstCaseValue(spell.cooldown - 1, category, spellId)

    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(spell.cooldown, category, spellId))

    assert.equal(spell.cooldown - 1, configuration.GetCooldownWorstCaseValue(category, spellId))
  end)

  it("GetCooldownWorstCaseValue is nil while cooldownOverrides is nil", function()
    assert.is_nil(configuration.GetCooldownWorstCaseValue("paladin", 1022))
  end)

  it("GetCooldownWorstCaseValue is nil for a never-configured spell in a known category", function()
    configuration.UpdateCooldownWorstCaseValue(42, "paladin", 1022)

    assert.is_nil(configuration.GetCooldownWorstCaseValue("paladin", 853))
  end)

  it("UpdateCooldownWorstCaseValue round-trips a value and returns it", function()
    local storedValue = configuration.UpdateCooldownWorstCaseValue(42, "paladin", 1022)

    assert.equal(42, storedValue)
    assert.equal(42, configuration.GetCooldownWorstCaseValue("paladin", 1022))
  end)

  it("UpdateCooldownWorstCaseValue clears the value when passed nil", function()
    configuration.UpdateCooldownWorstCaseValue(42, "paladin", 1022)

    local storedValue = configuration.UpdateCooldownWorstCaseValue(nil, "paladin", 1022)

    assert.is_nil(storedValue)
    assert.is_nil(configuration.GetCooldownWorstCaseValue("paladin", 1022))
  end)

  it("UpdateCooldownWorstCaseValue clearing a never-configured spell leaves the store untouched", function()
    configuration.UpdateCooldownWorstCaseValue(nil, "paladin", 1022)

    assert.is_nil(CooldownWatchConfiguration.cooldownOverrides)
  end)

  it("UpdateCooldownWorstCaseValue rejects invalid values without touching the store", function()
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue("fast", "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(0, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(-30, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(0 / 0, "paladin", 1022))
    assert.is_nil(configuration.UpdateCooldownWorstCaseValue(math.huge, "paladin", 1022))

    assert.is_nil(configuration.GetCooldownWorstCaseValue("paladin", 1022))
  end)

  it("the three per-spell override fields are independent", function()
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)
    configuration.UpdateCooldownManualOverride(42, "paladin", 1022)
    configuration.UpdateCooldownWorstCaseValue(17, "paladin", 1022)

    configuration.UpdateCooldownManualOverride(nil, "paladin", 1022)

    assert.is_nil(configuration.GetCooldownManualOverride("paladin", 1022))
    assert.equal(17, configuration.GetCooldownWorstCaseValue("paladin", 1022))
    assert.is_true(configuration.GetCooldownWorstCaseOverride("paladin", 1022))
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

  it("IsWorstCaseEffective follows the global default for a never-configured spell", function()
    assert.is_false(configuration.IsWorstCaseEffective("paladin", 1022))

    configuration.UpdateGlobalWorstCaseState(true)

    assert.is_true(configuration.IsWorstCaseEffective("paladin", 1022))
  end)

  it("IsWorstCaseEffective lets an explicit per-spell toggle win in both directions", function()
    configuration.UpdateGlobalWorstCaseState(true)
    configuration.UpdateCooldownWorstCaseState(false, "paladin", 1022)

    assert.is_false(configuration.IsWorstCaseEffective("paladin", 1022))

    configuration.UpdateGlobalWorstCaseState(false)
    configuration.UpdateCooldownWorstCaseState(true, "paladin", 1022)

    assert.is_true(configuration.IsWorstCaseEffective("paladin", 1022))
  end)

  it("IsWorstCaseEffective stays distinct from IsCooldownWorstCaseAssumed", function()
    --[[
      The checkbox's own state must not fold in the global default, or ticking
      the global option would make every per-spell checkbox appear individually
      set. Only the effective query does.
    ]]--
    configuration.UpdateGlobalWorstCaseState(true)

    assert.is_true(configuration.IsWorstCaseEffective("paladin", 1022))
    assert.is_false(configuration.IsCooldownWorstCaseAssumed("paladin", 1022))
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

--[[
  The schema-evolution story: ReconcileWithDefaults fills whatever the current defaults
  declare and the saved table is missing, on every load, without touching configured
  values. SetupConfiguration is its only production caller besides ConfigProfile.ApplySnapshot.
]]--
describe("Configuration schema reconcile", function()
  local configuration
  local restore

  before_each(function()
    configuration = rgcw.configuration
    restore = nil
  end)

  after_each(function()
    if restore ~= nil then restore() end
  end)

  --[[
    Swap the SavedVariable for a throwaway table for the duration of one test. busted
    insulates spec files, so a plain global assignment would be invisible to the
    production code reading CooldownWatchConfiguration - it has to go through _G,
    which is what wowStubs.install does.

    @param {table} saved
    @return {table}
  ]]--
  local function installSavedVariable(saved)
    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "1.2.0" }),
      CooldownWatchConfiguration = saved
    })

    return saved
  end

  it("fills a top-level field the saved table is missing", function()
    local saved = configuration.ReconcileWithDefaults({}, configuration.GetDefaults())

    assert.equal("", saved.lastNotifiedVersion)
    assert.is_false(saved.lockTargetCooldownBar)
    assert.is_false(saved.globalAssumeWorstCase)
    assert.same({}, saved.frames)
    assert.same({}, saved.profiles)
  end)

  it("leaves configured values untouched, including a value equal to the default", function()
    local saved = configuration.ReconcileWithDefaults(
      { lockTargetCooldownBar = true, globalAssumeWorstCase = false, lastNotifiedVersion = "1.1.0" },
      configuration.GetDefaults()
    )

    assert.is_true(saved.lockTargetCooldownBar)
    assert.is_false(saved.globalAssumeWorstCase)
    assert.equal("1.1.0", saved.lastNotifiedVersion)
  end)

  it("fills a category bucket added to the catalog since the configuration was saved", function()
    --[[
      The realistic additive change: a new category means a new bucket inside the two
      category-keyed maps. Simulate the old saved shape by keeping exactly one bucket.
    ]]--
    local saved = configuration.ReconcileWithDefaults(
      { cooldownConfiguration = { ["priest"] = { [10890] = false } }, cooldownOverrides = {} },
      configuration.GetDefaults()
    )

    for _, category in ipairs(rgcw.categories.GetCategories()) do
      assert.is_table(saved.cooldownConfiguration[category.categoryName])
      assert.is_table(saved.cooldownOverrides[category.categoryName])
    end

    -- the pre-existing bucket keeps the player's explicit opt-out
    assert.is_false(saved.cooldownConfiguration["priest"][10890])
  end)

  it("never rewrites player data living under a default-empty table", function()
    local profiles = { ["Default"] = { lockTargetCooldownBar = true }, ["Pvp"] = { frames = {} } }

    local saved = configuration.ReconcileWithDefaults(
      { profiles = profiles, frames = { ["CW_TargetCooldownBarFrame"] = { posX = 10, posY = 20 } } },
      configuration.GetDefaults()
    )

    assert.same({ ["Default"] = { lockTargetCooldownBar = true }, ["Pvp"] = { frames = {} } }, saved.profiles)
    assert.same({ ["CW_TargetCooldownBarFrame"] = { posX = 10, posY = 20 } }, saved.frames)
  end)

  it("resets a saved value whose type disagrees with the default", function()
    local saved = configuration.ReconcileWithDefaults(
      { lockTargetCooldownBar = "yes", frames = 42 },
      configuration.GetDefaults()
    )

    assert.is_false(saved.lockTargetCooldownBar)
    assert.same({}, saved.frames)
  end)

  it("clones the defaults instead of sharing table references with them", function()
    local defaults = configuration.GetDefaults()
    local saved = configuration.ReconcileWithDefaults({}, defaults)

    saved.cooldownConfiguration["priest"][10890] = true

    assert.is_nil(defaults.cooldownConfiguration["priest"][10890])
  end)

  it("is idempotent - a second pass changes nothing", function()
    local saved = configuration.ReconcileWithDefaults({ lockTargetCooldownBar = true }, configuration.GetDefaults())
    local first = rgcw.common.Clone(saved)

    configuration.ReconcileWithDefaults(saved, configuration.GetDefaults())

    assert.same(first, saved)
  end)

  it("returns a non-table saved value untouched instead of raising", function()
    assert.is_nil(configuration.ReconcileWithDefaults(nil, configuration.GetDefaults()))
    assert.equal("corrupt", configuration.ReconcileWithDefaults("corrupt", configuration.GetDefaults()))
  end)

  it("GetDefaults deliberately omits addonVersion - it is bookkeeping, not a configurable field", function()
    assert.is_nil(configuration.GetDefaults().addonVersion)
  end)

  it("SetupConfiguration initializes a wholesale-empty saved table", function()
    local saved = installSavedVariable({})

    configuration.SetupConfiguration()

    for field, defaultValue in pairs(configuration.GetDefaults()) do
      assert.same(defaultValue, saved[field])
    end
  end)

  it("SetupConfiguration fills a partial saved table without discarding user values", function()
    local saved = installSavedVariable({
      lockTargetCooldownBar = true,
      cooldownConfiguration = { ["priest"] = { [10890] = false } }
    })

    configuration.SetupConfiguration()

    assert.is_true(saved.lockTargetCooldownBar)
    assert.is_false(saved.cooldownConfiguration["priest"][10890])
    assert.same({}, saved.frames)
    assert.equal("", saved.lastNotifiedVersion)
  end)

  it("SetupConfiguration stamps the current addon version over a stale one", function()
    local saved = installSavedVariable({ addonVersion = "1.0.0" })

    configuration.SetupConfiguration()

    assert.equal("1.2.0", saved.addonVersion)
  end)
end)
