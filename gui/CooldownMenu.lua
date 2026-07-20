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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT ScrollUtil GameTooltip

local mod = rgcw
local me = {}
mod.cooldownMenu = me

me.tag = "CooldownMenu"

local uiState = {
  spellListScrollFrame = nil,
  spellListScrollBar = nil,
  spellListContent = nil,
  spellRows = {},
  --[[
    SpellId of the row whose options strip is unfolded - the list is an accordion,
    at most one row is expanded at a time. Nil when everything is collapsed.
  ]]--
  expandedSpellId = nil,
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
    -- collapse the accordion so a recycled row in the new category shows no stale strip
    uiState.expandedSpellId = nil
    mod.logger.LogInfo(me.tag, "Wiped cached spellList after category switch")

    me.UpdateCategoryMenu(frame)
    -- update the scrolllist with new category data
    me.RefreshSpellList(categoryName)
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
  local listWidth = RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_WIDTH - 22
  local listHeight = RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT * RGCW_CONSTANTS.SPELL_LIST_MAX_ROWS

  local spellListScrollFrame = CreateFrame(
    "ScrollFrame",
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SCROLL_FRAME,
    parentFrame
  )
  spellListScrollFrame:SetSize(listWidth, listHeight)
  spellListScrollFrame:SetPoint("TOPLEFT", parentFrame)

  local scrollBar = CreateFrame("EventFrame", nil, parentFrame, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", spellListScrollFrame, "TOPRIGHT", 8, 0)
  scrollBar:SetPoint("BOTTOMLEFT", spellListScrollFrame, "BOTTOMRIGHT", 8, 0)
  ScrollUtil.InitScrollFrameWithScrollBar(spellListScrollFrame, scrollBar)

  local spellListContent = CreateFrame("Frame", nil, spellListScrollFrame)
  spellListContent:SetSize(listWidth, listHeight)
  spellListScrollFrame:SetScrollChild(spellListContent)

  uiState.spellListScrollFrame = spellListScrollFrame
  uiState.spellListScrollBar = scrollBar
  uiState.spellListContent = spellListContent

  me.RefreshSpellList(categoryName)
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
  uiState.spellListScrollBar:SetParent(parentFrame)
  scrollFrame:SetVerticalScroll(0) -- reset scroll position to top
end

--[[
  Create a spell row. The row carries a fixed-height collapsed header (checkbox,
  icon, name, value line, expand indicator) and a hidden options strip below it
  (see CreateExpansionStrip) that unfolds on click. Rows own no position — the
  accordion makes row heights vary, so RefreshSpellList lays them out cumulatively.

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
  row:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })

  -- warm near-black zebra striping (Quartermaster panel palette)
  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.14, 0.12, 0.09, .75)
  else
    row:SetBackdropColor(0.05, 0.04, 0.03, .9)
  end

  -- flat hover sheen over the collapsed header - signals the row itself is clickable
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetPoint("TOPLEFT")
  highlight:SetPoint("TOPRIGHT")
  highlight:SetHeight(RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT)
  highlight:SetColorTexture(1, 1, 1, 0.06)

  row.cooldownIcon = me.CreateCooldownSpellIcon(row)
  row.cooldownStatus = me.CreateCooldownSpell(row)
  row.cooldownValue = me.CreateCooldownValueText(row, row.cooldownStatus)
  row.expandButton = me.CreateExpandButton(row)
  row.expansion = me.CreateExpansionStrip(row)
  row.manualOverrideInput = me.CreateManualOverrideInput(row)
  row.worstCaseValueInput = me.CreateWorstCaseValueField(row)
  row.worstCaseToggle = me.CreateWorstCaseToggle(row)

  row:SetScript("OnClick", me.RowOnClick)

  return row
end

--[[
  Create the expand indicator in the collapsed header: a "slate key" button
  (Quartermaster stepper-key look); ApplyRowExpansionState swaps its glyph
  between + and - while the row is expanded.

  @param {table} row

  @return {table}
    The created button
]]--
function me.CreateExpandButton(row)
  local expandButton = mod.guiHelper.CreateSlateKey(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_EXPAND_BUTTON,
    row,
    "expand",
    "+",
    RGCW_CONSTANTS.SLATE_KEY_SIZE
  )
  -- centered in the fixed-height collapsed header, not the (variable) row
  expandButton:SetPoint(
    "TOPRIGHT",
    -10,
    -((RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT - RGCW_CONSTANTS.SLATE_KEY_SIZE) / 2)
  )
  expandButton:SetScript("OnClick", me.ExpandButtonOnClick)

  return expandButton
end

--[[
  Create the options strip that unfolds below the collapsed header. It hosts the
  per-spell controls (manual override input, worst-case toggle) so the collapsed
  row stays clutter-free; hidden until the row is expanded. A flat continuation
  of the row background - only a hairline separator marks it off from the header.

  @param {table} row

  @return {table}
    The created frame
]]--
function me.CreateExpansionStrip(row)
  local expansion = CreateFrame(
    "Frame",
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_EXPANSION,
    row
  )
  expansion:SetPoint("TOPLEFT", row, 0, -RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT)
  expansion:SetPoint("BOTTOMRIGHT", row)

  -- hairline separator between the header and the unfolded options
  local separator = expansion:CreateTexture(nil, "ARTWORK")
  separator:SetPoint("TOPLEFT", 8, 0)
  separator:SetPoint("TOPRIGHT", -8, 0)
  separator:SetHeight(1)
  separator:SetColorTexture(0.16, 0.13, 0.09, 1)

  expansion:Hide()

  return expansion
end

--[[
  Creates the spell icon with a tooltip showing the hovered spell or item. The
  displayed spellId/itemId is stored on the iconHolder by the spell list row update.

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
  -- anchored to the top so the icon stays in the collapsed header when the row expands
  iconHolder:SetPoint("TOPLEFT", 10, -6)
  iconHolder:EnableMouse(true)
  iconHolder:SetScript("OnEnter", function(self)
    if self.itemId ~= nil then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemId)
      GameTooltip:Show()
    elseif self.spellId ~= nil then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetSpellByID(self.spellId)
      GameTooltip:Show()
    end
  end)
  iconHolder:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local cooldownIcon = iconHolder:CreateTexture(RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON, "ARTWORK")
  cooldownIcon.iconHolder = iconHolder
  -- trim the default icon border; the icon fills the holder up to the 2px outline
  cooldownIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  cooldownIcon:SetPoint("TOPLEFT", 2, -2)
  cooldownIcon:SetPoint("BOTTOMRIGHT", -2, 2)

  -- crisp 2px square outline (Quartermaster icon-frame look) so the class color
  -- reads as a clean tint instead of a beveled slot edge
  iconHolder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
  -- the border color is category-dependent (class color) and applied by
  -- UpdateCooldownUiState - rows are recycled across categories
  iconHolder:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.CATEGORY_NEUTRAL))

  return cooldownIcon
