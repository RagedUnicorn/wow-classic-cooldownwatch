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

--[[
  Constants for the development-only test framework and debug tools. These are
  intentionally kept out of RGCW_CONSTANTS so they never ship with release
  builds, which load code/Constants.lua but none of the test/ files. Only files
  registered in the development .toc consume this table.
]]--
RGCW_TEST_CONSTANTS = {
  --[[
    Test UI Elements
  ]]--
  ELEMENT_TEST_LOG_WINDOW = "CooldownWatch_TestLogWindow",
  ELEMENT_TEST_LOG_WINDOW_TITLE = "CooldownWatch_TestLogWindowTitle",
  ELEMENT_TEST_LOG_WINDOW_SCROLL_FRAME = "CooldownWatch_TestLogWindowScrollFrame",
  ELEMENT_TEST_LOG_WINDOW_SCROLL_CHILD = "CooldownWatch_TestLogWindowScrollChild",
  ELEMENT_TEST_LOG_WINDOW_AUTO_SCROLL = "CooldownWatch_TestLogWindowAutoScrollCheckBox",
  ELEMENT_TEST_LOG_WINDOW_CLOSE_BUTTON = "CooldownWatch_TestLogWindowCloseButton",
  ELEMENT_TEST_LOG_WINDOW_CLEAR_BUTTON = "CooldownWatch_TestLogWindowClearButton",
  --[[
    Debug Spell Injector Window (development only)
  ]]--
  ELEMENT_DEBUG_INJECTOR_WINDOW = "CooldownWatch_DebugInjectorWindow",
  ELEMENT_DEBUG_INJECTOR_WINDOW_CATEGORY_COLUMN = "CooldownWatch_DebugInjectorWindowCategoryColumn",
  ELEMENT_DEBUG_INJECTOR_WINDOW_SPELL_SCROLL_FRAME = "CooldownWatch_DebugInjectorWindowSpellScrollFrame",
  ELEMENT_DEBUG_INJECTOR_WINDOW_SPELL_SCROLL_CHILD = "CooldownWatch_DebugInjectorWindowSpellScrollChild",
  --[[
    SavedVariables
  ]]--
  SAVED_VARIABLE_TEST_LOG = "CooldownWatchTestLog",
}
