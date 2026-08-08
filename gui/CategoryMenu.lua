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

-- luacheck: globals CreateFrame

local mod = rgcw
local me = {}

mod.categoryMenu = me

me.tag = "CategoryMenu"

--[[
  Currently active category
]]--
local categoryName
--[[
  Track whether the tab containers for a certain category were already built and store all relevant ui
  elements for the category
]]--
local categoriesBuilt = {}

--[[
  Build or update (if already built) the category menus for configuring spells

  @param {table} self
    Reference to the addon configuration frame to attach to
]]--
function me.MenuOnShow(self)
  categoryName = self.categoryName

  if not me.IsCategoryContainerAlreadyBuilt(self.categoryName) then
    mod.logger.LogInfo(me.tag, "Category not built yet - building " .. self.categoryName)
    me.CreateCategoryMenu(self)
  end

  me.ActivateCooldownMenu()
end

--[[
  @param {string} category

  @return {boolean}
    true - if the category container was already built
    false - if the category container was not yet built
 --]]
function me.IsCategoryContainerAlreadyBuilt(category)
  for _, value in ipairs(categoriesBuilt) do
    if value.name == category then
      return true
    end
  end

  return false
end

--[[
  @param {string} category

  @return {table | nil}
    The category container reference or nil if not found
]]--
function me.GetCategoryContainerReference(category)
  for _, categoryReference in ipairs(categoriesBuilt) do
    if categoryReference.name == category then
      return categoryReference
    end
  end

  return nil
end

--[[
  Create the initial elements for the category menu. This function should only run once for each category.
  If the user navigates back to a category that was already built the function will not run again.
]]--
function me.CreateCategoryMenu(self)
  mod.guiHelper.CreatePanelTitle(
    self,
    RGCW_CONSTANTS.ELEMENT_CATEGORY_TITLE .. self.categoryName,
    rgcw.L[self.localizationKey]
  )

  --[[ the list starts below the panel title, which sits at -16 and is about 19px tall ]]--
  local spellContentFrame = me.CreateCategoryMenuContentFrame(
    self,
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_CONTENT_FRAME .. self.categoryName,
    {"TOPLEFT", self, 5, -46}
  )

  local category = {
    name = self.categoryName,
    spellContentFrame = spellContentFrame
  }

  table.insert(categoriesBuilt, category)
end

--[[
  Create the content frame that hosts a category's spell list. The frame stretches to the
  settings canvas it sits on instead of using a fixed box - the canvas size comes from the
  SettingsPanel and varies with resolution and ui scale, so a hardcoded size either overflows
  the panel or leaves a dead strip below and right of the list.

  @param {table} self
  @param {string} contentFrameName
  @param {table} position
    An object containing configuration parameters for a SetPoint function call. Defines the
    top left corner of the frame - the bottom right one always tracks the canvas

  @return {table}
]]--
function me.CreateCategoryMenuContentFrame(self, contentFrameName, position)
  local contentFrame = CreateFrame("Frame", contentFrameName, self)

  contentFrame:SetPoint(unpack(position))
  contentFrame:SetPoint(
    "BOTTOMRIGHT",
    self,
    "BOTTOMRIGHT",
    RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_INSET_RIGHT * -1,
    RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_INSET_BOTTOM
  )

  return contentFrame
end

function me.ActivateCooldownMenu()
  local category = me.GetCategoryContainerReference(categoryName)

  mod.cooldownMenu.InitCooldownMenu(category.spellContentFrame, categoryName)
end
