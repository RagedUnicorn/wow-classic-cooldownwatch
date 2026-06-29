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

local mod = rgcw
local me = {}

mod.categories = me

me.tag = "Categories"

--[[
  Ordered catalog of cooldown categories surfaced in the configuration UI and the
  debug injector. Each entry binds a catalog identity (`categoryName`, matching a
  key in SpellMap) to its UI naming (`localizationKey`, `name`).

  The display order is the array order. Add a new category here when porting a new
  class / group in — see CLAUDE.md "Adding new spells or a new category".

  [{number}] = {
    -- catalog identity, matches a SpellMap top-level key (e.g. "priest")
    ["categoryName"] = {string},
    -- localization lookup key for the UI label (rgcw.L[localizationKey])
    ["localizationKey"] = {string},
    -- frame name for the Blizzard options subcategory panel
    ["name"] = {string}
  }
]]--
local categories = {
  [1] = {
    ["categoryName"] = "priest",
    ["localizationKey"] = "category_priest",
    ["name"] = "CW_PriestOptionsFrame"
  },
  [2] = {
    ["categoryName"] = "rogue",
    ["localizationKey"] = "category_rogue",
    ["name"] = "CW_RogueOptionsFrame"
  },
  [3] = {
    ["categoryName"] = "mage",
    ["localizationKey"] = "category_mage",
    ["name"] = "CW_MageOptionsFrame"
  },
  [4] = {
    ["categoryName"] = "hunter",
    ["localizationKey"] = "category_hunter",
    ["name"] = "CW_HunterOptionsFrame"
  },
  [5] = {
    ["categoryName"] = "warlock",
    ["localizationKey"] = "category_warlock",
    ["name"] = "CW_WarlockOptionsFrame"
  },
  [6] = {
    ["categoryName"] = "paladin",
    ["localizationKey"] = "category_paladin",
    ["name"] = "CW_PaladinOptionsFrame"
  },
  [7] = {
    ["categoryName"] = "druid",
    ["localizationKey"] = "category_druid",
    ["name"] = "CW_DruidOptionsFrame"
  },
  [8] = {
    ["categoryName"] = "shaman",
    ["localizationKey"] = "category_shaman",
    ["name"] = "CW_ShamanOptionsFrame"
  },
  [9] = {
    ["categoryName"] = "warrior",
    ["localizationKey"] = "category_warrior",
    ["name"] = "CW_WarriorOptionsFrame"
  },
  [10] = {
    ["categoryName"] = "racials",
    ["localizationKey"] = "category_racials",
    ["name"] = "CW_RacialsOptionsFrame"
  },
  [11] = {
    ["categoryName"] = "misc",
    ["localizationKey"] = "category_misc",
    ["name"] = "CW_ItemsOptionsFrame"
  }
}

--[[
  @return {table}
    Cloned ordered array of category descriptors. Cloned so callers cannot mutate
    the canonical list.
]]--
function me.GetCategories()
  return mod.common.Clone(categories)
end
