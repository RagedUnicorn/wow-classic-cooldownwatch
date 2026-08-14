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
  Shipped defaults of the proximity cooldown window options, built fresh on every
  call so the saved-variable declaration below, me.GetDefaults and the accessor
  fallbacks never share one table. Single source for these values - the three
  consumers restating them would be exactly the drift the reconcile exists to
  prevent.

  maxDisplayedCooldowns mirrors the target cooldown bar's ten slots until the
  window layout settles on its own number; scale bounds are an options-ui
  concern and deliberately not enforced here beyond basic sanity.

  @return {table}
]]--
local function GetProximityCooldownsDefaults()
  return {
    -- whether the proximity cooldown window renders at all - opt-in
    ["enabled"] = false,
    -- whether the window is locked from moving
    ["locked"] = false,
    -- render scale of the window
    ["scale"] = 1.0,
    -- upper bound of cooldowns the window displays at once
    ["maxDisplayedCooldowns"] = 10,
    -- hide cooldowns above RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
    ["hideLongCooldowns"] = true
  }
end

--[[
  Shipped defaults of the FRIENDLY proximity cooldown window options - derived
  from the enemy window's defaults so the shared fields can never drift, with
  the two deliberate divergences spelled out here:

  hideLongCooldowns defaults OFF: the friendly cooldowns worth watching -
  insignias, the big defensives - mostly sit above the threshold, so the
  enemy window's default would hide exactly what a friendly window exists to
  show.

  scope restricts which friendly casters render ("group" / "raid" / "all",
  see RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_*) and exists on this side
  only - the enemy window has no roster to scope against.

  @return {table}
]]--
local function GetFriendlyProximityCooldownsDefaults()
  local defaults = GetProximityCooldownsDefaults()

  defaults.hideLongCooldowns = false
  defaults.scope = RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_ALL

  return defaults
end

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
    FRIENDLY-side twin of cooldownConfiguration. Tracking a spell for enemies
    and for friendly casters are independent decisions, so the friendly side
    keeps its own per-spell state instead of sharing the enemy store. Seeded by
    SetupConfiguration like its enemy twin. Declared here for visibility only.
  ]]--
  ["friendlyCooldownConfiguration"] = nil,
  --[[
    FRIENDLY-side twin of cooldownOverrides (same per-spell entry shape). Split
    deliberately: worst case models the ENEMY's assumed gear/talents, and a
    manual override tuned for enemies should not silently rewrite what a known
    teammate's cooldown shows. Seeded by SetupConfiguration like its enemy twin.
    Declared here for visibility only.
  ]]--
  ["friendlyCooldownOverrides"] = nil,
  --[[
    Whether cooldowns cast by FRIENDLY players (and their pets) are tracked at
    all - the master switch in front of the per-spell friendly-side state.
    Opt-in: enemy tracking is the addon's core job, friendly tracking an extra.
  ]]--
  ["trackFriendlyCooldowns"] = false,
  --[[
    Whether targeting a FRIENDLY player (or their pet - the target layer
    redirects pets to their owner) shows that player's tracked cooldowns on
    the target cooldown bar. Deliberately independent of
    trackFriendlyCooldowns: with tracking off the queue holds no friendly
    entries and the bar simply stays empty - enabling display never silently
    writes the tracking flag.
  ]]--
  ["showFriendlyTargetCooldowns"] = false,
  --[[
    Global default for the worst-case cooldown assumption. When enabled, every
    spell with a cooldownWorstCase value resolves to it unless the player set a
    per-spell override — the per-spell toggle wins in both directions
    (see CooldownQueue.ResolveCooldown). Deliberately a single global shared by
    both caster sides - per-side globals are not worth their surface until
    friendly tracking proves the shared default noisy.
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
    Options of the proximity cooldown window - the cross-caster window fed by
    CooldownQueue.GetAllCooldowns. Shape and defaults come from
    GetProximityCooldownsDefaults above; the window position lives in frames
    like every other movable frame.
  ]]--
  ["proximityCooldowns"] = GetProximityCooldownsDefaults(),
  --[[
    Options of the FRIENDLY proximity cooldown window - the second, separate
    window rendering the active cooldowns of nearby friendly casters. Same
    shape as proximityCooldowns plus the scope selector; shape and defaults
    come from GetFriendlyProximityCooldownsDefaults above. Deliberately its
    own block: enabling, placing and filtering the friendly window are
    decisions independent of the enemy window's.
  ]]--
  ["friendlyProximityCooldowns"] = GetFriendlyProximityCooldownsDefaults(),
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
    ["friendlyCooldownConfiguration"] = mod.profile.GetDefaultProfile(),
    ["friendlyCooldownOverrides"] = mod.profile.GetDefaultCooldownOverrides(),
    ["trackFriendlyCooldowns"] = false,
    ["showFriendlyTargetCooldowns"] = false,
    ["globalAssumeWorstCase"] = false,
    ["frames"] = {},
    ["proximityCooldowns"] = GetProximityCooldownsDefaults(),
    ["friendlyProximityCooldowns"] = GetFriendlyProximityCooldownsDefaults(),
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
  Every per-spell accessor below takes an optional trailing `friendly` flag
  that routes the read or write to the FRIENDLY-side twin store instead of the
  enemy store. Omitting it (every historical call site) keeps the enemy-side
  behavior bit-for-bit; the two sides never share state, so a spell's tracking
  decision and override values are fully independent per side. The two helpers
  are the single place the side -> store-field mapping lives.

  @param {boolean} friendly
    Optional. true routes to the friendly-side store

  @return {string}
    The CooldownWatchConfiguration field name of the selected store
]]--
local function TrackingStoreField(friendly)
  if friendly then
    return "friendlyCooldownConfiguration"
  end

  return "cooldownConfiguration"
