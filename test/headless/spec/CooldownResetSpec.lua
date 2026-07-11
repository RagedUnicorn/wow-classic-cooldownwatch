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
  Runtime behavior of CombatLog.ResetTargetedCooldowns (the cooldownResets
  feature): a trigger spell like rogue Preparation removes every cooldown
  listed in its cooldownResets from the caster's queue.

  Targets are derived from the SpellMap entry - never hardcoded - so the spec
  keeps exercising whatever the catalog declares. AddCooldown resolves its
  cooldown through mod.configuration, which reads the CooldownWatchConfiguration
  SavedVariable; the spec stubs it with an empty table (every getter in
  Configuration.lua is nil-tolerant against it) ad hoc rather than through
  WowStubs, since it is a SavedVariable and no other spec needs it yet.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup teardown after_each rgcw CooldownWatchConfiguration
-- luacheck: ignore 143

describe("CombatLog cooldown resets", function()
  local CASTER_GUID = "Player-0000-00000001"
  local CASTER_NAME = "Testcaster"
  local PREPARATION_SPELL_ID = 14185

  local previousConfiguration
  local preparationSpell

  --[[
    Queue one cooldown for the test caster, resolved from SpellMap by spellId.
  ]]--
  local function queueCooldown(spellId)
    local category, _, spell = rgcw.spellMapHelper.GetSpellById(spellId)

    assert.is_not_nil(spell)

    spell.castTime = 0
    rgcw.cooldownQueue.AddCooldown(CASTER_GUID, CASTER_NAME, category, spell)
  end

  --[[
    Set of spellIds currently queued for the test caster.
  ]]--
  local function queuedSpellIds()
    local queued = {}

    for _, cooldownEvent in ipairs(rgcw.cooldownQueue.GetCooldownsByTarget(CASTER_GUID)) do
      queued[cooldownEvent.spellData.spellId] = true
    end

    return queued
  end

  setup(function()
    previousConfiguration = CooldownWatchConfiguration
    CooldownWatchConfiguration = {}

    local _, _, spell = rgcw.spellMapHelper.GetSpellById(PREPARATION_SPELL_ID)
    preparationSpell = spell

    assert.is_not_nil(preparationSpell)
    assert.is_not_nil(preparationSpell.cooldownResets)
  end)

  teardown(function()
    CooldownWatchConfiguration = previousConfiguration
  end)

  after_each(function()
    rgcw.cooldownQueue.ClearCooldownQueue()
  end)

  it("removes every queued cooldownResets target from the caster's queue", function()
    for _, targetSpellId in ipairs(preparationSpell.cooldownResets) do
      queueCooldown(targetSpellId)
    end

    rgcw.combatLog.ResetTargetedCooldowns(CASTER_GUID, preparationSpell)

    assert.same({}, queuedSpellIds())
  end)

  it("is a no-op when none of the targets were ever queued", function()
    rgcw.combatLog.ResetTargetedCooldowns(CASTER_GUID, preparationSpell)

    assert.same({}, queuedSpellIds())
  end)

  it("leaves cooldowns that are not reset targets untouched", function()
    local survivorSpellId = 2139 -- mage Counterspell, not a Preparation target

    queueCooldown(survivorSpellId)
    queueCooldown(preparationSpell.cooldownResets[1])

    rgcw.combatLog.ResetTargetedCooldowns(CASTER_GUID, preparationSpell)

    assert.same({ [survivorSpellId] = true }, queuedSpellIds())
  end)
end)
