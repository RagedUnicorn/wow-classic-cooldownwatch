--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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

local mod = rgcw
local me = {}
mod.uiHelper = me

me.tag = "UiHelper"

--[[
  Creates a scrollframe for scrollable content

  @param {string} scrollFrameName
  @param {table} parent

  @return {table}
    the created scrollFrame
]]--
function me.CreateCategoryScrollFrame(scrollFrameName, parent)
  local scrollFrame = CreateFrame("ScrollFrame", scrollFrameName, parent)

  scrollFrame:SetWidth(parent:GetWidth())
  scrollFrame:SetHeight(parent:GetHeight() - 10)
  scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -5)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", me.ScrollFrameOnMouseWheel)

  return scrollFrame
end

--[[
  Scroll callback for scrollable content. Also updates the associated
  scrollFrameSlider to its new position

  @param {table} self
]]--
function me.ScrollFrameOnMouseWheel(self, arg1)
  local maxScroll = self:GetVerticalScrollRange()
  local scroll = self:GetVerticalScroll()
  local toScroll = (scroll - (20 * arg1))
  local scrollFrameSlider

  for _, child in ipairs({self:GetChildren()}) do
    if child:GetObjectType() == "Slider" then
      scrollFrameSlider = child
    end
  end

  if toScroll < 0 then
    self:SetVerticalScroll(0)
    me.SliderUpdatePosition(scrollFrameSlider, 0, maxScroll)
  elseif toScroll > maxScroll then
    self:SetVerticalScroll(maxScroll)
    me.SliderUpdatePosition(scrollFrameSlider, maxScroll, maxScroll)
  else
    self:SetVerticalScroll(toScroll)
    me.SliderUpdatePosition(scrollFrameSlider, toScroll, maxScroll)
  end
end

--[[
  Update scrollframeslider position

  @param {table} scrollFrameSlider
    reference to the scrollframeslider that should get updated
  @param {number} scrollPosition
  @param {number} maxScroll
]]--
function me.SliderUpdatePosition(scrollFrameSlider, scrollPosition, maxScroll)
  local position

  mod.logger.LogDebug(me.tag, "Content scrollposition: " .. scrollPosition)

  if scrollFrameSlider == nil then
    mod.logger.LogError(me.tag, "Unable to find frameslider for current scrollframe")
    return
  end

  position = 100 / (maxScroll / math.floor(scrollPosition))
  mod.logger.LogDebug(me.tag, "New Slider scrollposition: " .. math.ceil(position))
  scrollFrameSlider:SetValue(math.ceil(position))
end

--[[
  Creates a contentFrame for the scrollFrame

  @param {string} contentFrameName
  @param {table} scrollFrame

  @return {table}
]]--
function me.CreateCategoryContentFrame(contentFrameName, scrollFrame)
  mod.logger.LogError(me.tag, "ContentFrame called")
  local contentFrame = CreateFrame("Frame", contentFrameName, scrollFrame)

  contentFrame:SetWidth(scrollFrame:GetWidth())
  contentFrame:SetHeight(scrollFrame:GetHeight())
  scrollFrame:SetScrollChild(contentFrame)

  return contentFrame
end

--[[
  Creates a draggable slider for the scrollFrame

  @param {string} scrollFrameSliderName
  @param {table} scrollFrame
  @param {table} parent

  @return {table}
]]--
function me.CreateCategoryScrollFrameSlider(scrollFrameSliderName, scrollFrame, parent)
  local scrollBackground
  local scrollFrameSlider = CreateFrame("Slider", scrollFrameSliderName,
    scrollFrame, "UIPanelScrollBarTemplate")

  scrollFrameSlider:SetPoint("TOPLEFT", parent, "TOPRIGHT", 4, -16)
  scrollFrameSlider:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 4, 16)
  scrollFrameSlider:SetMinMaxValues(
    RGCW_CONSTANTS.CATEGORY_CONFIG_SLIDER_MIN_VALUE,
    RGCW_CONSTANTS.CATEGORY_CONFIG_SLIDER_MAX_VALUE
  )
  scrollFrameSlider:SetValueStep(1)
  scrollFrameSlider:SetValue(0)
  scrollFrameSlider:SetWidth(16)
  -- sets the stepsize that is made when clicking on up or down arrow button
  scrollFrameSlider:SetHeight(10)
  scrollFrameSlider:SetScript("OnValueChanged", me.ScrollFrameSliderOnValueChanged)
  scrollBackground = scrollFrameSlider:CreateTexture(nil, "BACKGROUND")
  scrollBackground:SetAllPoints(scrollFrameSlider)
  scrollBackground:SetTexture(0, 0, 0, 0.4)

  return scrollFrameSlider
