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
  Headless test bootstrap. Stubs the WoW globals that production files reach for
  at load time, then dofile()s the production files in dependency order so the
  pure data-integrity validators are runnable under busted.

  Expected cwd: addon repo root. Run from elsewhere and the dofile()s will fail.
]]--

-- luacheck: globals rgcw RGCW_ENVIRONMENT unpack UnitFactionGroup C_Timer GetTime

-- allow specs to require the opt-in WoW-global stub registry as `require("WowStubs")`
package.path = "./test/headless/?.lua;" .. package.path

-- WoW Classic Era runs Lua 5.1, where `unpack` is a global. busted may run a
-- newer Lua where it moved to `table.unpack`. Mirror the WoW global so any
-- production code that calls unpack() behaves the same headless as it does
-- in-game.
-- luacheck: push ignore 143
unpack = unpack or table.unpack
-- luacheck: pop

rgcw = {}

RGCW_ENVIRONMENT = { TEST = true }

rgcw.logger = {
  IsDebugEnabled = function() return false end,
  LogDebug = function() end,
  LogInfo = function() end,
  LogWarn = function() end,
  LogError = function() end,
  LogEvent = function() end,
}

rgcw.season = {
  IsSodActive = function() return false end,
  IsTbcActive = function() return false end,
}

-- CooldownQueue.AddCooldown wakes the render ticker on enqueue; the gui layer that
-- owns the real edge check (gui/TargetCooldownBar.lua) is not loaded headless
rgcw.targetCooldownBar = {
  WakeRenderTicker = function() end,
}

-- CooldownQueue's expiry-timer callback resolves the current target to decide between
-- flagging and removing; code/Target.lua reads WoW unit APIs and is not loaded headless.
-- "" (no target) sends every headless expiry fire down the immediate-removal path unless
-- a spec overrides the function.
rgcw.target = {
  GetCurrentTargetGuid = function() return "" end,
}

--[[
  CooldownQueue.AddCooldown schedules a one-shot expiry timer per enqueue. The no-op
  keeps specs that enqueue without caring about expiry green; CooldownQueueSpec installs
  a capturing C_Timer (and a fixed GetTime) via WowStubs to exercise the timer semantics.
]]--
C_Timer = {
  After = function() end,
}
GetTime = function() return 0 end

-- SpellMap resolves faction-mirrored insignia itemIds at load time
UnitFactionGroup = function() return "Alliance" end

dofile("code/Constants.lua")
dofile("code/Event.lua")
dofile("code/Common.lua")
dofile("code/Categories.lua")
dofile("code/Profile.lua")
dofile("code/Configuration.lua")
dofile("code/Serializer.lua")
dofile("code/Encoder.lua")
dofile("code/ConfigProfile.lua")
dofile("code/spellmap/base/Priest.lua")
dofile("code/spellmap/base/Rogue.lua")
dofile("code/spellmap/base/Shaman.lua")
dofile("code/spellmap/base/Mage.lua")
dofile("code/spellmap/base/Warrior.lua")
dofile("code/spellmap/base/Hunter.lua")
dofile("code/spellmap/base/Warlock.lua")
dofile("code/spellmap/base/Paladin.lua")
dofile("code/spellmap/base/Druid.lua")
dofile("code/spellmap/base/Racials.lua")
dofile("code/spellmap/base/Items.lua")
dofile("code/spellmap/Base.lua")
dofile("code/spellmap/overlay/Sod.lua")
dofile("code/spellmap/overlay/Tbc.lua")
dofile("code/spellmap/Assemble.lua")
dofile("code/SpellMap.lua")
dofile("code/SpellMapHelper.lua")
dofile("code/CooldownQueue.lua")
dofile("code/CombatLog.lua")
dofile("test/SpellMapValidation.lua")
