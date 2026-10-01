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
  Headless spec for the login bootstrap in code/Core.lua. Bootstrap does not load
  Core.lua (its Initialize builds the whole gui layer); this spec dofiles it against a
  capturing event bus, grabs the PLAYER_LOGIN handler OnLoad registers, and drives it
  with a first Initialize step that raises. The capturing bus also pins the event
  wiring of OnLoad: which events get a handler and which are gated behind the
  readiness flag. Every rgcw field Core.lua or the spec
  replaces is restored in after_each - busted's file insulation only snapshots the
  top-level `rgcw` reference.
]]--

local wowStubs = require("WowStubs")

describe("Core", function()
  local REPLACED_FIELDS = { "tag", "OnLoad", "OnEvent", "event", "cmd", "comm" }
  local savedFields
  local originalLogError
  local restore
  local handlers
  -- the options table each event was registered with
  local registrationOptions
  -- the login steps in the order they ran
  local loginSteps
  local ready
  local handledErrors
  local loggedErrors

  before_each(function()
    savedFields = {}

    for _, field in ipairs(REPLACED_FIELDS) do
      savedFields[field] = rgcw[field]
    end

    originalLogError = rgcw.logger.LogError
    handlers = {}
    registrationOptions = {}
    loginSteps = {}
    ready = false
    handledErrors = {}
    loggedErrors = {}

    restore = wowStubs.install({
      geterrorhandler = function()
        return function(err)
          handledErrors[#handledErrors + 1] = err
        end
      end
    })

    rgcw.logger.LogError = function(_, message)
      loggedErrors[#loggedErrors + 1] = message
    end

    rgcw.event = {
      Setup = function() end,
      Register = function(eventName, handler, options)
        handlers[eventName] = handler
        registrationOptions[eventName] = options
      end,
      SetReady = function()
        loginSteps[#loginSteps + 1] = "SetReady"
        ready = true
      end
    }

    -- OnLoad registers the addon message handler
    rgcw.comm = { OnChatMsgAddon = function() end }

    -- the first step of Initialize raises
    rgcw.cmd = {
      SetupSlashCmdList = function()
        loginSteps[#loginSteps + 1] = "Initialize"
        error("slash command setup failed")
      end
    }

    dofile("code/Core.lua")
    rgcw.OnLoad({})
  end)

  after_each(function()
    restore()
    rgcw.logger.LogError = originalLogError

    for _, field in ipairs(REPLACED_FIELDS) do
      rgcw[field] = savedFields[field]
    end
  end)

  it("registers every event handler, gating all but login and target change", function()
    local expectedGated = {
      PLAYER_LOGIN = false,
      PLAYER_TARGET_CHANGED = false,
      PLAYER_LOGOUT = true,
      COMBAT_LOG_EVENT_UNFILTERED = true,
      CHAT_MSG_ADDON = true,
      PLAYER_ENTERING_WORLD = true,
      GROUP_ROSTER_UPDATE = true,
    }

    for eventName, gated in pairs(expectedGated) do
      assert.is_function(handlers[eventName], eventName .. " has no handler")

      local options = registrationOptions[eventName]
      assert.equal(gated, options ~= nil and options.gated == true, eventName .. " gating")
    end

    for eventName in pairs(handlers) do
      assert.is_not_nil(expectedGated[eventName], "unexpected registration " .. eventName)
    end
  end)

  it("opens the readiness gate only after Initialize ran", function()
    handlers.PLAYER_LOGIN()

    assert.same({ "Initialize", "SetReady" }, loginSteps)
  end)

  it("opens the readiness gate even when a step of Initialize raises", function()
    assert.has_no.errors(function()
      handlers.PLAYER_LOGIN()
    end)

    assert.is_true(ready)
  end)

  it("hands the initialization error to the client error handler and logs it", function()
    handlers.PLAYER_LOGIN()

    assert.equal(1, #handledErrors)
    assert.truthy(string.find(handledErrors[1], "slash command setup failed", 1, true))
    assert.equal(1, #loggedErrors)
    assert.truthy(string.find(loggedErrors[1], "slash command setup failed", 1, true))
  end)
end)
