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
  local spellContentFrame = me.CreateCategoryMenuContentFrame(
    self,
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_CONTENT_FRAME .. self.categoryName,
    {"TOPLEFT", self, 5, -7}
  )

  local category = {
    name = self.categoryName,
    spellContentFrame = spellContentFrame
  }

  table.insert(categoriesBuilt, category)
end

--[[
  @param {table} self
  @param {string} contentFrameName
  @param {table} position

  @return {table}
]]--
function me.CreateCategoryMenuContentFrame(self, contentFrameName, position)
  local contentFrame = CreateFrame("Frame", contentFrameName, self, "BackdropTemplate")

  contentFrame:SetPoint(unpack(position))
  contentFrame:SetBackdropColor(1, 0.37, 0.5, .7)
  contentFrame:SetWidth(RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_WIDTH)
  contentFrame:SetHeight(RGCW_CONSTANTS.SPELL_LIST_CONTENT_FRAME_HEIGHT)

  return contentFrame
end

function me.ActivateCooldownMenu()
  local category = me.GetCategoryContainerReference(categoryName)

  mod.cooldownMenu.InitCooldownMenu(category.spellContentFrame, categoryName)
end
