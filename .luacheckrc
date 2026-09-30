--[[
  Writable globals: the addon namespace and the SavedVariables - their fields are set
  across many files. Everything else a file reads from the global environment (the
  RGCW_* constants below, the WoW API in each file's inline `-- luacheck: read globals`
  header) is read-only, so an accidental assignment is reported.
]]--
globals = {
  "rgcw",
  "CooldownWatchConfiguration",
  "CooldownWatchLogTracker",
  "CooldownWatchShotLog",
  "CooldownWatchTestLog"
}

read_globals = {
  "RGCW_CONSTANTS",
  "RGCW_TEST_CONSTANTS",
  "RGCW_ENVIRONMENT",
  "RGCW_SHOTS"
}

files = {
  ["code"] = {std = "lua51"},
  ["gui"] = {std = "lua51"},
  ["localization"] = {std = "lua51"},
  ["test"] = {std = "lua51"},
  ["test/headless/spec"] = {std = "lua51+busted"},
  ["dev"] = {std = "lua51"},
  -- the files that define an RGCW_* constant table may assign it
  ["code/Constants.lua"] = {globals = {"RGCW_CONSTANTS"}},
  ["code/Environment.lua"] = {globals = {"RGCW_ENVIRONMENT"}},
  ["test/framework/TestConstants.lua"] = {globals = {"RGCW_TEST_CONSTANTS"}},
  ["test/headless/Bootstrap.lua"] = {globals = {"RGCW_ENVIRONMENT"}},
  ["dev/ShotManifest.lua"] = {globals = {"RGCW_SHOTS"}}
}

exclude_files = {
  ".luacheckrc",
  "target/"
}
