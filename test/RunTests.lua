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

local registry = {}

--[[
  Register a test suite. Each suite file calls this at file-load time so the
  runner, the cmd dispatcher, and the help text can iterate a single source.

  @param {string} slug          - Command-line slug (e.g. "priestspells")
  @param {string} displayName   - Human-readable label for help text
  @param {function} run         - Suite entry point (runs the whole suite)
]]--
function me.Register(slug, displayName, run)
  table.insert(registry, { slug = slug, displayName = displayName, run = run })
end

--[[
  @return {table} - Ordered array of registered suites
]]--
function me.GetSuites()
  return registry
end

--[[
  @param {string} slug
  @return {table|nil} - Registered suite entry or nil
]]--
function me.GetSuite(slug)
  for _, suite in ipairs(registry) do
    if suite.slug == slug then
      return suite
    end
  end
end

--[[
  Initialize test runner
]]--
function me.Initialize()
  mod.logger.LogInfo(me.tag, "Test runner initialized")
  return true
end

--[[
  Run every registered test suite in registration (TOC) order.
]]--
function me.RunAllTests()
  mod.testLogger.Initialize()
  mod.testLogger.LogInfo("TestRunner", "Starting CooldownWatch Test Suite")

  if not me.Initialize() then
    mod.testLogger.LogError("TestRunner", "Failed to initialize test runner")
    mod.testLogger.Finalize()
    return
  end

  for _, suite in ipairs(registry) do
    suite.run()
  end

  mod.cooldownQueue.ClearCooldownQueue()

  mod.testLogger.Finalize()
end
