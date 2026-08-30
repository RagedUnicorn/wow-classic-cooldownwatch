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

mod.profile = me

me.tag = "Profile"

--[[
  Default tracking profile: one empty bucket per category, keyed by categoryName.
  Derived from the category catalog (code/Categories.lua) at load time so it can
  never drift from the canonical list — adding a category there propagates here
  automatically.

  [{string}] = {
    -- e.g. paladin, racials etc
    [{number}] = {boolean}
    -- true if the cooldown is enabled
    -- false if the cooldown is disabled
  }
]]--
local defaultProfile = {}

for _, category in ipairs(mod.categories.GetCategories()) do
  defaultProfile[category.categoryName] = {}
end

function me.GetDefaultProfile()
  return mod.common.Clone(defaultProfile)
end

--[[
  Default cooldown-override state: one empty bucket per category, keyed by
  categoryName. Shares the tracking profile's skeleton (both are category-keyed
  maps of per-spell entries) so a category added to the catalog propagates to
  both defaults automatically.

  [{string}] = {
    -- e.g. paladin, racials etc
    [{number}] = {table}
    -- per-spell override entry, e.g. { worstCase = true }
  }
]]--
function me.GetDefaultCooldownOverrides()
  return mod.common.Clone(defaultProfile)
end

--[[
  Curated default-enabled sets, assembled per branch from the
  code/profile/base/ slices plus the matching code/profile/overlay/ diff and
  keyed by active branch ("classic" / "sod" / "tbc"). Built lazily on first
  IsDefaultEnabled call - never at load time, because this file loads before
  the spellmap block (headless Bootstrap included) and the branch decision
  belongs to mod.spellMap.GetActiveBranch.
]]--
local defaultSetsByBranch = {}

--[[
  Build the curated default-enabled sets for a branch: the base slice arrays
  turned into per-category id sets, with the branch overlay's remove ops
  applied before its add ops. Pure and cache-free; exposed (rather than kept
  local to EnsureDefaultSets) for the per-branch validation specs, which
  build all three branches without touching the cache.

  @param {string} branch
    "classic" | "sod" | "tbc"

  @return {table}
    Table of categoryName -> { [primarySpellId] = true }
]]--
function me.BuildDefaultEnabledSets(branch)
  local sets = {}

  for categoryName, spellIds in pairs(mod.profileBaseClasses) do
    local set = {}

    for _, spellId in ipairs(spellIds) do
      set[spellId] = true
    end

    sets[categoryName] = set
  end

  local overlay

  if branch == "sod" then
    overlay = mod.profileOverlaySod.GetOverlay()
  elseif branch == "tbc" then
    overlay = mod.profileOverlayTbc.GetOverlay()
  end

  if overlay then
    for categoryName, ops in pairs(overlay) do
      local set = sets[categoryName] or {}
      sets[categoryName] = set

      if ops.remove then
        for _, spellId in ipairs(ops.remove) do
          set[spellId] = nil
        end
      end

      if ops.add then
        for _, spellId in ipairs(ops.add) do
          set[spellId] = true
        end
      end
    end
  end

  return sets
end

--[[
  Get the curated default-enabled sets for the active branch, building and
  caching them on first access.

  @return {table}
    Table of categoryName -> { [primarySpellId] = true }
]]--
local function EnsureDefaultSets()
  local branch = mod.spellMap.GetActiveBranch()

  if defaultSetsByBranch[branch] == nil then
    defaultSetsByBranch[branch] = me.BuildDefaultEnabledSets(branch)
  end

  return defaultSetsByBranch[branch]
end

--[[
  Whether a spell is in the curated default-enabled set of the active
  branch - the tracked state that applies while the player never configured
  the spell (the never-configured default fed into
  Configuration.GetCooldownConfigurationState; an explicit player toggle
  always wins in both directions). O(1) - sits on the combat-log hot path.

  @param {string} categoryName
  @param {number} spellId
    A PRIMARY spellId - the enabled state is keyed by primaries

  @return {boolean}
    true  - the spell tracks by default
    false - the spell is opt-in
]]--
function me.IsDefaultEnabled(categoryName, spellId)
  local set = EnsureDefaultSets()[categoryName]

  return set ~= nil and set[spellId] == true
end
