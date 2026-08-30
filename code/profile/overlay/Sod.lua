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
mod.profileOverlaySod = me

me.tag = "ProfileOverlaySod"

--[[
  Season of Discovery overlay of the curated default-enabled profile.
  Currently data-empty - the spellmap Sod overlay catalogs no SoD-specific
  cooldowns yet, so there is nothing to curate.

  When SoD spells land in the spellmap overlay, the ones important enough
  to track out of the box are added HERE as `add` ops; a base-curated spell
  that does not exist on SoD gets a `remove` op. Shape per category:
  { [category] = { remove = { spellId, ... }, add = { spellId, ... } } }.

  @return {table}
    Overlay table consumed by mod.profile.BuildDefaultEnabledSets
]]--
function me.GetOverlay()
  return {}
end
