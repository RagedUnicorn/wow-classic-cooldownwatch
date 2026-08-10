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

-- luacheck: globals CreateFrame CreateColor STANDARD_TEXT_FONT ScrollUtil GameTooltip

local mod = rgcw
local me = {}
mod.cooldownMenu = me

me.tag = "CooldownMenu"

local uiState = {
  --[[
    Outer container holding the scroll frame and its bar. It fills the category content
    frame and is the only piece re-anchored on a category switch
  ]]--
  spellListContainer = nil,
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
  Build the spell list. Everything is anchored rather than sized: the container fills the
  category content frame (which itself stretches to the settings canvas), the scroll frame
  fills the container, the scroll child follows the scroll frames width and the rows span
  the scroll child - so the list uses whatever space the canvas hands out at any resolution
  or ui scale.

  @param {table} parentFrame
  @param {string} categoryName
]]--
function me.BuildUi(parentFrame, categoryName)
  local container = CreateFrame("Frame", nil, parentFrame)
  me.AnchorContainer(container, parentFrame)

  local spellListScrollFrame = CreateFrame(
    "ScrollFrame",
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_SCROLL_FRAME,
    container
  )
  --[[ the rows fill the container, the scrollbar overlays them - see the scrollbar below ]]--
  spellListScrollFrame:SetPoint("TOPLEFT")
  spellListScrollFrame:SetPoint("BOTTOMRIGHT")

  --[[
    The bar is placed on top of the rows instead of next to them so the row background runs
    all the way to the border of the list. The rows keep their controls clear of it through
    RGCW_CONSTANTS.SPELL_LIST_ROW_INSET_RIGHT.
  ]]--
  local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
  scrollBar:SetPoint("TOPRIGHT", spellListScrollFrame, RGCW_CONSTANTS.SPELL_LIST_SCROLL_BAR_GAP * -1, 0)
  scrollBar:SetPoint("BOTTOMRIGHT", spellListScrollFrame, RGCW_CONSTANTS.SPELL_LIST_SCROLL_BAR_GAP * -1, 0)
  --[[ clears the rows, which sit two frame levels below their scroll frame ]]--
  scrollBar:SetFrameLevel(container:GetFrameLevel() + 10)
  ScrollUtil.InitScrollFrameWithScrollBar(spellListScrollFrame, scrollBar)
  --[[ a category with fewer spells than fit must not show an inert bar ]]--
  mod.guiHelper.EnableScrollBarAutoHide(spellListScrollFrame, scrollBar)

  local spellListContent = CreateFrame("Frame", nil, spellListScrollFrame)
  --[[
    Seed the content with the fallback width and no scrollable extent - UpdateContentWidth
    takes over the width as soon as the canvas reports one and RefreshSpellList sets the real
    height once it knows its row count and the accordion state. Seeding the full list height
    would leave the list scrollable and keep the scrollbar visible on a category that fits
  ]]--
  spellListContent:SetSize(RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_WIDTH, 1)
  spellListScrollFrame:SetScrollChild(spellListContent)

  uiState.spellListContainer = container
  uiState.spellListScrollFrame = spellListScrollFrame
  uiState.spellListScrollBar = scrollBar
  uiState.spellListContent = spellListContent

  --[[
    The settings canvas has no size before the panel was shown for the first time and changes
    with resolution and ui scale - follow it instead of sizing the list once
  ]]--
  spellListScrollFrame:HookScript("OnSizeChanged", me.UpdateContentWidth)
  me.UpdateContentWidth()

  me.RefreshSpellList(categoryName)
end

--[[
  Anchor the spell list container to fill the content frame it belongs to

  @param {table} container
  @param {table} parentFrame
]]--
function me.AnchorContainer(container, parentFrame)
  container:ClearAllPoints()
  container:SetPoint("TOPLEFT", parentFrame)
  container:SetPoint("BOTTOMRIGHT", parentFrame)
end

