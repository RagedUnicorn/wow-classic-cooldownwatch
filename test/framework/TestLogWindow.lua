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
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals C_Timer GameTooltip SLASH_COOLDOWNWATCH_TESTLOG1 SLASH_COOLDOWNWATCH_TESTLOG2
-- luacheck: globals SlashCmdList date CreateFrame CooldownWatchTestLog

-- Test log window UI for CooldownWatch addon
-- Displays test logs in a scrollable window

local mod = rgcw
local me = {}
mod.testLogWindow = me

me.tag = "TestLogWindow"

-- Forward declarations for local functions
local CreateTimestamp
local CreateLevelText
local CreateTestNameText
local GetMessageColor
local CreateMessageText
local AddDataTooltip

-- UI elements
me.logMessages = {}
me.maxMessages = 1000
me.messageHeight = 14
me.messagePadding = 2

-- Color codes for log levels
me.levelColors = {
  DEBUG = {0.5, 0.5, 0.5},     -- Gray
  INFO = {1, 1, 1},            -- White
  SUCCESS = {0, 1, 0},         -- Green
  FAIL = {1, 0, 0},            -- Red
  ERROR = {1, 0, 1}            -- Magenta
}

--[[
  Initialize test log window
]]--
function me.Initialize()
  -- Only override once to prevent multiple hooks
  if not me.initialized then
    -- Override the testLogger.Log function to also update the UI
    local originalLog = mod.testLogger.Log
    mod.testLogger.Log = function(level, testName, message, data)
      -- Call original log function
      originalLog(level, testName, message, data)

      -- Update UI if window exists
      if _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW] then
        me.AddLogMessage(level, testName, message, data)
      end
    end

    me.initialized = true
  end

  -- Clear existing messages when starting a new session
  local testLogWindow = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW]

  if testLogWindow then
    me.ClearLog()

    -- Update window title with new session info
    local windowTitle = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_TITLE]

    if windowTitle and _G[RGCW_CONSTANTS.SAVED_VARIABLE_TEST_LOG] and _G[RGCW_CONSTANTS.SAVED_VARIABLE_TEST_LOG].currentSession then
      windowTitle:SetText(string.format("CooldownWatch Test Log - Session: %s",
        _G[RGCW_CONSTANTS.SAVED_VARIABLE_TEST_LOG].currentSession))
    end
  end

  mod.logger.LogInfo(me.tag, "Test log window initialized")
end

--[[
  Show the test log window
]]--
function me.Show()
  local testLogWindow = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW]

  if not testLogWindow then
    mod.logger.LogError(me.tag, "Test log window not found")
    return
  end

  testLogWindow:Show()

  -- Load existing session logs if available
  me.LoadSessionLogs()
end

--[[
  Hide the test log window
]]--
function me.Hide()
  local testLogWindow = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW]

  if testLogWindow then
    testLogWindow:Hide()
  end
end

--[[
  Toggle the test log window
]]--
function me.Toggle()
  local testLogWindow = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW]

  if testLogWindow and testLogWindow:IsShown() then
    me.Hide()
  else
    me.Show()
  end
end

--[[
  Add a log message to the window

  @param {string} level - Log level
  @param {string} testName - Test name
  @param {string} message - Log message
  @param {table} data - Optional data
]]--
function me.AddLogMessage(level, testName, message, data)
  local scrollFrame = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_SCROLL_FRAME]
  local scrollChild = scrollFrame:GetScrollChild()

  if not scrollFrame or not scrollChild then
    return
  end

  -- Create message frame
  local messageFrame = me.CreateMessageFrame(scrollChild, level, testName, message, data)

  -- Position the message
  local yOffset = -(#me.logMessages * (me.messageHeight + me.messagePadding))
  messageFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)

  -- Add to messages array
  table.insert(me.logMessages, messageFrame)

  -- Limit message count
  if #me.logMessages > me.maxMessages then
    local oldMessage = table.remove(me.logMessages, 1)
    oldMessage:Hide()
    oldMessage:SetParent(nil)

    -- Reposition remaining messages
    me.RepositionMessages()
  end

  -- Update scroll child height
  local totalHeight = #me.logMessages * (me.messageHeight + me.messagePadding)
  scrollChild:SetHeight(math.max(totalHeight, 1))

  -- Auto-scroll if enabled (delay to ensure proper scroll calculation)
  local autoScrollCheckBox = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_AUTO_SCROLL]

  if autoScrollCheckBox and autoScrollCheckBox:GetChecked() then
    C_Timer.After(0.01, function()
      local scrollRange = scrollFrame:GetVerticalScrollRange()

      if scrollRange > 0 then
        scrollFrame:SetVerticalScroll(scrollRange)
      end
    end)
  end
