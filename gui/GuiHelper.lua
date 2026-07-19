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

-- luacheck: globals GetSpellInfo GetItemIcon CreateFrame STANDARD_TEXT_FONT

local mod = rgcw
local me = {}

mod.guiHelper = me

me.tag = "GuiHelper"

--[[
  Apply one of the RGCW_CONSTANTS.COLOR { r, g, b } tokens to a font string.

  @param {table} fontString
  @param {table} color
]]--
function me.SetColor(fontString, color)
  fontString:SetTextColor(color[1], color[2], color[3])
end

--[[
  Apply the shared bordered box backdrop used by panel content containers. The frame
  must have been created with the "BackdropTemplate" mixin.

  @param {table} frame
]]--
function me.ApplyBorderBackdrop(frame)
  frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.4)
  frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
end

--[[
  Create a configuration checkbox

  @param {string} frameName
  @param {table} parent
  @param {table} position
    An object containing configuration parameters for a SetPoint function call
  @param {function} onClickCallback
    Callback that is called onClick
  @param {function} onShowCallback
    Callback that is called onShow
  @param {string} text
    Optional text that is used as label for the checkbox
  @param {string} description
    Optional always-visible gray description rendered directly beneath the checkbox

  @return {table}
    The created checkbox
]]--
function me.CreateCheckBox(frameName, parent, position, onClickCallback, onShowCallback, text, description)
  local checkBoxFrame = CreateFrame(
    "CheckButton",
    frameName,
    parent,
    "SettingsCheckboxTemplate"
  )
  checkBoxFrame:SetSize(
    RGCW_CONSTANTS.CHECK_OPTION_SIZE,
    RGCW_CONSTANTS.CHECK_OPTION_SIZE
  )
  checkBoxFrame:SetPoint(unpack(position))

  --[[ the template's inherited hover scripts drive the settings-list row highlight and
       misbehave outside that list - remove them ]]--
  checkBoxFrame:SetScript("OnEnter", nil)
  checkBoxFrame:SetScript("OnLeave", nil)

  --[[ the template ships no label - the settings list rows normally provide it ]]--
  local labelFontString = checkBoxFrame:CreateFontString(nil, "OVERLAY")
  labelFontString:SetFont(STANDARD_TEXT_FONT, 15)
  me.SetColor(labelFontString, RGCW_CONSTANTS.COLOR.BODY)
  labelFontString:SetPoint("LEFT", checkBoxFrame, "RIGHT", 5, 0)
  checkBoxFrame.text = labelFontString

  if text ~= nil then
    checkBoxFrame.text:SetText(text)
  end

  if description ~= nil then
    local descriptionFontString = checkBoxFrame:CreateFontString(nil, "OVERLAY")
    descriptionFontString:SetFont(STANDARD_TEXT_FONT, 12)
    me.SetColor(descriptionFontString, RGCW_CONSTANTS.COLOR.SUBNOTE)
    descriptionFontString:SetPoint("TOPLEFT", checkBoxFrame, "BOTTOMLEFT", 4, -2)
    descriptionFontString:SetWidth(RGCW_CONSTANTS.CHECK_OPTION_DESCRIPTION_WIDTH)
    descriptionFontString:SetJustifyH("LEFT")
    descriptionFontString:SetText(description)
    checkBoxFrame.description = descriptionFontString
  end

  checkBoxFrame:SetScript("OnClick", onClickCallback)
  checkBoxFrame:SetScript("OnShow", onShowCallback)

  return checkBoxFrame
end

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
  Resolve the spell icon border color for a category. Class categories carry
  the class color; categories without an entry fall back to a neutral gray.

  @param {string} categoryName
    A categoryName as listed in code/Categories.lua (e.g. "priest")

  @return {table}
    A { r, g, b, a } tuple for unpack() at the call site
]]--
function me.GetCategoryColor(categoryName)
  return RGCW_CONSTANTS.COLORS.CATEGORY[categoryName] or RGCW_CONSTANTS.COLORS.CATEGORY_NEUTRAL
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
