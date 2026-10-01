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
  Tests for the log-tag filter (code/Filter.lua). The filter list is file-local, so the
  module is re-dofiled per test for a fresh, empty list; rgcw.filter (which Bootstrap does
  not set) is restored in after_each - busted's file insulation only snapshots the
  top-level `rgcw` reference.
]]--

describe("Filter", function()
  local filter
  local originalFilter = rgcw.filter

  before_each(function()
    dofile("code/Filter.lua")
    filter = rgcw.filter
  end)

  after_each(function()
    rgcw.filter = originalFilter
  end)

  it("filters no tag while no filter is registered", function()
    assert.is_false(filter.ShouldFilterTag("CombatLog"))
  end)

  it("filters a tag matching a registered pattern", function()
    filter.RegisterFilter("combatlog", "^CombatLog$")

    assert.is_true(filter.ShouldFilterTag("CombatLog"))
  end)

  it("treats the registered string as a Lua pattern, not a literal", function()
    filter.RegisterFilter("anchored", "^CombatLog$")
    filter.RegisterFilter("prefix", "^Proximity")

    assert.is_false(filter.ShouldFilterTag("CombatLogFriendly"))
    assert.is_true(filter.ShouldFilterTag("ProximityCooldownBar"))
  end)

  it("stops filtering a tag once its filter is deregistered", function()
    filter.RegisterFilter("combatlog", "^CombatLog$")
    filter.DeregisterFilter("combatlog")

    assert.is_false(filter.ShouldFilterTag("CombatLog"))
  end)

  it("deregisters only the named filter", function()
    filter.RegisterFilter("combatlog", "^CombatLog$")
    filter.RegisterFilter("target", "^Target$")
    filter.DeregisterFilter("combatlog")

    assert.is_false(filter.ShouldFilterTag("CombatLog"))
    assert.is_true(filter.ShouldFilterTag("Target"))
  end)

  it("ignores deregistering an unknown name", function()
    filter.RegisterFilter("combatlog", "^CombatLog$")

    assert.has_no.errors(function()
      filter.DeregisterFilter("unknown")
    end)
    assert.is_true(filter.ShouldFilterTag("CombatLog"))
  end)
end)
