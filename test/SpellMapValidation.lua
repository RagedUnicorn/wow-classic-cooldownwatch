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

local GetItemIdFailure

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
  Verify every allRanks element is a structured entry: a table carrying a
  positive integer spellId and a type that is one of the known spell type
  constants (SPELL_TYPE_BASE / SPELL_TYPE_SOD / SPELL_TYPE_TBC). A bare-number
  rank entry (the pre-structured shape) or an unknown type would break the
  per-branch rank handling that builds on this shape.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateAllRanksStructured(spellMap)
  local failures = {}
  local validTypes = {
    [RGCW_CONSTANTS.SPELL_TYPE_BASE] = true,
    [RGCW_CONSTANTS.SPELL_TYPE_SOD] = true,
    [RGCW_CONSTANTS.SPELL_TYPE_TBC] = true
  }

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) and type(entry.allRanks) == "table" then
        for index, rank in ipairs(entry.allRanks) do
          if type(rank) ~= "table" then
            table.insert(failures,
              string.format("%s/%s ('%s'): allRanks[%d] is %s, expected { spellId, type } table",
                category, tostring(spellId), entry.name, index, type(rank)))
          else
            if type(rank.spellId) ~= "number" or rank.spellId <= 0 or rank.spellId % 1 ~= 0 then
              table.insert(failures,
                string.format("%s/%s ('%s'): allRanks[%d].spellId %s is not a positive integer",
                  category, tostring(spellId), entry.name, index, tostring(rank.spellId)))
            end

            if not validTypes[rank.type] then
              table.insert(failures,
                string.format("%s/%s ('%s'): allRanks[%d].type %s is not a known spell type",
                  category, tostring(spellId), entry.name, index, tostring(rank.type)))
            end
          end
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

        for _, rank in ipairs(entry.allRanks) do
          if type(rank) == "table" and rank.spellId == spellId then
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
  Non-table allRanks elements are skipped here - ValidateAllRanksStructured
  reports them.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateAllRanksConsistent(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for primaryId, entry in pairs(spells) do
      if IsPrimary(entry) and type(entry.allRanks) == "table" then
        for _, rank in ipairs(entry.allRanks) do
          if type(rank) == "table" and type(rank.spellId) == "number" then
            local rankId = rank.spellId
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
  Verify SearchBySpellId returns nil for a spellId that is not in any category.

  @param {table} spellMapHelper - The mod.spellMapHelper module

  @return {table}
]]--
function me.ValidateUnknownSpellIdReturnsNil(spellMapHelper)
  local failures = {}
  local unknownSpellId = 99999
  local event = "SPELL_CAST_SUCCESS"
  local result = spellMapHelper.SearchBySpellId(unknownSpellId, event)

  if result ~= nil then
    table.insert(failures,
      string.format("SearchBySpellId(%d, '%s') should return nil but returned non-nil",
        unknownSpellId, event))
  end

  return failures
end

--[[
  Verify every alias entry returns nil from SearchBySpellId when called with an
  event that is not in its primary's trackedEvents. Uses a synthetic event name
  guaranteed not to appear anywhere in the spellMap.

  @param {table} spellMap
  @param {table} spellMapHelper - The mod.spellMapHelper module

  @return {table}
]]--
function me.ValidateAliasRejectsMismatchedEvent(spellMap, spellMapHelper)
  local failures = {}
  local fakeEvent = "SPELL_NEVER_TRACKED_BY_TEST"

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if type(entry) == "table" and type(entry.refId) == "number" then
        local result = spellMapHelper.SearchBySpellId(spellId, fakeEvent)

        if result ~= nil then
          table.insert(failures,
            string.format("%s/%s (alias of %s) returned non-nil for fake event '%s'",
              category, tostring(spellId), tostring(entry.refId), fakeEvent))
        end
      end
    end
  end

  return failures
end

