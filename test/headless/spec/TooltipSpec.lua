--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

--[[
  Tests for the option tooltip helper (code/Tooltip.lua). The tooltip frame is resolved
  through RGCW_CONSTANTS.ELEMENT_TOOLTIP, so a recording frame is installed under that
  global name (plus UIParent and GameTooltip_SetDefaultAnchor) via WowStubs. rgcw.tooltip,
  which Bootstrap does not set, is restored in after_each - busted's file insulation only
  snapshots the top-level `rgcw` reference.
]]--

local wowStubs = require("WowStubs")

describe("Tooltip", function()
  local tooltip
  local restore
  local frame
  local calls
  local anchoredTo
  local uiParent = {}
  local originalTooltip = rgcw.tooltip

  local function Record(name)
    return function(_, ...)
      calls[#calls + 1] = { name, ... }
    end
  end

  before_each(function()
    calls = {}
    anchoredTo = nil
    frame = {
      SetOwner = Record("SetOwner"),
      AddLine = Record("AddLine"),
      Show = Record("Show"),
      Hide = Record("Hide"),
    }

    restore = wowStubs.install({
      [RGCW_CONSTANTS.ELEMENT_TOOLTIP] = frame,
      UIParent = uiParent,
      GameTooltip_SetDefaultAnchor = function(anchoredTooltip, parent)
        anchoredTo = { anchoredTooltip, parent }
      end,
    })

    dofile("code/Tooltip.lua")
    tooltip = rgcw.tooltip
  end)

  after_each(function()
    restore()
    rgcw.tooltip = originalTooltip
  end)

  it("builds a two-line tooltip anchored to the default position", function()
    tooltip.BuildTooltipForOption("Title", "Description")

    assert.same({
      { "SetOwner", uiParent },
      { "AddLine", "Title" },
      { "AddLine", "Description", .8, .8, .8, 1 },
      { "Show" },
    }, calls)
    assert.equal(frame, anchoredTo[1])
    assert.equal(uiParent, anchoredTo[2])
  end)

  it("hides the tooltip on clear", function()
    tooltip.TooltipClear()

    assert.same({ { "Hide" } }, calls)
  end)
end)
