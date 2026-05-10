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
-- luacheck: globals describe it setup
-- luacheck: ignore 143

describe("SpellMap data integrity", function()
  local spellMap
  local groups
  local getSpellById

  setup(function()
    spellMap     = rgcw.spellMap.GetSpellMap()
    groups       = rgcw.spellMap.GetAllSharedCooldownGroups()
    getSpellById = rgcw.spellMapHelper.GetSpellById
  end)

  it("every refId resolves to a primary entry", function()
    assert.same({}, rgcw.spellMapValidation.ValidateRefIdsResolve(spellMap))
  end)

  it("every primary appears in its own allRanks", function()
    assert.same({}, rgcw.spellMapValidation.ValidatePrimaryAllRanksContainsSelf(spellMap))
  end)

  it("allRanks members refId back to their primary", function()
    assert.same({}, rgcw.spellMapValidation.ValidateAllRanksConsistent(spellMap))
  end)

  it("no spellId is primary in more than one category", function()
    assert.same({}, rgcw.spellMapValidation.ValidateNoDuplicatePrimaryAcrossCategories(spellMap))
  end)

  it("shared-cooldown groups are internally consistent", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateSharedCooldownGroupsConsistent(spellMap, groups, getSpellById))
  end)

  it("SearchBySpellId returns nil for an unknown spellId", function()
    assert.same({}, rgcw.spellMapValidation.ValidateUnknownSpellIdReturnsNil(rgcw.spellMapHelper))
  end)

  it("alias entries return nil for an event not in their primary's trackedEvents", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateAliasRejectsMismatchedEvent(spellMap, rgcw.spellMapHelper))
  end)

  it("GetSharedCooldownGroup returns nil for an unknown group name", function()
    assert.same({},
      rgcw.spellMapValidation.ValidateUnknownSharedCooldownGroupReturnsNil(rgcw.spellMap.GetSharedCooldownGroup))
  end)
end)