--[[
  Size the scroll child to the width of its scroll frame so the rows span the whole canvas.
  The height is owned by RefreshSpellList - it follows the accordion, not the canvas.
]]--
function me.UpdateContentWidth()
  local availableWidth = uiState.spellListScrollFrame:GetWidth()

  if availableWidth > 0 then
    uiState.spellListContent:SetWidth(availableWidth)
  end
end

--[[
  Update the category menu spells tab to its new parent category

  @param {table} parentFrame
]]--
function me.UpdateCategoryMenu(parentFrame)
  uiState.spellListContainer:SetParent(parentFrame)
  me.AnchorContainer(uiState.spellListContainer, parentFrame)
  uiState.spellListScrollFrame:SetVerticalScroll(0) -- reset scroll position to top
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
  --[[
    Rows carry no width of their own - RefreshSpellList anchors them to both sides of the
    scroll child so they follow the canvas whenever the settings panel changes size
  ]]--
  row:SetHeight(RGCW_CONSTANTS.SPELL_LIST_ROW_HEIGHT)
  row:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  row:SetBackdropColor(unpack(RGCW_CONSTANTS.COLORS.SPELL_ROW_BACKGROUND))

  --[[
    Category-colored wash on top of the warm near-black base, fading out towards the right
    so the row does not compete with its controls. Tinted per category in
    UpdateRowCategoryTint - rows are recycled across categories - where alternating its
    alpha between odd and even rows produces the zebra striping (PVPWarn parity).
  ]]--
  row.position = position
  row.categoryGradient = row:CreateTexture(nil, "BACKGROUND", nil, 1)
  row.categoryGradient:SetColorTexture(1, 1, 1, 1)
  row.categoryGradient:SetAllPoints(row)

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
  Tint a row's gradient with its category color. Zebra striping is achieved by alternating
  the gradients alpha between odd and even rows. Rows are shared across categories and thus
  need to be retinted on every category switch.

  @param {table} row
  @param {string} categoryName
]]--
function me.UpdateRowCategoryTint(row, categoryName)
  local color = mod.guiHelper.GetCategoryColor(categoryName)
  local alpha = math.fmod(row.position, 2) == 0
    and RGCW_CONSTANTS.SPELL_LIST_ROW_TINT_ALPHA_EVEN
    or RGCW_CONSTANTS.SPELL_LIST_ROW_TINT_ALPHA_ODD

  row.categoryGradient:SetGradient(
    "HORIZONTAL",
    CreateColor(color[1], color[2], color[3], alpha),
    CreateColor(color[1], color[2], color[3], 0)
  )
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
  --[[
    Centered in the fixed-height collapsed header, not the (variable) row, and kept clear
    of the scrollbar overlaying the right edge of the list
  ]]--
  expandButton:SetPoint(
    "TOPRIGHT",
    RGCW_CONSTANTS.SPELL_LIST_ROW_INSET_RIGHT * -1,
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

  --[[
    Hairline separator between the header and the unfolded options. Its right end stops
    where the row controls do so it does not run underneath the scrollbar.
  ]]--
  local separator = expansion:CreateTexture(nil, "ARTWORK")
  separator:SetPoint("TOPLEFT", 8, 0)
  separator:SetPoint("TOPRIGHT", RGCW_CONSTANTS.SPELL_LIST_ROW_INSET_RIGHT * -1, 0)
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
  is locale-independent, deliberately not a localization key). Styling plus the
  shared commit behaviour - the caller anchors the label, points the three
  store accessors at its own configuration field and sets the tooltip texts.

  Both fields in the strip behave identically (see me.CommitValueField):
  pressing Enter or leaving the box applies the value, Escape abandons the
  edit, and an emptied box drops back to the catalog value.

  @param {string} name
  @param {string} resetName
    Frame name for the field's reset key (see CreateValueFieldResetButton)
  @param {table} row
  @param {string} labelText

  @return {table}
    The created editbox (with .label, .suffix and .resetButton)
]]--
function me.CreateValueField(name, resetName, row, labelText)
  local valueField = CreateFrame("EditBox", name, row.expansion, "BackdropTemplate")
  valueField.row = row
  valueField:SetSize(
    RGCW_CONSTANTS.VALUE_FIELD_WIDTH,
    RGCW_CONSTANTS.VALUE_FIELD_HEIGHT
  )
  valueField:SetAutoFocus(false)
  valueField:SetMaxLetters(RGCW_CONSTANTS.VALUE_FIELD_MAX_LETTERS)
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

  valueField:SetScript("OnEnter", me.ValueFieldOnEnter)
  valueField:SetScript("OnLeave", me.ValueFieldOnLeave)
  valueField:SetScript("OnEnterPressed", me.ValueFieldOnEnterPressed)
  valueField:SetScript("OnEscapePressed", me.ValueFieldOnEscapePressed)
  valueField:SetScript("OnEditFocusLost", me.ValueFieldOnEditFocusLost)

  valueField.resetButton = me.CreateValueFieldResetButton(valueField, resetName)

  return valueField
