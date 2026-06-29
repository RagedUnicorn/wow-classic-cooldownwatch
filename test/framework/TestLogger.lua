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
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals GetAddOnMetadata CooldownWatchTestLog date

-- Test logger for CooldownWatch addon
-- Writes test results to SavedVariables for external analysis

local mod = rgcw
local me = {}
mod.testLogger = me

me.tag = "TestLogger"

--[[ Test-output categories. These tag each test-result line for coloring;
  they are not filtered by a threshold
]]--
me.LOG_LEVEL = {
  DEBUG = "DEBUG",
  INFO = "INFO",
  SUCCESS = "SUCCESS",
  FAIL = "FAIL",
  ERROR = "ERROR",
  HEADER = "HEADER"
}

--[[
  Functions to run before every test, in registration order. The orchestrator
  registers the cooldown-queue clear at file-load time so per-test isolation is
  enforced by the framework rather than negotiated by individual test bodies.
]]--
local setUpHooks = {}

--[[
  Register a function to run before every test. Hook receives the test name.

  @param {function} fn
]]--
function me.RegisterSetup(fn)
  table.insert(setUpHooks, fn)
end

--[[
  Initialize test logger
]]--
function me.Initialize()
  if not CooldownWatchTestLog then
    CooldownWatchTestLog = {
      version = GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version"),
      sessions = {}
    }
  end

  -- Create new test session
  local sessionId = date("%Y%m%d_%H%M%S")
  CooldownWatchTestLog.currentSession = sessionId
  CooldownWatchTestLog.sessions[sessionId] = {
    startTime = date("%Y-%m-%d %H:%M:%S"),
    endTime = nil,
    entries = {},
    summary = {
      totalTests = 0,
      passed = 0,
      failed = 0,
      errors = 0
    }
  }

  mod.logger.LogInfo(me.tag, "Test logger initialized - Session: " .. sessionId)

  -- Initialize test log window if available
  if mod.testLogWindow then
    mod.testLogWindow.Initialize()
  end
end

--[[
  Get current test session

  @return {table|nil}
]]--
function me.GetCurrentSession()
  if not CooldownWatchTestLog or not CooldownWatchTestLog.currentSession then
    return nil
  end

  return CooldownWatchTestLog.sessions[CooldownWatchTestLog.currentSession]
end

--[[
  Log test entry

  @param {string} level - Log level from me.LOG_LEVEL
  @param {string} testName - Name of the test
  @param {string} message - Log message
  @param {table} data - Optional additional data
]]--
function me.Log(level, testName, message, data)
  local session = me.GetCurrentSession()

  if not session then
    -- Initialize if not already done
    me.Initialize()
    session = me.GetCurrentSession()
  end

  local entry = {
    timestamp = date("%Y-%m-%d %H:%M:%S"),
    level = level,
    testName = testName,
    message = message
  }

  if data then
    entry.data = data
  end

  table.insert(session.entries, entry)

  -- Also print to chat for immediate feedback
  local colorCode = "|cFFFFFFFF"

  if level == me.LOG_LEVEL.SUCCESS then
    colorCode = "|cFF00FF00"
  elseif level == me.LOG_LEVEL.FAIL then
    colorCode = "|cFFFF0000"
  elseif level == me.LOG_LEVEL.ERROR then
    colorCode = "|cFFFF00FF"
  elseif level == me.LOG_LEVEL.DEBUG then
    colorCode = "|cFF888888"
  elseif level == me.LOG_LEVEL.HEADER then
    colorCode = "|cFF00FFFF"
  end

  print(string.format("%s[%s] %s: %s|r", colorCode, level, testName, message))
end

--[[
  Log debug message

  @param {string} testName
  @param {string} message
  @param {table} data
]]--
function me.LogDebug(testName, message, data)
  me.Log(me.LOG_LEVEL.DEBUG, testName, message, data)
end

--[[
  Log info message

  @param {string} testName
  @param {string} message
  @param {table} data
]]--
function me.LogInfo(testName, message, data)
  me.Log(me.LOG_LEVEL.INFO, testName, message, data)
end