end

local function OverridesStoreField(friendly)
  if friendly then
    return "friendlyCooldownOverrides"
  end

  return "cooldownOverrides"
end

--[[
  Update the tracking state of a cooldown spell for a certain category

  @param {boolean} enabled
    Whether the configuration should be enabled or disabled
  @param {number} categoryName
  @param {number} spellId
  @param {boolean} friendly
    Optional. true writes the FRIENDLY-side state (see TrackingStoreField)
]]--
function me.UpdateCooldownConfigurationState(enabled, categoryName, spellId, friendly)
  local storeField = TrackingStoreField(friendly)

  --[[
    Lazily create the store: it may be nil when SetupConfiguration never ran
    (headless test harness)
  ]]--
  if CooldownWatchConfiguration[storeField] == nil then
    CooldownWatchConfiguration[storeField] = {}
  end

  local config = CooldownWatchConfiguration[storeField]

  if config[categoryName] == nil then
    config[categoryName] = {}
  end

  if enabled then
    config[categoryName][spellId] = true
    mod.logger.LogDebug(me.tag, "Enabled cooldown (" .. storeField .. "): " .. categoryName .. " - " .. spellId)
  else
    config[categoryName][spellId] = false
    mod.logger.LogDebug(me.tag, "Disabled cooldown (" .. storeField .. "): " .. categoryName .. " - " .. spellId)
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
  @param {boolean} friendly
    Optional. true reads the FRIENDLY-side state (see TrackingStoreField).
    The catalog default applies per side independently - a spell the player
    only ever configured for enemies is still never-configured here.

  @return {boolean}
    true  - If the cooldown is tracked (enabled explicitly, or never
            configured with a true defaultState)
    false - Otherwise (disabled explicitly, or never configured without a
            true defaultState)
]]--
function me.GetCooldownConfigurationState(categoryName, spellId, defaultState, friendly)
  local config = CooldownWatchConfiguration[TrackingStoreField(friendly)]
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
  @param {boolean} friendly
    Optional. true writes the FRIENDLY-side toggle (see OverridesStoreField)
]]--
function me.UpdateCooldownWorstCaseState(assumed, categoryName, spellId, friendly)
  local storeField = OverridesStoreField(friendly)

  --[[
    Lazily create the table chain: the store itself may be nil when
    SetupConfiguration never ran (headless test harness), and the per-spell
    entry is table-valued so future override fields survive a toggle.
  ]]--
  if CooldownWatchConfiguration[storeField] == nil then
    CooldownWatchConfiguration[storeField] = {}
  end

  local overrides = CooldownWatchConfiguration[storeField]

  if overrides[categoryName] == nil then
    overrides[categoryName] = {}
  end

  if overrides[categoryName][spellId] == nil then
    overrides[categoryName][spellId] = {}
  end

  if assumed then
    overrides[categoryName][spellId].worstCase = true
    mod.logger.LogDebug(me.tag, "Enabled worst-case cooldown (" .. storeField .. "): "
      .. categoryName .. " - " .. spellId)
  else
    overrides[categoryName][spellId].worstCase = false
    mod.logger.LogDebug(me.tag, "Disabled worst-case cooldown (" .. storeField .. "): "
      .. categoryName .. " - " .. spellId)
  end