end

--[[
  @param {table} spellFrame

  @return {table}
    The created checkbox
]]--
function me.CreateCooldownSpell(spellFrame)
  local cooldownSpellStatusCheckBox = mod.guiHelper.CreateCheckBox(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS,
    spellFrame,
    -- anchored to the top so the checkbox stays in the collapsed header when the row expands
    {"TOPLEFT", RGCW_CONSTANTS.CATEGORY_COOLDOWN_SPELL_ICON_SIZE + 20, -13},
    me.CooldownEntryOnClick
  )

  -- top-aligned instead of the helper's centered anchor so the cooldown
  -- value line fits below the name (see CreateCooldownValueText)
  cooldownSpellStatusCheckBox.text:ClearAllPoints()
  cooldownSpellStatusCheckBox.text:SetPoint("TOPLEFT", cooldownSpellStatusCheckBox, "TOPRIGHT", 5, 2)

  return cooldownSpellStatusCheckBox
end

--[[
  Create the cooldown value line shown below the spell name. The row's
  horizontal space right of the name is claimed by the override input and the
  worst-case toggle, so the values live on a second smaller line instead of
  inline in the name — long names like "Blessing of Protection" would
  otherwise run into the override input.

  @param {table} spellFrame
  @param {table} cooldownStatusCheckBox

  @return {table}
    The created fontstring
]]--
function me.CreateCooldownValueText(spellFrame, cooldownStatusCheckBox)
  local cooldownValueText = spellFrame:CreateFontString(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_VALUE,
    "OVERLAY"
  )
  cooldownValueText:SetFont(STANDARD_TEXT_FONT, 12)
  mod.guiHelper.SetColor(cooldownValueText, RGCW_CONSTANTS.COLOR.SUBNOTE)
  cooldownValueText:SetPoint("TOPLEFT", cooldownStatusCheckBox.text, "BOTTOMLEFT", 0, -2)

  return cooldownValueText