end

--[[
  Create the reset key that clears a value field back to the catalog default.

  Emptying the box and leaving it does the same thing, but that is a gesture
  nobody discovers by looking - the key makes the escape route visible, and its
  presence doubles as the answer to "did I override this one?". It is shown
  only while the field actually carries an override (UpdateResetButtonState),
  so an untouched strip carries no extra clutter.

  A small key rather than a labelled "Default" button on purpose: the strip's
  controls are anchored in one left-to-right chain that already runs close to
  the width of the settings canvas, and a labelled button would either extend
  that chain past the edge or, right-aligned, collide with the worst-case
  toggle's label on a narrower canvas.

  @param {table} valueField
  @param {string} name

  @return {table}
    The created button
]]--
function me.CreateValueFieldResetButton(valueField, name)
  local resetButton = mod.guiHelper.CreateSlateKey(
    name,
    valueField.row.expansion,
    "reset",
    "x",
    RGCW_CONSTANTS.SLATE_KEY_SIZE_SMALL
  )
  resetButton.valueField = valueField
  resetButton:SetPoint("LEFT", valueField.suffix, "RIGHT", 6, 0)
  resetButton:SetScript("OnClick", me.ValueFieldResetOnClick)
  --[[
    Hooked, not set: CreateSlateKey owns OnEnter/OnLeave for the hover glow and
    replacing them would leave the key visually dead on mouseover.
  ]]--
  resetButton:HookScript("OnEnter", me.ValueFieldResetOnEnter)
  resetButton:HookScript("OnLeave", me.ValueFieldResetOnLeave)
  resetButton:Hide()

  return resetButton
end

--[[
  OnClick callback for a value field's reset key - clear the override and
  rebind the row from the store

  @param {table} self
]]--
function me.ValueFieldResetOnClick(self)
  local valueField = self.valueField
  local row = valueField.row

  if row.spellId == nil then return end

  valueField.SetOverride(row, nil)
  me.RefreshRowValueFields(row)
  me.RefreshRowResolvedState(row)
end

--[[
  OnEnter callback for a value field's reset key - show tooltip
]]--
function me.ValueFieldResetOnEnter()
  mod.tooltip.BuildTooltipForOption(
    rgcw.L["option_reset_to_default"],
    rgcw.L["option_reset_to_default_tooltip"]
  )
end

--[[
  OnLeave callback for a value field's reset key - hide tooltip
]]--
function me.ValueFieldResetOnLeave()
  mod.tooltip.TooltipClear()
end

--[[
  Show a value field's reset key only while the field carries an override the
  key could clear, and only on a tracked row. BindValueField has already
  recorded whether it does.

  @param {table} valueField
  @param {boolean} enabled
]]--
function me.UpdateResetButtonState(valueField, enabled)
  valueField.resetButton:SetShown(enabled and valueField.overridden == true and valueField:IsShown())