end

--[[
  Callback for slider - called each time the value of the slider changes

  @param {table} self
]]--
function me.ScrollFrameSliderOnValueChanged(self)
  local scrollFrame = self:GetParent()

  if scrollFrame == nil then
    mod.logger.LogError(me.tag, "Unable to find scrollFrame")
    return
  end
  -- getmaxscroll of scrollFrame
  local maxScroll = scrollFrame:GetVerticalScrollRange()
  -- translate max/min 0 - 100 to maxScroll
  local stepSize = maxScroll / RGCW_CONSTANTS.CATEGORY_CONFIG_SLIDER_MAX_VALUE
  -- set vertical scroll of the contenframe - (currentslider value * stepsize)
  scrollFrame:SetVerticalScroll(self:GetValue() * stepSize)
end

--[[
  Creates a new spellFrame

  @param {string} spellFrameName
  @param {table} contentFrame
    Base for the spellFrame name. Builds a fully name combinend with position
  @param {number} position
  @return {table}
    the created spellFrame
]]--
function me.CreateCooldownSpellFrame(spellFrameName, contentFrame, position)
  mod.logger.LogDebug(me.tag, "Creating new Spellcontainer" .. position
    .. " because it did not yet exist")
    testing = contentFrame

  -- TODO consider the template that can be used
  -- local spellFrame = CreateFrame("Frame", spellFrameName .. position, contentFrame, PVPW_CONSTANTS.ELEMENT_PVPW_CLASS_SPELL_CONFIGURATION_TEMPLATE)
  local spellFrame = CreateFrame("Frame", spellFrameName .. position, contentFrame)
  spellFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 4, -position * RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_FRAME_HEIGHT)
  spellFrame:SetWidth(contentFrame:GetWidth() - 8)
  spellFrame:SetHeight(RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_FRAME_HEIGHT)

  spellFrame:SetBackdrop({
    bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    spellFrame:SetBackdropColor(0.37, 0.37, 0.37, .4)
  else
    spellFrame:SetBackdropColor(.25, .25, .25, .8)
  end
  spellFrame:SetBackdropBorderColor(0, 0.2, 0, .8)

  spellFrame.cooldownIcon = me.CreateCooldownSpellIcon(spellFrame)
  spellFrame.cooldownStatus = me.CreateCooldownSpell(spellFrame, spellFrame.cooldownIcon)

  return spellFrame
end

--[[
  @param {table} spellFrame

  @return {table}
    The created icon texture holder
]]--
function me.CreateCooldownSpellIcon(spellFrame)
  local cooldownIcon = spellFrame:CreateTexture(RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON, "ARTWORK")
  cooldownIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  cooldownIcon:SetPoint("LEFT", 10, 0)
  cooldownIcon:SetSize(
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON_SIZE,
    RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON_SIZE
  )

  return cooldownIcon
end

--[[
  TODO
]]--
function me.CreateCooldownSpell(spellFrame, spellIcon)
  local cooldownSpellStatusCheckBox = CreateFrame("CheckButton", RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS, spellFrame, "UICheckButtonTemplate")
  cooldownSpellStatusCheckBox:SetSize(RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS_SIZE, RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS_SIZE)
  cooldownSpellStatusCheckBox:SetPoint("RIGHT", spellIcon, 50, 0)

  return cooldownSpellStatusCheckBox
end

--[[
  TODO

  TODO need to build a workaround here because a lot of our spells don't exist in the _retail_ version of the game
  but will again in wow classic
]]--
function me.ConfigureSpellFrame(cooldownSpellFrame, spellId, spellData)
  mod.logger.LogError(me.tag, "SpellInfo: " .. spellId)
  local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellId)

  if name ~= nil and icon ~= nil then
    cooldownSpellFrame.cooldownIcon:SetTexture(icon)

    for _, region in ipairs({cooldownSpellFrame.cooldownStatus:GetRegions()}) do
      if string.find(region:GetName() or "", "Text$") and region:IsObjectType("FontString") then
        region:SetFont("Fonts\\FRIZQT__.TTF", 15)
        region:SetTextColor(.95, .95, .95)

        if rank ~= nil then
          -- TODO rank does not exist in _retail_
          region:SetText(name .. rank)
        else
          region:SetText(name)
        end

        break
      end
    end
  else
    mod.logger.LogWarn(me.tag, "Spell not found in this version of WoW")
  end
end