end

--[[
  Create a flat dark value field in the row's expansion strip: an edit box with
  a 1px border, a leading label and a trailing unit suffix (the SI second symbol
  is locale-independent, deliberately not a localization key). Styling only -
  the caller anchors the label and wires the scripts. ApplySingleFieldHighlight
  turns the border and text gold while the field holds the live value.

  @param {string} name
  @param {table} row
  @param {string} labelText

  @return {table}
    The created editbox (with .label and .suffix)
]]--
function me.CreateValueField(name, row, labelText)
  local valueField = CreateFrame("EditBox", name, row.expansion, "BackdropTemplate")
  valueField.row = row
  valueField:SetSize(
    RGCW_CONSTANTS.MANUAL_OVERRIDE_EDIT_BOX_WIDTH,
    RGCW_CONSTANTS.MANUAL_OVERRIDE_EDIT_BOX_HEIGHT
  )
  valueField:SetAutoFocus(false)
  valueField:SetMaxLetters(RGCW_CONSTANTS.MANUAL_OVERRIDE_EDIT_BOX_MAX_LETTERS)
  valueField:SetFont(STANDARD_TEXT_FONT, 13, "")
  valueField:SetJustifyH("RIGHT")
  valueField:SetTextInsets(6, 6, 0, 0)
  valueField:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1
  })
  valueField:SetBackdropColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_BG))
  valueField:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_BORDER))

  local label = row.expansion:CreateFontString(nil, "OVERLAY")
  label:SetFont(STANDARD_TEXT_FONT, 13)
  mod.guiHelper.SetColor(label, RGCW_CONSTANTS.COLOR.BODY)
  label:SetText(labelText)
  valueField.label = label

  local suffix = row.expansion:CreateFontString(nil, "OVERLAY")
  suffix:SetFont(STANDARD_TEXT_FONT, 12)
  mod.guiHelper.SetColor(suffix, RGCW_CONSTANTS.COLOR.SUBNOTE)
  suffix:SetText("s")
  suffix:SetPoint("LEFT", valueField, "RIGHT", 4, 0)
  valueField.suffix = suffix

  return valueField
end

--[[
  Create the worst-case value field. Display-only for now: there is no store
  for a per-spell worst-case override yet, so the field is disabled and only
  mirrors the catalog's cooldownWorstCase - a mock of the intended editable
  field. Mouse stays enabled so a click on the box does not fall through to the
  row and collapse it. Hidden by UpdateWorstCaseToggleState for spells without
  a cooldownWorstCase value.

  @param {table} row

  @return {table}
    The created editbox
]]--
function me.CreateWorstCaseValueField(row)
  local worstCaseValueInput = me.CreateValueField(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE_VALUE,
    row,
    rgcw.L["option_assume_worst_case"]
  )
  worstCaseValueInput.label:SetPoint("LEFT", row.manualOverrideInput.suffix, "RIGHT", 24, 0)
  worstCaseValueInput:SetPoint("LEFT", worstCaseValueInput.label, "RIGHT", 10, 0)
  worstCaseValueInput:Disable()
  worstCaseValueInput:EnableMouse(true)

  return worstCaseValueInput