end

--[[
  Rebind everything on a row that reports the resolved state - the description
  line and both reset keys - after the player changed a setting on it.

  Every caller is a control that is only live on a tracked row (a value field,
  a reset key, the worst-case toggle), so enabled is implied. The row-rebind
  path does not use this: it goes through UpdateRowControlsState, which knows
  the real tracking state.

  @param {table} row
]]--
function me.RefreshRowResolvedState(row)
  me.UpdateCooldownValueLine(row, true)
  me.UpdateResetButtonState(row.manualOverrideInput, true)
  me.UpdateResetButtonState(row.worstCaseValueInput, true)
end

--[[
  Drop an in-progress edit without committing it. Used wherever the *addon*
  takes focus away rather than the player: rebinding a recycled row onto
  another spell, and locking the controls when the spell is untracked. A plain
  ClearFocus would commit (see me.ValueFieldOnEditFocusLost) and the text
  belongs to the state the row is leaving.

  @param {table} valueField
]]--
local function DropFieldEdit(valueField)
  valueField.suppressCommit = true
  valueField:ClearFocus()
  valueField.suppressCommit = false
end

--[[
  Create the worst-case value field. Backed by the per-spell worst-case value
  store: the box shows the player's value when one is set and the catalog's
  cooldownWorstCase otherwise, and an emptied commit drops back to the catalog.
  It corrects the *value* only - whether the worst case is assumed at all stays
  with the toggle next to it. Hidden by UpdateWorstCaseToggleState for spells
  the catalog carries no worst case for; those have nothing to correct and use
  the plain cooldown override instead.

  @param {table} row

  @return {table}
    The created editbox
]]--
function me.CreateWorstCaseValueField(row)
  local worstCaseValueInput = me.CreateValueField(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE_VALUE,
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE_VALUE_RESET,
    row,
    rgcw.L["option_assume_worst_case"]
  )
  --[[
    Anchored past the cooldown field's reset key rather than its suffix, so the
    space the key occupies is reserved whether it is shown or not - the strip
    must not shuffle sideways the moment a value is overridden.
  ]]--
  worstCaseValueInput.label:SetPoint("LEFT", row.manualOverrideInput.resetButton, "RIGHT", 20, 0)
  worstCaseValueInput:SetPoint("LEFT", worstCaseValueInput.label, "RIGHT", 10, 0)

  worstCaseValueInput.GetOverride = function(fieldRow)
    return mod.configuration.GetCooldownWorstCaseValue(fieldRow.categoryName, fieldRow.spellId)
  end
  worstCaseValueInput.SetOverride = function(fieldRow, value)
    return mod.configuration.UpdateCooldownWorstCaseValue(value, fieldRow.categoryName, fieldRow.spellId)
  end
  worstCaseValueInput.GetCatalogValue = function(fieldRow)
    return fieldRow.worstCaseCooldown
  end
  worstCaseValueInput.tooltipTitle = rgcw.L["option_assume_worst_case"]
  worstCaseValueInput.tooltipText = rgcw.L["option_worst_case_value_tooltip"]
  worstCaseValueInput.liveBorderColor = RGCW_CONSTANTS.COLORS.VALUE_FIELD_WORST_CASE

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
    -- past the worst-case reset key for the same reason (see CreateWorstCaseValueField)
    {"LEFT", row.worstCaseValueInput.resetButton, "RIGHT", 20, 0},
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
  catalog's base cooldown otherwise, and an emptied commit clears the override,
  dropping the box back to the base value.

  @param {table} row

  @return {table}
    The created editbox
]]--
function me.CreateManualOverrideInput(row)
  local manualOverrideInput = me.CreateValueField(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_MANUAL_OVERRIDE,
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_MANUAL_OVERRIDE_RESET,
    row,
    rgcw.L["option_cooldown_label"]
  )
  -- indented to sit under the name column of the collapsed header
  manualOverrideInput.label:SetPoint("LEFT", row.expansion, 64, 0)
  manualOverrideInput:SetPoint("LEFT", manualOverrideInput.label, "RIGHT", 10, 0)

  manualOverrideInput.GetOverride = function(fieldRow)
    return mod.configuration.GetCooldownManualOverride(fieldRow.categoryName, fieldRow.spellId)
  end
  manualOverrideInput.SetOverride = function(fieldRow, value)
    return mod.configuration.UpdateCooldownManualOverride(value, fieldRow.categoryName, fieldRow.spellId)
  end
  manualOverrideInput.GetCatalogValue = function(fieldRow)
    return fieldRow.baseCooldown
  end
  manualOverrideInput.tooltipTitle = rgcw.L["option_manual_cooldown_override"]
  manualOverrideInput.tooltipText = rgcw.L["option_manual_cooldown_override_tooltip"]
  manualOverrideInput.liveBorderColor = RGCW_CONSTANTS.COLORS.VALUE_FIELD_ACTIVE

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
      --[[ anchored to both sides so the row follows the scroll childs width ]]--
      row:SetPoint("TOPLEFT", uiState.spellListContent, 0, -offsetY)
      row:SetPoint("TOPRIGHT", uiState.spellListContent, 0, -offsetY)
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
    Drop an in-progress edit *before* the identity below is rebound. Leaving a
    value field commits it, so a recycled row still holding focus would write
    the text the player typed for the previous spell onto the new one.
  ]]--
  DropFieldEdit(row.manualOverrideInput)
  DropFieldEdit(row.worstCaseValueInput)

  --[[
    Bind the new spell identity next - every control update below reads it: the
    fields rebind their text through the store accessors and the highlight
    resolves the live value against it.
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
  me.UpdateRowCategoryTint(row, categoryName)
  row.cooldownStatus.text:SetText(cooldown.name)

  if enabled then
    row.cooldownStatus:SetChecked(true)
  else
    row.cooldownStatus:SetChecked(false)
  end

  me.UpdateWorstCaseToggleState(row, cooldown, categoryName)
  me.RefreshRowValueFields(row)
  -- after RefreshRowValueFields - the controls state re-applies the value colors
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
  expanded one, clicking the expanded row collapses it.

  Focus is dropped unsuppressed on purpose: folding the strip away is the
  player leaving the field, so an in-progress edit commits exactly as it would
  on any other click-away rather than vanishing with the strip.

  @param {table} row
]]--
function me.ToggleRowExpansion(row)
  if uiState.expandedSpellId == row.spellId then
    uiState.expandedSpellId = nil
  else
    uiState.expandedSpellId = row.spellId
  end

  row.manualOverrideInput:ClearFocus()
  row.worstCaseValueInput:ClearFocus()
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
  Build the localized cooldown value line for a spell row - the description
  under the spell name, and the only place the resolved state is visible
  without expanding the row.

  The line is an inventory of the settings that are switched on for the spell,
  worst case first:

    plain                            "30s cooldown"
    "Use worst case" on              "20s worst case / 30s cooldown"
    ...and the cooldown overridden   "20s worst case / 15s override (base 30s)"
    "Use worst case" off             "30s cooldown"

  The worst-case segment tracks the *toggle*, not the resolution: it appears
  whenever the worst case is switched on for the spell (per-spell toggle, or
  the global default for a spell that was never configured) and disappears the
  moment it is switched off. A cooldown override beats the worst case at
  resolution time but does not hide it here - the two are independent settings
  and hiding one because the other exists loses information the player put in.

  Colour says what kind of value each segment is: cyan for a worst case (the
  same cyan as the bar's small worst-case timer and the strip's worst-case
  field border), gold for a cooldown the player set on this spell, dim for an
  untouched catalog value. Gold is therefore never reached by the global
  worst-case default, which would falsely mark a spell as customized.

  Values go through Common.FormatCooldownDuration rather than being printed as
  raw seconds: this is prose under the spell name, and "5m" or "1m 30s" is read
  at a glance where "300" and "90" have to be divided first. The editable value
  fields in the expansion strip keep raw seconds - those are inputs, and a unit
  suffix in the box would have to be parsed back out.

  @param {table} row

  @return {table}
    An ordered array of { text, color } segments the caller joins
]]--
function me.BuildCooldownValueSegments(row)
  local segments = {}
  local override = mod.configuration.GetCooldownManualOverride(row.categoryName, row.spellId)

  if row.worstCaseCooldown ~= nil
    and mod.configuration.IsWorstCaseEffective(row.categoryName, row.spellId) then
    -- the player's corrected value when there is one, the catalog's otherwise
    local worstCase = mod.configuration.GetCooldownWorstCaseValue(row.categoryName, row.spellId)
      or row.worstCaseCooldown

    table.insert(segments, {
      text = string.format(
        rgcw.L["option_cooldown_values_worst_case"],
        mod.common.FormatCooldownDuration(worstCase)
      ),
      color = RGCW_CONSTANTS.COLOR.WORST_CASE,
    })
  end

  if override ~= nil then
    table.insert(segments, {
      text = string.format(
        rgcw.L["option_cooldown_values_override"],
        mod.common.FormatCooldownDuration(override),
        mod.common.FormatCooldownDuration(row.baseCooldown)
      ),
      color = RGCW_CONSTANTS.COLOR.TITLE_GOLD,
    })

    return segments
  end

  table.insert(segments, {
    text = string.format(
      rgcw.L["option_cooldown_values"],
      mod.common.FormatCooldownDuration(row.baseCooldown)
    ),
    color = RGCW_CONSTANTS.COLOR.SUBNOTE,
  })

  return segments
