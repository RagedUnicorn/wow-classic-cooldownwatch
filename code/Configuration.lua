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

-- luacheck: globals C_AddOns

local mod = rgcw
local me = {}
mod.configuration = me

me.tag = "Configuration"

--[[
  Declaration of the saved variable. WoW replaces this table with the saved one on load,
  so the values here only ever apply to a character that never saved a configuration -
  every other backfill (upgrade, applied profile) goes through me.GetDefaults below
  via me.ReconcileWithDefaults, which must stay in sync with the values declared here.
]]--
CooldownWatchConfiguration = {
  --[[
    Whether the targetCooldownBar is locked from moving or not
  ]]--
  ["lockTargetCooldownBar"] = false,
  --[[
    Initial addon version
  ]]--
  ["addonVersion"] = nil,
  --[[
    Per-category cooldown tracking state. The default derives from
    mod.profile.GetDefaultProfile(), which is not loaded yet at this point —
    SetupConfiguration seeds it instead. Declared here for visibility only.
  ]]--
  ["cooldownConfiguration"] = nil,
  --[[
    Per-spell cooldown overrides. The default derives from
    mod.profile.GetDefaultCooldownOverrides(), which is not loaded yet at this
    point — SetupConfiguration seeds it instead. Declared here for visibility only.

    cooldownOverrides = {
      [categoryName] = {
        [primarySpellId] = {
          worstCase = {boolean | nil},
          -- true if the runtime should assume the worst-case cooldown
          -- false if it should not, even when the global default is enabled
          -- nil (never configured) defers to globalAssumeWorstCase
          value = {number | nil}
          -- manual cooldown override in seconds; replaces the resolved cooldown
          -- entirely and beats both worst-case settings
          -- nil (never configured) defers to the worst-case resolution
        }
      }
    }
  ]]--
  ["cooldownOverrides"] = nil,
  --[[
    Global default for the worst-case cooldown assumption. When enabled, every
    spell with a cooldownWorstCase value resolves to it unless the player set a
    per-spell override — the per-spell toggle wins in both directions
    (see CooldownQueue.ResolveCooldown).
  ]]--
  ["globalAssumeWorstCase"] = false,
  --[[
    Framepositions for user draggable Frames
    frames = {
      -- should match the actual frame name
      ["CW_Frame"] = {
      point: "CENTER",
        posX: 0,
        posY: 0
      }
      ...
    }
  ]]--
  ["frames"] = {},
  --[[
    Named configuration profiles managed by rgcw.configProfile
    profiles = {
      [profileName] = {snapshot of the PROFILE_FIELDS}
      ...
    }
  ]]--
  ["profiles"] = {},
  --[[
    Newest addon version already announced by the update notice (see Comm.lua).
    Empty string means no version was announced yet
  ]]--
  ["lastNotifiedVersion"] = ""
}

--[[
  The shipped default value of every configurable field - the single source of truth
  for the schema SetupConfiguration reconciles the saved variables against and for
  the frozen default profile (see code/ConfigProfile.lua BuildDefaultSnapshot).
  addonVersion is deliberately absent; it is stamped by SetAddonVersion.

  Every field a new addon version adds has to be declared here, otherwise the
  reconcile cannot know about it. Nested tables are part of that schema: a key
  added inside one of them is filled on upgraded characters just like a top level
  field is.

  Returns a fresh table on every call: the two category-keyed maps are derived from
  the category catalog at call time and must never be shared between the live
  configuration and a stored profile.

  @return {table}
]]--
function me.GetDefaults()
  return {
    ["lockTargetCooldownBar"] = false,
    ["cooldownConfiguration"] = mod.profile.GetDefaultProfile(),
    ["cooldownOverrides"] = mod.profile.GetDefaultCooldownOverrides(),
    ["globalAssumeWorstCase"] = false,
    ["frames"] = {},
    ["profiles"] = {},
    ["lastNotifiedVersion"] = ""
  }
end