--[[
  Log a section header / cyan-highlighted notice. Used for the test session
  summary delimiters and informational footer lines that should stand out.

  @param {string} testName
  @param {string} message
  @param {table} data
]]--
function me.LogHeader(testName, message, data)
  me.Log(me.LOG_LEVEL.HEADER, testName, message, data)
end

--[[
  Log success message

  @param {string} testName
  @param {string} message
  @param {table} data
]]--
function me.LogSuccess(testName, message, data)
  local session = me.GetCurrentSession()

  if session then
    session.summary.passed = session.summary.passed + 1
  end

  me.Log(me.LOG_LEVEL.SUCCESS, testName, message, data)
end

--[[
  Log failure message

  @param {string} testName
  @param {string} message
  @param {table} data
]]--
function me.LogFail(testName, message, data)
  local session = me.GetCurrentSession()

  if session then
    session.summary.failed = session.summary.failed + 1
  end

  me.Log(me.LOG_LEVEL.FAIL, testName, message, data)
end

--[[
  Log error message

  @param {string} testName
  @param {string} message
  @param {table} data
]]--
function me.LogError(testName, message, data)
  local session = me.GetCurrentSession()

  if session then
    session.summary.errors = session.summary.errors + 1
  end

  me.Log(me.LOG_LEVEL.ERROR, testName, message, data)
end

--[[
  Start a test run

  @param {string} testName
]]--
function me.StartTest(testName)
  local session = me.GetCurrentSession()

  if session then
    session.summary.totalTests = session.summary.totalTests + 1
  end
  me.LogInfo(testName, "Test started")

  for _, fn in ipairs(setUpHooks) do
    fn(testName)
  end
end

--[[
  End a test run

  @param {string} testName
  @param {boolean} success
  @param {string} message
]]--
function me.EndTest(testName, success, message)
  if success then
    me.LogSuccess(testName, message or "Test completed successfully")
  else
    me.LogFail(testName, message or "Test failed")
  end
end

--[[
  Finalize test session
]]--
function me.Finalize()
  local session = me.GetCurrentSession()

  if session then
    session.endTime = date("%Y-%m-%d %H:%M:%S")

    -- Log summary so it appears in both chat and window. The SUCCESS/FAIL/ERROR
    -- lines call Log directly rather than LogSuccess/LogFail/LogError because
    -- those wrappers bump session.summary counters — these are recap lines, not
    -- per-test results, so a wrapper call would double-count.
    me.LogHeader("TestSummary", "=== Test Session Summary ===")
    me.LogInfo("TestSummary", string.format("Total Tests: %d", session.summary.totalTests))
    me.Log(me.LOG_LEVEL.SUCCESS, "TestSummary", string.format("Passed: %d", session.summary.passed))
    me.Log(me.LOG_LEVEL.FAIL, "TestSummary", string.format("Failed: %d", session.summary.failed))
    me.Log(me.LOG_LEVEL.ERROR, "TestSummary", string.format("Errors: %d", session.summary.errors))
    me.LogHeader("TestSummary", "Test log saved to CooldownWatchTestLog")
    me.LogHeader("TestSummary", "Access after /reload or logout")

    -- Guard against the Initialize-failure path in RunAllTests, which calls
    -- Finalize() before any StartTest fires
    if session.summary.totalTests > 0 then
      if me.HasFailures() then
        print("|cFFFF0000=== TESTS FAILED ===|r")
      else
        print("|cFF00FF00=== ALL TESTS PASSED ===|r")
      end
    end
  end
end

--[[
  Clear all test logs
]]--
function me.ClearLogs()
  CooldownWatchTestLog = {
    version = GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version"),
    sessions = {}
  }
  print("|cFF00FFFFTest logs cleared|r")
end

--[[
  Whether the current session has accumulated any test failures or errors.
  Returns false if there is no current session. Errors are treated as failures
  for this signal - LogError is the catch-path for tests that threw, and a run
  where every test crashed should not return false.

  @return {boolean}
]]--
function me.HasFailures()
  local session = me.GetCurrentSession()

  if not session then
    return false
  end

  return session.summary.failed > 0 or session.summary.errors > 0
end

--[[
  Get test summary for current session

  @return {table|nil}
]]--
function me.GetSummary()
  local session = me.GetCurrentSession()

  return session and session.summary or nil
end
