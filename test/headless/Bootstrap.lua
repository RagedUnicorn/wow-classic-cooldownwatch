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

-- luacheck: globals rgcw RGCW_ENVIRONMENT unpack

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
}

dofile("code/Constants.lua")
dofile("code/Event.lua")
dofile("code/Common.lua")
dofile("code/Categories.lua")
dofile("code/Profile.lua")
dofile("code/Configuration.lua")
dofile("code/Serializer.lua")
dofile("code/Encoder.lua")
dofile("code/ConfigProfile.lua")
dofile("code/SpellMap.lua")
dofile("code/SpellMapHelper.lua")
dofile("code/CooldownQueue.lua")
dofile("test/SpellMapValidation.lua")