--[[
  Path of a field inside the configuration tree, used for log messages only.

  @param {string | nil} path
    the parent path, nil for a top level field
  @param {any} key

  @return {string}
]]--
local function FieldPath(path, key)
  if path == nil then
    return tostring(key)
  end

  return path .. "." .. tostring(key)
end

--[[
  Recursively reconcile a saved configuration table against the shipped defaults.
  Every key the defaults declare but the saved table is missing gets filled from
  the defaults; every value the player actually configured is left untouched.
  This is the addon's whole schema-evolution story for additive changes - a new
  option field, a new category bucket inside cooldownConfiguration /
  cooldownOverrides - and it runs unconditionally on every load rather than
  behind a version check, so a downgrade-then-upgrade or a hand edited saved
  variables file heals just the same.

  Only two things can happen to a key that already exists:
   - its value is a table on both sides: recurse into it. Category keyed maps of
     player data (cooldownConfiguration.priest, frames, profiles) default to
     empty tables, so recursion over them is a no-op and stored player data and
     profile snapshots are never rewritten
   - its type disagrees with the default: the saved value cannot be interpreted
     under the current schema (corruption, or a reshape that a future migration
     path should have handled), so it is reset to the default and logged

  What this deliberately does NOT do is rename keys or reshape values - a
  reconcile cannot tell a renamed field from a new one. That is what the
  reserved me.MigrationPath hook in me.SetAddonVersion is for, and it stays
  unwritten until such a change actually lands.

  @param {table} saved
    the table to fill in place, usually CooldownWatchConfiguration
  @param {table} defaults
    the shipped defaults to reconcile against, usually me.GetDefaults()
  @param {string | nil} path
    parent path of the reconciled table, used for log messages only

  @return {table}
    the passed saved table, reconciled in place
]]--
function me.ReconcileWithDefaults(saved, defaults, path)
  if type(saved) ~= "table" or type(defaults) ~= "table" then
    return saved
  end

  for key, defaultValue in pairs(defaults) do
    local savedValue = saved[key]

    if savedValue == nil then
      mod.logger.LogInfo(me.tag, FieldPath(path, key) .. " is missing - filling in the default value")
      saved[key] = mod.common.Clone(defaultValue)
    elseif type(savedValue) ~= type(defaultValue) then
      mod.logger.LogWarn(me.tag, FieldPath(path, key) .. " is a " .. type(savedValue)
        .. " but the default is a " .. type(defaultValue) .. " - resetting it to the default value")
      saved[key] = mod.common.Clone(defaultValue)
    elseif type(defaultValue) == "table" then
      me.ReconcileWithDefaults(savedValue, defaultValue, FieldPath(path, key))
    end
  end

  return saved
end

--[[
  Bring the saved configuration up to the current schema. Runs on every load
  (see code/Core.lua Initialize) and after a profile was applied
  (see code/ConfigProfile.lua ApplySnapshot), which is why it has to be
  idempotent and cheap.
]]--
function me.SetupConfiguration()
  me.ReconcileWithDefaults(CooldownWatchConfiguration, me.GetDefaults())

  --[[
    Set saved variables with addon version. This can be used later to determine whether
    a migration path applies to the current saved variables or not
  ]]--
  me.SetAddonVersion()
end

--[[
  Set addon version on addon options. Before setting a new version make sure
  to run through migration paths.

  Additive schema changes need no migration path - me.ReconcileWithDefaults
  already covers them. The commented call below is the reserved hook for the
  changes a reconcile cannot express (a renamed key, a reshaped value); wire it
  up together with the first such change, comparing the stamped
  CooldownWatchConfiguration.addonVersion against the current one via
  me.IsVersionBefore.
]]--
function me.SetAddonVersion()
  -- me.MigrationPath()
  -- migration done update addon version to current
  CooldownWatchConfiguration.addonVersion = C_AddOns.GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
end