end

--[[
  Get the raw per-spell worst-case override for a spell in a certain category.
  Unlike IsCooldownWorstCaseAssumed this distinguishes an explicit opt-out from
  a spell the player never configured — only the latter falls back to the
  global default (see CooldownQueue.ResolveCooldown).

  @param {string} categoryName
  @param {number} spellId
  @param {boolean} friendly
    Optional. true reads the FRIENDLY-side toggle (see OverridesStoreField)

  @return {boolean | nil}
    true  - The player explicitly opted into the worst-case cooldown
    false - The player explicitly opted out
    nil   - Never configured; the global default applies
]]--
function me.GetCooldownWorstCaseOverride(categoryName, spellId, friendly)
  local overrides = CooldownWatchConfiguration[OverridesStoreField(friendly)]

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
  @param {boolean} friendly
    Optional. true reads the FRIENDLY-side toggle

  @return {boolean}
    true  - If the worst-case cooldown should be assumed
    false - Otherwise (disabled, or never configured)
]]--
function me.IsCooldownWorstCaseAssumed(categoryName, spellId, friendly)
  return me.GetCooldownWorstCaseOverride(categoryName, spellId, friendly) == true
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
  @param {boolean} friendly
    Optional. true resolves against the FRIENDLY-side toggle. The global
    default is deliberately shared by both sides (see globalAssumeWorstCase)

  @return {boolean}
]]--
function me.IsWorstCaseEffective(categoryName, spellId, friendly)
  local override = me.GetCooldownWorstCaseOverride(categoryName, spellId, friendly)

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
  @param {boolean} friendly
    Optional. true writes the FRIENDLY-side store (see OverridesStoreField)

  @return {number | nil}
    The value that was stored — callers display this instead of the raw input.
    nil when the override was cleared or rejected.
]]--
local function UpdateOverrideValue(fieldName, value, categoryName, spellId, friendly)
  local storeField = OverridesStoreField(friendly)
  local overrides = CooldownWatchConfiguration[storeField]

  if value == nil then
    if overrides and overrides[categoryName] and overrides[categoryName][spellId] then
      overrides[categoryName][spellId][fieldName] = nil
      mod.logger.LogDebug(me.tag, "Cleared " .. fieldName .. " override (" .. storeField .. "): "
        .. categoryName .. " - " .. spellId)
    end

    return nil
  end

  if not IsValidOverrideValue(value) then
    mod.logger.LogWarn(me.tag, "Rejected invalid " .. fieldName .. " override: "
      .. categoryName .. " - " .. spellId .. " - " .. tostring(value))

    return nil
  end

  --[[
    Lazily create the table chain: the store itself may be nil when
    SetupConfiguration never ran (headless test harness), and the per-spell
    entry is table-valued so the worst-case toggle survives a value edit.
  ]]--
  if overrides == nil then
    overrides = {}
    CooldownWatchConfiguration[storeField] = overrides
  end

  if overrides[categoryName] == nil then
    overrides[categoryName] = {}
  end

  if overrides[categoryName][spellId] == nil then
    overrides[categoryName][spellId] = {}
  end

  overrides[categoryName][spellId][fieldName] = value
  mod.logger.LogDebug(me.tag, "Set " .. fieldName .. " override (" .. storeField .. "): "
    .. categoryName .. " - " .. spellId .. " - " .. value)

  return value
end

