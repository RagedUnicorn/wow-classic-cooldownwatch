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

-- luacheck: globals CreateFrame GetSpellInfo GetTime

-- Debug spell injector window. Lets the dev push spells into the cooldown queue
-- with the player as both source and target so the cooldown bar renders without
-- needing an enemy in combat.

local mod = rgcw
local me = {}
mod.debugInjectorWindow = me

me.tag = "DebugInjectorWindow"

local CATEGORY_BUTTON_HEIGHT = 22
local SPELL_ROW_HEIGHT = 32
local SPELL_ROW_PADDING = 4

local spellRows = {}
local selectedCategory

--[[
  Build the vertical stack of category buttons on the left column.
]]--
local function BuildCategoryButtons()
  local column = _G[RGCW_TEST_CONSTANTS.ELEMENT_DEBUG_INJECTOR_WINDOW_CATEGORY_COLUMN]

  if not column then return end

  for i, category in ipairs(mod.categories.GetCategories()) do
    local button = CreateFrame("Button", nil, column, "UIPanelButtonTemplate")
    button:SetSize(110, CATEGORY_BUTTON_HEIGHT)
    button:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -((i - 1) * (CATEGORY_BUTTON_HEIGHT + 2)))
    button:SetText(category.categoryName)
    button:SetScript("OnClick", function()
      me.SelectCategory(category.categoryName)
    end)
  end
end

--[[
  Hide and forget every spell row from the previous category.
]]--
local function ClearSpellRows()
  for _, row in ipairs(spellRows) do
    row:Hide()
    row:SetParent(nil)
  end

  spellRows = {}
end

--[[
  Create a single spell row with icon, name, and Inject button.

  @param {Frame} parent
  @param {number} index    1-based row position
  @param {string} category
  @param {table}  spell    entry from spellMapHelper.GetAllForCategory

  @return {Frame}
]]--
local function CreateSpellRow(parent, index, category, spell)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(parent:GetWidth(), SPELL_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * (SPELL_ROW_HEIGHT + SPELL_ROW_PADDING)))

  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(SPELL_ROW_HEIGHT, SPELL_ROW_HEIGHT)
  icon:SetPoint("LEFT", row, "LEFT", 0, 0)
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  local _, _, iconTexture = GetSpellInfo(spell.spellId)

  if iconTexture then
    icon:SetTexture(iconTexture)
  end

  local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  nameText:SetText(string.format("%s  (%ds)", spell.name, spell.cooldown or 0))
  nameText:SetJustifyH("LEFT")

  local injectButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  injectButton:SetSize(80, 22)
  injectButton:SetPoint("RIGHT", row, "RIGHT", -5, 0)
  injectButton:SetText("Inject")
  injectButton:SetScript("OnClick", function()
    me.InjectSpell(category, spell.spellId)
  end)

  return row
end

--[[
  Inject a spell into the cooldown queue using the player as source.
  Routed through CombatLog.TrackCooldown so shared-cooldown fan-out fires.

  @param {string} category
  @param {number} spellId
]]--
function me.InjectSpell(category, spellId)
  local _, _, spell = mod.spellMapHelper.GetSpellById(spellId)

  if not spell then
    mod.logger.LogError(me.tag, "GetSpellById returned nil for spellId " .. tostring(spellId))
    return
  end

  local caster = mod.testHelper.GetTestCasterData()

  if not caster then return end

  mod.combatLog.TrackCooldown(caster.guid, caster.name, spell, GetTime(), category)
end

--[[
  Repaint the spell list for a category.

  @param {string} categoryName
]]--
function me.SelectCategory(categoryName)
  selectedCategory = categoryName

  local scrollChild = _G[RGCW_TEST_CONSTANTS.ELEMENT_DEBUG_INJECTOR_WINDOW_SPELL_SCROLL_CHILD]

  if not scrollChild then return end

  ClearSpellRows()

  local spells = mod.spellMapHelper.GetAllForCategory(categoryName) or {}

  for index, spell in ipairs(spells) do
    table.insert(spellRows, CreateSpellRow(scrollChild, index, categoryName, spell))
  end

  local totalHeight = math.max(#spells * (SPELL_ROW_HEIGHT + SPELL_ROW_PADDING), 1)
  scrollChild:SetHeight(totalHeight)

  local scrollFrame = _G[RGCW_TEST_CONSTANTS.ELEMENT_DEBUG_INJECTOR_WINDOW_SPELL_SCROLL_FRAME]

  if scrollFrame then
    scrollFrame:SetVerticalScroll(0)
  end
end

--[[
  Initialize the debug injector window. Called from Core after addon load.
]]--
function me.Initialize()
  BuildCategoryButtons()

  local categories = mod.categories.GetCategories()

  if categories[1] then
    selectedCategory = categories[1].categoryName
  end

  mod.logger.LogInfo(me.tag, "Debug injector window initialized")
end

--[[
  Toggle window visibility. Refreshes the spell list and prints the targeting
  hint when opening so the dev knows to /target self.
]]--
function me.Toggle()
  local window = _G[RGCW_TEST_CONSTANTS.ELEMENT_DEBUG_INJECTOR_WINDOW]

  if not window then
    mod.logger.LogError(me.tag, "Debug injector window not found")
    return
  end

  if window:IsShown() then
    window:Hide()
    return
  end

  window:Show()

  if selectedCategory then
    me.SelectCategory(selectedCategory)
  end

  mod.testHelper.ShowTargetingHint()
end
