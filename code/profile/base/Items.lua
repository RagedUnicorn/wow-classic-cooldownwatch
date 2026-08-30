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

--[[
  Items slice of the curated default-enabled profile: the PRIMARY spellIds
  that track out of the box on a fresh profile. Each slice file registers
  exactly one category on the shared profileBaseClasses table;
  code/Profile.lua assembles the slices into per-branch sets. Membership is
  only the never-configured default - an explicit player toggle always wins
  in both directions.

  Only the five insignia use-effects are curated - the PvP trinket is the
  one item cooldown every player cares about; engineering gadgets and ZG
  charms stay opt-in.
]]--
mod.profileBaseClasses = mod.profileBaseClasses or {}

mod.profileBaseClasses["items"] = {
  5579, -- Immune Root/Snare/Stun (warrior/hunter/shaman insignia)
  23273, -- Immune Charm/Fear/Polymorph (warlock/rogue insignia)
  23274, -- Immune Fear/Polymorph/Snare (mage insignia)
  23276, -- Immune Fear/Polymorph/Stun (priest/paladin insignia)
  23277, -- Immune Charm/Fear/Stun (druid insignia)
}