end

--[[
  Create the per-spell worst-case toggle inside the row's expansion strip.
  Checking it makes the runtime assume the spell's worst-case cooldown (see
  CooldownQueue.ResolveCooldown); it is hidden by UpdateWorstCaseToggleState for
  spells without a cooldownWorstCase value. Parented to the strip (shown/hidden
  with it), so it carries a row back-pointer for its callbacks.

  @param {table} row

  @return {table}
    The created checkbox
]]--
function me.CreateWorstCaseToggle(row)
  local worstCaseCheckBox = mod.guiHelper.CreateCheckBox(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE,
    row.expansion,
    {"LEFT", row.worstCaseValueInput.suffix, "RIGHT", 24, 0},
    me.WorstCaseToggleOnClick,
    nil,
    rgcw.L["option_use_worst_case"]
  )
  worstCaseCheckBox.row = row

  worstCaseCheckBox:SetScript("OnEnter", me.WorstCaseToggleOnEnter)
  worstCaseCheckBox:SetScript("OnLeave", me.WorstCaseToggleOnLeave)

  return worstCaseCheckBox
end

--[[
  Create the cooldown value field inside the row's expansion strip. Backed by
  the manual override store: the box shows the override when one is set and the
  base cooldown otherwise, and a committed edit goes through
  Configuration.UpdateCooldownManualOverride (which caps and validates). An
  empty commit clears the override, dropping the box back to the base value.

  @param {table} row

  @return {table}
    The created editbox
]]--
function me.CreateManualOverrideInput(row)
  local manualOverrideInput = me.CreateValueField(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_MANUAL_OVERRIDE,
    row,
    rgcw.L["option_cooldown_label"]
  )
  -- indented to sit under the name column of the collapsed header
  manualOverrideInput.label:SetPoint("LEFT", row.expansion, 64, 0)
  manualOverrideInput:SetPoint("LEFT", manualOverrideInput.label, "RIGHT", 10, 0)

  manualOverrideInput:SetScript("OnEnter", me.ManualOverrideOnEnter)
  manualOverrideInput:SetScript("OnLeave", me.ManualOverrideOnLeave)
  manualOverrideInput:SetScript("OnEnterPressed", me.ManualOverrideOnEnterPressed)
  manualOverrideInput:SetScript("OnEscapePressed", me.ManualOverrideOnEscapePressed)
  manualOverrideInput:SetScript("OnEditFocusLost", me.RefreshManualOverride)

  return manualOverrideInput
end