end

--[[
  Rebind a row's cooldown value line from the store. Called wherever the
  resolution can change: the row taking on a new spell, the tracking checkbox,
  the worst-case toggle, a committed value edit and a reset.

  @param {table} row
  @param {boolean} enabled
    The spell's tracking state. An untracked row dims as a whole, so its
    segments are emitted *without* colour escapes - an escape would survive
    SetTextColor and leave a greyed-out row still showing live colours.
]]--
function me.UpdateCooldownValueLine(row, enabled)
  local segments = me.BuildCooldownValueSegments(row)
  local parts = {}

  for _, segment in ipairs(segments) do
    table.insert(parts, enabled and mod.common.ColorText(segment.text, segment.color) or segment.text)
  end

  row.cooldownValue:SetText(table.concat(parts, " / "))
  -- colours the separators between segments, and the whole line while untracked
  mod.guiHelper.SetColor(
    row.cooldownValue,
    enabled and RGCW_CONSTANTS.COLOR.SUBNOTE or RGCW_CONSTANTS.COLOR.DISABLED
  )
end

--[[
  Update the visibility of a row's worst-case group (value field with its label
  and suffix, plus the toggle) and the toggle's state. Rows are recycled across
  categories, so both are set on every pass. Spells without a cooldownWorstCase
  value have nothing to assume — the whole group is hidden entirely.

  The field's text is not set here: RefreshRowValueFields owns the content of
  both value fields so the store stays the single source for what they show.

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
  disable the per-spell controls (worst-case toggle and both value fields)
  while the spell itself is deactivated. Rows are recycled across categories,
  so the state is also rebound on every UpdateCooldownUiState pass — never only
  on click.

  @param {table} row
  @param {boolean} enabled
]]--
function me.UpdateRowControlsState(row, enabled)
  local manualOverrideInput = row.manualOverrideInput
  local worstCaseValueInput = row.worstCaseValueInput

  --[[
    The description line reports the resolved state, so it follows the tracking
    state with everything else. Both callers of this function (the row rebind
    and the tracking checkbox) get it for free; the two paths that change the
    resolution without touching the checkbox refresh it themselves.
  ]]--
  me.UpdateCooldownValueLine(row, enabled)
  me.UpdateResetButtonState(manualOverrideInput, enabled)
  me.UpdateResetButtonState(worstCaseValueInput, enabled)

  if enabled then
    mod.guiHelper.SetColor(row.cooldownStatus.text, RGCW_CONSTANTS.COLOR.SPELL_TITLE)
    mod.guiHelper.SetColor(row.worstCaseToggle.text, RGCW_CONSTANTS.COLOR.BODY)
    mod.guiHelper.SetColor(manualOverrideInput.label, RGCW_CONSTANTS.COLOR.BODY)
    mod.guiHelper.SetColor(worstCaseValueInput.label, RGCW_CONSTANTS.COLOR.BODY)
    mod.guiHelper.SetColor(manualOverrideInput.suffix, RGCW_CONSTANTS.COLOR.SUBNOTE)
    mod.guiHelper.SetColor(worstCaseValueInput.suffix, RGCW_CONSTANTS.COLOR.SUBNOTE)
    row.worstCaseToggle:Enable()
    manualOverrideInput:Enable()
    worstCaseValueInput:Enable()
    me.ApplyValueFieldHighlight(row)
  else
    mod.guiHelper.SetColor(row.cooldownStatus.text, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(row.worstCaseToggle.text, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(manualOverrideInput.label, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(worstCaseValueInput.label, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(manualOverrideInput.suffix, RGCW_CONSTANTS.COLOR.DISABLED)
    mod.guiHelper.SetColor(worstCaseValueInput.suffix, RGCW_CONSTANTS.COLOR.DISABLED)
    row.worstCaseToggle:Disable()
    --[[
      Drop in-progress edits before locking the boxes - focus survives Disable.
      Suppressed: untracking a spell is not the player leaving the field, so
      whatever they had typed must not be committed on the way out.
    ]]--
    DropFieldEdit(manualOverrideInput)
    DropFieldEdit(worstCaseValueInput)
    manualOverrideInput:Disable()
    worstCaseValueInput:Disable()
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
  Two independent signals on two channels, so a field answers both questions a
  player has about the number in it:

  - lit border: this is the value the runtime will actually use for the spell.
    The colour it lights up in is the field's own (valueField.liveBorderColor) -
    gold on the cooldown field, cyan on the worst-case field - so the border
    says *which kind* of value is live, not merely that one is. Lighting the
    worst-case field gold would have it claim the player set a value on this
    spell, when the global default may be what switched it on.
  - text solid vs dimmed: the number is the player's own, versus the catalog
    value merely displayed in the box. Dimmed reads as placeholder text, which
    is exactly what it is — emptying the field and leaving it returns to the
    dimmed catalog value. Without this the two states are indistinguishable and
    there is no way to tell whether a spell was ever configured.

  @param {table} valueField
  @param {boolean} live
]]--
function me.ApplySingleFieldHighlight(valueField, live)
  if live then
    valueField:SetBackdropBorderColor(unpack(valueField.liveBorderColor))
  else
    valueField:SetBackdropBorderColor(unpack(RGCW_CONSTANTS.COLORS.VALUE_FIELD_BORDER))
  end

  mod.guiHelper.SetColor(
    valueField,
    valueField.overridden and RGCW_CONSTANTS.COLOR.BODY or RGCW_CONSTANTS.COLOR.MUTED
  )
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
  me.RefreshRowResolvedState(self.row)
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
  Rebind a single value field from the store: the player's override when one is
  set, the catalog value otherwise (%g because the catalog holds fractional
  cooldowns). Records what was bound on the field itself — `overridden` drives
  the placeholder coloring in ApplySingleFieldHighlight, `boundText` is what
  the commit compares against to tell an actual edit from an untouched box.

  @param {table} valueField
]]--
function me.BindValueField(valueField)
  local row = valueField.row
  local override = valueField.GetOverride(row)

  valueField.overridden = override ~= nil
  valueField.boundText = string.format("%g", override or valueField.GetCatalogValue(row))
  valueField:SetText(valueField.boundText)