--[[
  Read one numeric field of a spell's override entry

  @param {string} fieldName
  @param {string} categoryName
  @param {number} spellId
  @param {boolean} friendly
    Optional. true reads the FRIENDLY-side store (see OverridesStoreField)

  @return {number | nil}
]]--
local function GetOverrideValue(fieldName, categoryName, spellId, friendly)
  local overrides = CooldownWatchConfiguration[OverridesStoreField(friendly)]

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
  @param {boolean} friendly
    Optional. true writes the FRIENDLY-side override

  @return {number | nil}
    The value that was stored, nil when it was cleared or rejected
]]--
function me.UpdateCooldownManualOverride(value, categoryName, spellId, friendly)
  return UpdateOverrideValue("value", value, categoryName, spellId, friendly)
end

--[[
  Get the manual cooldown override for a spell in a certain category

  @param {string} categoryName
  @param {number} spellId
  @param {boolean} friendly
    Optional. true reads the FRIENDLY-side override

  @return {number | nil}
    number - The override in seconds
    nil    - Never configured; the worst-case resolution applies
]]--
function me.GetCooldownManualOverride(categoryName, spellId, friendly)
  return GetOverrideValue("value", categoryName, spellId, friendly)
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
  @param {boolean} friendly
    Optional. true writes the FRIENDLY-side value. The below-base-cooldown
    rule is the same on both sides - it is a property of the catalog entry,
    not of the store the value lands in

  @return {number | nil}
    The value that was stored, nil when it was cleared or rejected
]]--
function me.UpdateCooldownWorstCaseValue(value, categoryName, spellId, friendly)
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

  return UpdateOverrideValue("worstCaseValue", value, categoryName, spellId, friendly)
end

--[[
  Get the per-spell worst-case cooldown value for a spell in a certain category

  @param {string} categoryName
  @param {number} spellId
  @param {boolean} friendly
    Optional. true reads the FRIENDLY-side value

  @return {number | nil}
    number - The player's worst-case value in seconds
    nil    - Never configured; the catalog's cooldownWorstCase applies
]]--
function me.GetCooldownWorstCaseValue(categoryName, spellId, friendly)
  return GetOverrideValue("worstCaseValue", categoryName, spellId, friendly)
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

--[[
  Update whether cooldowns cast by FRIENDLY players (and their pets) are
  tracked at all. The master switch in front of the per-spell friendly-side
  state - with it off, CombatLog never enters the friendly branch.

  @param {boolean} enabled
    Whether friendly cooldown tracking should be enabled
]]--
function me.UpdateTrackFriendlyCooldownsState(enabled)
  if enabled then
    CooldownWatchConfiguration.trackFriendlyCooldowns = true
    mod.logger.LogDebug(me.tag, "Enabled friendly cooldown tracking")
  else
    CooldownWatchConfiguration.trackFriendlyCooldowns = false
    mod.logger.LogDebug(me.tag, "Disabled friendly cooldown tracking")
  end
end

--[[
  @return {boolean}
    true  - If cooldowns of friendly players are tracked
    false - Otherwise (disabled, or never configured - friendly tracking is
            opt-in)
]]--
function me.IsTrackFriendlyCooldownsEnabled()
  return CooldownWatchConfiguration.trackFriendlyCooldowns == true
end

--[[
  Update whether targeting a FRIENDLY player (or their pet) shows that player's
  tracked cooldowns on the target cooldown bar. Deliberately does NOT touch
  trackFriendlyCooldowns - the two flags are independent, and with tracking off
  the bar simply stays empty for friendly targets.

  @param {boolean} enabled
    Whether friendly targets should show their cooldowns on the target bar
]]--
function me.UpdateShowFriendlyTargetCooldownsState(enabled)
  if enabled then
    CooldownWatchConfiguration.showFriendlyTargetCooldowns = true
    mod.logger.LogDebug(me.tag, "Enabled friendly target cooldown display")
  else
    CooldownWatchConfiguration.showFriendlyTargetCooldowns = false
    mod.logger.LogDebug(me.tag, "Disabled friendly target cooldown display")
  end
end

--[[
  @return {boolean}
    true  - If targeting a friendly player shows their cooldowns on the
            target cooldown bar
    false - Otherwise (disabled, or never configured - the display is opt-in)
]]--
function me.IsShowFriendlyTargetCooldownsEnabled()
  return CooldownWatchConfiguration.showFriendlyTargetCooldowns == true
end