--[[
  Update the spell list. One row per spell in the category lives in the scroll
  child - rows are created on demand (the pool grows to the largest category
  seen) and surplus rows from a larger previous category are hidden. Row heights
  vary with the accordion (an expanded row is taller), so rows are laid out with
  a cumulative offset instead of fixed slots. The scroll range follows from the
  content height (content height - visible height).

  @param {string} categoryName
]]--
function me.RefreshSpellList(categoryName)
  if cachedCategoryData == nil then
    mod.logger.LogInfo(me.tag, string.format("Warmed up cached spellList for category '%s'", categoryName))
    cachedCategoryData = mod.spellMapHelper.GetAllForCategory(categoryName)
  end

  local rowCount = #cachedCategoryData
  local offsetY = 0

  for index = 1, math.max(rowCount, #uiState.spellRows) do
    local row = uiState.spellRows[index]
    local cooldown = cachedCategoryData[index]

    if cooldown then
      if row == nil then
        row = me.CreateRuleRowFrame(uiState.spellListContent, index)
        uiState.spellRows[index] = row
      end

      me.UpdateCooldownUiState(row, cooldown, categoryName)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", uiState.spellListContent, 0, -offsetY)
      offsetY = offsetY + row:GetHeight()
    elseif row then
      row:Hide()
    end
  end

  uiState.spellListContent:SetHeight(math.max(offsetY, 1))
end

--[[
  @param {table} row
  @param {table} cooldown
  @param {string} categoryName
]]--
function me.UpdateCooldownUiState(row, cooldown, categoryName)
  local enabled = mod.configuration.GetCooldownConfigurationState(categoryName, cooldown.spellId, cooldown.active)

  --[[
    Bind the new spell identity first - the control updates below read it (the
    value-field highlight resolves against the store, the focus-lost restore
    rebinds from it). An in-progress edit on the recycled row is dropped by
    UpdateManualOverrideState's ClearFocus; nothing is committed on focus loss,
    so restoring against the new identity is harmless.
  ]]--
  row.spellId = cooldown.spellId
  row.categoryName = categoryName
  row.baseCooldown = cooldown.cooldown
  row.worstCaseCooldown = cooldown.cooldownWorstCase

  row.cooldownIcon:SetTexture(mod.guiHelper.GetIconId(cooldown))
  -- itemId may be nil which clears a stale value when the row is reused
  row.cooldownIcon.iconHolder.spellId = cooldown.spellId
  row.cooldownIcon.iconHolder.itemId = cooldown.itemId
  row.cooldownIcon.iconHolder:SetBackdropBorderColor(unpack(mod.guiHelper.GetCategoryColor(categoryName)))
  row.cooldownStatus.text:SetText(cooldown.name)
  row.cooldownValue:SetText(me.BuildCooldownValueText(cooldown))

  if enabled then
    row.cooldownStatus:SetChecked(true)
  else
    row.cooldownStatus:SetChecked(false)
  end

  me.UpdateWorstCaseToggleState(row, cooldown, categoryName)
  me.UpdateManualOverrideState(row.manualOverrideInput, cooldown, categoryName)
  -- after UpdateManualOverrideState - the controls state re-applies the value colors
  me.UpdateRowControlsState(row, enabled)
  me.ApplyRowExpansionState(row, uiState.expandedSpellId == cooldown.spellId)

  row:Show()
end

--[[
  Fold or unfold a row's options strip. Sets the row height (RefreshSpellList
  derives the layout from it), shows/hides the strip and swaps the plus/minus
  indicator. Rebound on every UpdateCooldownUiState pass because rows are
  recycled across spells and categories.

  @param {table} row
  @param {boolean} expanded
]]--
function me.ApplyRowExpansionState(row, expanded)
  if expanded then
    row:SetHeight(RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT + RGCW_CONSTANTS.SPELL_LIST_ROW_EXPANSION_HEIGHT)
    row.expansion:Show()
    row.expandButton:SetGlyph("-")
  else
    row:SetHeight(RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT)
    row.expansion:Hide()
    row.expandButton:SetGlyph("+")
  end
end

--[[
  Toggle the accordion for a row: expanding one row collapses the previously
  expanded one, clicking the expanded row collapses it. An in-progress override
  edit is dropped first — the relayout rebinds every input from the store.

  @param {table} row
]]--
function me.ToggleRowExpansion(row)
  if uiState.expandedSpellId == row.spellId then
    uiState.expandedSpellId = nil
  else
    uiState.expandedSpellId = row.spellId
  end

  row.manualOverrideInput:ClearFocus()
  me.RefreshSpellList(row.categoryName)
end

--[[
  OnClick callback for the whole spell row - the row background is the large
  click target for the expansion toggle

  @param {table} self
]]--
function me.RowOnClick(self)
  me.ToggleRowExpansion(self)
end

--[[
  OnClick callback for the expand indicator button

  @param {table} self
]]--
function me.ExpandButtonOnClick(self)
  me.ToggleRowExpansion(self:GetParent())
end

