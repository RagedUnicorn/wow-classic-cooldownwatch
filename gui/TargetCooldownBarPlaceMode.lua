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
  Test/place mode of the TARGET COOLDOWN BAR. The mode shell lives in
  gui/PlaceMode.lua; the preview content is the bar's existing example mode
  (gui/TargetCooldownBarPreview.lua, also reachable via /rgcw conf) - this
  module only ties the two together. The preview itself owns the positioning
  look: its show/hide repaint the backdrop and dragging is gated on the
  preview flag (there is deliberately no lock option, proximity-window
  parity), so the shell's StartPreview/StopPreview need nothing beyond the
  example mode's own entry points.
]]--

local mod = rgcw
local me = {}

mod.targetCooldownBarPlaceMode = me

me.tag = "TargetCooldownBarPlaceMode"

local instance = mod.placeMode.CreateInstance({
  tag = me.tag,
  GetAnchorFrame = function() return mod.targetCooldownBar.GetTargetCooldownBarFrame() end,
  applyButtonName = RGCW_CONSTANTS.ELEMENT_TARGET_BAR_PLACE_MODE_APPLY_BUTTON,
  applyButtonLabel = rgcw.L["target_bar_place_mode_apply_button"],
  settingsCategoryKey = "general",
  StartPreview = function() mod.targetCooldownBarPreview.ShowExampleTargetCooldownBar() end,
  StopPreview = function() mod.targetCooldownBarPreview.HideExampleTargetCooldownBar() end
})

me.IsPlaceModeActive = instance.IsPlaceModeActive
me.EnterPlaceMode = instance.EnterPlaceMode
me.FinishPlaceMode = instance.FinishPlaceMode