--[[
  Every proximity accessor below takes an optional trailing `friendly` flag
  that routes the read or write to the FRIENDLY proximity window's block
  instead of the enemy window's - the same convention the per-spell accessors
  above follow. Omitting it (every historical call site) keeps the enemy-side
  behavior bit-for-bit. The two helpers are the single place the side ->
  block-field / block-defaults mapping lives.

  @param {boolean} friendly
    Optional. true routes to the friendly window's block

  @return {string}
    The CooldownWatchConfiguration field name of the selected block
]]--
local function ProximityStoreField(friendly)
  if friendly then
    return "friendlyProximityCooldowns"
  end

  return "proximityCooldowns"
end

local function GetProximityDefaultsForSide(friendly)
  if friendly then
    return GetFriendlyProximityCooldownsDefaults()
  end

  return GetProximityCooldownsDefaults()
end

--[[
  Lazily access a proximity cooldowns block. It may be nil when
  SetupConfiguration never ran (headless test harness), in which case it is
  seeded from the shipped defaults - identical to what the reconcile would
  have filled in.

  @param {boolean} friendly
    Optional. true accesses the friendly window's block

  @return {table}
]]--
local function GetProximityCooldowns(friendly)
  local storeField = ProximityStoreField(friendly)

  if CooldownWatchConfiguration[storeField] == nil then
    CooldownWatchConfiguration[storeField] = GetProximityDefaultsForSide(friendly)
  end

  return CooldownWatchConfiguration[storeField]
end

--[[
  Read one field of a proximity cooldowns block. A field an older saved shape
  is missing resolves to its shipped default, the same value the reconcile
  would fill in on the next load.

  @param {string} fieldName
  @param {boolean} friendly
    Optional. true reads the friendly window's block
  @return {any}
]]--
local function GetProximityCooldownField(fieldName, friendly)
  local value = GetProximityCooldowns(friendly)[fieldName]

  if value == nil then
    return GetProximityDefaultsForSide(friendly)[fieldName]
  end

  return value
end

--[[
  Write one field of a proximity cooldowns block. Validation stays with the
  public accessors - this only owns the lazy block creation and the logging.

  @param {string} fieldName
  @param {any} value
  @param {boolean} friendly
    Optional. true writes the friendly window's block
]]--
local function UpdateProximityCooldownField(fieldName, value, friendly)
  GetProximityCooldowns(friendly)[fieldName] = value
  mod.logger.LogDebug(me.tag, "Set " .. ProximityStoreField(friendly) .. "."
    .. fieldName .. " - " .. tostring(value))
end

--[[
  Update whether the proximity cooldown window is enabled at all

  @param {boolean} enabled
  @param {boolean} friendly
    Optional. true writes the friendly window's option
]]--
function me.UpdateProximityCooldownsEnabled(enabled, friendly)
  UpdateProximityCooldownField("enabled", enabled == true, friendly)
end

--[[
  @param {boolean} friendly
    Optional. true reads the friendly window's option

  @return {boolean}
    true  - If the proximity cooldown window is enabled
    false - Otherwise (disabled, or never configured - the window is opt-in)
]]--
function me.IsProximityCooldownsEnabled(friendly)
  return GetProximityCooldownField("enabled", friendly) == true
end

--[[
  Update whether the proximity cooldown window is locked from moving

  @param {boolean} locked
  @param {boolean} friendly
    Optional. true writes the friendly window's option
]]--
function me.UpdateProximityCooldownsLocked(locked, friendly)
  UpdateProximityCooldownField("locked", locked == true, friendly)
end

--[[
  @param {boolean} friendly
    Optional. true reads the friendly window's option

  @return {boolean}
    true  - If the proximity cooldown window is locked
    false - If the proximity cooldown window is not locked
]]--
function me.IsProximityCooldownsLocked(friendly)
  return GetProximityCooldownField("locked", friendly) == true
end

--[[
  Update the render scale of the proximity cooldown window. Only basic sanity
  is enforced here - a positive finite number. The slider bounds belong to the
  options ui, which is the sole producer of player-entered values.

  @param {number} scale
  @param {boolean} friendly
    Optional. true writes the friendly window's option

  @return {number | nil}
    The value that was stored, nil when it was rejected
]]--
function me.UpdateProximityCooldownsScale(scale, friendly)
  if type(scale) ~= "number"
    or scale ~= scale -- NaN is the only value not equal to itself
    or scale <= 0
    or scale == math.huge then
    mod.logger.LogWarn(me.tag, "Rejected invalid proximity window scale: " .. tostring(scale))

    return nil
  end

  UpdateProximityCooldownField("scale", scale, friendly)

  return scale
