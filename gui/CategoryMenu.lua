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
  Identifiers for the two caster-side tabs on every category panel. Unlike the PVPWarn
  precedent the tabs do not switch content frames - both sides render the same spell
  list - they switch which side's stores the rows read and write
  (see CooldownMenu.SetFriendlySideActive).
]]--
local enemyTab = 1
local friendlyTab = 2
--[[
  Reference to the currently active tab

  One of enemyTab(1) or friendlyTab(2)
]]--
local activeTab
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

  me.ResetNavigation()
  me.ActivateTab(enemyTab) -- the enemy side is the default on every visit
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

  --[[ the tabs start below the panel title, which sits at -16 and is about 19px tall ]]--
  local enemyTabButton = me.CreateTabButton(
    self,
    RGCW_CONSTANTS.ELEMENT_CATEGORY_TAB_BUTTON .. enemyTab,
    {"TOPLEFT", 5, -44},
    rgcw.L["tab_button_enemy"],
    enemyTab
  )

  local friendlyTabButton = me.CreateTabButton(
    self,
    RGCW_CONSTANTS.ELEMENT_CATEGORY_TAB_BUTTON .. friendlyTab,
    {"LEFT", enemyTabButton, "RIGHT", 5, 0},
    rgcw.L["tab_button_friendly"],
    friendlyTab
  )

  --[[ the list sits directly below the 37px tall tabs so the active tab art connects to it ]]--
  local spellContentFrame = me.CreateCategoryMenuContentFrame(
    self,
    RGCW_CONSTANTS.ELEMENT_SPELL_LIST_CONTENT_FRAME .. self.categoryName,
    {"TOPLEFT", self, 5, -81}
  )

  local category = {
    name = self.categoryName,
    spellContentFrame = spellContentFrame,
    enemyTabButton = enemyTabButton,
    friendlyTabButton = friendlyTabButton
  }

  table.insert(categoriesBuilt, category)
end

--[[
  @param {table} parentFrame
  @param {string} tabButtonName
  @param {table} position
  @param {string} text
  @param {number} id

  @return {table}
]]--
function me.CreateTabButton(parentFrame, tabButtonName, position, text, id)
  local tabButton = CreateFrame("Button", tabButtonName, parentFrame, "MinimalTabTemplate")

  tabButton.id = id
  tabButton:SetPoint(unpack(position))
  --[[ the template reads its text from an xml keyvalue which CreateFrame cannot pass -
       assign it after the fact and redo the mixin's width calculation ]]--
  tabButton.Text:SetText(text)
  tabButton:SetWidth(tabButton.Text:GetStringWidth() + 40)
  tabButton:SetScript("OnClick", me.TabNavigationButtonOnClick)

  return tabButton
end

--[[
  @param {table} self
]]--
function me.TabNavigationButtonOnClick(self)
  if activeTab == self.id then
    mod.logger.LogDebug(me.tag, "Tab is already active - skipping...")

    return
  end

  me.ResetNavigation()
  me.ActivateTab(self.id)
end

--[[
  Reset navigation - deselect both side tabs. There is no content frame to hide here:
  both sides share one spell list, only the stores behind it differ.
]]--
function me.ResetNavigation()
  mod.logger.LogDebug(me.tag, "Resetting navigation")

  local category = me.GetCategoryContainerReference(categoryName)

  category.enemyTabButton:SetSelected(false)
  category.friendlyTabButton:SetSelected(false)

  activeTab = nil
end

--[[
  Activate a caster-side tab: mark its button selected, point the spell list at that
  side's stores and rebuild the list so every row re-reads its state from them. Called
  by the tab buttons and initially by MenuOnShow, which defaults to the enemy tab.

  @param {number} position enemyTab or friendlyTab
]]--
function me.ActivateTab(position)
  mod.logger.LogDebug(me.tag, "Activating tab position " .. position)

  local category = me.GetCategoryContainerReference(categoryName)

  if position == enemyTab then
    category.enemyTabButton:SetSelected(true)
  elseif position == friendlyTab then
    category.friendlyTabButton:SetSelected(true)
  else
    return
  end

  activeTab = position

  mod.cooldownMenu.SetFriendlySideActive(position == friendlyTab)
  me.ActivateCooldownMenu()
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
