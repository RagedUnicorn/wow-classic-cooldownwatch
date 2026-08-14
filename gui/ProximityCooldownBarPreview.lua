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
  Test/place mode of the ENEMY proximity cooldown window. All machinery lives
  in the shared builder (gui/ProximityPlaceMode.lua) - this module only
  supplies what makes the mode the enemy one: the enemy window wrapper, the
  enemy preview ticker pair, the save button identity and the proximity
  settings category the save button returns to.
]]--

local mod = rgcw
local me = {}

mod.proximityCooldownBarPreview = me

me.tag = "ProximityCooldownBarPreview"

local instance = mod.proximityPlaceMode.CreateInstance({
  tag = me.tag,
  bar = mod.proximityCooldownBar,
  saveButtonName = RGCW_CONSTANTS.ELEMENT_PROXIMITY_PLACE_MODE_SAVE_BUTTON,
  saveButtonLabel = rgcw.L["proximity_place_mode_save_button"],
  settingsCategoryKey = "proximity",
  StartPreviewTicker = function() mod.ticker.StartTickerProximityCooldownBarPreview() end,
  StopPreviewTicker = function() mod.ticker.StopTickerProximityCooldownBarPreview() end,
  flagFriendly = false
})

me.IsPlaceModeActive = instance.IsPlaceModeActive
me.EnterPlaceMode = instance.EnterPlaceMode
me.FinishPlaceMode = instance.FinishPlaceMode
me.ProximityCooldownBarPreviewOnUpdate = instance.OnUpdate
