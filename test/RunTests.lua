--[[
  MIT License

  Copyright (c) 2025 Michael Wiesendanger

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

-- Test runner for CooldownWatch addon
-- Usage: /run rgcw.testRunner.RunAllTests()

local mod = rgcw
local me = {}
mod.testRunner = me

me.tag = "TestRunner"

--[[
  Initialize test runner
]]--
function me.Initialize()
  -- Initialize test components
  mod.logger.LogInfo(me.tag, "Test runner initialized")
  return true
end

--[[
  Run all tests
]]--
function me.RunAllTests()
  -- Initialize test logger
  mod.testLogger.Initialize()
  mod.testLogger.LogInfo("TestRunner", "Starting CooldownWatch Test Suite")

  if not me.Initialize() then
    mod.testLogger.LogError("TestRunner", "Failed to initialize test runner")
    mod.testLogger.Finalize()
    return
  end

  -- Run individual test suites
  me.TestCooldownQueue()
  me.TestSpellMap()

  -- Cleanup - clear any test cooldowns from the queue
  if mod.cooldownQueue then
    mod.cooldownQueue.ClearCooldownQueue()
  end

  -- Finalize test logger
  mod.testLogger.Finalize()
end

--[[
  Test cooldown queue functionality
]]--
function me.TestCooldownQueue()
  if mod.testCooldownQueue then
    mod.testCooldownQueue.RunAllTests()
  else
    mod.testLogger.LogError("TestRunner", "TestCooldownQueue module not loaded")
  end
end

--[[
  Test spellMap data integrity
]]--
function me.TestSpellMap()
  if mod.testSpellMap then
    mod.testSpellMap.RunAllTests()
  else
    mod.testLogger.LogError("TestRunner", "TestSpellMap module not loaded")
  end
end