--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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

-- luacheck: globals DEFAULT_CHAT_FRAME SLASH_COOLDOWNWATCH1 SLASH_COOLDOWNWATCH2 SlashCmdList ReloadUI

local mod = rgcw
local me = {}
mod.cmd = me

me.tag = "Cmd"

-- forward declaration
local ParseSlashCommand

-- registered subcommands
me.registeredCommands = {}

--[[
  Print cmd options for addon
]]--
local function ShowInfoMessage()
  DEFAULT_CHAT_FRAME:AddMessage(rgcw.L["info_title"])
  DEFAULT_CHAT_FRAME:AddMessage(rgcw.L["reload"])
  DEFAULT_CHAT_FRAME:AddMessage(rgcw.L["opt"])
  DEFAULT_CHAT_FRAME:AddMessage(rgcw.L["conf"])

  if RGCW_ENVIRONMENT.DEBUG then
    DEFAULT_CHAT_FRAME:AddMessage(rgcw.L["test"])
  end
end

--[[
  Setup slash command handler
]]--
function me.SetupSlashCmdList()
  SLASH_COOLDOWNWATCH1 = "/rgcw"
  SLASH_COOLDOWNWATCH2 = "/cooldownwatch"

  SlashCmdList["COOLDOWNWATCH"] = ParseSlashCommand
end

--[[
  Parse and handle slash command arguments
  @param {string} msg - The message/arguments passed to the slash command
]]--
ParseSlashCommand = function(msg)
  local args = {}

  mod.logger.LogDebug(me.tag, "/rgcw passed argument: " .. msg)

  -- parse arguments by whitespace
  for arg in string.gmatch(msg, "%S+") do
    table.insert(args, arg)
  end

  if args[1] == "" or args[1] == "help" or #args == 0 then
    ShowInfoMessage()
  elseif args[1] == "rl" or args[1] == "reload" then
    ReloadUI()
  elseif args[1] == "opt" then
    mod.addonConfiguration.OpenAddonPanel()
  elseif args[1] == "conf" or args[1] == "configure" then
    if args[2] == "enable" then
      mod.targetCooldownBar.ShowExampleTargetCooldownBar()
    elseif args[2] == "disable" then
      mod.targetCooldownBar.HideExampleTargetCooldownBar()
    else
      mod.logger.PrintUserError(rgcw.L["invalid_argument"])
    end
  else
    -- Check for registered commands
    if me.registeredCommands[args[1]] then
      local commandName = args[1]
      table.remove(args, 1)
      me.registeredCommands[commandName](args)
    else
      mod.logger.PrintUserError(rgcw.L["invalid_argument"])
    end
  end
end

--[[
  Register a subcommand handler

  @param {string} command - The subcommand name
  @param {function} handler - The function to handle the subcommand
]]--
function me.RegisterCommand(command, handler)
  if type(command) ~= "string" or type(handler) ~= "function" then
    mod.logger.LogError(me.tag, "Invalid command registration - command must be string and handler must be function")
    return
  end

  me.registeredCommands[command] = handler
  mod.logger.LogDebug(me.tag, "Registered command: " .. command)
end
