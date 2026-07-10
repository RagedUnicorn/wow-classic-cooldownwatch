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
  Key-set parity across CooldownWatch's localization files (localization/*.lua).

  The recurring bug this pins down (CW-0056): deDE.lua replaces rgcw.L wholesale, so a string added
  to enUS but not mirrored to deDE resolves to nil on German clients — a SetText(nil) or concat
  error at runtime. Rather than an English fallback in production, parity is enforced here: every
  locale must ship the exact same key set. The locale set is glob-discovered (lfs over
  localization/) rather than hard-coded, so a new locale file is picked up automatically.

  On top of key parity, each shared key's string.format placeholder set is compared against enUS
  (the declared source of truth): a translation dropping or adding a %s/%d would crash the
  formatting call at runtime. Placeholders are compared as a sorted multiset so a translator may
  legitimately reorder them.

  Loading mechanics: enUS.lua sets rgcw.L unconditionally, while deDE.lua is wrapped in
  `if (GetLocale() == "deDE")`. So each file is dofile'd with GetLocale() stubbed to return that
  file's locale; every file's `version` string also reads the legacy GetAddOnMetadata global (via
  RGCW_CONSTANTS.ADDON_NAME, which Bootstrap's Constants.lua dofile provides), so GetAddOnMetadata
  is stubbed too. Both stubs come from WowStubs and are restored after each load. rgcw.L is a deep
  field of the shared rgcw table that busted's file insulation does not roll back, so the original
  (nil) is restored once loading is done.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it rgcw
-- luacheck: ignore 143

local lfs = require("lfs")
local wowStubs = require("WowStubs")

--[[
  Glob localization/*.lua and return { { path = "localization/enUS.lua", locale = "enUS" }, ... }
  sorted by locale, so the locale set is never hard-coded.
]]--
local function discoverLocaleFiles()
  local files = {}

  for entry in lfs.dir("localization") do
    local locale = entry:match("^(%w+)%.lua$")

    if locale then
      files[#files + 1] = { path = "localization/" .. entry, locale = locale }
    end
  end

  table.sort(files, function(a, b) return a.locale < b.locale end)

  return files
end

--[[
  dofile a single localization file with GetLocale / GetAddOnMetadata stubbed and return a shallow
  copy of the strings it registered on rgcw.L (as { ["key"] = "value" }).
]]--
local function loadLocaleStrings(path, locale)
  local restore = wowStubs.install({
    GetLocale = wowStubs.stubs.GetLocale(locale),
    GetAddOnMetadata = wowStubs.stubs.GetAddOnMetadata({ Version = "1.2.3" })
  })

  rgcw.L = {}
  dofile(path)

  local strings = {}
  for key, value in pairs(rgcw.L) do
    strings[key] = value
  end

  restore()

  return strings
end

--[[
  Return the key set (key -> true) of a locale's string table.
]]--
local function keySet(strings)
  local keys = {}
  for key in pairs(strings) do
    keys[key] = true
  end

  return keys
end

--[[
  Extract the string.format placeholders from a localized string as a sorted list, so two strings
  can be compared as a multiset (a reorder by a translator is allowed, a count/type change is not).

  Escaped "%%" (a literal percent) is stripped first so it is not mistaken for a placeholder. The
  remaining specifiers are matched as "%" + optional positional index ("1$") + optional
  flags/width/precision + a conversion letter, covering plain ("%s"), typed ("%d") and positional
  ("%1$s") forms.
]]--
local function extractPlaceholders(value)
  local specifiers = {}

  for spec in value:gsub("%%%%", ""):gmatch("%%[%d%$%-%+ #%.]*[diouxXeEfgGqcsaA]") do
    specifiers[#specifiers + 1] = spec
  end
  table.sort(specifiers)

  return specifiers
end

--[[
  Compare every key shared between the reference locale's strings and another locale's strings by
  placeholder multiset. Returns a sorted list of human-readable mismatch descriptions; an empty
  list means every shared key consumes the same format arguments.
]]--
local function findPlaceholderMismatches(referenceStrings, localeStrings, localeName)
  local mismatches = {}

  for key, referenceValue in pairs(referenceStrings) do
    local localeValue = localeStrings[key]

    if localeValue ~= nil then
      local referenceSpecs = table.concat(extractPlaceholders(referenceValue), ",")
      local localeSpecs = table.concat(extractPlaceholders(localeValue), ",")

      if referenceSpecs ~= localeSpecs then
        mismatches[#mismatches + 1] = string.format(
          "%s (enUS expects [%s], %s has [%s])", key, referenceSpecs, localeName, localeSpecs
        )
      end
    end
  end

  table.sort(mismatches)

  return mismatches
end

--[[
  Given { [locale] = { [key] = true } }, return a sorted list of human-readable parity problems:
  every key in the union of all locales that some locale is missing. An empty list means full parity.
]]--
local function findParityProblems(localeKeys)
  local union = {}
  for _, keys in pairs(localeKeys) do
    for key in pairs(keys) do
      union[key] = true
    end
  end

  local problems = {}
  for locale, keys in pairs(localeKeys) do
    for key in pairs(union) do
      if not keys[key] then
        problems[#problems + 1] = locale .. " is missing key '" .. key .. "'"
      end
    end
  end

  table.sort(problems)

  return problems
end

describe("Localization parity", function()
  local originalL = rgcw.L

  local localeFiles = discoverLocaleFiles()

  local shippedStrings = {}
  local shippedKeys = {}
  for _, file in ipairs(localeFiles) do
    shippedStrings[file.locale] = loadLocaleStrings(file.path, file.locale)
    shippedKeys[file.locale] = keySet(shippedStrings[file.locale])
  end

  -- restore the deep field the loads above clobbered (bootstrap never set rgcw.L)
  rgcw.L = originalL

  it("auto-discovers the localization files via glob (not a hard-coded list)", function()
    local discovered = {}
    for _, file in ipairs(localeFiles) do
      discovered[file.locale] = true
    end

    assert.is_true(discovered.enUS)
    assert.is_true(discovered.deDE)
  end)

  it("loads a non-empty key set for every discovered locale", function()
    for locale, keys in pairs(shippedKeys) do
      assert.is_true(next(keys) ~= nil, locale .. " registered no keys")
    end
  end)

  it("has identical key sets across all shipped locales", function()
    -- assert.are.same gives a readable diff of the offending "locale is missing key" lines
    assert.are.same({}, findParityProblems(shippedKeys))
  end)

  it("has matching string.format placeholders against enUS for every shipped locale", function()
    for locale, strings in pairs(shippedStrings) do
      if locale ~= "enUS" then
        assert.are.same({}, findPlaceholderMismatches(shippedStrings.enUS, strings, locale))
      end
    end
  end)

  it("flags a shared key whose translation drops a placeholder", function()
    -- guards the placeholder check itself: a dropped placeholder must be reported, while a
    -- translator reordering placeholders (compared as a sorted multiset) and a literal escaped
    -- percent ("%%") must not
    local mismatches = findPlaceholderMismatches(
      { help = "(%s) use %s or %d", reorder = "%s %d", literal = "100%%" },
      { help = "(%s) benutze %s", reorder = "%d %s", literal = "100%%" },
      "deDE"
    )

    assert.are.same(
      { "help (enUS expects [%d,%s,%s], deDE has [%s,%s])" },
      mismatches
    )
  end)

  it("flags a locale that carries a key the others lack", function()
    -- guards the parity check itself: a stray key in one locale must be reported as the others
    -- missing it (this is exactly the 'added to enUS, forgotten elsewhere' regression)
    local problems = findParityProblems({
      enUS = { addon_name = true, help = true },
      deDE = { addon_name = true, help = true, stray_key = true }
    })

    assert.are.same(
      { "enUS is missing key 'stray_key'" },
      problems
    )
  end)
end)