end

--[[
  Rebind both value fields of a row from the store and re-apply the live-value
  highlight. The single path back to a clean state — used when a row takes on a
  new spell, after a commit, and to abandon an edit.

  @param {table} row
]]--
function me.RefreshRowValueFields(row)
  if row.spellId == nil then
    return
  end

  me.BindValueField(row.manualOverrideInput)

  -- the worst-case field is hidden (and carries no catalog value) without one
  if row.worstCaseCooldown ~= nil then
    me.BindValueField(row.worstCaseValueInput)
  end

  me.ApplyValueFieldHighlight(row)
end

--[[
  Commit the text of a value field to its store. Shared by the Enter and the
  focus-lost path so both apply exactly the same value — "leaving the field
  reverts my edit" was the single most confusing thing about this strip.

  An emptied box clears the override and falls back to the catalog value.

  Text identical to what was last bound is a no-op: the box displays the
  catalog value when nothing is configured, so committing an untouched field
  would silently turn that display into a stored override just because the
  player clicked into it and back out.

  @param {table} valueField

  @return {boolean}
    true  - Committed (or nothing to commit)
    false - The typed text could not be stored; the field keeps it
]]--
function me.CommitValueField(valueField)
  local row = valueField.row

  if row.spellId == nil then
    return true
  end

  local text = valueField:GetText()

  if text == valueField.boundText then
    return true
  end

  if text == "" then
    valueField.SetOverride(row, nil)
  else
    local value = mod.common.ParseSeconds(text)

    --[[
      Parse before storing, never SetOverride(tonumber(text)) directly: nil is
      the *clear* argument, so handing unparseable text straight through would
      wipe the existing override while reporting the edit as rejected.
    ]]--
    if value == nil or valueField.SetOverride(row, value) == nil then
      return false
    end
  end

  me.RefreshRowValueFields(row)
  --[[
    A committed edit changes which value is tracked, so the description line and
    the reset keys have to follow. Only the commit path needs this - Escape and
    a rejected value restore, they do not change the resolution.
  ]]--
  me.RefreshRowResolvedState(row)

  return true
