--[[
  MIT License

  Copyright (c) 2025 Michael Wiesendanger

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

--[[
  Pure data-integrity validators for the SpellMap. Each function takes the
  spellMap (and optionally a groups table / accessor) and returns an array of
  human-readable failure strings. An empty array means the check passed.

  Validators must not call into mod.testLogger, mod.logger, or any WoW API.
  This keeps them runnable both in-game and under headless busted.
]]--

local mod = rgcw
local me = {}

mod.spellMapValidation = me

me.tag = "SpellMapValidation"

local function IsPrimary(entry)
  return type(entry) == "table" and type(entry.name) == "string"
end

--[[
  Verify every refId entry points at a primary entry in the same category.

  @param {table} spellMap

  @return {table} - Array of failure description strings (empty if all pass)
]]--
function me.ValidateRefIdsResolve(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if type(entry) == "table" and type(entry.refId) == "number" then
        local target = spells[entry.refId]

        if not IsPrimary(target) then
          table.insert(failures,
            string.format("%s/%s -> refId %s does not resolve to a primary entry",
              category, tostring(spellId), tostring(entry.refId)))
        end
      end
    end
  end

  return failures
end

--[[
  Verify every primary entry's allRanks list contains its own spellId.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidatePrimaryAllRanksContainsSelf(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) and type(entry.allRanks) == "table" then
        local found = false

        for _, rankId in ipairs(entry.allRanks) do
          if rankId == spellId then
            found = true

            break
          end
        end

        if not found then
          table.insert(failures,
            string.format("%s/%s ('%s') is missing from its own allRanks",
              category, tostring(spellId), entry.name))
        end
      end
    end
  end

  return failures
end

--[[
  Verify every spellId in a primary's allRanks list exists in the same category
  and is either the primary itself or a refId entry pointing back to it.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateAllRanksConsistent(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for primaryId, entry in pairs(spells) do
      if IsPrimary(entry) and type(entry.allRanks) == "table" then
        for _, rankId in ipairs(entry.allRanks) do
          local rankEntry = spells[rankId]

          if not rankEntry then
            table.insert(failures,
              string.format("%s/%s ('%s'): rank id %s missing from category",
                category, tostring(primaryId), entry.name, tostring(rankId)))
          elseif rankId ~= primaryId then
            if type(rankEntry.refId) ~= "number" or rankEntry.refId ~= primaryId then
              table.insert(failures,
                string.format("%s/%s ('%s'): rank id %s does not refId back to primary",
                  category, tostring(primaryId), entry.name, tostring(rankId)))
            end
          end
        end
      end
    end
  end

  return failures
end

--[[
  Verify no spellId is registered as a primary entry in more than one category.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateNoDuplicatePrimaryAcrossCategories(spellMap)
  local primaryToCategories = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) then
        if not primaryToCategories[spellId] then
          primaryToCategories[spellId] = {}
        end

        table.insert(primaryToCategories[spellId], category)
      end
    end
  end

  local failures = {}

  for spellId, categories in pairs(primaryToCategories) do
    if #categories > 1 then
      table.insert(failures,
        string.format("spellId %s is primary in: %s",
          tostring(spellId), table.concat(categories, ", ")))
    end
  end

  return failures
end

--[[
  Verify every member of every shared-cooldown group resolves to a primary,
  shares the same cooldown value within the group, and carries the matching
  sharedCooldownGroup field on its primary entry.

  @param {table} spellMap
  @param {table} groups - Map of groupName -> array of spellIds
  @param {function} getSpellById - Accessor (spellId) -> category, realSpellId, spell

  @return {table}
]]--
function me.ValidateSharedCooldownGroupsConsistent(spellMap, groups, getSpellById)
  local failures = {}

  if next(groups) == nil then
    return failures
  end

  for groupName, members in pairs(groups) do
    local expectedCooldown

    for _, memberSpellId in ipairs(members) do
      local _, _, found = getSpellById(memberSpellId)

      if not found then
        table.insert(failures,
          string.format("group '%s': member spellId %s not found in spellMap",
            groupName, tostring(memberSpellId)))
      else
        if expectedCooldown == nil then
          expectedCooldown = found.cooldown
        elseif found.cooldown ~= expectedCooldown then
          table.insert(failures,
            string.format("group '%s': member %s ('%s') cooldown %s differs from %s",
              groupName, tostring(memberSpellId), tostring(found.name),
              tostring(found.cooldown), tostring(expectedCooldown)))
        end

        local primary

        for _, spells in pairs(spellMap) do
          if IsPrimary(spells[memberSpellId]) then
            primary = spells[memberSpellId]

            break
          end
        end

        if primary and primary.sharedCooldownGroup ~= groupName then
          table.insert(failures,
            string.format("group '%s': member %s ('%s') has sharedCooldownGroup '%s'",
              groupName, tostring(memberSpellId), tostring(primary.name),
              tostring(primary.sharedCooldownGroup)))
        end
      end
    end
  end

  return failures
end
