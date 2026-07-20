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

--[[
  SpellMap orchestrator. The spell catalog itself lives in
  code/spellmap/Base.lua (Classic Era base) plus the per-branch overlays in
  code/spellmap/overlay/. This module detects the active WoW branch, assembles
  base + overlays via mod.spellMapAssembler, caches the result per branch, and
  exposes the public accessors every consumer reads spell data through.
]]--

local mod = rgcw
local me = {}
mod.spellMap = me

me.tag = "SpellMap"

-- assembled spellMap, keyed by active branch ("classic" / "sod" / "tbc"). Each
-- branch's map is built once on first access; a production run only ever
-- populates one branch entry.
local assembledByBranch = {}

--[[
  Determine which WoW branch the client is running. In TEST mode a test helper
  can override the detected branch (mod.testHelper.GetActiveBranch, the seam
  for per-branch assembler specs); without an override the client globals
  behind mod.season decide, most specific branch first.

  @return {string}
    "classic" | "sod" | "tbc"
]]--
local function DetermineActiveBranch()
  if RGCW_ENVIRONMENT.TEST and mod.testHelper and mod.testHelper.GetActiveBranch then
    return mod.testHelper.GetActiveBranch()
  end

  if mod.season.IsTbcActive() then return "tbc" end
  if mod.season.IsSodActive() then return "sod" end

  return "classic"
end

--[[
  Synthesize the { refId = primaryId } alias entry for every non-primary rank
  listed in a primary's allRanks. Rank aliases are derived data - hand-writing
  them in the base slices would duplicate each primary's allRanks list and
  drift silently, so the slices carry only aliases that are NOT derivable from
  allRanks (aura ids that differ from the cast id, e.g. Combustion's buff
  28682). Existing entries are never overwritten. Exposed (rather than kept
  local to BuildAssembledMap) for the per-branch validation specs, which
  assemble maps directly via the assembler to keep the orchestrator's
  per-branch cache untouched.

  @param {table} assembledMap
    The assembled spellMap; mutated in place.
]]--
function me.SynthesizeRankAliases(assembledMap)
  for _, spells in pairs(assembledMap) do
    -- collect first, insert after: adding keys to a table while pairs-iterating
    -- it is undefined behavior in Lua
    local synthesized = {}

    for primaryId, entry in pairs(spells) do
      if type(entry.name) == "string" and type(entry.allRanks) == "table" then
        for _, rank in ipairs(entry.allRanks) do
          if type(rank) == "table" and type(rank.spellId) == "number"
            and rank.spellId ~= primaryId and spells[rank.spellId] == nil then
            synthesized[rank.spellId] = primaryId
          end
        end
      end
    end

    for rankId, primaryId in pairs(synthesized) do
      spells[rankId] = { refId = primaryId }
    end
  end
end

--[[
  Build the assembled spellMap for a branch: validate and apply the branch's
  overlays to the base catalog, then synthesize the rank aliases and decorate
  every primary with its normalizedSpellName. Validation failures are logged;
  Apply skips the offending ops. Post-assembly derivations belong here (not in
  Base) so overlay-added entries are covered too - a rank appended by an
  overlay's appendRanks op gains its alias like any base rank.

  @param {string} branch

  @return {table}
    The assembled spellMap
]]--
local function BuildAssembledMap(branch)
  local overlays = {}

  if branch == "sod" then
    table.insert(overlays, mod.spellMapOverlaySod.GetOverlay())
  elseif branch == "tbc" then
    table.insert(overlays, mod.spellMapOverlayTbc.GetOverlay())
  end

  local base = mod.spellMapBase.GetMap()
  local ok, errs = mod.spellMapAssembler.Validate(base, overlays)

  if not ok then
    for _, errMsg in ipairs(errs) do
      mod.logger.LogError(me.tag, "spellMap overlay validation: " .. errMsg)
    end
  end

  local assembled = mod.spellMapAssembler.Apply(base, overlays)

  me.SynthesizeRankAliases(assembled)

  for _, spells in pairs(assembled) do
    for _, spellData in pairs(spells) do
      if type(spellData.name) == "string" then
        spellData.normalizedSpellName = mod.common.NormalizeSpellName(spellData.name)
      end
    end
  end

  return assembled
end

--[[
  Get the assembled spellMap for the active branch, building and caching it on
  first access.

  @return {table}
    The assembled spellMap
]]--
local function EnsureAssembled()
  local branch = DetermineActiveBranch()

  if assembledByBranch[branch] == nil then
    assembledByBranch[branch] = BuildAssembledMap(branch)
  end

  return assembledByBranch[branch]
end

--[[
  Get the branch the spellMap is assembled for. Exposed so branch-aware
  consumers (per-branch data validation, debug surfaces) share the
  orchestrator's branch decision instead of re-deriving it from the season
  globals - the TEST-mode override would otherwise be bypassed.

  @return {string}
    "classic" | "sod" | "tbc"
]]--
function me.GetActiveBranch()
  return DetermineActiveBranch()
end

--[[
  Get the spellMap assembled for the active branch. Callers MUST treat the
  result as read-only and never mutate it (returned directly, not cloned,
  because it runs in the combat-log hot path).

  @return {table}
    The spellMap (read-only — do not mutate)
]]--
function me.GetSpellMap()
  return EnsureAssembled()
end

--[[
  Get the list of primary spellIds belonging to a shared-cooldown group.
  Groups live in Base and do not vary by branch (yet - a branch-varying group
  would need overlay support first).

  @param {string} groupName

  @return {table|nil}
    The list of primary spellIds (read-only — do not mutate), or nil if the
    group is unknown. Called on every shared-cooldown sibling fan-out, so it
    returns the internal list directly rather than cloning.
]]--
function me.GetSharedCooldownGroup(groupName)
  if not groupName then return nil end

  return mod.spellMapBase.GetSharedCooldownGroups()[groupName]
end

--[[
  Get all shared-cooldown groups keyed by group name.

  @return {table}
    Table of groupName -> list of primary spellIds (read-only — do not mutate)
]]--
function me.GetAllSharedCooldownGroups()
  return mod.spellMapBase.GetSharedCooldownGroups()
end
