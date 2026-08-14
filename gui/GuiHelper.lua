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

-- luacheck: globals GetSpellInfo GetItemIcon CreateFrame CreateColor STANDARD_TEXT_FONT
-- luacheck: globals Settings MinimalSliderWithSteppersMixin

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
  Create the gold panel title every configuration panel carries in its top left corner.

  @param {table} parentFrame
  @param {string} frameName
  @param {string} text

  @return {table}
    The created fontstring
]]--
function me.CreatePanelTitle(parentFrame, frameName, text)
  local titleFontString = parentFrame:CreateFontString(frameName, "OVERLAY", "GameFontNormalLarge")
  titleFontString:SetPoint("TOPLEFT", 16, -16)
  me.SetColor(titleFontString, RGCW_CONSTANTS.COLOR.TITLE_GOLD)
  titleFontString:SetText(text)

  return titleFontString
end

--[[
  Hide a scrollbar while its list fits into the visible area. Must be called after the scroll
  frame and its bar were wired up through ScrollUtil.InitScrollFrameWithScrollBar.

  @param {table} scrollFrame
  @param {table} scrollBar
]]--
function me.EnableScrollBarAutoHide(scrollFrame, scrollBar)
  if scrollBar.SetHideIfUnscrollable then
    scrollBar:SetHideIfUnscrollable(true)

    return
  end

  --[[
    Classic Era did not backport ScrollBarMixin:SetHideIfUnscrollable - track the scroll
    range manually instead
  ]]--
  scrollFrame:HookScript("OnScrollRangeChanged", function(_, _, yRange)
    scrollBar:SetShown(yRange > 0)
  end)
  scrollBar:Hide()
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
  Create the slider options consumed by a MinimalSliderWithSteppersTemplate frame

  @param {number} minValue
  @param {number} maxValue
  @param {number} stepSize
  @param {string} title
  @param {function} formatValue
    Formats a value for the current-value label and the min/max labels

  @return {table}
    The created slider options
]]--
local function CreateSliderOptions(minValue, maxValue, stepSize, title, formatValue)
  local sliderOptions = Settings.CreateSliderOptions(minValue, maxValue, stepSize)

  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatValue)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Max, function() return formatValue(maxValue) end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Min, function() return formatValue(minValue) end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Top, function() return title end)

  return sliderOptions
end

--[[
  Create an always-visible gray description below a slider - the slider counterpart
  to the checkbox description in CreateCheckBox

  @param {table} sliderFrame
  @param {string} description
]]--
local function CreateSliderDescription(sliderFrame, description)
  local descriptionFontString = sliderFrame:CreateFontString(nil, "OVERLAY")
  descriptionFontString:SetFont(STANDARD_TEXT_FONT, 12)
  me.SetColor(descriptionFontString, RGCW_CONSTANTS.COLOR.SUBNOTE)
  -- the template renders its min/max value labels below the frame - keep clear of them
  descriptionFontString:SetPoint("TOPLEFT", sliderFrame, "BOTTOMLEFT", 4, -16)
  descriptionFontString:SetWidth(RGCW_CONSTANTS.CHECK_OPTION_DESCRIPTION_WIDTH)
  descriptionFontString:SetJustifyH("LEFT")
  descriptionFontString:SetText(description)
  sliderFrame.description = descriptionFontString
end

--[[
  Create a configuration slider: a MinimalSliderWithSteppersTemplate frame with the
  title above it, the current value beside it and an always-visible description below.
  Port of GearMenu's UiHelper.CreateSizeSlider (family convention - when the mechanism
  changes, change it in the whole family).

  The callback is registered after Init, so it only ever fires for player interaction,
  never for the initial value.

  @param {string} frameName
  @param {table} parent
  @param {table} position
    An object containing configuration parameters for a SetPoint function call
  @param {table} sliderValues
    minValue, maxValue, stepSize and initialValue of the slider
  @param {string} title
  @param {string} description
  @param {function} onValueChangedCallback
    Invoked with (owner, value) whenever the player moves the slider
  @param {function} formatValue
    Optional formatter for the displayed value labels - defaults to the raw value.
    Sliders with fractional steps should pass one to hide float artifacts.

  @return {table}
    The created slider frame
]]--
function me.CreateSlider(frameName, parent, position, sliderValues, title, description,
    onValueChangedCallback, formatValue)
  formatValue = formatValue or function(value) return value end

  local sliderOptions = CreateSliderOptions(
    sliderValues.minValue,
    sliderValues.maxValue,
    sliderValues.stepSize,
    title,
    formatValue
  )

  local sliderFrame = CreateFrame(
    "Frame",
    frameName,
    parent,
    "MinimalSliderWithSteppersTemplate"
  )
  sliderFrame:SetWidth(RGCW_CONSTANTS.OPTION_SLIDER_WIDTH)
  sliderFrame:SetPoint(unpack(position))
  sliderFrame:Init(
    sliderValues.initialValue,
    sliderOptions.minValue,
    sliderOptions.maxValue,
    sliderOptions.steps,
    sliderOptions.formatters
  )

  if onValueChangedCallback ~= nil then
    sliderFrame:RegisterCallback("OnValueChanged", onValueChangedCallback, sliderFrame)
  end

  CreateSliderDescription(sliderFrame, description)

  return sliderFrame
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
  Brighten an { r, g, b } colour by a flat amount, clamped to 1. Returns the three
  channels separately (ready for SetVertexColor / SetTextColor).

  @param {table} color
  @param {number} amount

  @return {number}, {number}, {number}
]]--
local function Brighten(color, amount)
  return math.min(color[1] + amount, 1), math.min(color[2] + amount, 1), math.min(color[3] + amount, 1)
