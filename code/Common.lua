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
  Parse a player-entered duration in seconds.

  Lua's tonumber alone is too permissive for an input box: it reads hex
  ("0x10" -> 16) and scientific notation ("1e5" -> 100000), neither of which
  anyone means to type into a seconds field, and both of which land far away
  from what the text looks like. Only plain decimal digits with at most one
  separator are accepted.

  A comma is normalized to a dot first - the addon ships a deDE locale and
  "12,5" is what that keyboard layout produces; rejecting it would show an
  error for input the player has every reason to consider correct.

  Fractions are preserved: the catalog holds fractional cooldowns
  (e.g. 5.5s) and a typed 12.5 must survive as 12.5, not collapse to 12.

  Range is deliberately not checked here - that belongs to
  Configuration.IsValidOverrideValue so it applies to every caller rather than
  only to typed input.

  @param {string} text

  @return {number | nil}
    nil when the text is not a plain decimal number
]]--
function me.ParseSeconds(text)
  if type(text) ~= "string" then return nil end

  local normalized = string.gsub(text, ",", ".")

  -- digits with at most one separator, and at least one digit somewhere
  if not string.match(normalized, "^%d*%.?%d*$") or not string.match(normalized, "%d") then
    return nil
  end

  return tonumber(normalized)
end

--[[
  Format a remaining cooldown for the target cooldown bar.

  The slot is 60px wide and the big timer renders at font size 17, so the
  string has to stay short - a flat "%.1f" produced "3600.0" for paladin Lay on
  Hands, which ran past the slot edge into its neighbour. Precision is spent
  where it is worth something instead: tenths only matter in the last seconds
  before the enemy has the spell back, and nobody reads the tenths digit of a
  30 minute cooldown.

  Tiers (the longest output of any of them is three characters, which is what
  makes overflow structurally impossible rather than merely unlikely):

    >= 60s  "60m" "30m" "2m"   minutes, rounded up so it never reads "0m"
    >= 10s  "59" "10"          whole seconds, no decimal noise
     > 0s   "9.9" "0.4"        tenths, where they are actually useful
    <= 0s   ""                 the caller blanks an elapsed timer

  @param {number} seconds

  @return {string}
]]--
function me.FormatCooldownTime(seconds)
  if type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 then
    return ""
  end

  if seconds >= 60 then
    return string.format("%dm", math.ceil(seconds / 60))
  end

  if seconds >= 10 then
    return string.format("%d", math.floor(seconds))
  end

  return string.format("%.1f", seconds)
end

--[[
  Format a cooldown as a readable duration for the options menu.

  The sibling of FormatCooldownTime, and deliberately not the same function:
  that one feeds a 60px bar slot and trades detail for brevity, this one sits
  on the description line under a spell name where there is room to spell the
  value out. "3600" and even "60m" say much less at a glance than "60m", and
  "90" says much less than "1m 30s".

    < 60s   "30s" "5.5s"       plain seconds, fractions kept
    >= 60s  "2m" "60m"         whole minutes on the dot
            "1m 30s"           minutes and the remainder otherwise

  The m/s unit symbols are deliberately not localization keys, matching the
  existing choice for the value fields' "s" suffix - they are SI symbols, not
  words.

  @param {number} seconds

  @return {string}
]]--
function me.FormatCooldownDuration(seconds)
  if type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 then
    return ""
  end

  if seconds < 60 then
    -- %g because the catalog holds fractional cooldowns (e.g. Mind Blast at 5.5)
    return string.format("%gs", seconds)
  end

  local minutes = math.floor(seconds / 60)
  local rest = seconds - minutes * 60

  if rest == 0 then
    return string.format("%dm", minutes)
  end

  return string.format("%dm %gs", minutes, rest)
end

--[[
  Wrap text in a WoW inline colour escape.

  A font string carries exactly one colour, so a line that has to show two
  values in two different colours - "worst case" in cyan next to an overridden
  "cooldown" in gold - can only do it through these escapes. Text left outside
  an escape keeps the font string's own colour, which is what the separator
  between segments uses.

  @param {string} text
  @param {table} color
    An RGCW_CONSTANTS.COLOR { r, g, b } token, components 0-1

  @return {string}
]]--
function me.ColorText(text, color)
  return string.format(
    "|cff%02x%02x%02x%s|r",
    math.floor(color[1] * 255 + 0.5),
    math.floor(color[2] * 255 + 0.5),
    math.floor(color[3] * 255 + 0.5),
    text
  )
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