end

--[[
  Create timestamp font string

  @param {Frame} parent - Parent frame

  @return {FontString} - Created timestamp
]]--
CreateTimestamp = function(parent)
  local timestamp = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  timestamp:SetPoint("LEFT", parent, "LEFT", 0, 0)
  timestamp:SetText(date("%H:%M:%S"))
  timestamp:SetTextColor(0.6, 0.6, 0.6)
  timestamp:SetWidth(60)
  timestamp:SetJustifyH("LEFT")

  return timestamp
end

--[[
  Create level indicator font string

  @param {Frame} parent - Parent frame
  @param {FontString} anchor - Anchor element
  @param {string} level - Log level

  @return {FontString} - Created level text
]]--
CreateLevelText = function(parent, anchor, level)
  local levelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  levelText:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
  levelText:SetText(string.format("[%s]", level))

  local color = me.levelColors[level] or {1, 1, 1}
  levelText:SetTextColor(unpack(color))
  levelText:SetWidth(60)
  levelText:SetJustifyH("LEFT")

  return levelText
end

--[[
  Create test name font string

  @param {Frame} parent - Parent frame
  @param {FontString} anchor - Anchor element
  @param {string} testName - Test name

  @return {FontString} - Created test name text
]]--
CreateTestNameText = function(parent, anchor, testName)
  local testNameText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  testNameText:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
  testNameText:SetText(testName .. ":")
  testNameText:SetTextColor(0.8, 0.8, 1)
  testNameText:SetWidth(120)
  testNameText:SetJustifyH("LEFT")

  return testNameText
end

--[[
  Get message text color based on content

  @param {string} testName - Test name
  @param {string} message - Log message
  @param {table} defaultColor - Default color to use

  @return {number, number, number} - RGB color values
]]--
GetMessageColor = function(testName, message, defaultColor)
  if testName == "TestSummary" then
    if message:find("===") then
      return 0, 1, 1  -- Cyan for headers
    elseif message:find("Passed:") then
      return 0, 1, 0  -- Green for passed
    elseif message:find("Failed:") then
      return 1, 0, 0  -- Red for failed
    elseif message:find("Errors:") then
      return 1, 0, 1  -- Magenta for errors
    end
  end

  return unpack(defaultColor)
end

--[[
  Create message text font string

  @param {Frame} parent - Parent frame
  @param {FontString} anchor - Anchor element
  @param {string} testName - Test name
  @param {string} message - Log message
  @param {table} defaultColor - Default color

  @return {FontString} - Created message text
]]--
CreateMessageText = function(parent, anchor, testName, message, defaultColor)
  local messageText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  messageText:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
  messageText:SetPoint("RIGHT", parent, "RIGHT", -5, 0)
  messageText:SetText(message)
  messageText:SetTextColor(GetMessageColor(testName, message, defaultColor))
  messageText:SetJustifyH("LEFT")

  return messageText
end

--[[
  Add tooltip to frame for displaying data

  @param {Frame} frame - Frame to add tooltip to
  @param {table} data - Data to display in tooltip
]]--
AddDataTooltip = function(frame, data)
  frame:EnableMouse(true)
  frame:SetScript("OnEnter", function(self)
    local tooltip = _G["GameTooltip"]
    tooltip:SetOwner(self, "ANCHOR_CURSOR")
    tooltip:AddLine("Test Data", 1, 1, 1)
    tooltip:AddLine(" ")

    for key, value in pairs(data) do
      local valueStr = tostring(value)

      if type(value) == "table" then
        valueStr = "{table}"
      end
      tooltip:AddDoubleLine(key .. ":", valueStr, 0.8, 0.8, 0.8, 1, 1, 1)
    end

    tooltip:Show()
  end)

  frame:SetScript("OnLeave", function()
    _G["GameTooltip"]:Hide()
  end)