end

--[[
  OnEnterPressed callback for a value field. A rejected value (non-numeric,
  zero or negative) turns red and keeps focus so it can be corrected right
  away; everything else commits and releases focus.

  @param {table} self
]]--
function me.ValueFieldOnEnterPressed(self)
  if me.CommitValueField(self) then
    self:ClearFocus()

    return
  end

  mod.guiHelper.SetColor(self, RGCW_CONSTANTS.COLOR.REJECTED)
end

--[[
  OnEditFocusLost callback for a value field. Leaving the box applies the value
  exactly like pressing Enter; text that cannot be stored simply reverts, since
  the box is no longer focused and there is nothing left to correct.

  Suppressed while the addon itself takes focus away rather than the player
  (see DropFieldEdit).

  @param {table} self
]]--
function me.ValueFieldOnEditFocusLost(self)
  if self.suppressCommit then
    return
  end

  if not me.CommitValueField(self) then
    me.RefreshRowValueFields(self.row)
  end
end

--[[
  OnEscapePressed callback for a value field - abandon the edit. Restoring the
  bound text first also disarms the commit on the focus loss that follows.

  @param {table} self
]]--
function me.ValueFieldOnEscapePressed(self)
  me.RefreshRowValueFields(self.row)
  self:ClearFocus()
end

--[[
  OnEnter callback for a value field - show the field's own tooltip

  @param {table} self
]]--
function me.ValueFieldOnEnter(self)
  mod.tooltip.BuildTooltipForOption(self.tooltipTitle, self.tooltipText)
end

--[[
  OnLeave callback for a value field - hide tooltip
]]--
function me.ValueFieldOnLeave()
  mod.tooltip.TooltipClear()
end