--[[
  Build the localized cooldown value line for a spell row. Spells with a
  cooldownWorstCase show both values so the player can judge whether the
  worst-case toggle is worth flipping; all other spells show the base value
  only. Values are formatted with %g because the catalog holds fractional
  cooldowns (e.g. Mind Blast at 5.5s).

  @param {table} cooldown

  @return {string}
    The formatted cooldown value line
]]--
function me.BuildCooldownValueText(cooldown)
  if cooldown.cooldownWorstCase ~= nil then
    return string.format(
      rgcw.L["option_cooldown_values_worst_case"],
      cooldown.cooldown,
      cooldown.cooldownWorstCase
    )
  end

  return string.format(rgcw.L["option_cooldown_values"], cooldown.cooldown)
end

--[[
  Update the worst-case controls of a row: the display-only value field (with
  its label and suffix) and the toggle. Rows are recycled across spells while
  scrolling, so both the visibility and the states are set on every pass.
  Spells without a cooldownWorstCase value have nothing to assume — the whole
  worst-case group is hidden entirely.

  @param {table} row
  @param {table} cooldown
  @param {string} categoryName
]]--
function me.UpdateWorstCaseToggleState(row, cooldown, categoryName)
  local worstCaseValueInput = row.worstCaseValueInput

  if cooldown.cooldownWorstCase == nil then
    row.worstCaseToggle:Hide()
    worstCaseValueInput:Hide()
    worstCaseValueInput.label:Hide()
    worstCaseValueInput.suffix:Hide()

    return
  end

  -- %g because the catalog holds fractional cooldowns
  worstCaseValueInput:SetText(string.format("%g", cooldown.cooldownWorstCase))
  row.worstCaseToggle:SetChecked(
    mod.configuration.IsCooldownWorstCaseAssumed(categoryName, cooldown.spellId)
  )
  row.worstCaseToggle:Show()
  worstCaseValueInput:Show()
  worstCaseValueInput.label:Show()
  worstCaseValueInput.suffix:Show()
end

--[[
  OnClick callback for cooldown configuration check buttons

  @param {table} self
]]--
function me.CooldownEntryOnClick(self)
  local enabled = self:GetChecked()

  mod.configuration.UpdateCooldownConfigurationState(enabled, self:GetParent().categoryName, self:GetParent().spellId)
  me.UpdateRowControlsState(self:GetParent(), enabled)
end

