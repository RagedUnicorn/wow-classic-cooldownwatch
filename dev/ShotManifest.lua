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

-- THIS FILE IS AUTO-GENERATED. ALL CHANGES ARE OVERWRITTEN
-- Source: wow-media-capture/reference/media/cooldownwatch.json
-- Regenerate: scripts/gen-shot-table.ps1 -Addon cooldownwatch

-- shows/name are human-facing copy carried over from the manifest verbatim - reflowing
-- them is not the generator's call, so the 120-column limit does not apply here
-- luacheck: max line length 400

RGCW_SHOTS = {
  {
    name = "cooldownwatch_target_cooldown_bar",
    shot = "target_cooldown_bar",
    frame = "CW_TargetCooldownWatchBar",
    setup = { "closeSettings", "previewTargetCooldownBar" },
    includeFrames = { "TargetFrame" },
    hideChrome = true,
    padding = 120,
    shows = "The target cooldown bar with ten enemy cooldowns counting down, the shortest-remaining ones glowing in their warn and alert states"
  },
  {
    name = "cooldownwatch_cooldown_selection",
    shot = "cooldown_selection",
    frame = "SettingsPanel",
    setup = { "openCategory:priest", "collapseSpellRows" },
    hideFrames = { "CW_TargetCooldownWatchBar" },
    hideChrome = true,
    padding = 0,
    shows = "The Priest category panel: the per-spell list with checkboxes, class-tinted rows, spell icons and the resolved cooldown value line"
  },
  {
    name = "cooldownwatch_worst_case_override",
    shot = "worst_case_override",
    frame = "SettingsPanel",
    setup = { "openCategory:priest", "expandSpellRow:5" },
    hideFrames = { "CW_TargetCooldownWatchBar" },
    hideChrome = true,
    padding = 0,
    shows = "The same Priest panel with Mind Blast's options strip unfolded, showing the Use worst case toggle, its value field and the manual cooldown override"
  },
  {
    name = "cooldownwatch_profile_configuration",
    shot = "profile_configuration",
    frame = "SettingsPanel",
    setup = { "openCategory:profile" },
    hideFrames = { "CW_TargetCooldownWatchBar" },
    hideChrome = true,
    padding = 0,
    shows = "The Profiles panel with the named-profile list, the Default profile selected with Rename and Delete greyed out, and the export/import controls"
  }
}
