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

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it before_each
-- luacheck: ignore 143

describe("Event bus", function()
  local registered
  local stubFrame

  before_each(function()
    -- Re-dofile the bus so each test starts with fresh handler/ready state.
    dofile("code/Event.lua")

    registered = {}
    stubFrame = {
      RegisterEvent = function(_, eventName)
        registered[eventName] = true
      end,
    }
  end)

  it("Setup registers every declared event on the frame", function()
    rgcw.event.Register("PLAYER_LOGIN", function() end)
    rgcw.event.Register("PLAYER_TARGET_CHANGED", function() end)

    rgcw.event.Setup(stubFrame)

    assert.is_true(registered["PLAYER_LOGIN"])
    assert.is_true(registered["PLAYER_TARGET_CHANGED"])
  end)

  it("Dispatch invokes the matching handler with the event varargs", function()
    local received

    rgcw.event.Register("CUSTOM_EVENT", function(a, b)
      received = { a, b }
    end)

    rgcw.event.Dispatch("CUSTOM_EVENT", "unit", 42)

    assert.same({ "unit", 42 }, received)
  end)

  it("Register accepts an array of events sharing one handler", function()
    local calls = 0

    rgcw.event.Register({ "EVENT_A", "EVENT_B", "EVENT_C" }, function()
      calls = calls + 1
    end)

    rgcw.event.Setup(stubFrame)

    assert.is_true(registered["EVENT_A"])
    assert.is_true(registered["EVENT_B"])
    assert.is_true(registered["EVENT_C"])

    rgcw.event.Dispatch("EVENT_A")
    rgcw.event.Dispatch("EVENT_C")

    assert.equal(2, calls)
  end)

  it("Dispatch ignores an unregistered event", function()
    assert.has_no.errors(function()
      rgcw.event.Dispatch("UNREGISTERED_EVENT")
    end)
  end)

  it("ungated handlers fire before SetReady", function()
    local calls = 0

    rgcw.event.Register("UNGATED", function() calls = calls + 1 end)

    rgcw.event.Dispatch("UNGATED")

    assert.equal(1, calls)
  end)

  it("gated handlers are suppressed until SetReady, then fire", function()
    local calls = 0

    rgcw.event.Register("GATED", function() calls = calls + 1 end, { gated = true })

    rgcw.event.Dispatch("GATED")
    assert.equal(0, calls)

    rgcw.event.SetReady()

    rgcw.event.Dispatch("GATED")
    assert.equal(1, calls)
  end)
end)