--[[
  Follow the tracking state with the whole row: gray out the spell title and
  disable the per-spell controls (worst-case toggle and manual override input)
  while the spell itself is deactivated. Rows are recycled across spells while
  scrolling, so the state is also rebound on every UpdateCooldownUiState pass —
  never only on click.

  @param {table} row
  @param {boolean} enabled
]]--
function me.UpdateRowControlsState(row, enabled)
  local manualOverrideInput = row.manualOverrideInput
  local worstCaseValueInput = row.worstCaseValueInput

  if enabled then
    mod.guiHelper.SetColor(row.cooldownStatus.text, RGCW_CONSTANTS.COLOR.SPELL_TITLE)
    mod.guiHelper.SetColor(row.worstCaseToggle.text, RGCW_CONSTANTS.COLOR.BODY)
    mod.guiHelper.SetColor(manualOverrideInput.label, RGCW_CONSTANTS.COLOR.BODY)
    mod.guiHelper.SetColor(worstCaseValueInput.label, RGCW_CONSTANTS.COLOR.BODY)
    mod.guiHelper.SetColor(manualOverrideInput.suffix, RGCW_CONSTANTS.COLOR.SUBNOTE)
    mod.guiHelper.SetColor(worstCaseValueInput.suffix, RGCW_CONSTANTS.COLOR.SUBNOTE)
    row.worstCaseToggle:Enable()
    manualOverrideInput:Enable()
    me.ApplyValueFieldHighlight(row)
  else
    mod.guiHelper.SetColor(row.cooldownStatus.text, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(row.worstCaseToggle.text, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(manualOverrideInput.label, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(worstCaseValueInput.label, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(manualOverrideInput.suffix, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(worstCaseValueInput.suffix, RGCW_CONSTANTS.COLOR.DISABLED)
    row.worstCaseToggle:Disable()
    -- drop an in-progress edit before locking the box - focus survives Disable
    manualOverrideInput:ClearFocus()
    manualOverrideInput:Disable()
    -- no live-value gold on a disabled row - everything reads as dimmed
    mod.guiHelper.SetColor(manualOverrideInput, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(worstCaseValueInput, RGCW_CONSTANTS.COLOR.DISABLED)
    manualOverrideInput:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_BORDER))
    worstCaseValueInput:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_BORDER))
  end
end

--[[
  Color the two value fields so the gold one is the value the runtime will
  actually use for this spell. The precedence (manual override beats worst
  case, per-spell toggle beats the global default) is not restated here -
  CooldownQueue.ResolveCooldown runs on a scratch copy and the outcome is read
  off it.

  @param {table} row
]]--
function me.ApplyValueFieldHighlight(row)
  local override = mod.configuration.GetCooldownManualOverride(row.categoryName, row.spellId)
  local resolved = {
    spellId = row.spellId,
    cooldown = row.baseCooldown,
    cooldownWorstCase = row.worstCaseCooldown,
  }
  mod.cooldownQueue.ResolveCooldown(row.categoryName, resolved)

  -- ResolveCooldown consumes cooldownWorstCase when it applies it (and when an
  -- override wins) - worst case is live only in the no-override consumed case
  local worstCaseLive = override == nil
    and row.worstCaseCooldown ~= nil
    and resolved.cooldownWorstCase == nil

  me.ApplySingleFieldHighlight(row.manualOverrideInput, not worstCaseLive)
  me.ApplySingleFieldHighlight(row.worstCaseValueInput, worstCaseLive)
end

--[[
  @param {table} valueField
  @param {boolean} live
]]--
function me.ApplySingleFieldHighlight(valueField, live)
  if live then
    valueField:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_ACTIVE))
    mod.guiHelper.SetColor(valueField, RGCW_CONSTANTS.COLOR.TITLE_GOLD)
  else
    valueField:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_BORDER))
    mod.guiHelper.SetColor(valueField, RGCW_CONSTANTS.COLOR.BODY)
  end
end

--[[
  OnClick callback for the worst-case toggle

  @param {table} self
]]--
function me.WorstCaseToggleOnClick(self)
  local assumed = self:GetChecked()

  -- self.row, not GetParent() - the toggle lives in the row's expansion strip
  mod.configuration.UpdateCooldownWorstCaseState(assumed, self.row.categoryName, self.row.spellId)
  -- the live value may have moved between the two fields
  me.ApplyValueFieldHighlight(self.row)
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
  Update the cooldown value field of a row: the override when one is set, the
  base cooldown otherwise (%g because the catalog holds fractional cooldowns).
  Rows are recycled across spells while scrolling, so the text is rebound from
  the store on every pass; an in-progress edit is dropped first (ClearFocus).
  The text color is re-applied afterwards by UpdateRowControlsState.

  @param {table} manualOverrideInput
  @param {table} cooldown
  @param {string} categoryName
]]--
function me.UpdateManualOverrideState(manualOverrideInput, cooldown, categoryName)
  manualOverrideInput:ClearFocus()

  local value = mod.configuration.GetCooldownManualOverride(categoryName, cooldown.spellId)

  manualOverrideInput:SetText(string.format("%g", value or cooldown.cooldown))
end

--[[
  Rebind the cooldown value field from the store — restores the persisted
  override (or the base cooldown) and resets the reject coloring via the
  live-value highlight. Serves as the OnEditFocusLost handler so an abandoned
  edit never lingers in the box.

  @param {table} self
]]--
function me.RefreshManualOverride(self)
  -- self.row, not GetParent() - the input lives in the row's expansion strip
  local row = self.row

  if row.spellId == nil then
    return
  end

  local value = mod.configuration.GetCooldownManualOverride(row.categoryName, row.spellId)

  self:SetText(string.format("%g", value or row.baseCooldown))
  me.ApplyValueFieldHighlight(row)
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
  -- self.row, not GetParent() - the input lives in the row's expansion strip
  local row = self.row
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
