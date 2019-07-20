--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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

local mod = rgcw
local me = {}
mod.addonConfiguration = me

me.tag = "AddonConfiguration"

--[[
  Create addon configuration menu(s)
]]--
function me.SetupAddonConfiguration()
  local configurationPanel = CreateFrame("Frame", RGCW_CONSTANTS.ELEMENT_ADDON_PANEL, UIParent)

  -- Register in the Interface Addon Options GUI
  configurationPanel.name = rgcw.L["addon_name"]
  -- Add the panel to the Interface Options
  InterfaceOptions_AddCategory(configurationPanel)

  -- Create subcategory
  local generalMenu = CreateFrame("Frame", RGCW_CONSTANTS.ELEMENT_GENERAL_SUB_OPTION_FRAME, configurationPanel)
  generalMenu.name = rgcw.L["general_category_name"]
  generalMenu.parent = configurationPanel
  -- Add the child to the Interface Options
  InterfaceOptions_AddCategory(generalMenu)

  configurationPanel:Hide()

  --[[
    For development purpose the InterfaceOptionsFrame_OpenToCategory function can be used to directly
    open a specific category. Because of a blizzard bug this usually has to be called twice to actually work.

    Example:

    InterfaceOptionsFrame_OpenToCategory(generalMenu)
    InterfaceOptionsFrame_OpenToCategory(generalMenu)

    Note: The behavior with how events fire might change quite a bit when using the above debug method.
    Because of this it is important that the "normal" manuall way of opening the menu is tested as well.
  ]]--
  mod.aboutContent.BuildAboutContent(configurationPanel)
  -- mod.generalMenu.BuildUi(generalMenu)
  me.BuildSubCategories(configurationPanel)
end
--[[
  @param {table} configurationPanel
]]--
function me.BuildSubCategories(configurationPanel)
  for i = 1, table.getn(RGCW_CONSTANTS.CATEGORIES) do
    -- Create subcategory
    local menu = CreateFrame("Frame", RGCW_CONSTANTS.CATEGORIES[i].name, configurationPanel)
    menu.name = rgcw.L[RGCW_CONSTANTS.CATEGORIES[i].localizationKey]
    menu.parent = configurationPanel
    -- Add the child to the Interface Options
    InterfaceOptions_AddCategory(menu)
  end
end

--[[
  Open the Blizzard addon configurations panel for the addon
]]--
function me.OpenAddonPanel()
  -- Because of a blizzard bug this usually has to be called twice to actually work
  InterfaceOptionsFrame_OpenToCategory(_G[RGCW_CONSTANTS.ELEMENT_ADDON_PANEL])
  InterfaceOptionsFrame_OpenToCategory(_G[RGCW_CONSTANTS.ELEMENT_ADDON_PANEL])
end
