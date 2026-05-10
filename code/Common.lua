--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals GetLocale

local mod = rgcw
local me = {}
mod.common = me

me.tag = "Common"

--[[
  Normalize spellName by replacing spaces with underscores and removing special characters

  @param {string} spellName
  @return {string}
    normalized spellName
]]--
function me.NormalizeSpellName(spellName)
  local name = string.gsub(string.lower(spellName), "%s+", "_")

  name = string.gsub(name, "_%-_", "_")
  name = string.gsub(name, "[-/]", "_")
  name = string.gsub(name, "[':%(%)!]+", "")

  return name
end

--[[
  @param {table} obj
    the object that should be cloned

  @return {table}
    a clone of the object passed
]]--
function me.Clone(obj)
  if type(obj) ~= "table" then return obj end

  local res = {}

  for k, v in pairs(obj) do
    res[me.Clone(k)] = me.Clone(v)
  end

  return res
end

--[[
  Select multiple values from a variable argument list based on the provided indices

  @param {table} indices
    A table containing the indices of the values to select
  @param {...}
    Variable number of arguments from which to select values

  @return {table}
    Returns a table containing the selected values
]]--
function me.SelectMultiple(indices, ...)
  local results = {}

  for i, index in ipairs(indices) do
    results[i] = select(index, ...)
  end

  return unpack(results)
end
