## Interface: ${addon.interface}
## Title: ${addon.name}
## Author: ${addon.author}
## Notes: ${addon.description}
## Version: ${addon.tag.version}
## SavedVariablesPerCharacter: ${addon.savedVariablesPerCharacter}
## SavedVariables: CooldownWatchTestLog

# constant values
code/Constants.lua
# environment variables
code/Environment.lua

# localization
localization/enUS.lua
localization/deDE.lua

code/Core.lua
code/Logger.lua
code/Cmd.lua
code/Filter.lua
code/CombatLog.lua
code/Common.lua
code/SpellMapHelper.lua
code/SpellMap.lua
code/CooldownQueue.lua
code/Target.lua
code/Ticker.lua
code/Tooltip.lua
code/Configuration.lua
code/Profile.lua
code/Season.lua

# debug
code/Debug.lua

# Test Framework (Development Only)
test/framework/TestCmd.lua
test/framework/TestLogger.lua
test/framework/TestHelper.lua
test/framework/TestLogWindow.lua
test/framework/TestLogWindow.xml
test/RunTests.lua
test/TestCooldownQueue.lua
test/TestSpellMap.lua
test/category/TestPriestSpells.lua
test/category/TestShamanSpells.lua
test/category/TestRogueSpells.lua

# Debug Tools (Development Only)
test/debug/DebugInjectorWindow.lua
test/debug/DebugInjectorWindow.xml

# gui
gui/Frame.xml
gui/TargetCooldownBar.lua
gui/CategoryMenu.lua
gui/AddonConfiguration.lua
gui/AboutContent.lua
gui/GeneralMenu.lua
gui/CooldownMenu.lua
