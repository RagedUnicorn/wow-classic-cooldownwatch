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
end)