--[[
  Semver-ish comparison of two version strings of the form "v1.2.0" (the leading "v"
  is optional). Missing or unparseable versions are never considered older.

  @param {string | nil} version
  @param {string} otherVersion
  @return {boolean}
    true - if version is older than otherVersion
    false - otherwise
]]--
function me.IsVersionBefore(version, otherVersion)
  local major, minor, patch = string.match(version or "", "^v?(%d+)%.(%d+)%.(%d+)")
  local otherMajor, otherMinor, otherPatch = string.match(otherVersion or "", "^v?(%d+)%.(%d+)%.(%d+)")

  if major == nil or otherMajor == nil then return false end

  if tonumber(major) ~= tonumber(otherMajor) then
    return tonumber(major) < tonumber(otherMajor)
  end

  if tonumber(minor) ~= tonumber(otherMinor) then
    return tonumber(minor) < tonumber(otherMinor)
  end

  return tonumber(patch) < tonumber(otherPatch)
end

--[[
  Enable moving of targetCooldownBar window
]]--
function me.UnlockTargetCooldownBar()
  CooldownWatchConfiguration.lockTargetCooldownBar = false
  mod.targetCooldownBar.TargetCooldownBarUiUpdate()
end

--[[
  Disable moving of targetCooldownBar window
]]--
function me.LockTargetCooldownBar()
  CooldownWatchConfiguration.lockTargetCooldownBar = true
  mod.targetCooldownBar.TargetCooldownBarUiUpdate()
end

--[[
  @return {boolean}
    true - if the targetCooldownBar is locked
    false - if the targetCooldownBar is not locked
]]--
function me.IsTargetCooldownBarLocked()
  return CooldownWatchConfiguration.lockTargetCooldownBar
end

--[[
  Save the position of a frame in the addon variables allowing to persist its position

  @param {string} frameName
  @param {string} point
  @param {string} relativeTo
  @param {string} relativePoint
  @param {number} posX
  @param {number} posY
]]--
function me.SaveUserPlacedFramePosition(frameName, point, relativeTo, relativePoint, posX, posY)
  if CooldownWatchConfiguration.frames[frameName] == nil then
    CooldownWatchConfiguration.frames[frameName] = {}
  end

  CooldownWatchConfiguration.frames[frameName].posX = posX
  CooldownWatchConfiguration.frames[frameName].posY = posY
  CooldownWatchConfiguration.frames[frameName].point = point
  CooldownWatchConfiguration.frames[frameName].relativeTo = relativeTo
  CooldownWatchConfiguration.frames[frameName].relativePoint = relativePoint

  mod.logger.LogDebug(me.tag, "Saved frame position for - " .. frameName
    .. " - new pos: posX " .. posX .. " posY " .. posY .. " point " .. point)
end

--[[
  Get the position of a saved frame

  @param {string} frameName

  @return {table | nil}
    table - the returned x and y position
    nil - if no frame with the passed name could be found
]]--
function me.GetUserPlacedFramePosition(frameName)
  local frameConfig = CooldownWatchConfiguration.frames[frameName]

  if type(frameConfig) == "table" then
    return frameConfig
  end

  return nil
end

--[[
  Update the tracking state of a cooldown spell for a certain category

  @param {boolean} enabled
    Whether the configuration should be enabled or disabled
  @param {number} categoryName
  @param {number} spellId
]]--
function me.UpdateCooldownConfigurationState(enabled, categoryName, spellId)
  local config = CooldownWatchConfiguration.cooldownConfiguration

  if config[categoryName] == nil then
    config[categoryName] = {}
  end

  if enabled then
    config[categoryName][spellId] = true
    mod.logger.LogDebug(me.tag, "Enabled cooldown: " .. categoryName .. " - " .. spellId)
  else
    config[categoryName][spellId] = false
    mod.logger.LogDebug(me.tag, "Disabled cooldown: " .. categoryName .. " - " .. spellId)
  end
end

