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

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.
]]--

-- Test command handler for CooldownWatch addon
-- This module is only loaded in development builds

local mod = rgcw
local me = {}
mod.testCmd = me

me.tag = "TestCmd"

-- Forward declarations for local functions
local HandleTestCommand
local ShowTestHelp
local ToggleDebugMode

--[[
  Initialize test command module
]]--
function me.Initialize()
  mod.cmd.RegisterCommand("test", function(args)
    if #args > 0 then
      HandleTestCommand(args[1], args)
    else
      ShowTestHelp()
    end
  end)

  mod.cmd.RegisterCommand("debug", function()
    ToggleDebugMode()
  end)

  mod.logger.LogDebug(me.tag, "Test commands registered")
end

--[[
  Show test command help. Per-suite lines come from the testRunner registry;
  static lines (utility commands, sub-test invocation) are hand-written.

  Note: Will not be translated as this is a development-only feature
]]--
ShowTestHelp = function()
  print("|cFF00FFFFTest Commands:|r")
  print("|cFF00FFFF/rgcw test all|r - Run all test suites")

  for _, suite in ipairs(mod.testRunner.GetSuites()) do
    print("|cFF00FFFF/rgcw test " .. suite.slug .. "|r - Run " .. suite.displayName)
  end

  print("|cFF00FFFF/rgcw test cooldownqueue <test>|r - Run a specific cooldown queue test")
  print("|cFF00FFFF/rgcw test inject|r - Toggle debug spell injector window")
  print("|cFF00FFFF/rgcw test log|r - Toggle test log window")
  print("|cFF00FFFF/rgcw test clear-logs|r - Clear test logs")
  print("")
  print("Available cooldown queue tests:")
  print("  AddCooldown, AddMultipleCooldowns, DuplicateCooldown, RemoveCooldown")
  print("")
  print("|cFF00FFFF/rgcw debug|r - Toggle debug mode")
end

--[[
  Handle test commands. Suite invocations dispatch through the testRunner
  registry; the cooldownqueue sub-test arg and the utility commands are the
  only special cases.

  @param {string} testCommand - The test command to execute
  @param {table} args - All command arguments
]]--
HandleTestCommand = function(testCommand, args)
  if testCommand == "all" then
    mod.testRunner.RunAllTests()
    return
  end

  if testCommand == "cooldownqueue" and #args > 1 then
    local testName = args[2]
    local fn = mod.testCooldownQueue["Test" .. testName]

    if fn then
      fn()
    else
      print("|cFFFF0000Unknown test: " .. testName .. "|r")
      print("Available tests: AddCooldown, AddMultipleCooldowns, DuplicateCooldown, RemoveCooldown")
    end

    return
  end

  local suite = mod.testRunner.GetSuite(testCommand)

  if suite then
    suite.run()
    return
  end

  if testCommand == "inject" then
    mod.debugInjectorWindow.Toggle()
  elseif testCommand == "log" or testCommand == "logs" then
    mod.testLogWindow.Toggle()
  elseif testCommand == "clear-logs" then
    mod.testLogger.ClearLogs()
  else
    ShowTestHelp()
  end
end

--[[
  Toggle debug mode
]]--
ToggleDebugMode = function()
  if RGCW_ENVIRONMENT.LOG_LEVEL == 4 then
    RGCW_ENVIRONMENT.LOG_LEVEL = 1
    mod.logger.LogInfo(me.tag, "Debug mode disabled")
  else
    RGCW_ENVIRONMENT.LOG_LEVEL = 4
    mod.logger.LogInfo(me.tag, "Debug mode enabled")
  end
end
