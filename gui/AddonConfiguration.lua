--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals CreateFrame Settings

local mod = rgcw
local me = {}

mod.addonConfiguration = me

me.tag = "AddonConfiguration"

--[[
  Holds the id reference to the main category of the addon. Can be used with Settings.OpenToCategory({number})
  {number}
]]--
local mainCategoryId

--[[
  Numeric ids of every registered category, keyed by a stable, locale independent key:
  "main", "general", "proximity", "friendly", "profile" and one entry per catalog category (its categoryName, e.g.
  "priest", "items"). Settings.OpenToCategory takes the numeric id only - passing a category
  NAME errors in Classic Era ("outside of expected range") because the name is handed
  straight to C_SettingsUtil.OpenSettingsPanel. Callers therefore resolve through
  me.GetCategoryId instead of looking a category up by its displayed name.
  {table}
]]--
local categoryIds = {}

--[[
  Retrieve a reference to the main category of the addon

  @return {table | nil}
    The main category of the addon or nil if not found
]]--
function me.GetMainCategory()
  if mainCategoryId ~= nil then
    return Settings.GetCategory(mainCategoryId)
  end

  return nil
end

--[[
  Retrieve the numeric id of a registered category for use with Settings.OpenToCategory

  @param {string} key
    "main", "general", "proximity", "friendly", "profile" or a catalog categoryName

  @return {number | nil}
    The category id or nil if no category is registered under that key
]]--
function me.GetCategoryId(key)
  return categoryIds[key]
end

--[[
  Create addon configuration menu(s)
]]--
function me.SetupAddonConfiguration()
  -- initialize the main addon category
  local category, menu = me.BuildCategory(RGCW_CONSTANTS.ELEMENT_ADDON_PANEL, nil, rgcw.L["addon_name"])
  -- add about content into main category
  mod.aboutContent.BuildAboutContent(menu)

  local generalCategory = me.BuildCategory(
    RGCW_CONSTANTS.ELEMENT_GENERAL_SUB_OPTION_FRAME,
    category,
    rgcw.L["options_category_name"],
    mod.generalMenu.BuildUi
  )
  categoryIds.general = generalCategory.ID

  local proximityCategory = me.BuildCategory(
    RGCW_CONSTANTS.ELEMENT_PROXIMITY_SUB_OPTION_FRAME,
    category,
    rgcw.L["proximity_category_name"],
    mod.proximityMenu.BuildUi
  )
  categoryIds.proximity = proximityCategory.ID

  local friendlyCategory = me.BuildCategory(
    RGCW_CONSTANTS.ELEMENT_FRIENDLY_SUB_OPTION_FRAME,
    category,
    rgcw.L["friendly_category_name"],
    mod.friendlyCooldownMenu.BuildUi
  )
  categoryIds.friendly = friendlyCategory.ID

  local profileCategory = me.BuildCategory(
    RGCW_CONSTANTS.ELEMENT_PROFILE_SUB_OPTION_FRAME,
    category,
    rgcw.L["profile_category_name"],
    mod.profileMenu.BuildUi
  )
  categoryIds.profile = profileCategory.ID

  me.BuildCooldownCategories(category)
end

--[[
  @param {string} frameName
  @param {table} parent
  @param {string} panelText
  @param {function} onShowCallback

  @return {table}, {table}
    category, menu
]]--
function me.BuildCategory(frameName, parent, panelText, onShowCallback)
  local category
  local menu

  if parent == nil then
    menu = CreateFrame("Frame", frameName)
    category = Settings.RegisterCanvasLayoutCategory(menu, panelText)
    mainCategoryId = category.ID
    categoryIds.main = category.ID
    Settings.RegisterAddOnCategory(category)
  else
    menu = CreateFrame("Frame", frameName, nil)
    menu.parent = parent.name
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parent, menu, frameName)
    subcategory.name = panelText
    category = subcategory
    Settings.RegisterAddOnCategory(subcategory)
  end

  if onShowCallback ~= nil then
    menu:SetScript("OnShow", onShowCallback)
  end

  --[[
   Important to hide panel initially. Interface addon options will take care of showing the menu.
   If this is not done OnShow callbacks will not be invoked correctly.
  ]]--
  menu:Hide()

  return category, menu
end

--[[
  Build configuration panels for all categories

  @param {table} configurationPanel
]]--
function me.BuildCooldownCategories(parent)
  for index, category in ipairs(mod.categories.GetCategories()) do
    local menu = CreateFrame("Frame", category.name, nil)
    menu.parent = parent.name
    menu.value = index
    menu.categoryName = category.categoryName
    -- carried along so the panel can title itself without looking the category up again
    menu.localizationKey = category.localizationKey

    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parent, menu, category.name)
    subcategory.name = rgcw.L[category.localizationKey]
    -- keyed by the catalog categoryName so a caller never has to know the frame or panel title
    categoryIds[category.categoryName] = subcategory.ID

    Settings.RegisterAddOnCategory(subcategory)
    menu:SetScript("OnShow", mod.categoryMenu.MenuOnShow)

    --[[
     Important to hide panel initially. Interface addon options will take care of showing the menu.
     If this is not done OnShow callbacks will not be invoked correctly.
    ]]--
    menu:Hide()
  end
end

--[[
  Open the Blizzard addon configurations panel for the addon
]]--
function me.OpenMainCategory()
  if mainCategoryId ~= nil then
    Settings.OpenToCategory(mainCategoryId)
  end
end
