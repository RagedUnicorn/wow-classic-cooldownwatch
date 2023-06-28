--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT FauxScrollFrame_Update FauxScrollFrame_GetOffset
-- luacheck: globals GetSpellInfo GetItemIcon

local mod = rgcw
local me = {}
mod.cooldownMenu = me

me.tag = "CooldownMenu"

local spellRows = {}

-- track whether the menu was already built
local builtMenu = false

--[[
  Builds the menu for the first time. After that the menu is reused for all categories

  @param {table} self
]]--
function me.cooldownMenuOnShow(self)
  if builtMenu then
    _G[RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SCROLL_FRAME]:SetParent(self)
    me.SpellListScrollFrameOnUpdate(_G[RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SCROLL_FRAME], self.value)
  else
    me.BuildUi(self, self.value)
  end
end

--[[
  Create the cooldown configuration menu for enabling/disabling certain cooldowns

  @param {table} frame
  @param {number} category
]]--
function me.BuildUi(frame, category)
  local spellListScrollFrame = CreateFrame(
    "ScrollFrame",
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SCROLL_FRAME,
    frame,
    "FauxScrollFrameTemplate"
  )

  spellListScrollFrame:SetWidth(RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_WIDTH)
  spellListScrollFrame:SetHeight(
    RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT * RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS
  )
  spellListScrollFrame:SetPoint("TOPLEFT", 10, -50)
  spellListScrollFrame:EnableMouseWheel(true)

  spellListScrollFrame:SetScript("OnVerticalScroll", me.RuleListOnVerticalScroll)

  for i = 1, RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS do
    table.insert(spellRows, me.CreateRuleRowFrame(spellListScrollFrame, i))
  end

  me.SpellListScrollFrameOnUpdate(spellListScrollFrame, category)

  builtMenu = true
end

--[[
  OnVerticalScroll callback for scrollable rule list

  @param {table} self
  @param {number} offset
]]--
function me.RuleListOnVerticalScroll(self, offset)
  self.ScrollBar:SetValue(offset)
  self.offset = math.floor(offset / RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT + 0.5)
  me.SpellListScrollFrameOnUpdate(self, self:GetParent().value)
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateRuleRowFrame(frame, position)
  local row = CreateFrame("Button", RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SPELL_ROW .. position, frame, "BackdropTemplate")
  row:SetSize(frame:GetWidth() -5, RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", frame, 0, (position -1) * RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT * -1)

  row:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0.37, 0.37, .4)
  else
    row:SetBackdropColor(.25, .25, .25, .8)
  end

  row.cooldownIcon = me.CreateCooldownSpellIcon(row)
  row.cooldownStatus = me.CreateCooldownSpell(row)

  return row
end

--[[
  @param {table} spellFrame
  TODO might need rework

  @return {table}
    The created icon texture holder
]]--
function me.CreateCooldownSpellIcon(spellFrame)
  local iconHolder = CreateFrame("Frame", nil, spellFrame, "BackdropTemplate")
  iconHolder:SetSize(
    RGCW_CONSTANTS.CATEGORY_COOLDOWN_SPELL_ICON_SIZE + 5,
    RGCW_CONSTANTS.CATEGORY_COOLDOWN_SPELL_ICON_SIZE + 5
  )
  iconHolder:SetPoint("LEFT", 10, 0)

  local cooldownIcon = iconHolder:CreateTexture(RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON, "ARTWORK")
  cooldownIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  cooldownIcon:SetPoint("CENTER", 0, 0)
  cooldownIcon:SetSize(
    RGCW_CONSTANTS.CATEGORY_COOLDOWN_SPELL_ICON_SIZE,
    RGCW_CONSTANTS.CATEGORY_COOLDOWN_SPELL_ICON_SIZE
  )

  local backdrop = {
    bgFile = "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    edgeFile = "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    tile = false,
    tileSize = 32,
    edgeSize = 20,
    insets = {
      left = 12,
      right = 12,
      top = 12,
      bottom = 12
    }
  }

  iconHolder:SetBackdrop(backdrop)
  iconHolder:SetBackdropColor(0.15, 0.15, 0.15, 1)
  iconHolder:SetBackdropBorderColor(0.47, 0.21, 0.74, 1)

  return cooldownIcon
end

--[[
  @param {table} spellFrame

  @return {table}
    The created checkbox
]]--
function me.CreateCooldownSpell(spellFrame)
  local cooldownSpellStatusCheckBox = CreateFrame(
    "CheckButton",
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS,
    spellFrame,
    "UICheckButtonTemplate"
  )
  cooldownSpellStatusCheckBox:SetSize(
    RGCW_CONSTANTS.COOLDOWN_SPELL_DEFAULT_SIZE,
    RGCW_CONSTANTS.COOLDOWN_SPELL_DEFAULT_SIZE
  )
  cooldownSpellStatusCheckBox:SetPoint("LEFT", RGCW_CONSTANTS.CATEGORY_COOLDOWN_SPELL_ICON_SIZE + 20, 0)

  cooldownSpellStatusCheckBox.text = _G[cooldownSpellStatusCheckBox:GetName() .. 'Text']
  cooldownSpellStatusCheckBox.text:SetFont(STANDARD_TEXT_FONT, 15)
  cooldownSpellStatusCheckBox.text:SetTextColor(.95, .95, .95)

  cooldownSpellStatusCheckBox:SetScript("OnClick", me.CooldownEntryOnClick)

  return cooldownSpellStatusCheckBox
end

--[[
  Update the quickchange rules list

  @param {table} scrollFrame
  @param {number} category
]]--
function me.SpellListScrollFrameOnUpdate(scrollFrame, category)
  local cooldownList = mod.spellMap.GetAllForCategory(RGCW_CONSTANTS.CATEGORIES[category].categoryName)
  local count = 0
  -- count entries in table
  for _ in pairs(cooldownList) do count = count + 1 end

  local maxValue = count or 0

  if maxValue <= RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS then
    maxValue = RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS + 1
  end

  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS,
    RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)
  for index = 1, RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS do
    local value = index + offset
    local idx = 1
    local row = spellRows[index]
    local wasShown = false

    for _, cooldown in pairs(cooldownList) do
      if idx == value then
        local iconId
        local enabled = mod.configuration.GetCooldownConfigurationState(category, cooldown.spellId)

        --[[
          For most items we have to track the actual spelleffect in the combat log. However for
          people to recognize the item it is much better to use items icon itself.
        ]]--
        if cooldown.itemId ~= nil then
          iconId = GetItemIcon(cooldown.itemId)
        else
          _, _, iconId = GetSpellInfo(cooldown.spellId)
        end

        row.cooldownIcon:SetTexture(iconId)
        row.cooldownStatus.text:SetText(cooldown.spellName)
        if enabled then
          row.cooldownStatus:SetChecked(true)
        else
          row.cooldownStatus:SetChecked(false)
        end
        row.spellId = cooldown.spellId
        row.category = category

        row:Show()
        wasShown = true
      end

      idx = idx + 1
    end

    if not wasShown then
      spellRows[index]:Hide()
    end
  end
end

--[[
  OnClick callback for cooldown configuration checkbuttons

  @param {table} self
]]--
function me.CooldownEntryOnClick(self)
  local enabled = self:GetChecked()

  mod.configuration.UpdateCooldownConfigurationState(enabled, self:GetParent().category, self:GetParent().spellId)
end
