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
  if mod.cmd and mod.cmd.RegisterCommand then
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
  else
    mod.logger.LogError(me.tag, "Failed to register test commands - command module not available")
  end
end

--[[
  Show test command help

  Note: Will not be translated as this is a development-only feature
]]--
ShowTestHelp = function()
  print("|cFF00FFFFTest Commands:|r")
  print("|cFF00FFFF/rgcw test cooldownqueue|r - Run all cooldown queue tests")
  print("|cFF00FFFF/rgcw test cooldownqueue <test>|r - Run specific test")
  print("")
  print("Available cooldown queue tests:")
  print("  AddCooldown, AddMultipleCooldowns, DuplicateCooldown, RemoveCooldown")
  print("")
  print("|cFF00FFFF/rgcw debug|r - Toggle debug mode")
end

--[[
  Handle test commands

  @param {string} testCommand - The test command to execute
  @param {table} args - All command arguments
]]--
HandleTestCommand = function(testCommand, args)
  if testCommand == "cooldownqueue" then
    if not mod.testCooldownQueue then
      mod.logger.LogError(me.tag, "CooldownQueue test module not loaded")
      return
    end

    if #args > 1 then
      -- Run specific test
      local testName = args[2]
      local testFunction = "Test" .. testName
      
      if mod.testCooldownQueue[testFunction] then
        mod.testCooldownQueue[testFunction]()
      else
        print("|cFFFF0000Unknown test: " .. testName .. "|r")
        print("Available tests: AddCooldown, AddMultipleCooldowns, DuplicateCooldown, RemoveCooldown")
      end
    else
      -- Run all tests
      mod.testCooldownQueue.RunAllTests()
    end
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