end

--[[
  Create a single styled "slate key" button: a gradient face over a coloured rim,
  a beveled inset, an additive hover glow, a 1px press nudge, and an outlined
  glyph. Trimmed clone of Quartermaster's UiHelper createKey (no tooltip wiring -
  when the look changes, change the whole family). The caller wires OnClick
  (RegisterForClicks is already set) and may swap the glyph via :SetGlyph(). Use
  ASCII glyphs only - some Unicode symbols do not render in the game font.

  @param {string} name
  @param {table} parent
  @param {string} kind - a RGCW_CONSTANTS.SLATE_KEY palette key (expand)
  @param {string} glyph - the character drawn on the key (+, -)
  @param {number} size

  @return {table}
    The created button
]]--
function me.CreateSlateKey(name, parent, kind, glyph, size)
  local skin = RGCW_CONSTANTS.SLATE_KEY[kind]

  local button = CreateFrame("Button", name, parent, "BackdropTemplate")
  button:SetSize(size, size)
  button:EnableMouse(true)

  -- coloured rim fills the whole button; the face is inset 2px on top of it
  local rim = button:CreateTexture(nil, "BACKGROUND", nil, 0)
  rim:SetAllPoints(button)
  rim:SetColorTexture(skin.rim[1], skin.rim[2], skin.rim[3], 1)

  -- gradient face (darker at the bottom, lighter at the top)
  local face = button:CreateTexture(nil, "BACKGROUND", nil, 1)
  face:SetPoint("TOPLEFT", 2, -2)
  face:SetPoint("BOTTOMRIGHT", -2, 2)
  face:SetColorTexture(1, 1, 1, 1)
  face:SetGradient("VERTICAL",
    CreateColor(skin.bot[1], skin.bot[2], skin.bot[3], 1),
    CreateColor(skin.top[1], skin.top[2], skin.top[3], 1))

  -- additive hover bloom, hidden until OnEnter
  local glow = button:CreateTexture(nil, "ARTWORK", nil, 1)
  glow:SetPoint("CENTER")
  glow:SetSize(size * 0.92, size * 0.92)
  glow:SetColorTexture(1, 1, 1, 1)
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(skin.glow[1], skin.glow[2], skin.glow[3], 1)
  glow:SetAlpha(0)

  -- glyph, sized off a TTF so it can be smaller than any Blizzard font object
  local label = button:CreateFontString(nil, "OVERLAY")
  label:SetFont(RGCW_CONSTANTS.SLATE_KEY_FONT, math.floor(size * 0.52), "OUTLINE")
  label:SetPoint("CENTER", 0, 0)
  label:SetText(glyph)
  label:SetTextColor(skin.glyph[1], skin.glyph[2], skin.glyph[3], 1)
  label:SetShadowColor(0, 0, 0, 1)
  label:SetShadowOffset(0, -1)
  button.label = label

  -- crisp 2px square border tinted to the rim colour
  button:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
  button:SetBackdropBorderColor(skin.rim[1], skin.rim[2], skin.rim[3], 1)

  button:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(Brighten(skin.rim, 0.25))
    rim:SetVertexColor(Brighten(skin.rim, 0.25))
    glow:SetAlpha(0.22)
    label:SetTextColor(Brighten(skin.glyph, 0.10))
  end)

  button:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(skin.rim[1], skin.rim[2], skin.rim[3], 1)
    rim:SetVertexColor(skin.rim[1], skin.rim[2], skin.rim[3], 1)
    glow:SetAlpha(0)
    label:SetTextColor(skin.glyph[1], skin.glyph[2], skin.glyph[3], 1)
  end)

  -- press = nudge the glyph + glow down 1px
  button:SetScript("OnMouseDown", function()
    label:SetPoint("CENTER", 0, -1)
    glow:SetPoint("CENTER", 0, -1)
  end)

  button:SetScript("OnMouseUp", function()
    label:SetPoint("CENTER", 0, 0)
    glow:SetPoint("CENTER", 0, 0)
  end)

  -- disabled = desaturate the face / rim and dim the glyph
  button:SetScript("OnDisable", function()
    face:SetDesaturated(true)
    rim:SetDesaturated(true)
    label:SetTextColor(0.45, 0.41, 0.35, 1)
  end)

  button:SetScript("OnEnable", function()
    face:SetDesaturated(false)
    rim:SetDesaturated(false)
    label:SetTextColor(skin.glyph[1], skin.glyph[2], skin.glyph[3], 1)
  end)

  --[[
    Swap the character drawn on the key (e.g. + to - while a row is expanded)

    @param {string} newGlyph
  ]]--
  function button:SetGlyph(newGlyph)
    self.label:SetText(newGlyph)
  end

  button:RegisterForClicks("LeftButtonUp")

  return button
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
