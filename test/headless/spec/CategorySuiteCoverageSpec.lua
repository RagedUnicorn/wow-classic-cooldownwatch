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
  Category-to-suite coverage parity between code/Categories.lua and test/category/.

  Per-spell coverage is already structural: the in-game category suites derive their spell list
  from the live SpellMap (TestHelper.GetSpellsForCategory), so a new spell entry is exercised
  automatically. Category-level coverage is not — the mapping "category X has suite file
  test/category/Test<X>Spells.lua" exists only by convention, so a category added to
  code/Categories.lua without a suite file would silently ship with zero category-suite coverage.
  This spec pins that convention in both directions: every catalog category must have a suite
  file, and every suite file must map back to a catalog category (catching a suite stranded by a
  category rename, e.g. the pre-release misc -> items rename).

  The suite file for a category is Test<UpperFirst(categoryName)>Spells.lua (priest ->
  TestPriestSpells.lua). Suite files are glob-discovered via lfs over test/category/ rather than
  hard-coded, mirroring LocalizationParitySpec, so both sides of the comparison track the tree.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it rgcw
-- luacheck: ignore 143

local lfs = require("lfs")

--[[
  Map a catalog categoryName to its expected suite file name: priest -> TestPriestSpells.lua.
]]--
local function suiteFileName(categoryName)
  return "Test" .. categoryName:gsub("^%l", string.upper) .. "Spells.lua"
end

--[[
  Glob test/category/Test*Spells.lua and return the sorted file names, so the suite set is never
  hard-coded.
]]--
local function discoverSuiteFiles()
  local files = {}

  for entry in lfs.dir("test/category") do
    if entry:match("^Test%w+Spells%.lua$") then
      files[#files + 1] = entry
    end
  end

  table.sort(files)

  return files
end

--[[
  Return a sorted list of human-readable problems for every category whose suite file is absent.
  An empty list means every category is covered.
]]--
local function findUncoveredCategories(categoryNames, suiteFiles)
  local fileSet = {}

  for _, file in ipairs(suiteFiles) do
    fileSet[file] = true
  end

  local problems = {}

  for _, categoryName in ipairs(categoryNames) do
    if not fileSet[suiteFileName(categoryName)] then
      problems[#problems + 1] = "category '" .. categoryName
        .. "' has no suite file test/category/" .. suiteFileName(categoryName)
    end
  end

  table.sort(problems)

  return problems
end

--[[
  Return a sorted list of human-readable problems for every suite file that maps to no catalog
  category. An empty list means no suite file is stranded.
]]--
local function findStraySuiteFiles(categoryNames, suiteFiles)
  local expected = {}

  for _, categoryName in ipairs(categoryNames) do
    expected[suiteFileName(categoryName)] = true
  end

  local problems = {}

  for _, file in ipairs(suiteFiles) do
    if not expected[file] then
      problems[#problems + 1] = "test/category/" .. file
        .. " matches no category in code/Categories.lua"
    end
  end

  table.sort(problems)

  return problems
end

describe("Category suite coverage", function()
  local categoryNames = {}

  for _, category in ipairs(rgcw.categories.GetCategories()) do
    categoryNames[#categoryNames + 1] = category.categoryName
  end

  local suiteFiles = discoverSuiteFiles()

  it("discovers categories and suite files from the tree (not hard-coded lists)", function()
    -- an empty side would make both parity checks pass vacuously
    assert.is_true(#categoryNames > 0, "no categories loaded from code/Categories.lua")
    assert.is_true(#suiteFiles > 0, "no suite files discovered in test/category/")
  end)

  it("has a category test suite file for every catalog category", function()
    -- assert.are.same gives a readable diff of the offending "category has no suite file" lines
    assert.are.same({}, findUncoveredCategories(categoryNames, suiteFiles))
  end)

  it("has a catalog category for every category test suite file", function()
    assert.are.same({}, findStraySuiteFiles(categoryNames, suiteFiles))
  end)

  it("flags a category whose suite file is missing", function()
    -- guards the coverage check itself: a category without a suite file must be reported,
    -- while covered categories must not
    local problems = findUncoveredCategories(
      { "priest", "items" },
      { "TestPriestSpells.lua" }
    )

    assert.are.same(
      { "category 'items' has no suite file test/category/TestItemsSpells.lua" },
      problems
    )
  end)

  it("flags a suite file with no matching category", function()
    -- guards the inverse check itself: this is exactly the 'category renamed, suite left behind'
    -- regression (misc -> items)
    local problems = findStraySuiteFiles(
      { "items" },
      { "TestItemsSpells.lua", "TestMiscSpells.lua" }
    )

    assert.are.same(
      { "test/category/TestMiscSpells.lua matches no category in code/Categories.lua" },
      problems
    )
  end)
end)
