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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT FauxScrollFrame_Update FauxScrollFrame_GetOffset
-- luacheck: globals CloseMenus

local mod = rgcw
local me = {}
mod.cooldownMenu = me

me.tag = "CooldownMenu"

local uiState = {
  spellListScrollFrame = nil,
  spellRows = {},
}

-- track whether the menu was already built
local builtMenu = false
--[[
  Cached spellList for reusing while the player scrolls through the spellList. Wiped
  when the category changes
]]--
local cachedCategoryData

--[[
  @param {table} frame
  @param {string} categoryName
]]--
function me.InitCooldownMenu(frame, categoryName)
  frame.categoryName = categoryName

  if builtMenu then
    cachedCategoryData = nil
    mod.logger.LogInfo(me.tag, "Wiped cached spellList after category switch")

    me.UpdateCategoryMenu(frame)
    -- update the scrolllist with new category data
    me.SpellListScrollFrameOnUpdate(uiState.spellListScrollFrame, categoryName)
  else
    me.BuildUi(frame, categoryName)
    builtMenu = true
  end
end

--[[
  @param {table} parentFrame
  @param {string} categoryName
]]--
function me.BuildUi(parentFrame, categoryName)
  local spellListScrollFrame = CreateFrame(
    "ScrollFrame",
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SCROLL_FRAME,
    parentFrame,
    "FauxScrollFrameTemplate"
  )

  spellListScrollFrame:SetWidth(RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_WIDTH)
  spellListScrollFrame:SetHeight(
    RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT * RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS
  )
  spellListScrollFrame:EnableMouseWheel(true)

  spellListScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    CloseMenus()
    self.ScrollBar:SetValue(offset)
    self.offset = math.floor(offset / RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT + 0.5)
    me.SpellListScrollFrameOnUpdate(self, self:GetParent().categoryName)
  end)

  for i = 1, RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS do
    table.insert(uiState.spellRows, me.CreateRuleRowFrame(spellListScrollFrame, i))
  end

  spellListScrollFrame:ClearAllPoints()
  spellListScrollFrame:SetPoint("TOPLEFT", parentFrame)

  me.SpellListScrollFrameOnUpdate(spellListScrollFrame, categoryName)
  uiState.spellListScrollFrame = spellListScrollFrame
end

--[[
  Update the category menu spells tab to its new parent category

  @param {table} parentFrame
]]--
function me.UpdateCategoryMenu(parentFrame)
  local scrollFrame = uiState.spellListScrollFrame
  scrollFrame:ClearAllPoints()
  scrollFrame:SetPoint("TOPLEFT", parentFrame)
  scrollFrame:SetParent(parentFrame)
  scrollFrame:SetVerticalScroll(0) -- reset scroll position to top
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateRuleRowFrame(frame, position)
  local row = CreateFrame(
    "Button",
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SPELL_ROW .. position,
    frame,
    "BackdropTemplate"
  )
  row:SetSize(frame:GetWidth() - 5, RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", frame, 0, (position - 1) * RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT * -1)
  row:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0.37, 0.37, .4)
  else
    row:SetBackdropColor(.25, .25, .25, .8)
  end

  row.cooldownIcon = me.CreateCooldownSpellIcon(row)
  row.cooldownStatus = me.CreateCooldownSpell(row)
  row.worstCaseToggle = me.CreateWorstCaseToggle(row)
  row.manualOverrideInput = me.CreateManualOverrideInput(row)

  return row
end

--[[
  @param {table} spellFrame

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

  local backdrop = mod.guiHelper.MakeSlotBackdrop(
    "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    "Interface\\AddOns\\CooldownWatch\\assets\\ui_slot_background",
    RGCW_CONSTANTS.SLOT_BACKDROP
  )

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
  Create the per-spell worst-case toggle. Checking it makes the runtime assume
  the spell's worst-case cooldown (see CooldownQueue.ResolveCooldown); it is
  hidden by UpdateWorstCaseToggleState for spells without a cooldownWorstCase value.

  @param {table} spellFrame

  @return {table}
    The created checkbox
]]--
function me.CreateWorstCaseToggle(spellFrame)
  local worstCaseCheckBox = CreateFrame(
    "CheckButton",
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE,
    spellFrame,
    "UICheckButtonTemplate"
  )
  worstCaseCheckBox:SetSize(
    RGCW_CONSTANTS.COOLDOWN_SPELL_DEFAULT_SIZE,
    RGCW_CONSTANTS.COOLDOWN_SPELL_DEFAULT_SIZE
  )
  -- right-aligned column; the negative offset leaves room for the trailing label text
  worstCaseCheckBox:SetPoint("RIGHT", -110, 0)

  worstCaseCheckBox.text = _G[worstCaseCheckBox:GetName() .. 'Text']
  worstCaseCheckBox.text:SetFont(STANDARD_TEXT_FONT, 15)
  worstCaseCheckBox.text:SetTextColor(.95, .95, .95)
  worstCaseCheckBox.text:SetText(rgcw.L["option_assume_worst_case"])

  worstCaseCheckBox:SetScript("OnEnter", me.WorstCaseToggleOnEnter)
  worstCaseCheckBox:SetScript("OnLeave", me.WorstCaseToggleOnLeave)
  worstCaseCheckBox:SetScript("OnClick", me.WorstCaseToggleOnClick)

  return worstCaseCheckBox
