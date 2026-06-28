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

local mod = rgcw
local me = {}
mod.spellMapHelper = me

me.tag = "SpellMapHelper"

-- Forward declarations
local GetFilteredSpellMap

--[[
  Whether a primary spell is allowed in the active WoW season. Base spells are
  always allowed; SOD-only spells require Season of Discovery to be active (or
  the TEST environment flag).

  @param {table} primarySpell

  @return {boolean}
]]--
local function IsPrimaryAllowedInCurrentSeason(primarySpell)
  if primarySpell.type == RGCW_CONSTANTS.SPELL_TYPE_BASE then
    return true
  end

  if primarySpell.type == RGCW_CONSTANTS.SPELL_TYPE_SOD then
    return mod.season.IsSodActive() or RGCW_ENVIRONMENT.TEST
  end

  return false
end

--[[
  Retrieve the spellMap filtered to the version of WoW running. There are base spells present
  in all versions marked with RGPVPW_CONSTANTS.SPELL_TYPE_BASE. Spells that are only available
  in Season of Discovery are marked with RGPVPW_CONSTANTS.SPELL_TYPE_SOD

  Note: refId entries are intentionally excluded - this view is for UI listings
  that only care about primary spells. Combat-log lookups go through the
  unfiltered spellMap (see SearchBySpellId / GetSpellById).

  @return {table}
    The filtered spellMap
]]--
GetFilteredSpellMap = function()
  local filteredSpellMap = {}
  local baseSpellMap = mod.spellMap.GetSpellMap()

  for category, _ in pairs(baseSpellMap) do
    filteredSpellMap[category] = {}

    for spellId, spellData in pairs(baseSpellMap[category]) do
      -- spells that only contain a refId are not added to the filtered SpellMap
      if spellData.refId == nil and IsPrimaryAllowedInCurrentSeason(spellData) then
        filteredSpellMap[category][spellId] = spellData
      end
    end
  end

  return filteredSpellMap
end

--[[
  Get map for a certain category - used for ui tabs

  @param {string} category

  @return {table}
    Map for the passed category
]]--
function me.GetAllForCategory(category)
  if not category then return nil end

  local spellList = {}
  local filteredSpellMap = GetFilteredSpellMap()

  for spellId, spellData in pairs(filteredSpellMap[category]) do
    local clonedSpell = mod.common.Clone(spellData)
    clonedSpell.spellId = spellId
    clonedSpell.normalizedSpellName = mod.common.NormalizeSpellName(spellData.name)
    table.insert(spellList, clonedSpell)
  end

  return spellList
end

--[[
  Event-aware spellMap lookup for the combat-log path. Resolves spellId to its
  primary entry (following refId chains and season-gating), then returns the
  spell only if `event` is in the primary's `trackedEvents`. Returns nil for
  unknown spellIds, SOD spells outside Season of Discovery, and event mismatches.

  Use this when a combat-log event is firing. For event-free lookups (sibling
  fan-out, debug injection, data validation), use GetSpellById instead.

  @param {number} spellId
  @param {string} event

  @return ({string} {number} {table}) | {nil}
    category, realSpellId, clonedSpell. realSpellId is the primary's spellId
    (which differs from the input when the input is a non-primary rank's id).
]]--
function me.SearchBySpellId(spellId, event)
  if not spellId then return nil end

  local baseSpellMap = mod.spellMap.GetSpellMap()

  mod.logger.LogDebug(me.tag, string.format("Searching for spellId %s in spellMap", spellId))

  for category, spells in pairs(baseSpellMap) do
    local spellData = spells[spellId]
    local baseSpell
    local realSpellId

    if spellData then
      if type(spellData.name) == "string" then
        baseSpell = spellData
        realSpellId = spellId
      elseif type(spellData.refId) == "number" then
        baseSpell = spells[spellData.refId]
        realSpellId = spellData.refId
      end
    end

    if baseSpell then
      if not IsPrimaryAllowedInCurrentSeason(baseSpell) then
        return nil
      end

      for _, trackedEvent in pairs(baseSpell.trackedEvents) do
        if trackedEvent == event then
          mod.logger.LogDebug(me.tag, string.format(
            "Found matching tracked event %s for spellId %s", event, spellId))

          local clonedSpell = mod.common.Clone(baseSpell)
          clonedSpell.spellId = realSpellId -- overwrite spellId with the real spellId
          clonedSpell.normalizedSpellName = mod.common.NormalizeSpellName(baseSpell.name)

          return category, realSpellId, clonedSpell
        end
      end

      return nil
    end
  end

  return nil
end

--[[
  Event-free spellMap lookup. Resolves spellId to its primary entry (following
  refId chains and season-gating) and returns it whenever the id matches a
  season-allowed primary. No `trackedEvents` filter — the counterpart to
  SearchBySpellId for paths where no combat-log event is in flight.

  Use cases:
   - shared-cooldown sibling fan-out (CombatLog.TrackSharedCooldownSiblings):
     siblings go on cooldown by virtue of the trigger spell, so their own
     events have not fired and there is nothing to filter against.
   - debug spell injection (DebugInjectorWindow): caller picks a spellId
     directly from the UI.
   - data validation walks (ValidateSharedCooldownGroupsConsistent and similar):
     iterates spellMap entries by id, no combat-log context.

  For the event-aware combat-log lookup, use SearchBySpellId.

  @param {number} spellId

  @return ({string} {number} {table}) | {nil}
    category, realSpellId (primary), clonedSpell (with spellId and
    normalizedSpellName populated).
]]--
function me.GetSpellById(spellId)
  if not spellId then return nil end

  local baseSpellMap = mod.spellMap.GetSpellMap()

  for category, spells in pairs(baseSpellMap) do
    local entry = spells[spellId]
    local baseSpell
    local realSpellId

    if entry then
      if type(entry.name) == "string" then
        baseSpell = entry
        realSpellId = spellId
      elseif type(entry.refId) == "number" then
        baseSpell = spells[entry.refId]
        realSpellId = entry.refId
      end
    end

    if baseSpell then
      if not IsPrimaryAllowedInCurrentSeason(baseSpell) then
        return nil
      end

      local clonedSpell = mod.common.Clone(baseSpell)

      clonedSpell.spellId = realSpellId
      clonedSpell.normalizedSpellName = mod.common.NormalizeSpellName(baseSpell.name)

      return category, realSpellId, clonedSpell
    end
  end

  return nil
end
