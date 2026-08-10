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

describe("Common pure helpers", function()
  local common

  setup(function()
    common = rgcw.common
  end)

  describe("NormalizeSpellName", function()
    -- { input, expected, note }
    local cases = {
      { "Concussion Blow",               "concussion_blow",            "spaces to underscores" },
      { "Cold Snap",                     "cold_snap",                  "single space" },
      { "Drink Healing Potion (Major)",  "drink_healing_potion_major", "parentheses stripped" },
      { "Fire - Ice",                    "fire_ice",                   "spaced hyphen collapses to one underscore" },
      { "Block/Parry",                   "block_parry",                "slash to underscore" },
      { "Will's Power",                  "wills_power",                "apostrophe stripped" },
      { "Charge!",                       "charge",                     "exclamation stripped" },
      { "Aspect: Hawk",                  "aspect_hawk",                "colon stripped" },
    }

    for _, case in ipairs(cases) do
      local input, expected, note = case[1], case[2], case[3]
      it(string.format("normalizes %q -> %q (%s)", input, expected, note), function()
        assert.equal(expected, common.NormalizeSpellName(input))
      end)
    end
  end)

  describe("ParseSeconds", function()
    -- { input, expected, note }
    local cases = {
      { "30",       30,   "whole seconds" },
      { "12.5",     12.5, "fraction survives - the catalog holds fractional cooldowns" },
      { "12,5",     12.5, "decimal comma, what a deDE keyboard layout produces" },
      { "0.5",      0.5,  "leading zero" },
      { ".5",       0.5,  "no leading zero" },
      { "3600",     3600, "the 60 minute limit itself parses; the range check is Configuration's" },
      { "120.",     120,  "trailing separator is unambiguous" },
      { "abc",      nil,  "not a number" },
      { "",         nil,  "empty - callers treat this as clear, never as a value" },
      { "0x10",     nil,  "hex would silently become 16" },
      { "1e5",      nil,  "scientific notation would silently become 100000" },
      { "-5",       nil,  "sign rejected here, negative values are also refused by the store" },
      { "12.5.5",   nil,  "two separators" },
      { "12 5",     nil,  "embedded space" },
      { " 12",      nil,  "leading space - tonumber would have accepted it" },
      { "inf",      nil,  "not a number in Lua either, pinned so that stays true" },
    }

    for _, case in ipairs(cases) do
      local input, expected, note = case[1], case[2], case[3]
      it(string.format("parses %q -> %s (%s)", input, tostring(expected), note), function()
        assert.equal(expected, common.ParseSeconds(input))
      end)
    end

    it("returns nil for a non-string", function()
      assert.is_nil(common.ParseSeconds(nil))
      assert.is_nil(common.ParseSeconds(30))
    end)
  end)

  describe("FormatCooldownTime", function()
    -- { input, expected, note }
    local cases = {
      { 3600,  "60m", "paladin Lay on Hands - the value that used to render as 3600.0 and overflow" },
      { 1800,  "30m", "druid Rebirth" },
      { 121,   "3m",  "rounded up - 2m01s has more than two minutes to go" },
      { 120,   "2m",  "exact minutes are not rounded past themselves" },
      { 60,    "1m",  "lower edge of the minute tier" },
      { 59.9,  "59",  "just below the minute tier - whole seconds, no decimal" },
      { 10,    "10",  "lower edge of the whole-second tier" },
      { 9.99,  "10.0", "just below it - tenths, and %.1f may round up to the tier boundary" },
      { 9.5,   "9.5", "tenths where they matter" },
      { 0.4,   "0.4", "final moments" },
      { 0,     "",    "an elapsed timer is blanked, not shown as 0.0" },
      { -5,    "",    "overshoot is blanked too" },
    }

    for _, case in ipairs(cases) do
      local input, expected, note = case[1], case[2], case[3]
      it(string.format("formats %s -> %q (%s)", tostring(input), expected, note), function()
        assert.equal(expected, common.FormatCooldownTime(input))
      end)
    end

    it("returns an empty string for a non-number and for NaN", function()
      assert.equal("", common.FormatCooldownTime(nil))
      assert.equal("", common.FormatCooldownTime("30"))
      assert.equal("", common.FormatCooldownTime(0 / 0))
    end)

    --[[
      The whole point of the tiers: the slot is 60px wide and the big timer
      renders at font size 17, so the guarantee has to be on the string length
      itself rather than on the values that happen to be in the catalog today.
    ]]--
    it("never produces more than four characters for any value up to the cooldown limit", function()
      local longest = ""

      for tenths = 1, RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS * 10 do
        local formatted = common.FormatCooldownTime(tenths / 10)

        if #formatted > #longest then
          longest = formatted
        end
      end

      assert.is_true(#longest <= 4, "longest formatted timer was '" .. longest .. "'")
    end)
  end)

  describe("ColorText", function()
    it("wraps text in a WoW inline colour escape", function()
      assert.equal("|cffffd10030s cooldown|r",
        common.ColorText("30s cooldown", RGCW_CONSTANTS.COLOR.TITLE_GOLD))
    end)

    it("pads each component to two hex digits", function()
      -- 0.01 * 255 rounds to 3 -> "03", not "3", or the escape is misparsed
      assert.equal("|cff03a8f2x|r", common.ColorText("x", RGCW_CONSTANTS.COLOR.WORST_CASE))
    end)

    it("handles the extremes without overflowing a byte", function()
      assert.equal("|cff000000a|r", common.ColorText("a", { 0, 0, 0 }))
      assert.equal("|cffffffffa|r", common.ColorText("a", { 1, 1, 1 }))
    end)

    it("produces escapes the client will not truncate mid-line", function()
      --[[
        Two coloured segments joined by an uncoloured separator is the shape the
        spell row's description line uses; each escape has to close with |r or
        the colour bleeds into everything after it.
      ]]--
      local line = common.ColorText("20s worst case", RGCW_CONSTANTS.COLOR.WORST_CASE)
        .. " / " .. common.ColorText("15s override", RGCW_CONSTANTS.COLOR.TITLE_GOLD)
      local _, opens = string.gsub(line, "|cff%x%x%x%x%x%x", "")
      local _, closes = string.gsub(line, "|r", "")

      assert.equal(2, opens)
      assert.equal(2, closes)
    end)
  end)

  describe("FormatCooldownDuration", function()
    -- { input, expected, note }
    local cases = {
      { 30,    "30s",     "plain seconds below a minute" },
      { 5.5,   "5.5s",    "priest Mind Blast worst case - the fraction is kept" },
      { 59,    "59s",     "upper edge of the seconds tier" },
      { 60,    "1m",      "exactly one minute, no dangling 0s" },
      { 90,    "1m 30s",  "minutes and seconds, the readable middle case" },
      { 120,   "2m",      "whole minutes on the dot" },
      { 300,   "5m",      "rogue Vanish" },
      { 1800,  "30m",     "druid Rebirth" },
      { 3600,  "60m",     "paladin Lay on Hands, the catalog maximum" },
      { 185.5, "3m 5.5s", "fractional remainder survives the minute split" },
      { 0,     "",        "not a duration" },
    }

    for _, case in ipairs(cases) do
      local input, expected, note = case[1], case[2], case[3]
      it(string.format("formats %s -> %q (%s)", tostring(input), expected, note), function()
        assert.equal(expected, common.FormatCooldownDuration(input))
      end)
    end

    it("returns an empty string for a non-number and for NaN", function()
      assert.equal("", common.FormatCooldownDuration(nil))
      assert.equal("", common.FormatCooldownDuration("30"))
      assert.equal("", common.FormatCooldownDuration(0 / 0))
    end)

    it("renders every catalog cooldown without a stray zero remainder", function()
      --[[
        Guards the floating point split against real data: a cooldown that is a
        whole number of minutes must never come out as "5m 0s", and a remainder
        must never surface an artifact like "3m 5.699999s". Values are walked
        out of SpellMap rather than restated (see CLAUDE.md).
      ]]--
      local function AssertClean(name, value)
        if value == nil then return end

        local formatted = common.FormatCooldownDuration(value)
        local context = string.format("%s (%s) formatted as '%s'", name, tostring(value), formatted)

        assert.is_nil(string.match(formatted, "m 0s$"), context)
        assert.is_nil(string.match(formatted, "%d%d%d%d"), context)
      end

      for _, spells in pairs(rgcw.spellMap.GetSpellMap()) do
        for _, entry in pairs(spells) do
          if entry.refId == nil then
            AssertClean(entry.name, entry.cooldown)
            AssertClean(entry.name, entry.cooldownWorstCase)
          end
        end
      end
    end)
  end)
end)
