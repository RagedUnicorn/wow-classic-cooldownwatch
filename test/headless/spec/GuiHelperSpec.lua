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
  Icon resolution for spellMap-derived entries (GuiHelper.GetIconId), with the
  caster-relative branch for faction-mirrored items: a friendly queue entry
  carrying a friendlyItemId resolves the player's own faction's item, every
  other entry the (opposing-faction) itemId, and entries without any item the
  spell icon.

  gui/GuiHelper.lua is load-safe headless (it only defines functions), so the
  spec dofiles it like ProximityCooldownBarSpec does its gui file. The two icon
  APIs it reaches for at call time are stubbed to echo their id, keeping the
  assertions about which id was resolved, not about real icon data.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup before_each after_each rgcw
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("GuiHelper icon resolution", function()
  local ITEM_ICON_OFFSET = 100000
  local SPELL_ICON_OFFSET = 200000

  local restoreStubs

  setup(function()
    dofile("gui/GuiHelper.lua")
  end)

  before_each(function()
    restoreStubs = wowStubs.install({
      GetItemIcon = function(itemId) return ITEM_ICON_OFFSET + itemId end,
      GetSpellInfo = function(spellId) return "TestSpell", nil, SPELL_ICON_OFFSET + spellId end,
    })
  end)

  after_each(function()
    restoreStubs()
  end)

  it("resolves entries without an itemId through the spell icon", function()
    assert.equal(SPELL_ICON_OFFSET + 10947, rgcw.guiHelper.GetIconId({ spellId = 10947 }))
  end)

  it("resolves item-triggered entries through the item icon", function()
    assert.equal(ITEM_ICON_OFFSET + 10588, rgcw.guiHelper.GetIconId({ spellId = 22641, itemId = 10588 }))
  end)

  it("resolves a friendly entry with a friendlyItemId through the own-faction item", function()
    local entry = { spellId = 5579, itemId = 18834, friendlyItemId = 18854, friendly = true }

    assert.equal(ITEM_ICON_OFFSET + 18854, rgcw.guiHelper.GetIconId(entry))
  end)

  it("keeps resolving the hostile itemId for entries without the friendly marker", function()
    local entry = { spellId = 5579, itemId = 18834, friendlyItemId = 18854 }

    assert.equal(ITEM_ICON_OFFSET + 18834, rgcw.guiHelper.GetIconId(entry))
  end)

  it("falls back to the itemId for friendly entries of non-mirrored items", function()
    local entry = { spellId = 22641, itemId = 10588, friendly = true }

    assert.equal(ITEM_ICON_OFFSET + 10588, rgcw.guiHelper.GetIconId(entry))
  end)

  it("resolves the insignia catalog entries caster-relative", function()
    --[[
      The catalog's warrior/hunter/shaman insignia entry, assembled under the
      Bootstrap's Alliance faction stub: the hostile side must resolve the
      HORDE item (the enemy pressed theirs), the friendly side the ALLIANCE
      item (a teammate pressed the player's own). The two item ids are
      restated from the slice on purpose - the direction of the faction
      mirroring is exactly what this pins.
    ]]--
    local _, _, insignia = rgcw.spellMapHelper.GetSpellById(5579)

    assert.equal(18834, insignia.itemId)
    assert.equal(18854, insignia.friendlyItemId)

    assert.equal(ITEM_ICON_OFFSET + 18834, rgcw.guiHelper.GetIconId(insignia))

    insignia.friendly = true

    assert.equal(ITEM_ICON_OFFSET + 18854, rgcw.guiHelper.GetIconId(insignia))
  end)
end)
