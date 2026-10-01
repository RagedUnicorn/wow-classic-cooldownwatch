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
  Tests for the chat logger (code/Logger.lua): level gating per Log* function, the
  separate event switch, the tag filter, and the always-shown user message.

  Bootstrap installs a no-op rgcw.logger stub that every other spec relies on; this spec
  dofiles the real module (and the real code/Filter.lua it consults) per test and restores
  both fields in after_each - busted's file insulation only snapshots the top-level `rgcw`
  reference. `print` and the C_AddOns title lookup go through WowStubs so the captured
  lines are what the module actually prints.
]]--

local wowStubs = require("WowStubs")

describe("Logger", function()
  local logger
  local restore
  local printed
  local originalLogger = rgcw.logger
  local originalFilter = rgcw.filter

  -- one call per Log* function, keyed by the level the function logs at
  local function LogAtEveryLevel()
    logger.LogDebug("Spec", "debug message")
    logger.LogInfo("Spec", "info message")
    logger.LogWarn("Spec", "warn message")
    logger.LogError("Spec", "error message")
  end

  local function PrintedContaining(text)
    local count = 0

    for _, line in ipairs(printed) do
      if string.find(line, text, 1, true) then
        count = count + 1
      end
    end

    return count
  end

  before_each(function()
    printed = {}

    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Title = "CooldownWatch" }),
      print = function(line)
        printed[#printed + 1] = line
      end
    })

    dofile("code/Filter.lua")
    dofile("code/Logger.lua")
    logger = rgcw.logger
    logger.logEvent = false
  end)

  after_each(function()
    restore()
    rgcw.logger = originalLogger
    rgcw.filter = originalFilter
  end)

  it("prints every level at debug", function()
    logger.logLevel = logger.debug
    LogAtEveryLevel()

    assert.equal(4, #printed)
    assert.is_true(logger.IsDebugEnabled())
  end)

  it("drops debug messages below the debug level", function()
    logger.logLevel = logger.info
    LogAtEveryLevel()

    assert.equal(0, PrintedContaining("debug message"))
    assert.equal(1, PrintedContaining("info message"))
    assert.equal(1, PrintedContaining("warn message"))
    assert.equal(1, PrintedContaining("error message"))
    assert.is_false(logger.IsDebugEnabled())
  end)

  it("prints only errors at the error level", function()
    logger.logLevel = logger.error
    LogAtEveryLevel()

    assert.equal(1, #printed)
    assert.equal(1, PrintedContaining("error message"))
  end)

  it("prints no leveled message at the event level", function()
    logger.logLevel = logger.event
    LogAtEveryLevel()

    assert.equal(0, #printed)
  end)

  it("gates event logging on the event switch, independent of the level", function()
    logger.logLevel = logger.event
    logger.LogEvent("Spec", "event message")
    assert.equal(0, #printed)

    logger.logEvent = true
    logger.LogEvent("Spec", "event message")
    assert.equal(1, PrintedContaining("event message"))
  end)

  it("prefixes the level color, addon title and tag", function()
    logger.logLevel = logger.error
    logger.LogError("Spec", "error message")

    assert.equal(logger.colors.error .. "CooldownWatch:Spec - error message", printed[1])
  end)

  it("labels a message without a tag as Unknown", function()
    logger.logLevel = logger.error
    logger.LogError(nil, "error message")

    assert.equal(1, PrintedContaining("CooldownWatch:Unknown - error message"))
  end)

  it("suppresses messages whose tag is filtered", function()
    logger.logLevel = logger.debug
    rgcw.filter.RegisterFilter("spec", "^Spec$")

    LogAtEveryLevel()
    logger.LogError("Other", "other message")

    assert.equal(1, #printed)
    assert.equal(1, PrintedContaining("other message"))
  end)

  it("always shows a user message, regardless of level and filter", function()
    logger.logLevel = logger.event
    rgcw.filter.RegisterFilter("all", ".*")

    logger.PrintUserMessage("user message")

    assert.equal(logger.colors.info .. "CooldownWatch:|r user message", printed[1])
  end)
end)