end

--[[
  Create the per-spell manual cooldown override input. A committed value
  replaces the resolved cooldown entirely (see CooldownQueue.ResolveCooldown);
  an empty box means no override. Compact and label-free by design — the row
  already carries the tracking checkbox and the worst-case toggle, so the
  input explains itself through its tooltip instead of an inline label.

  @param {table} spellFrame

  @return {table}
    The created editbox
]]--
function me.CreateManualOverrideInput(spellFrame)
  local manualOverrideInput = CreateFrame(
    "EditBox",
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_MANUAL_OVERRIDE,
    spellFrame,
    "InputBoxTemplate"
  )
  manualOverrideInput:SetSize(
    RGCW_CONSTANTS.MANUAL_OVERRIDE_EDIT_BOX_WIDTH,
    RGCW_CONSTANTS.MANUAL_OVERRIDE_EDIT_BOX_HEIGHT
  )
  -- right-aligned column left of the worst-case toggle and its label
  manualOverrideInput:SetPoint("RIGHT", -160, 0)
  manualOverrideInput:SetAutoFocus(false)
  manualOverrideInput:SetMaxLetters(RGCW_CONSTANTS.MANUAL_OVERRIDE_EDIT_BOX_MAX_LETTERS)
  manualOverrideInput:SetJustifyH("CENTER")

  manualOverrideInput:SetScript("OnEnter", me.ManualOverrideOnEnter)
  manualOverrideInput:SetScript("OnLeave", me.ManualOverrideOnLeave)
  manualOverrideInput:SetScript("OnEnterPressed", me.ManualOverrideOnEnterPressed)
  manualOverrideInput:SetScript("OnEscapePressed", me.ManualOverrideOnEscapePressed)
  manualOverrideInput:SetScript("OnEditFocusLost", me.RefreshManualOverride)

  return manualOverrideInput
end

--[[
  Update the spell list

  @param {table} scrollFrame
  @param {string} categoryName
]]--
function me.SpellListScrollFrameOnUpdate(scrollFrame, categoryName)
  if cachedCategoryData == nil then
    mod.logger.LogInfo(me.tag, string.format("Warmed up cached spellList for category '%s'", categoryName))
    cachedCategoryData = mod.spellMapHelper.GetAllForCategory(categoryName)
  end

  local maxValue = #cachedCategoryData

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

  for index = 1, RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS do
    local value = index + FauxScrollFrame_GetOffset(scrollFrame)
    local row = uiState.spellRows[index]
    local cooldown = cachedCategoryData[value]

    if cooldown then
      me.UpdateCooldownUiState(row, cooldown, categoryName)
    else
      row:Hide()
    end
  end
end

--[[
  @param {table} row
  @param {table} cooldown
  @param {string} categoryName
]]--
function me.UpdateCooldownUiState(row, cooldown, categoryName)
  local enabled = mod.configuration.GetCooldownConfigurationState(categoryName, cooldown.spellId)

  row.cooldownIcon:SetTexture(mod.guiHelper.GetIconId(cooldown))
  row.cooldownStatus.text:SetText(cooldown.name)

  if enabled then
    row.cooldownStatus:SetChecked(true)
  else
    row.cooldownStatus:SetChecked(false)
  end

  me.UpdateWorstCaseToggleState(row.worstCaseToggle, cooldown, categoryName)
  me.UpdateManualOverrideState(row.manualOverrideInput, cooldown, categoryName)

  row.spellId = cooldown.spellId
  row.categoryName = categoryName
  row:Show()
end

