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
mod.cooldownMenu = me

me.tag = "CooldownMenu"

--[[
  TODO description

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(category)

  mod.logger.LogError(me.tag, "Build Ui CooldownMenu")

  -- TODO need to prevent build menu over and over again slots that already exist should not be rebuilt

  local categoryScrollFrame = _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_SCROLL_FRAME]
  local categoryScrollFrameSlider = _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_SCROLL_FRAME_SLIDER]
  local categoryContentFrame = _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_CONTENT_FRAME]

  if categoryScrollFrame == nil then
    mod.logger.LogDebug(me.tag, "categoryScrollFrame did not exist - creating")
    mod.uiHelper.CreateCategoryScrollFrame(
      RGCW_CONSTANTS.ELEMENT_CATEGORY_SCROLL_FRAME,
      _G[RGCW_CONSTANTS.CATEGORIES[category].name]
    )
  end

  -- create contentFrame if it does not yet exist
  if categoryContentFrame == nil then
    mod.logger.LogDebug(me.tag, "categoryContentFrame did not exist - creating")
    mod.uiHelper.CreateCategoryContentFrame(
      RGCW_CONSTANTS.ELEMENT_CATEGORY_CONTENT_FRAME,
      _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_SCROLL_FRAME]
    )
  end

  -- create slider if it does not yet exist
  if categoryScrollFrameSlider == nil then
    mod.uiHelper.CreateCategoryScrollFrameSlider(
      RGCW_CONSTANTS.ELEMENT_CATEGORY_SCROLL_FRAME_SLIDER,
      _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_SCROLL_FRAME],
      _G[RGCW_CONSTANTS.CATEGORIES[category].name]
    )
  end

  -- TODO local
  cooldownList = mod.spellMap.GetAllForCategory(RGCW_CONSTANTS.CATEGORIES[category].categoryName)

  local position = 0

  for spellId, spellData in pairs(cooldownList) do
    local cooldownSpellFrame = _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_FRAME .. position]

    if cooldownSpellFrame == nil then
      cooldownSpellFrame = mod.uiHelper.CreateCooldownSpellFrame(
        RGCW_CONSTANTS.ELEMENT_CATEGORY_COOLDOWN_SPELL_FRAME,
        _G[RGCW_CONSTANTS.ELEMENT_CATEGORY_CONTENT_FRAME],
        position
      )
    end

    mod.uiHelper.ConfigureSpellFrame(
      cooldownSpellFrame,
      spellId,
      spellData
    )

    cooldownSpellFrame:Show()
    position = position + 1
  end
end

function me.cooldownMenuOnShow(self)
  mod.logger.LogError(me.tag, "OnShow: " .. self.value)
  me.BuildUi(self.value)
end
