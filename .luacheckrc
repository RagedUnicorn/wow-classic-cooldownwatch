globals = {
  "rgcw",
  "CooldownWatchConfiguration",
  "RGCW_CONSTANTS",
  "RGCW_TEST_CONSTANTS",
  "RGCW_ENVIRONMENT",
  "CooldownWatchLogTracker",
  "CooldownWatchShotLog",
  "RGCW_SHOTS"
}

files = {
  ["code"] = {std = "lua51"},
  ["gui"] = {std = "lua51"},
  ["localization"] = {std = "lua51"},
  ["test"] = {std = "lua51"},
  ["dev"] = {std = "lua51"}
}

exclude_files = {
  ".luacheckrc",
  "target/"
}
