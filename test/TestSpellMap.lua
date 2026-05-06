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

local mod = rgcw
local me = {}

mod.testSpellMap = me

me.tag = "TestSpellMap"

--[[
  Determine whether a spellMap entry is a primary entry (has its own data) or
  a refId pointer entry (rank alias to a primary).

  @param {table} entry

  @return {boolean}
]]--
local function IsPrimary(entry)
  return type(entry) == "table" and type(entry.name) == "string"
end

--[[
  Test that every refId entry points at a primary entry in the same category.
]]--
function me.TestRefIdsResolve()
  mod.testLogger.StartTest("TestRefIdsResolve")

  local spellMap = mod.spellMap.GetSpellMap()
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

  if #failures == 0 then
    mod.testLogger.EndTest("TestRefIdsResolve", true, "All refIds resolve to primary entries")
  else
    mod.testLogger.LogError("TestRefIdsResolve", "Unresolved refIds", failures)
    mod.testLogger.EndTest("TestRefIdsResolve", false,
      string.format("%d unresolved refId(s)", #failures))
  end
end

--[[
  Test that every primary entry's allRanks list (when present) contains its own
  spellId. Without this the primary itself would not be tracked as one of its
  own ranks.
]]--
function me.TestPrimaryAllRanksContainsSelf()
  mod.testLogger.StartTest("TestPrimaryAllRanksContainsSelf")

  local spellMap = mod.spellMap.GetSpellMap()
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

  if #failures == 0 then
    mod.testLogger.EndTest("TestPrimaryAllRanksContainsSelf", true,
      "All primary entries appear in their own allRanks")
  else
    mod.testLogger.LogError("TestPrimaryAllRanksContainsSelf", "Missing self-references", failures)
    mod.testLogger.EndTest("TestPrimaryAllRanksContainsSelf", false,
      string.format("%d primary(ies) missing from their own allRanks", #failures))
  end
end

--[[
  Test that every spellId in a primary's allRanks list exists in the same
  category and is either the primary itself or a refId entry pointing back to
  the primary.
]]--
function me.TestAllRanksConsistent()
  mod.testLogger.StartTest("TestAllRanksConsistent")

  local spellMap = mod.spellMap.GetSpellMap()
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

  if #failures == 0 then
    mod.testLogger.EndTest("TestAllRanksConsistent", true,
      "All allRanks entries are consistent with their primary")
  else
    mod.testLogger.LogError("TestAllRanksConsistent", "Inconsistent allRanks", failures)
    mod.testLogger.EndTest("TestAllRanksConsistent", false,
      string.format("%d inconsistent allRanks entry(ies)", #failures))
  end
end

--[[
  Test that no spellId appears as a primary entry in more than one category.
  refId entries are allowed to repeat across categories because they are aliases.
]]--
function me.TestNoDuplicatePrimaryAcrossCategories()
  mod.testLogger.StartTest("TestNoDuplicatePrimaryAcrossCategories")

  local spellMap = mod.spellMap.GetSpellMap()
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

  if #failures == 0 then
    mod.testLogger.EndTest("TestNoDuplicatePrimaryAcrossCategories", true,
      "No primary spellId appears in more than one category")
  else
    mod.testLogger.LogError("TestNoDuplicatePrimaryAcrossCategories",
      "Duplicate primaries", failures)
    mod.testLogger.EndTest("TestNoDuplicatePrimaryAcrossCategories", false,
      string.format("%d duplicate primary spellId(s)", #failures))
  end
end

--[[
  Test that every member of a shared-cooldown group resolves to a primary entry,
  shares the same cooldown value, and carries the matching sharedCooldownGroup
  field.
]]--
function me.TestSharedCooldownGroupsConsistent()
  mod.testLogger.StartTest("TestSharedCooldownGroupsConsistent")

  local groups = mod.spellMap.GetAllSharedCooldownGroups()

  if next(groups) == nil then
    mod.testLogger.EndTest("TestSharedCooldownGroupsConsistent", true,
      "No shared-cooldown groups defined - skipped")
    return
  end

  local spellMap = mod.spellMap.GetSpellMap()
  local failures = {}

  for groupName, members in pairs(groups) do
    local expectedCooldown

    for _, memberSpellId in ipairs(members) do
      local _, _, found = mod.spellMapHelper.GetSpellById(memberSpellId)

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

  if #failures == 0 then
    mod.testLogger.EndTest("TestSharedCooldownGroupsConsistent", true,
      "All shared-cooldown groups are internally consistent")
  else
    mod.testLogger.LogError("TestSharedCooldownGroupsConsistent",
      "Inconsistent shared-cooldown groups", failures)
    mod.testLogger.EndTest("TestSharedCooldownGroupsConsistent", false,
      string.format("%d shared-cooldown inconsistency(ies)", #failures))
  end
end

--[[
  Run all spellMap data-integrity tests.
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("SpellMap", "=== Running SpellMap Tests ===")

  me.TestRefIdsResolve()
  me.TestPrimaryAllRanksContainsSelf()
  me.TestAllRanksConsistent()
  me.TestNoDuplicatePrimaryAcrossCategories()
  me.TestSharedCooldownGroupsConsistent()

  mod.testLogger.LogInfo("SpellMap", "=== SpellMap Tests Complete ===")
end