--[[
  Verify GetSharedCooldownGroup returns nil for a group name that is not
  registered.

  @param {function} getSharedCooldownGroup - mod.spellMap.GetSharedCooldownGroup

  @return {table}
]]--
function me.ValidateUnknownSharedCooldownGroupReturnsNil(getSharedCooldownGroup)
  local failures = {}
  local unknown = "this_group_should_not_exist"
  local result = getSharedCooldownGroup(unknown)

  if result ~= nil then
    table.insert(failures,
      string.format("GetSharedCooldownGroup('%s') should return nil but returned non-nil",
        unknown))
  end

  return failures
end

--[[
  Verify GetSpellsForCategory returns an empty array for a category name that
  is not present in the spellMap. The function lives on mod.testHelper rather
  than the production data layer, so this validator is exercised only by the
  in-game wrapper (Bootstrap.lua does not load TestHelper).

  @param {function} getSpellsForCategory - mod.testHelper.GetSpellsForCategory

  @return {table}
]]--
function me.ValidateUnknownCategoryReturnsEmpty(getSpellsForCategory)
  local failures = {}
  local unknown = "this_category_should_not_exist"
  local result = getSpellsForCategory(unknown)

  if type(result) ~= "table" then
    table.insert(failures,
      string.format("GetSpellsForCategory('%s') should return a table but returned %s",
        unknown, type(result)))
  elseif #result ~= 0 then
    table.insert(failures,
      string.format("GetSpellsForCategory('%s') should return empty but returned %d entries",
        unknown, #result))
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

--[[
  Verify the category catalog (code/Categories.lua) and the SpellMap top-level
  keys are in one-to-one correspondence. Profile.lua and Configuration.lua both
  derive their per-category buckets from the catalog, so a catalog entry without
  a SpellMap section (or a SpellMap section without a catalog entry) is exactly
  the drift this guard exists to catch.

  @param {table} categories - Array of {categoryName, ...} from mod.categories.GetCategories()
  @param {table} spellMap - The cloned spellMap keyed by category name

  @return {table}
]]--
function me.ValidateCategoriesMatchSpellMap(categories, spellMap)
  local failures = {}
  local inCatalog = {}

  for _, category in ipairs(categories) do
    inCatalog[category.categoryName] = true

    if spellMap[category.categoryName] == nil then
      table.insert(failures,
        string.format("catalog category '%s' has no SpellMap section",
          tostring(category.categoryName)))
    end
  end

  for categoryName in pairs(spellMap) do
    if not inCatalog[categoryName] then
      table.insert(failures,
        string.format("SpellMap category '%s' is missing from the category catalog",
          tostring(categoryName)))
    end
  end

  return failures
end

--[[
  Verify cooldownWorstCase, where present, never exceeds the base cooldown.
  cooldownWorstCase represents the talent-reduced lower bound of a cooldown, so
  logically it must be <= cooldown. A typo (e.g. cooldown = 5.5,
  cooldownWorstCase = 8) would otherwise surface only as confusing UI behaviour
  (a timer running past the supposed worst case).

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateCooldownWorstCaseSane(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) and entry.cooldownWorstCase ~= nil
        and entry.cooldownWorstCase > entry.cooldown then
        table.insert(failures,
          string.format("%s/%s ('%s'): cooldownWorstCase %s exceeds cooldown %s",
            category, tostring(spellId), entry.name,
            tostring(entry.cooldownWorstCase), tostring(entry.cooldown)))
      end
    end
  end

  return failures
end

--[[
  Verify every cooldownResets array, where present, sits on a primary entry and
  contains only valid reset targets: each target must be a number that is a
  primary entry key in any category (cross-category resets are valid, e.g. an
  item trigger resetting class cooldowns), must not be the trigger's own
  spellId, and must not appear twice in the same list. Alias spellIds are
  rejected because the cooldown queue is keyed by primary spellId - a
  RemoveCooldown on an alias id would silently never match.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateCooldownResetTargets(spellMap)
  local failures = {}
  local primaryIds = {}

  for _, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) then
        primaryIds[spellId] = true
      end
    end
  end

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if type(entry) == "table" and entry.cooldownResets ~= nil then
        if not IsPrimary(entry) then
          table.insert(failures,
            string.format("%s/%s: cooldownResets on alias entry is ignored - move it to the primary",
              category, tostring(spellId)))
        elseif type(entry.cooldownResets) ~= "table" then
          table.insert(failures,
            string.format("%s/%s ('%s'): cooldownResets is not a table",
              category, tostring(spellId), entry.name))
        else
          local seen = {}

          for _, targetSpellId in ipairs(entry.cooldownResets) do
            if type(targetSpellId) ~= "number" then
              table.insert(failures,
                string.format("%s/%s ('%s'): cooldownResets target %s is not a number",
                  category, tostring(spellId), entry.name, tostring(targetSpellId)))
            elseif targetSpellId == spellId then
              table.insert(failures,
                string.format("%s/%s ('%s'): cooldownResets lists the trigger itself",
                  category, tostring(spellId), entry.name))
            elseif not primaryIds[targetSpellId] then
              table.insert(failures,
                string.format("%s/%s ('%s'): cooldownResets target %s does not resolve to a primary entry",
                  category, tostring(spellId), entry.name, tostring(targetSpellId)))
            elseif seen[targetSpellId] then
              table.insert(failures,
                string.format("%s/%s ('%s'): cooldownResets target %s is listed twice",
                  category, tostring(spellId), entry.name, tostring(targetSpellId)))
            else
              seen[targetSpellId] = true
            end
          end
        end
      end
    end
  end

  return failures
end

--[[
  Check a single entry's itemId. Part of ValidateItemIdSane.

  @param {string} category
  @param {number} spellId
  @param {table} entry

  @return {string|nil}
    A failure description, or nil if the entry has no itemId or a valid one
]]--
GetItemIdFailure = function(category, spellId, entry)
  if entry.itemId == nil then return nil end

  if not IsPrimary(entry) then
    return string.format("%s/%s: itemId %s on alias entry is ignored - move it to the primary",
      category, tostring(spellId), tostring(entry.itemId))
  end

  if type(entry.itemId) ~= "number" or entry.itemId <= 0 or entry.itemId % 1 ~= 0 then
    return string.format("%s/%s ('%s'): itemId %s is not a positive integer",
      category, tostring(spellId), entry.name, tostring(entry.itemId))
  end

  return nil
end

--[[
  Verify every primary's trackedEvents contains only events CombatLog actually
  dispatches on (CombatLog.GetSupportedEvents). An unsupported event name (typo
  or an event the combat-log gate drops) would never fire and the spell would
  silently stop being tracked. Also catches empty or missing trackedEvents,
  which would make the spell unreachable from the combat-log path entirely.

  @param {table} spellMap
  @param {table} supportedEvents - Map of eventName -> properties table
    (mod.combatLog.GetSupportedEvents)

  @return {table}
]]--
function me.ValidateTrackedEventsSupported(spellMap, supportedEvents)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) then
        if type(entry.trackedEvents) ~= "table" or #entry.trackedEvents == 0 then
          table.insert(failures,
            string.format("%s/%s ('%s'): trackedEvents is missing or empty",
              category, tostring(spellId), entry.name))
        else
          for _, trackedEvent in ipairs(entry.trackedEvents) do
            if supportedEvents[trackedEvent] == nil then
              table.insert(failures,
                string.format("%s/%s ('%s'): tracked event '%s' is not dispatched by CombatLog",
                  category, tostring(spellId), entry.name, tostring(trackedEvent)))
            end
          end
        end
      end
    end
  end

  return failures
end

--[[
  Verify itemId, where present, is a positive integer and sits on a primary
  entry. itemId points at the item whose "Use" effect casts the tracked spell
  so the ui can show the recognizable item icon (GuiHelper.GetIconId). An
  itemId on an alias entry would be silently ignored (lookups resolve to the
  primary), and a non-numeric or non-positive value would break GetItemIcon.

  @param {table} spellMap

  @return {table}
]]--
function me.ValidateItemIdSane(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      local failure = GetItemIdFailure(category, spellId, entry)

      if failure ~= nil then
        table.insert(failures, failure)
      end
    end
  end

  return failures
end

--[[
  Verify petCast, where present, is `true`, sits on a primary entry, and the
  primary tracks exactly { "SPELL_CAST_SUCCESS" }. Pet-cast attribution resolves
  the owner of the acting SOURCE unit; aura events attribute by dest unit (the
  aura owner), so a petCast entry tracking anything else would attribute the
  cooldown to the wrong unit entirely. petCast on an alias entry would be
  silently ignored (lookups resolve to the primary).

  @param {table} spellMap

  @return {table}
]]--
function me.ValidatePetCastTrackedEvents(spellMap)
  local failures = {}

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if type(entry) == "table" and entry.petCast ~= nil then
        if not IsPrimary(entry) then
          table.insert(failures,
            string.format("%s/%s: petCast on a non-primary entry is ignored",
              category, tostring(spellId)))
        elseif entry.petCast ~= true then
          table.insert(failures,
            string.format("%s/%s ('%s'): petCast is %s, expected true or absent",
              category, tostring(spellId), entry.name, tostring(entry.petCast)))
        elseif type(entry.trackedEvents) ~= "table"
          or #entry.trackedEvents ~= 1
          or entry.trackedEvents[1] ~= "SPELL_CAST_SUCCESS" then
          table.insert(failures,
            string.format("%s/%s ('%s'): petCast entries must track exactly SPELL_CAST_SUCCESS",
              category, tostring(spellId), entry.name))
        end
      end
    end
  end

  return failures
end

--[[
  Verify every primary's type and every allRanks entry's type is allowed on the
  passed branch: classic allows SPELL_TYPE_BASE only, sod adds SPELL_TYPE_SOD,
  tbc adds SPELL_TYPE_TBC. Run this against the ASSEMBLED map for a branch - it
  is the post-assembly counterpart to ValidateBaseEntriesAreBaseType and
  catches an overlay op that smuggles a wrong-branch entry or rank into a
  branch's map (e.g. a TBC-typed rank appended by the SoD overlay). A primary
  with an unknown type is reported here too (no other validator checks primary
  types after assembly); rank entries with a malformed or unknown type are
  ValidateAllRanksStructured's job and are not re-reported.

  @param {table} spellMap - The assembled spellMap for the branch
  @param {string} branch - "classic" | "sod" | "tbc"

  @return {table}
]]--
function me.ValidateSpellTypesMatchBranch(spellMap, branch)
  local failures = {}
  local allowedByBranch = {
    classic = {
      [RGCW_CONSTANTS.SPELL_TYPE_BASE] = true
    },
    sod = {
      [RGCW_CONSTANTS.SPELL_TYPE_BASE] = true,
      [RGCW_CONSTANTS.SPELL_TYPE_SOD] = true
    },
    tbc = {
      [RGCW_CONSTANTS.SPELL_TYPE_BASE] = true,
      [RGCW_CONSTANTS.SPELL_TYPE_TBC] = true
    }
  }
  local knownTypes = {
    [RGCW_CONSTANTS.SPELL_TYPE_BASE] = true,
    [RGCW_CONSTANTS.SPELL_TYPE_SOD] = true,
    [RGCW_CONSTANTS.SPELL_TYPE_TBC] = true
  }
  local allowed = allowedByBranch[branch]

  if allowed == nil then
    table.insert(failures,
      string.format("unknown branch '%s' - expected classic, sod or tbc", tostring(branch)))

    return failures
  end

  for category, spells in pairs(spellMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) then
        if not allowed[entry.type] then
          table.insert(failures,
            string.format("%s/%s ('%s'): type %s is not allowed on the %s branch",
              category, tostring(spellId), entry.name, tostring(entry.type), branch))
        end

        if type(entry.allRanks) == "table" then
          for index, rank in ipairs(entry.allRanks) do
            if type(rank) == "table" and knownTypes[rank.type] and not allowed[rank.type] then
              table.insert(failures,
                string.format("%s/%s ('%s'): allRanks[%d].type %s is not allowed on the %s branch",
                  category, tostring(spellId), entry.name, index, tostring(rank.type), branch))
            end
          end
        end
      end
    end
  end

  return failures
end

--[[
  Verify no rank listed in a base primary's allRanks also has its own entry in
  the base catalog. Rank aliases ({ refId = primaryId }) are derived from
  allRanks and synthesized post-assembly (SpellMap.SynthesizeRankAliases) -
  hand-writing one in a base slice duplicates allRanks and drifts silently.

  Run this against mod.spellMapBase.GetMap(), not the assembled map - after
  assembly, every rank deliberately has its synthesized entry.

  @param {table} baseMap - The unassembled base catalog (mod.spellMapBase.GetMap)

  @return {table}
]]--
function me.ValidateBaseHasNoHandWrittenRankAliases(baseMap)
  local failures = {}

  for category, spells in pairs(baseMap) do
    for primaryId, entry in pairs(spells) do
      if IsPrimary(entry) and type(entry.allRanks) == "table" then
        for _, rank in ipairs(entry.allRanks) do
          if type(rank) == "table" and type(rank.spellId) == "number"
            and rank.spellId ~= primaryId and spells[rank.spellId] ~= nil then
            table.insert(failures, string.format(
              "%s/%s ('%s'): rank id %s has a hand-written base entry - rank aliases are synthesized at assembly",
              category, tostring(primaryId), entry.name, tostring(rank.spellId)))
          end
        end
      end
    end
  end

  return failures
end

--[[
  Verify the base catalog carries only SPELL_TYPE_BASE entries. Branch-specific
  spells (SPELL_TYPE_SOD / SPELL_TYPE_TBC) belong in their branch overlay under
  code/spellmap/overlay/ - a branch-only spell as an add op, a branch rework as
  replace, a branch-only rank as appendRanks - never in the base slices. Checks
  each primary's own type and every allRanks entry's type; rank entries with a
  malformed or unknown type are ValidateAllRanksStructured's job and are not
  re-reported here.

  Run this against mod.spellMapBase.GetMap(), not the assembled map - after
  assembly, overlay-added entries legitimately carry branch types.

  @param {table} baseMap - The unassembled base catalog (mod.spellMapBase.GetMap)

  @return {table}
]]--
function me.ValidateBaseEntriesAreBaseType(baseMap)
  local failures = {}
  local branchTypes = {
    [RGCW_CONSTANTS.SPELL_TYPE_SOD] = true,
    [RGCW_CONSTANTS.SPELL_TYPE_TBC] = true
  }

  for category, spells in pairs(baseMap) do
    for spellId, entry in pairs(spells) do
      if IsPrimary(entry) then
        if entry.type ~= RGCW_CONSTANTS.SPELL_TYPE_BASE then
          table.insert(failures, string.format(
            "%s/%s ('%s'): type %s is not SPELL_TYPE_BASE - branch-specific entries live in their overlay",
            category, tostring(spellId), entry.name, tostring(entry.type)))
        end

        if type(entry.allRanks) == "table" then
          for index, rank in ipairs(entry.allRanks) do
            if type(rank) == "table" and branchTypes[rank.type] then
              table.insert(failures, string.format(
                "%s/%s ('%s'): allRanks[%d].type %s is branch-specific - append it via the overlay's appendRanks",
                category, tostring(spellId), entry.name, index, tostring(rank.type)))
            end
          end
        end
      end
    end
  end

  return failures
end
