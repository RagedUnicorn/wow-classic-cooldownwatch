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

local mod = rgcw
local me = {}
mod.spellMapOverlaySod = me

me.tag = "SpellMapOverlaySod"

--[[
  Branch overlay applied when Season of Discovery is the active client.
  Currently data-empty - CooldownWatch catalogs no SoD-specific cooldowns yet.

  When one lands it is added HERE, never in code/spellmap/base/ (enforced by
  ValidateBaseEntriesAreBaseType): a SoD-only spell as an `add` op typed
  SPELL_TYPE_SOD, a SoD rework of a Classic spell as `replace` (or remove+add
  when the rework has a new spellId), a SoD-only rank of a Classic spell as
  `appendRanks`. PVPWarn's code/spellmap/overlay/Sod.lua is the worked
  reference for all three shapes.

  The SPELL_TYPE_SOD tag on each entry stays meaningful alongside the overlay
  (PVPWarn parity): the overlay decides which entries exist in the
  assembled map per branch, while SpellMapHelper.IsPrimaryAllowedInCurrentSeason
  keeps filtering by tag for UI listings, lookups, and TEST-mode visibility.

  @return {table}
    Overlay table consumed by mod.spellMapAssembler.Apply
]]--
function me.GetOverlay()
  return {}
end