end

--[[
  @param {boolean} friendly
    Optional. true reads the friendly window's option

  @return {number}
    The render scale of the proximity cooldown window
]]--
function me.GetProximityCooldownsScale(friendly)
  return GetProximityCooldownField("scale", friendly)
end

--[[
  Update how many cooldowns the proximity cooldown window displays at once.
  Must be a positive integer - there is no upper bound here, the render layer
  truncates to its slot count either way.

  @param {number} maxDisplayedCooldowns
  @param {boolean} friendly
    Optional. true writes the friendly window's option

  @return {number | nil}
    The value that was stored, nil when it was rejected
]]--
function me.UpdateProximityCooldownsMaxDisplayed(maxDisplayedCooldowns, friendly)
  if type(maxDisplayedCooldowns) ~= "number"
    or maxDisplayedCooldowns ~= maxDisplayedCooldowns -- NaN
    or maxDisplayedCooldowns <= 0
    or maxDisplayedCooldowns == math.huge
    or maxDisplayedCooldowns ~= math.floor(maxDisplayedCooldowns) then
    mod.logger.LogWarn(me.tag, "Rejected invalid proximity window display count: "
      .. tostring(maxDisplayedCooldowns))

    return nil
  end

  UpdateProximityCooldownField("maxDisplayedCooldowns", maxDisplayedCooldowns, friendly)

  return maxDisplayedCooldowns
end

--[[
  @param {boolean} friendly
    Optional. true reads the friendly window's option

  @return {number}
    How many cooldowns the proximity cooldown window displays at once
]]--
function me.GetProximityCooldownsMaxDisplayed(friendly)
  return GetProximityCooldownField("maxDisplayedCooldowns", friendly)
end

--[[
  Update whether cooldowns above RGCW_CONSTANTS.PROXIMITY_LONG_COOLDOWN_THRESHOLD
  are hidden from the proximity cooldown window

  @param {boolean} hideLongCooldowns
  @param {boolean} friendly
    Optional. true writes the friendly window's option
]]--
function me.UpdateProximityCooldownsHideLong(hideLongCooldowns, friendly)
  UpdateProximityCooldownField("hideLongCooldowns", hideLongCooldowns == true, friendly)
end

--[[
  @param {boolean} friendly
    Optional. true reads the friendly window's option (which defaults to
    showing long cooldowns - see GetFriendlyProximityCooldownsDefaults)

  @return {boolean}
    true  - If cooldowns above the threshold are hidden from the proximity
            cooldown window
    false - If every tracked cooldown is shown
]]--
function me.IsProximityCooldownsHideLongEnabled(friendly)
  return GetProximityCooldownField("hideLongCooldowns", friendly) == true
end

--[[
  The scope values the friendly proximity window accepts. Anything else is a
  typo or a foreign import and is rejected rather than stored - an unknown
  scope would silently render like "all" (see GroupRoster.IsGuidInScope).
]]--
local VALID_PROXIMITY_SCOPES = {
  [RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP] = true,
  [RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_RAID] = true,
  [RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_ALL] = true
}

--[[
  Update which friendly casters the friendly proximity window renders. The
  scope exists on the friendly side only, so unlike the shared accessors above
  there is no trailing flag to pass.

  @param {string} scope
    One of RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP / _RAID / _ALL

  @return {string | nil}
    The value that was stored, nil when it was rejected
]]--
function me.UpdateFriendlyProximityCooldownsScope(scope)
  if VALID_PROXIMITY_SCOPES[scope] ~= true then
    mod.logger.LogWarn(me.tag, "Rejected invalid friendly proximity scope: " .. tostring(scope))

    return nil
  end

  UpdateProximityCooldownField("scope", scope, true)

  return scope
end

--[[
  @return {string}
    Which friendly casters the friendly proximity window renders (one of
    RGCW_CONSTANTS.PROXIMITY_COOLDOWN_SCOPE_GROUP / _RAID / _ALL)
]]--
function me.GetFriendlyProximityCooldownsScope()
  return GetProximityCooldownField("scope", true)
end