--[[
  Get the tracking state of a cooldown spell for a certain category

  Never-configured and explicitly disabled are distinct states: the config ui
  writes an explicit true/false on every toggle, so a nil entry means the
  player never touched the spell and the catalog's intended default applies.

  @param {string} categoryName
  @param {number} spellId
  @param {boolean} defaultState
    Optional. The spell's catalog `active` flag - the tracked state that
    applies while the player never configured the spell. Omitting it keeps
    the pure config read (never-configured resolves to false).

  @return {boolean}
    true  - If the cooldown is tracked (enabled explicitly, or never
            configured with a true defaultState)
    false - Otherwise (disabled explicitly, or never configured without a
            true defaultState)
]]--
function me.GetCooldownConfigurationState(categoryName, spellId, defaultState)
  local config = CooldownWatchConfiguration.cooldownConfiguration
  local categoryConfig = config and config[categoryName]
  local state = categoryConfig and categoryConfig[spellId]

  if state == nil then
    return defaultState == true -- never configured - the catalog default decides
  end

  return state == true
end

--[[
  Update whether the worst-case cooldown should be assumed for a spell in a
  certain category

  @param {boolean} assumed
    Whether the worst-case cooldown should be assumed or not
  @param {string} categoryName
  @param {number} spellId
]]--
function me.UpdateCooldownWorstCaseState(assumed, categoryName, spellId)
  --[[
    Lazily create the table chain: cooldownOverrides itself may be nil when
    SetupConfiguration never ran (headless test harness), and the per-spell
    entry is table-valued so future override fields survive a toggle.
  ]]--
  if CooldownWatchConfiguration.cooldownOverrides == nil then
    CooldownWatchConfiguration.cooldownOverrides = {}
  end

  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if overrides[categoryName] == nil then
    overrides[categoryName] = {}
  end

  if overrides[categoryName][spellId] == nil then
    overrides[categoryName][spellId] = {}
  end

  if assumed then
    overrides[categoryName][spellId].worstCase = true
    mod.logger.LogDebug(me.tag, "Enabled worst-case cooldown: " .. categoryName .. " - " .. spellId)
  else
    overrides[categoryName][spellId].worstCase = false
    mod.logger.LogDebug(me.tag, "Disabled worst-case cooldown: " .. categoryName .. " - " .. spellId)
  end
end

--[[
  Get the raw per-spell worst-case override for a spell in a certain category.
  Unlike IsCooldownWorstCaseAssumed this distinguishes an explicit opt-out from
  a spell the player never configured — only the latter falls back to the
  global default (see CooldownQueue.ResolveCooldown).

  @param {string} categoryName
  @param {number} spellId

  @return {boolean | nil}
    true  - The player explicitly opted into the worst-case cooldown
    false - The player explicitly opted out
    nil   - Never configured; the global default applies
]]--
function me.GetCooldownWorstCaseOverride(categoryName, spellId)
  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if overrides == nil or overrides[categoryName] == nil or overrides[categoryName][spellId] == nil then
    return nil
  end

  return overrides[categoryName][spellId].worstCase
end

--[[
  Get whether the worst-case cooldown should be assumed for a spell in a
  certain category

  @param {string} categoryName
  @param {number} spellId

  @return {boolean}
    true  - If the worst-case cooldown should be assumed
    false - Otherwise (disabled, or never configured)
]]--
function me.IsCooldownWorstCaseAssumed(categoryName, spellId)
  return me.GetCooldownWorstCaseOverride(categoryName, spellId) == true
end

--[[
  Whether the worst case is assumed for a spell once the global default is
  taken into account: an explicit per-spell toggle wins in both directions, and
  a spell that was never configured follows the global option.

  This is the rule ResolveCooldown applies and the one the config menu's
  description line asks about, kept in one place so the two cannot disagree.
  Not to be confused with IsCooldownWorstCaseAssumed, which collapses only the
  per-spell tri-state and exists to drive the checkbox's own checked state -
  that one must NOT fold in the global default, or ticking the global option
  would make every checkbox appear individually set.

  Says nothing about whether the worst case ends up *tracked*: a manual
  override beats it (see CooldownQueue.ResolveCooldown).

  @param {string} categoryName
  @param {number} spellId

  @return {boolean}
]]--
function me.IsWorstCaseEffective(categoryName, spellId)
  local override = me.GetCooldownWorstCaseOverride(categoryName, spellId)

  if override ~= nil then
    return override
  end

  return me.IsGlobalWorstCaseAssumed()
