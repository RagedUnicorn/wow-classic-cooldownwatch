--[[
  MIT License

  Copyright (c) 2025 Michael Wiesendanger

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
  Lightweight assertion helpers for in-game test suites. Each helper returns
  true on success and false on failure; on failure, it ends the named test via
  testLogger so callers can collapse a guard clause to a single early-return:

    if not mod.testAssert.Equal(testName, actual, expected, "label") then return end
]]--

local mod = rgcw
local me = {}

mod.testAssert = me

me.tag = "TestAssert"

--[[
  Pass-through if `actual == expected`. On mismatch, end the test as a failure
  with a message of the form "<label>: <actual> (expected <expected>)".

  @param {string} testName
  @param {any} actual
  @param {any} expected
  @param {string} label - Short identifier for the value being checked
                          (e.g. "category", "realSpellId", "spell.name")
  @return {boolean}
]]--
function me.Equal(testName, actual, expected, label)
  if actual == expected then
    return true
  end

  mod.testLogger.EndTest(testName, false,
    string.format("%s: %s (expected %s)", label, tostring(actual), tostring(expected)))

  return false
end

--[[
  Pass-through if `value` is not nil. On nil, end the test as a failure with
  the caller-supplied message verbatim — nil-failure context varies enough
  (which lookup, which arguments) that auto-formatting is less useful than
  letting callers pre-format.

  @param {string} testName
  @param {any} value
  @param {string} failMsg - Message logged on failure
  @return {boolean}
]]--
function me.NotNil(testName, value, failMsg)
  if value ~= nil then
    return true
  end

  mod.testLogger.EndTest(testName, false, failMsg)

  return false
end
