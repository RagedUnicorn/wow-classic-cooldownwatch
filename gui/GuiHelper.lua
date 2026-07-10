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

-- luacheck: globals GetSpellInfo GetItemIcon

local mod = rgcw
local me = {}

mod.guiHelper = me

me.tag = "GuiHelper"

--[[
  Resolve the icon for a spellMap-derived entry (a config-menu row or a queue
  entry's spellData).

  For most items we have to track the actual spell-effect in the combat log.
  However for people to recognize the item it is much better to use the item's
  icon itself - entries carrying an itemId resolve through GetItemIcon, all
  others through GetSpellInfo.

  @param {table} spellEntry
    Any table with a spellId and an optional itemId (see SpellMap entry shape)

  @return {number}
    The iconId for the spellEntry
]]--
function me.GetIconId(spellEntry)
  if spellEntry.itemId ~= nil then
    return GetItemIcon(spellEntry.itemId)
  end

  local _, _, iconId = GetSpellInfo(spellEntry.spellId)

  return iconId
end

--[[
  Assemble a backdrop table for a cooldown slot widget from shared geometry.

  Centralises the table skeleton so the slot look-and-feel lives in one place
  instead of being copy-pasted across widgets. Returns a fresh table on every
  call so callers never share a mutable backdrop instance.

  @param {string} bgFile
    Background texture path
  @param {string} edgeFile
    Border texture path
  @param {table} dimensions
    A RGCW_CONSTANTS backdrop geometry sub-table (SLOT_BACKDROP / HIGHLIGHT_BACKDROP)
    providing TILE_SIZE, EDGE_SIZE and INSET

  @return {table}
    The assembled backdrop table accepted by Frame:SetBackdrop
]]--
function me.MakeSlotBackdrop(bgFile, edgeFile, dimensions)
  return {
    bgFile = bgFile,
    edgeFile = edgeFile,
    tile = false,
    tileSize = dimensions.TILE_SIZE,
    edgeSize = dimensions.EDGE_SIZE,
    insets = {
      left = dimensions.INSET,
      right = dimensions.INSET,
      top = dimensions.INSET,
      bottom = dimensions.INSET
    }
  }
end