--[[
  Update the worst-case toggle of a row. Rows are recycled across spells while
  scrolling, so both the visibility and the checked state are set on every pass.
  Spells without a cooldownWorstCase value have nothing to assume — their toggle
  is hidden entirely.

  @param {table} worstCaseToggle
  @param {table} cooldown
  @param {string} categoryName
]]--
function me.UpdateWorstCaseToggleState(worstCaseToggle, cooldown, categoryName)
  if cooldown.cooldownWorstCase == nil then
    worstCaseToggle:Hide()

    return
  end

  worstCaseToggle:SetChecked(
    mod.configuration.IsCooldownWorstCaseAssumed(categoryName, cooldown.spellId)
  )
  worstCaseToggle:Show()
end

--[[
  OnClick callback for cooldown configuration check buttons

  @param {table} self
]]--
function me.CooldownEntryOnClick(self)
  local enabled = self:GetChecked()

  mod.configuration.UpdateCooldownConfigurationState(enabled, self:GetParent().categoryName, self:GetParent().spellId)
end

--[[
  OnClick callback for the worst-case toggle

  @param {table} self
]]--
function me.WorstCaseToggleOnClick(self)
  local assumed = self:GetChecked()

  mod.configuration.UpdateCooldownWorstCaseState(assumed, self:GetParent().categoryName, self:GetParent().spellId)
end

--[[
  OnEnter callback for the worst-case toggle - show tooltip
]]--
function me.WorstCaseToggleOnEnter()
  mod.tooltip.BuildTooltipForOption(
    rgcw.L["option_assume_worst_case"],
    rgcw.L["option_assume_worst_case_tooltip"]
  )
end

--[[
  OnLeave callback for the worst-case toggle - hide tooltip
]]--
function me.WorstCaseToggleOnLeave()
  mod.tooltip.TooltipClear()
end

--[[
  Update the manual override input of a row. Rows are recycled across spells
  while scrolling, so the text is rebound from the store on every pass. An
  in-progress edit is dropped first (ClearFocus) — its OnEditFocusLost handler
  restores the previous spell's value while the row still carries that spell's
  identity, before the rebind below writes the new spell's value.

  @param {table} manualOverrideInput
  @param {table} cooldown
  @param {string} categoryName
]]--
function me.UpdateManualOverrideState(manualOverrideInput, cooldown, categoryName)
  manualOverrideInput:ClearFocus()

  local value = mod.configuration.GetCooldownManualOverride(categoryName, cooldown.spellId)

  manualOverrideInput:SetText(value ~= nil and tostring(value) or "")
  manualOverrideInput:SetTextColor(1, 1, 1)
end

--[[
  Rebind the manual override input from the store — restores the persisted
  value (or empty) and resets the reject coloring. Serves as the
  OnEditFocusLost handler so an abandoned edit never lingers in the box.

  @param {table} self
]]--
function me.RefreshManualOverride(self)
  local row = self:GetParent()
  local value = mod.configuration.GetCooldownManualOverride(row.categoryName, row.spellId)

  self:SetText(value ~= nil and tostring(value) or "")
  self:SetTextColor(1, 1, 1)
end

--[[
  OnEnterPressed callback for the manual override input. Commits the typed
  value: empty clears the override, a valid number is stored (capped at the
  spell's base cooldown — see Configuration.UpdateCooldownManualOverride) and
  the box re-renders the stored value via the focus-lost refresh. A rejected
  value (non-numeric, zero or negative) turns red and keeps focus so it can
  be corrected; leaving the box restores the previous value instead.

  @param {table} self
]]--
function me.ManualOverrideOnEnterPressed(self)
  local row = self:GetParent()
  local text = self:GetText()

  if text == "" then
    mod.configuration.UpdateCooldownManualOverride(nil, row.categoryName, row.spellId)
    self:ClearFocus()

    return
  end

  local storedValue = mod.configuration.UpdateCooldownManualOverride(
    tonumber(text), row.categoryName, row.spellId
  )

  if storedValue == nil then
    self:SetTextColor(1, 0, 0)

    return
  end

  self:ClearFocus()
end

--[[
  OnEscapePressed callback for the manual override input - abandon the edit
  (the focus-lost refresh restores the persisted value)

  @param {table} self
]]--
function me.ManualOverrideOnEscapePressed(self)
  self:ClearFocus()
end

--[[
  OnEnter callback for the manual override input - show tooltip
]]--
function me.ManualOverrideOnEnter()
  mod.tooltip.BuildTooltipForOption(
    rgcw.L["option_manual_cooldown_override"],
    rgcw.L["option_manual_cooldown_override_tooltip"]
  )
end

--[[
  OnLeave callback for the manual override input - hide tooltip
]]--
function me.ManualOverrideOnLeave()
  mod.tooltip.TooltipClear()
end