end

--[[
  Whether a player-entered override value is usable at all.

  Deliberately NOT rejected: a value above the *catalog* cooldown for the spell.
  The catalog is a best effort and the player watching the enemy may simply know
  better (a rank the catalog does not carry, a season tweak, an unlisted set
  bonus), so the override is free in both directions within the absolute limit.
  Silently clamping to the catalog value would be worse than wrong: the field is
  pre-filled with it, so a clamped commit re-renders the exact number that was
  already there and is indistinguishable from the edit having been ignored.

  Rejected is anything past RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS — 60 minutes,
  the same ceiling the catalog itself is held to. Past that a value is a typo,
  not a cooldown, and it would sit on the bar for the rest of the session.

  @param {any} value

  @return {boolean}
    true - The value can be stored as an override
]]--
local function IsValidOverrideValue(value)
  return type(value) == "number"
    and value == value      -- NaN is the only value not equal to itself
    and value > 0
    -- also excludes math.huge, which fails every finite comparison
    and value <= RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS
end

--[[
  Write one numeric field of a spell's override entry. Shared by the cooldown
  and the worst-case value so the two cannot drift apart in validation or in
  their lazy table-chain handling.

  Validation lives here rather than in the GUI so it applies to every caller
  and is testable under the headless harness:
   - nil clears the field (sibling fields on the entry survive)
   - anything IsValidOverrideValue rejects leaves the store untouched
   - clearing a spell that was never configured must not fabricate the chain

  @param {string} fieldName
    The key on the per-spell override entry ("value" or "worstCaseValue")
  @param {number | nil} value
    The override in seconds, or nil to clear it
  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
    The value that was stored — callers display this instead of the raw input.
    nil when the override was cleared or rejected.
]]--
local function UpdateOverrideValue(fieldName, value, categoryName, spellId)
  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if value == nil then
    if overrides and overrides[categoryName] and overrides[categoryName][spellId] then
      overrides[categoryName][spellId][fieldName] = nil
      mod.logger.LogDebug(me.tag, "Cleared " .. fieldName .. " override: " .. categoryName .. " - " .. spellId)
    end

    return nil
  end

  if not IsValidOverrideValue(value) then
    mod.logger.LogWarn(me.tag, "Rejected invalid " .. fieldName .. " override: "
      .. categoryName .. " - " .. spellId .. " - " .. tostring(value))

    return nil
  end

  --[[
    Lazily create the table chain: cooldownOverrides itself may be nil when
    SetupConfiguration never ran (headless test harness), and the per-spell
    entry is table-valued so the worst-case toggle survives a value edit.
  ]]--
  if overrides == nil then
    overrides = {}
    CooldownWatchConfiguration.cooldownOverrides = overrides
  end

  if overrides[categoryName] == nil then
    overrides[categoryName] = {}
  end

  if overrides[categoryName][spellId] == nil then
    overrides[categoryName][spellId] = {}
  end

  overrides[categoryName][spellId][fieldName] = value
  mod.logger.LogDebug(me.tag, "Set " .. fieldName .. " override: "
    .. categoryName .. " - " .. spellId .. " - " .. value)

  return value
end

--[[
  Read one numeric field of a spell's override entry

  @param {string} fieldName
  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
]]--
local function GetOverrideValue(fieldName, categoryName, spellId)
  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if overrides == nil or overrides[categoryName] == nil or overrides[categoryName][spellId] == nil then
    return nil
  end

  return overrides[categoryName][spellId][fieldName]
end

