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
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals GetAddOnMetadata CombatLogGetCurrentEventInfo

rgcw = rgcw or {}
local me = rgcw

me.tag = "Core"

-- Forward declarations
local OnPlayerLogin
local OnCombatLog
local OnTargetChanged
local Initialize
local ShowWelcomeMessage
local InitializeTestFramework

--[[
  Run the bootstrap sequence on login, then open the readiness gate so gated
  handlers (e.g. combat log) begin processing.
]]--
OnPlayerLogin = function()
  Initialize()
  me.event.SetReady()
end

--[[
  Process the current unfiltered combat log event. Gated until initialization
  is complete (see OnLoad).
]]--
OnCombatLog = function()
  me.combatLog.ProcessUnfilteredCombatLogEvent(CombatLogGetCurrentEventInfo())
end

--[[
  Update the tracked target when the player's target changes.
]]--
OnTargetChanged = function()
  me.target.UpdateCurrentTarget()
end

--[[
  Addon load

  @param {table} self
]]--
function me.OnLoad(self)
  -- Register to player login event also fires on /reload
  me.event.Register("PLAYER_LOGIN", OnPlayerLogin)
  --[[
    Register to combat event unfiltered. Gated so combat log events are ignored
    until initialization completes.

    COMBAT_LOG_EVENT_UNFILTERED - show all logs independent of what the player has configured
    COMBAT_LOG_EVENT - shows only the logs that the player has configured
  ]]--
  me.event.Register("COMBAT_LOG_EVENT_UNFILTERED", OnCombatLog, { gated = true })
  -- Register to the event that fires when the players target changes
  me.event.Register("PLAYER_TARGET_CHANGED", OnTargetChanged)

  me.event.Setup(self)
end

--[[
  MainFrame OnEvent handler. Delegates to the event bus for dispatch.

  @param {string} event
  @param {vararg} ...
]]--
function me.OnEvent(event, ...)
  me.event.Dispatch(event, ...)
end

--[[
  Initialize addon
]]--
Initialize = function()
  me.logger.LogDebug(me.tag, "Initialize addon")
  -- setup slash commands
  me.cmd.SetupSlashCmdList()
  -- setup addon configuration ui
  me.addonConfiguration.SetupAddonConfiguration()
  -- build ui for targetcooldownbar
  me.targetCooldownBar.BuildUi()
  -- load addon variables
  me.configuration.SetupConfiguration()
  -- setup tickers
  me.ticker.StartTickerTargetCooldownBar()
  -- update initial view of gearBars after addon initialization
  me.targetCooldownBar.TargetCooldownBarUiUpdate()
  -- initialize test commands and logger (debug mode only)

  InitializeTestFramework()
  ShowWelcomeMessage()
end

--[[
  Show welcome message to user
]]--
ShowWelcomeMessage = function()
  print(
    string.format("|cFF00FFB0" .. RGCW_CONSTANTS.ADDON_NAME .. rgcw.L["help"],
      GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version"))
  )
end

--[[
  Initialize test framework modules if in development mode
]]--
InitializeTestFramework = function()
  if not RGCW_ENVIRONMENT.DEBUG then
    return
  end

  if me.testLogWindow then
    me.testLogWindow.Initialize()
  end

  if me.testCmd then
    me.testCmd.Initialize()
  end

  if me.debugInjectorWindow then
    me.debugInjectorWindow.Initialize()
  end

  me.logger.LogDebug(me.tag, "Test framework modules initialized")
end
