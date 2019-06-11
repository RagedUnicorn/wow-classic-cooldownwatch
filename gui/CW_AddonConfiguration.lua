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
  local cooldownWatch = {}
  cooldownWatch.panel = CreateFrame("Frame", RGCW_CONSTANTS.ELEMENT_ADDON_PANEL, UIParent)

  -- Register in the Interface Addon Options GUI
  cooldownWatch.panel.name = rgcw.L["addon_name"]
  -- Add the panel to the Interface Options
  InterfaceOptions_AddCategory(cooldownWatch.panel)

  -- Create subcategory
  cooldownWatch.generalMenu = CreateFrame("Frame", RGCW_CONSTANTS.ELEMENT_GENERAL_SUB_OPTION_FRAME, cooldownWatch.panel)
  cooldownWatch.generalMenu.name = rgcw.L["general_category_name"]
  cooldownWatch.generalMenu.parent = cooldownWatch.panel.name
  -- Add the child to the Interface Options
  InterfaceOptions_AddCategory(cooldownWatch.generalMenu)

  --[[
    For development purpose the InterfaceOptionsFrame_OpenToCategory function can be used to directly
    open a specific category. Because of a blizzard bug this usually has to be called twice to actually work.

    Example:

    InterfaceOptionsFrame_OpenToCategory(cooldownWatch.generalMenu)
    InterfaceOptionsFrame_OpenToCategory(cooldownWatch.generalMenu)

    Note: The behavior with how events fire might change quite a bit when using the above debug method.
    Because of this it is important that the "normal" manuall way of opening the menu is tested as well.
  ]]--

  me.BuildAboutContent(cooldownWatch.panel)
  -- mod.generalMenu.BuildUi(cooldownWatch.generalMenu)
end

--[[
  Main tab for addon - show about content

  @param {table} frame
]]--
function me.BuildAboutContent(frame)
  local ragedUnicornLogo  = frame:CreateTexture(RGCW_CONSTANTS.ELEMENT_ABOUT_LOGO, "ARTWORK")
  ragedUnicornLogo:SetPoint("TOP", 0, -20)
  ragedUnicornLogo:SetSize(256, 256)
  ragedUnicornLogo:SetTexture([[Interface\AddOns\EnemyCastBar\assets\UI-Logo-RagedUnicorn]])

  local authorFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_ABOUT_AUTHOR_FONT_STRING, "OVERLAY")
  authorFontString:SetFont("Fonts\\FRIZQT__.TTF", 15)
  authorFontString:SetPoint("TOP", 0, -300)
  authorFontString:SetSize(frame:GetWidth(), 20)
  authorFontString:SetText(rgcw.L["author"])

  local emailFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_ABOUT_EMAIL_FONT_STRING, "OVERLAY")
  emailFontString:SetFont("Fonts\\FRIZQT__.TTF", 15)
  emailFontString:SetPoint("TOP", 0, -320)
  emailFontString:SetSize(frame:GetWidth(), 20)
  emailFontString:SetText(rgcw.L["email"])

  local versionFontString = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_ABOUT_VERSION_FONT_STRING, "OVERLAY")
  versionFontString:SetFont("Fonts\\FRIZQT__.TTF", 15)
  versionFontString:SetPoint("TOP", 0, -340)
  versionFontString:SetSize(frame:GetWidth(), 20)
  versionFontString:SetText(rgcw.L["version"])

  local issuesSimpleHtml = frame:CreateFontString(RGCW_CONSTANTS.ELEMENT_ABOUT_ISSUES_FONT_STRING, "OVERLAY")
  issuesSimpleHtml:SetFont("Fonts\\FRIZQT__.TTF", 15)
  issuesSimpleHtml:SetPoint("TOP", 0, -360)
  issuesSimpleHtml:SetSize(frame:GetWidth(), 20)
  issuesSimpleHtml:SetText(rgcw.L["issues"])
end