end

--[[
  Create a message frame

  @param {Frame} parent - Parent frame
  @param {string} level - Log level
  @param {string} testName - Test name
  @param {string} message - Log message
  @param {table} data - Optional data

  @return {Frame} - Created message frame
]]--
function me.CreateMessageFrame(parent, level, testName, message, data)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetHeight(me.messageHeight)
  frame:SetWidth(parent:GetWidth())

  local timestamp = CreateTimestamp(frame)
  local levelText = CreateLevelText(frame, timestamp, level)
  local testNameText = CreateTestNameText(frame, levelText, testName)

  local color = me.levelColors[level] or {1, 1, 1}
  CreateMessageText(frame, testNameText, testName, message, color)

  if data then
    AddDataTooltip(frame, data)
  end

  return frame
end

--[[
  Reposition all messages after removal
]]--
function me.RepositionMessages()
  for i, messageFrame in ipairs(me.logMessages) do
    local yOffset = -((i - 1) * (me.messageHeight + me.messagePadding))
    messageFrame:SetPoint("TOPLEFT", messageFrame:GetParent(), "TOPLEFT", 0, yOffset)
  end
end

--[[
  Clear all log messages
]]--
function me.ClearLog()
  for _, messageFrame in ipairs(me.logMessages) do
    messageFrame:Hide()
    messageFrame:SetParent(nil)
  end

  me.logMessages = {}
  me.currentSessionId = nil -- Reset session tracking

  local scrollChild = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_SCROLL_CHILD]
  if scrollChild then
    scrollChild:SetHeight(1)
  end

  mod.logger.LogInfo(me.tag, "Test log cleared")
end

--[[
  Load session logs into the window
]]--
function me.LoadSessionLogs()
  local session = mod.testLogger.GetCurrentSession()

  if not session or not session.entries then
    return
  end

  -- Don't reload if we're already showing current session
  local testLog = _G[RGCW_CONSTANTS.SAVED_VARIABLE_TEST_LOG]

  if me.currentSessionId == testLog.currentSession then
    return
  end

  -- Clear existing messages
  me.ClearLog()

  -- Remember which session we're showing
  me.currentSessionId = testLog.currentSession

  -- Add each log entry
  for _, entry in ipairs(session.entries) do
    me.AddLogMessage(entry.level, entry.testName, entry.message, entry.data)
  end

  -- Update window title with session info
  local windowTitle = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_TITLE]

  if windowTitle then
    windowTitle:SetText(string.format("CooldownWatch Test Log - Session: %s", me.currentSessionId))
  end

  -- Ensure scroll is at bottom after loading
  local scrollFrame = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_SCROLL_FRAME]
  local autoScrollCheckBox = _G[RGCW_CONSTANTS.ELEMENT_TEST_LOG_WINDOW_AUTO_SCROLL]

  if scrollFrame and autoScrollCheckBox and autoScrollCheckBox:GetChecked() then
    C_Timer.After(0.1, function()
      local scrollRange = scrollFrame:GetVerticalScrollRange()

      if scrollRange > 0 then
        scrollFrame:SetVerticalScroll(scrollRange)
      end
    end)
  end
end

--[[
  Setup test log window slash commands
]]--
_G["SLASH_COOLDOWNWATCH_TESTLOG1"] = "/cwlog"
_G["SLASH_COOLDOWNWATCH_TESTLOG2"] = "/cooldownwatchTestLog"
_G["SlashCmdList"]["COOLDOWNWATCH_TESTLOG"] = function(msg)
  if msg == "show" then
    me.Show()
  elseif msg == "hide" then
    me.Hide()
  elseif msg == "clear" then
    me.ClearLog()
  else
    me.Toggle()
  end
end
