--[[
  MIT License

  Copyright (c) 2021 Michael Wiesendanger

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

-- luacheck: globals C_Timer

local mod = rgcw
local me = {}
mod.ticker = me

me.tag = "Ticker"

local targetCooldownBarTicker

--[[
  Start the repeating update ticker for targetCastBar
]]--
function me.StartTickerTargetCooldownBar()
  if targetCooldownBarTicker == nil or targetCooldownBarTicker._cancelled then
    targetCooldownBarTicker = C_Timer.NewTicker(
      RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_UPDATE_INTERVAL, mod.targetCooldownBar.TargetCooldownBarOnUpdate)
      mod.logger.LogInfo(me.tag, "Started 'TargetCooldownBarTicker'")
  end
end

--[[
  Stop the repeating update ticker for targetCastBar
]]--
function me.StopTickerTargetCooldownBar()
  if targetCooldownBarTicker then
    targetCooldownBarTicker:Cancel()
    mod.logger.LogInfo(me.tag, "Stopped 'TargetCooldownBarTicker'")
  end
end