--[[
  Update the manual cooldown override for a spell in a certain category. The
  manual value replaces the resolved cooldown entirely and beats both
  worst-case settings (see CooldownQueue.ResolveCooldown).

  @param {number | nil} value
    The override in seconds, or nil to clear it
  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
    The value that was stored, nil when it was cleared or rejected
]]--
function me.UpdateCooldownManualOverride(value, categoryName, spellId)
  return UpdateOverrideValue("value", value, categoryName, spellId)
end

--[[
  Get the manual cooldown override for a spell in a certain category

  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
    number - The override in seconds
    nil    - Never configured; the worst-case resolution applies
]]--
function me.GetCooldownManualOverride(categoryName, spellId)
  return GetOverrideValue("value", categoryName, spellId)
end

--[[
  Update the per-spell worst-case cooldown value for a spell in a certain
  category — the player's correction of the catalog's cooldownWorstCase.

  This only replaces the *value*; whether the worst case is assumed at all
  stays with the toggle (UpdateCooldownWorstCaseState) and the global default.
  A stored value for a spell the catalog carries no worst case for is inert —
  the catalog decides whether a spell has a worst case, the player only what it
  is (see CooldownQueue.ResolveCooldown).

  On top of the shared validation this enforces the one rule that makes a worst
  case a worst case: it must be **strictly below** the spell's base cooldown. A
  worst case at or above the base describes nothing — assuming it would make
  the tracked cooldown longer than the spell can possibly have, and at exactly
  the base the toggle would silently do nothing. The catalog is held to the
  same rule by SpellMapValidation.ValidateCooldownWorstCaseSane.

  The comparison is against the *catalog* cooldown, not a manual override: an
  override replaces the resolution wholesale (worst-case settings included), so
  it is not the thing this value is a worst case of. Spells unknown to SpellMap
  have no base to compare against and skip the check.

  @param {number | nil} value
    The worst-case cooldown in seconds, or nil to fall back to the catalog
  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
    The value that was stored, nil when it was cleared or rejected
]]--
function me.UpdateCooldownWorstCaseValue(value, categoryName, spellId)
  -- type-guarded: a non-number is not ordered against a number in Lua, it raises
  if type(value) == "number" then
    local _, _, spell = mod.spellMapHelper.GetSpellById(spellId)

    if spell and value >= spell.cooldown then
      mod.logger.LogWarn(me.tag, "Rejected worst-case value not below the base cooldown: "
        .. categoryName .. " - " .. spellId .. " - " .. tostring(value)
        .. " (base " .. tostring(spell.cooldown) .. ")")

      return nil
    end
  end

  return UpdateOverrideValue("worstCaseValue", value, categoryName, spellId)
end

--[[
  Get the per-spell worst-case cooldown value for a spell in a certain category

  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
    number - The player's worst-case value in seconds
    nil    - Never configured; the catalog's cooldownWorstCase applies
]]--
function me.GetCooldownWorstCaseValue(categoryName, spellId)
  return GetOverrideValue("worstCaseValue", categoryName, spellId)
end

--[[
  Update the global default for assuming worst-case cooldowns. A per-spell
  override still wins in both directions (see GetCooldownWorstCaseOverride).

  @param {boolean} assumed
    Whether worst-case cooldowns should be assumed by default
]]--
function me.UpdateGlobalWorstCaseState(assumed)
  if assumed then
    CooldownWatchConfiguration.globalAssumeWorstCase = true
    mod.logger.LogDebug(me.tag, "Enabled global worst-case cooldown default")
  else
    CooldownWatchConfiguration.globalAssumeWorstCase = false
    mod.logger.LogDebug(me.tag, "Disabled global worst-case cooldown default")
  end
end

--[[
  @return {boolean}
    true  - If worst-case cooldowns should be assumed by default
    false - Otherwise
]]--
function me.IsGlobalWorstCaseAssumed()
  return CooldownWatchConfiguration.globalAssumeWorstCase == true
end
