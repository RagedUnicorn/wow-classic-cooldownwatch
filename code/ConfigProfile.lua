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
  CooldownWatch settings profiles - the family feature every sibling addon carries.

  Owns everything that makes a "CooldownWatch profile": which configuration
  fields are part of a profile, snapshotting the live config into a profile and
  applying a profile back, encoding a profile to / from a portable string (via
  the generic rgcw.serializer + rgcw.encoder modules), and the per-character
  named-profile store kept in CooldownWatchConfiguration.profiles.

  One stored profile is the ACTIVE profile, named by CooldownWatchConfiguration.activeProfile
  (bookkeeping outside GetDefaults - the reconcile must not backfill it, adoption keys
  on nil). The live configuration is what the player edits; it is mirrored into the
  active profile's stored copy at the moments that matter - before a switch, on
  PLAYER_LOGOUT (code/Core.lua), on export, after a reset to defaults and at login
  (EnsureActiveProfile) - so a profile never goes stale behind the player's back and
  switching never loses an edit. Between those moments the live SavedVariable is the
  truth; nothing hooks the individual setters. "Default" is the editable home profile
  every character starts on: seeded from the factory settings only when absent, never
  deleted or renamed, and reset through ResetActiveProfile rather than re-loaded.

  Deliberately named configProfile - rgcw.profile is taken by the curated
  default-enabled spell sets (mod.profile.IsDefaultEnabled()).
]]--

local mod = rgcw
local me = {}
mod.configProfile = me

me.tag = "ConfigProfile"

--[[
  Bumped when the on-the-wire profile payload changes shape. Import refuses any
  string whose schemaVersion is newer than this build understands.
]]--
local SCHEMA_VERSION = 1
--[[
  Identifies a CooldownWatch profile string and lets import fast-reject foreign
  strings before any decoding. The authoritative provenance check is the
  envelope's addon/schemaVersion fields.
]]--
local EXPORT_PREFIX = "CooldownWatch1:"
local ADDON_TAG = "CooldownWatch"

--[[
  @param {any} value
  @return {boolean}
    true - if value is a number that is neither NaN nor infinite
]]--
local function IsFiniteNumber(value)
  return type(value) == "number"
    and value == value -- NaN is the only value not equal to itself
    and value ~= math.huge
    and value ~= -math.huge
end

--[[
  @param {number} min
  @param {number} max
  @return {function}
    a validator accepting a finite number within [min, max] - the range of the
    options slider that is the only other producer of the value
]]--
local function IsNumberInRange(min, max)
  return function(value)
    return IsFiniteNumber(value) and value >= min and value <= max
  end
end

--[[
  @param {any} value
  @return {boolean}
]]--
local function IsBoolean(value)
  return type(value) == "boolean"
end

--[[
  @param {any} value
  @return {boolean}
    true - if value is nil or a boolean, the shape of an optional flag
]]--
local function IsOptionalBoolean(value)
  return value == nil or type(value) == "boolean"
end

--[[
  @param {any} value
  @param {function} isValidEntry
    called with each value of the table
  @return {boolean}
    true - if value is a table whose every value passes isValidEntry
]]--
local function IsTableOf(value, isValidEntry)
  if type(value) ~= "table" then
    return false
  end

  for _, entry in pairs(value) do
    if not isValidEntry(entry) then
      return false
    end
  end

  return true
end

--[[
  A per-side tracking store: category -> spellId -> explicit enabled flag.

  @param {any} value
  @return {boolean}
]]--
local function IsValidCooldownConfiguration(value)
  return IsTableOf(value, function(category)
    return IsTableOf(category, IsBoolean)
  end)
end

--[[
  A per-side overrides store: category -> spellId -> { worstCase, value,
  worstCaseValue }, the numbers held to the same rule the store enforces on
  player input.

  @param {any} value
  @return {boolean}
]]--
local function IsValidCooldownOverrides(value)
  local function IsOptionalOverrideValue(overrideValue)
    return overrideValue == nil or mod.configuration.IsValidOverrideValue(overrideValue)
  end

  return IsTableOf(value, function(category)
    return IsTableOf(category, function(entry)
      return type(entry) == "table"
        and IsOptionalBoolean(entry.worstCase)
        and IsOptionalOverrideValue(entry.value)
        and IsOptionalOverrideValue(entry.worstCaseValue)
    end)
  end)
end

--[[
  A proximity window options block. Every field is optional (an older-shaped
  block is backfilled by the reconcile on apply) and unknown keys are ignored
  (an old export may still carry the removed lock flag, which nothing reads).

  @param {any} value
  @return {boolean}
]]--
local function IsValidProximityCooldowns(value)
  if type(value) ~= "table" then
    return false
  end

  local isValidScale = IsNumberInRange(
    RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_MIN,
    RGCW_CONSTANTS.PROXIMITY_SCALE_SLIDER_MAX
  )
  local maxDisplayed = value.maxDisplayedCooldowns

  return IsOptionalBoolean(value.enabled)
    and IsOptionalBoolean(value.hideLongCooldowns)
    and (value.scale == nil or isValidScale(value.scale))
    and (maxDisplayed == nil
      or (IsFiniteNumber(maxDisplayed) and maxDisplayed >= 1 and maxDisplayed == math.floor(maxDisplayed)))
    and (value.scope == nil or mod.configuration.IsValidProximityScope(value.scope))
end

-- the anchor points SetPoint accepts
local VALID_ANCHOR_POINTS = {
  ["TOPLEFT"] = true,
  ["TOP"] = true,
  ["TOPRIGHT"] = true,
  ["LEFT"] = true,
  ["CENTER"] = true,
  ["RIGHT"] = true,
  ["BOTTOMLEFT"] = true,
  ["BOTTOM"] = true,
  ["BOTTOMRIGHT"] = true
}

--[[
  The saved frame positions: frameName -> the SetPoint arguments a drag stored.
  relativeTo is nil (relative to the parent) or a frame name, a missing
  relativePoint defaults to point in SetPoint.

  @param {any} value
  @return {boolean}
]]--
local function IsValidFrames(value)
  return IsTableOf(value, function(position)
    return type(position) == "table"
      and VALID_ANCHOR_POINTS[position.point] == true
      and (position.relativePoint == nil or VALID_ANCHOR_POINTS[position.relativePoint] == true)
      and (position.relativeTo == nil or type(position.relativeTo) == "string")
      and IsFiniteNumber(position.posX)
      and IsFiniteNumber(position.posY)
  end)
end

--[[
  The single source of truth for what a profile contains: every configurable field
  with the validator an imported value must pass. Snapshot and apply iterate the
  names, import rejects a string whose payload carries a field that fails its
  validator - a crafted or corrupt value would otherwise flow straight into
  SetScale / SetPoint or break the category menus after the reload. Adding a new
  configurable option is a one-line change here. Deliberately excludes the
  bookkeeping (addonVersion, lastNotifiedVersion, and activeProfile - which
  profile the live configuration belongs to is not a setting of that profile) and
  the profile store itself (profiles).
]]--
local PROFILE_FIELD_SPEC = {
  {
    ["name"] = "targetCooldownBarScale",
    ["isValid"] = IsNumberInRange(
      RGCW_CONSTANTS.TARGET_BAR_SCALE_SLIDER_MIN,
      RGCW_CONSTANTS.TARGET_BAR_SCALE_SLIDER_MAX
    )
  },
  { ["name"] = "globalAssumeWorstCase", ["isValid"] = IsBoolean },
  { ["name"] = "trackFriendlyCooldowns", ["isValid"] = IsBoolean },
  { ["name"] = "showFriendlyTargetCooldowns", ["isValid"] = IsBoolean },
  { ["name"] = "cooldownConfiguration", ["isValid"] = IsValidCooldownConfiguration },
  { ["name"] = "cooldownOverrides", ["isValid"] = IsValidCooldownOverrides },
  { ["name"] = "friendlyCooldownConfiguration", ["isValid"] = IsValidCooldownConfiguration },
  { ["name"] = "friendlyCooldownOverrides", ["isValid"] = IsValidCooldownOverrides },
  { ["name"] = "proximityCooldowns", ["isValid"] = IsValidProximityCooldowns },
  { ["name"] = "friendlyProximityCooldowns", ["isValid"] = IsValidProximityCooldowns },
  { ["name"] = "frames", ["isValid"] = IsValidFrames }
}

--[[
  Ordered list of profile field names, derived from PROFILE_FIELD_SPEC. Public so
  BuildSnapshot / ApplySnapshot and the specs can iterate it.
]]--
me.PROFILE_FIELDS = {}

for _, spec in ipairs(PROFILE_FIELD_SPEC) do
  me.PROFILE_FIELDS[#me.PROFILE_FIELDS + 1] = spec.name
end

--[[
  @param {table} payload
  @return {boolean}
    true - if every profile field the payload carries passes its validator
    (an absent field is fine, the reconcile backfills it on apply)
]]--
local function IsValidPayload(payload)
  for _, spec in ipairs(PROFILE_FIELD_SPEC) do
    local value = payload[spec.name]

    if value ~= nil and not spec.isValid(value) then
      mod.logger.LogWarn(me.tag, "Rejected imported profile - invalid field: " .. spec.name)

      return false
    end
  end

  return true
end

--[[
  Recursively copy a value so a profile and the live config never share table
  references.

  @param {any} value
  @return {any}
]]--
local function DeepCopy(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}

  for itemKey, itemValue in pairs(value) do
    copy[itemKey] = DeepCopy(itemValue)
  end

  return copy
end

--[[
  Lazily access the per-character profile store.

  @return {table}
    map of profileName -> payload snapshot
]]--
local function GetStore()
  if CooldownWatchConfiguration.profiles == nil then
    CooldownWatchConfiguration.profiles = {}
  end

  return CooldownWatchConfiguration.profiles
end

--[[
  @param {string} name
  @return {boolean}
    true - if the name is the reserved default profile name
    false - otherwise
]]--
function me.IsDefaultProfile(name)
  return name == RGCW_CONSTANTS.DEFAULT_PROFILE_NAME
end

--[[
  Length of a name in characters. A plain `#name` would count bytes and cut a localized
  name short, so continuation bytes (0x80-0xBF) of a utf-8 sequence are not counted.

  @param {string} name
  @return {number}
]]--
local function NameLength(name)
  local _, count = string.gsub(name, "[^\128-\191]", "")

  return count
end

--[[
  @param {string} name
  @return {boolean}
    true - if the name exceeds RGCW_CONSTANTS.PROFILE_NAME_MAX_LENGTH characters
    false - otherwise
]]--
function me.IsNameTooLong(name)
  if type(name) ~= "string" then
    return false
  end

  return NameLength(name) > RGCW_CONSTANTS.PROFILE_NAME_MAX_LENGTH
end

--[[
  Build a snapshot of the configurable fields out of the shipped defaults rather than
  the live configuration: the factory baseline a fresh character starts on, the seed
  of the Default profile and what ResetActiveProfile restores.

  @return {table}
]]--
function me.BuildDefaultSnapshot()
  local defaults = mod.configuration.GetDefaults()
  local snapshot = {}

  for _, field in ipairs(me.PROFILE_FIELDS) do
    snapshot[field] = DeepCopy(defaults[field])
  end

  return snapshot
end

--[[
  Seed the undeletable default profile from the running version's factory defaults
  when the store has none - a fresh character, or a store from before profiles
  existed. Called on every login (see code/Core.lua Initialize) right after the
  configuration was set up and ahead of the active profile adoption.

  Never re-seeds: Default is the editable home profile, so its stored copy holds the
  player's own settings whenever it is the active one and the mirror is its only
  writer after the seed. The factory settings stay reachable through
  ResetActiveProfile.
]]--
function me.EnsureDefaultProfile()
  local store = GetStore()

  if store[RGCW_CONSTANTS.DEFAULT_PROFILE_NAME] == nil then
    store[RGCW_CONSTANTS.DEFAULT_PROFILE_NAME] = me.BuildDefaultSnapshot()
  end
end

--[[
  Build a snapshot of the configurable fields out of the live
  CooldownWatchConfiguration.

  @return {table}
]]--
function me.BuildSnapshot()
  local snapshot = {}

  for _, field in ipairs(me.PROFILE_FIELDS) do
    snapshot[field] = DeepCopy(CooldownWatchConfiguration[field])
  end

  return snapshot
end

--[[
  Overwrite the configurable fields of the live CooldownWatchConfiguration from
  a snapshot. Missing fields are left for Configuration.SetupConfiguration to
  backfill with defaults, so an older-schema profile applies cleanly. The
  caller is responsible for refreshing the UI afterwards (a ReloadUI).

  @param {table} payload
]]--
function me.ApplySnapshot(payload)
  if type(payload) ~= "table" then return end

  for _, field in ipairs(me.PROFILE_FIELDS) do
    if payload[field] ~= nil then
      CooldownWatchConfiguration[field] = DeepCopy(payload[field])
    end
  end

  -- backfill any field the imported profile did not carry
  mod.configuration.SetupConfiguration()
end

--[[
  Encode a profile payload into a portable, copy-pasteable string.

  @param {table} payload
    a snapshot as produced by me.BuildSnapshot
  @param {string} name
    the profile name, carried in the envelope so import can suggest it

  @return {string}
]]--
function me.ExportString(payload, name)
  local envelope = {
    addon = ADDON_TAG,
    schemaVersion = SCHEMA_VERSION,
    addonVersion = CooldownWatchConfiguration.addonVersion,
    name = name,
    payload = payload
  }

  return EXPORT_PREFIX .. mod.encoder.Encode(mod.serializer.Serialize(envelope))
end

--[[
  Reduce an imported payload to the profile fields. The string is untrusted input:
  keys outside PROFILE_FIELDS would otherwise be stored with the profile and carried
  along by every later export. They are inert on apply (ApplySnapshot copies
  PROFILE_FIELDS only), so dropping them loses nothing.

  @param {table} payload
  @return {table}
    a new table holding only the payload's PROFILE_FIELDS entries
]]--
local function ProjectPayload(payload)
  local projected = {}

  for _, field in ipairs(me.PROFILE_FIELDS) do
    projected[field] = payload[field]
  end

  return projected
end

--[[
  Decode and validate a profile string. Never raises - returns a localization
  error key on any failure and leaves all state untouched.

  @param {string} encoded

  @return {table | nil}, {string | nil}
    the decoded envelope { addon, schemaVersion, addonVersion, name, payload },
    or nil plus a localization key describing the failure
]]--
function me.ImportString(encoded)
  if type(encoded) ~= "string" or #encoded > RGCW_CONSTANTS.PROFILE_IMPORT_MAX_LENGTH then
    return nil, "profile_error_invalid"
  end

  -- strip any whitespace a paste may have wrapped around / into the string
  encoded = string.gsub(encoded, "%s+", "")

  if encoded == "" then
    return nil, "profile_error_empty"
  end

  if string.sub(encoded, 1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
    return nil, "profile_error_invalid"
  end

  local serialized, decodeErr = mod.encoder.Decode(string.sub(encoded, #EXPORT_PREFIX + 1))

  if not serialized then
    if decodeErr == "checksum" then
      return nil, "profile_error_checksum"
    end

    return nil, "profile_error_invalid"
  end

  local envelope = mod.serializer.Deserialize(serialized)

  if type(envelope) ~= "table" then
    return nil, "profile_error_invalid"
  end

  if envelope.addon ~= ADDON_TAG then
    return nil, "profile_error_wrong_addon"
  end

  if type(envelope.schemaVersion) ~= "number" or envelope.schemaVersion > SCHEMA_VERSION then
    return nil, "profile_error_version"
  end

  if type(envelope.payload) ~= "table" then
    return nil, "profile_error_invalid"
  end

  envelope.payload = ProjectPayload(envelope.payload)

  if not IsValidPayload(envelope.payload) then
    return nil, "profile_error_invalid"
  end

  -- the name only prefills the import popup's edit box; anything but a string would
  -- raise in SetText, so it is dropped and the player types a name instead
  if type(envelope.name) ~= "string" then
    envelope.name = nil
  end

  return envelope
end

--[[
  @return {table}
    the saved profile names, the default profile first and the rest sorted
]]--
function me.ListProfiles()
  local store = GetStore()
  local names = {}

  for name in pairs(store) do
    if not me.IsDefaultProfile(name) then
      names[#names + 1] = name
    end
  end

  table.sort(names)

  if store[RGCW_CONSTANTS.DEFAULT_PROFILE_NAME] ~= nil then
    table.insert(names, 1, RGCW_CONSTANTS.DEFAULT_PROFILE_NAME)
  end

  return names
end

--[[
  @param {string} name
  @return {boolean}
]]--
function me.ProfileExists(name)
  return GetStore()[name] ~= nil
end

--[[
  @param {string} name
  @return {table | nil}
    the stored payload snapshot, or nil if no such profile
]]--
function me.GetProfile(name)
  return GetStore()[name]
end

--[[
  Store (or overwrite) a named profile from a payload snapshot - the import path.
  The reserved default name is refused: the mirror (SaveActiveProfile) is the only
  writer of the Default profile's copy.

  @param {string} name
  @param {table} payload

  @return {boolean}
    true on success, false if name is the default profile
]]--
function me.SaveProfile(name, payload)
  if me.IsDefaultProfile(name) then
    return false
  end

  GetStore()[name] = DeepCopy(payload)

  return true
end

--[[
  Delete a stored profile. The default profile can never be deleted. Deleting the
  active profile falls back to Default: its stored copy is applied to the live
  configuration and it becomes the active one - with no mirror before or after,
  which would only resurrect the deleted profile - and the caller reloads the UI
  when the second return value says so.

  @param {string} name

  @return {boolean}, {boolean}
    true on success, false if name is the default profile;
    whether the live configuration fell back to Default (the active profile went)
]]--
function me.DeleteProfile(name)
  if me.IsDefaultProfile(name) then
    return false
  end

  local store = GetStore()

  store[name] = nil

  if name ~= CooldownWatchConfiguration.activeProfile then
    return true, false
  end

  me.EnsureDefaultProfile()
  me.ApplySnapshot(store[RGCW_CONSTANTS.DEFAULT_PROFILE_NAME])
  CooldownWatchConfiguration.activeProfile = RGCW_CONSTANTS.DEFAULT_PROFILE_NAME

  return true, true
end

--[[
  Rename a stored profile. The default profile can neither be renamed nor be replaced
  by renaming another profile onto its name. Renaming the active profile moves the
  active name along. Renaming a profile to its own name is a successful no-op - the
  move below would otherwise copy and then nil the same key, deleting the profile.

  @param {string} oldName
  @param {string} newName

  @return {boolean}
    true on success, false if oldName does not exist or either name is the default profile
]]--
function me.RenameProfile(oldName, newName)
  if me.IsDefaultProfile(oldName) or me.IsDefaultProfile(newName) then
    return false
  end

  local store = GetStore()

  if store[oldName] == nil then
    return false
  end

  if oldName == newName then
    return true
  end

  store[newName] = store[oldName]
  store[oldName] = nil

  if CooldownWatchConfiguration.activeProfile == oldName then
    CooldownWatchConfiguration.activeProfile = newName
  end

  return true
end

--[[
  @return {string|nil}
    the name of the active profile; nil on a store from before the active profile
    existed, until EnsureActiveProfile adopted one
]]--
function me.GetActiveProfileName()
  return CooldownWatchConfiguration.activeProfile
end

--[[
  Mirror the live configuration into the active profile's stored copy - the one
  writer of a profile from the live state. Bypasses SaveProfile on purpose: Default
  is a home profile like any other here. A missing or dangling active name (a store
  from before the active profile existed, a hand-edited file) is repaired to Default
  first, so the mirror always lands somewhere.

  Runs before a switch, on PLAYER_LOGOUT, on export, after a reset and at login;
  between those moments the live SavedVariable is the truth.

  @return {string}
    the name the configuration was mirrored into
]]--
function me.SaveActiveProfile()
  local store = GetStore()
  local name = CooldownWatchConfiguration.activeProfile

  if name == nil or store[name] == nil then
    name = RGCW_CONSTANTS.DEFAULT_PROFILE_NAME
    CooldownWatchConfiguration.activeProfile = name
  end

  store[name] = me.BuildSnapshot()

  return name
end

--[[
  Adopt the active profile at login (see code/Core.lua Initialize, right after
  EnsureDefaultProfile) and mirror the live configuration into it. A store that
  names a stored profile keeps it. One that does not - the first login after the
  upgrade from the snapshot model, or a name that no longer exists - activates the
  first profile other than Default whose stored copy deep-equals the live
  configuration (the player applied it and changed nothing since), else Default.
  Nothing is lost either way: the live settings become the active profile's, and the
  factory copy stays reachable through ResetActiveProfile. The closing mirror is also
  the self-heal for a logout the mirror missed (a crash).
]]--
function me.EnsureActiveProfile()
  local store = GetStore()
  local name = CooldownWatchConfiguration.activeProfile

  if name == nil or store[name] == nil then
    local live = me.BuildSnapshot()

    name = RGCW_CONSTANTS.DEFAULT_PROFILE_NAME

    for _, candidate in ipairs(me.ListProfiles()) do
      if not me.IsDefaultProfile(candidate) and mod.common.DeepEquals(store[candidate], live) then
        name = candidate
        break
      end
    end

    CooldownWatchConfiguration.activeProfile = name
    mod.logger.LogInfo(me.tag, "Adopted \"" .. name .. "\" as the active settings profile")
  end

  me.SaveActiveProfile()
end

--[[
  Switch to a stored profile: mirror the live configuration into the active profile
  first, so nothing edited since it was activated is lost, then apply the target and
  make it the active one. The caller reloads the UI afterwards (every surface
  rebuilds from the applied state at login). Switching to the profile that is
  active already is a no-op.

  @param {string} name

  @return {boolean}
    true on a real switch, false for an unknown name or the active profile
]]--
function me.SwitchProfile(name)
  local store = GetStore()

  if store[name] == nil or name == CooldownWatchConfiguration.activeProfile then
    return false
  end

  me.SaveActiveProfile()
  me.ApplySnapshot(store[name])
  CooldownWatchConfiguration.activeProfile = name

  return true
end

--[[
  Store a copy of the current settings under a new name and make it the active
  profile. The live configuration is unchanged, so no reload is needed; the profile
  that was active keeps everything edited up to now (it is mirrored first).

  @param {string} name

  @return {boolean}
    true on success, false for a blank name, the reserved default name or a name in use
]]--
function me.CreateProfile(name)
  local store = GetStore()

  if type(name) ~= "string" or name == "" or me.IsDefaultProfile(name) or store[name] ~= nil then
    return false
  end

  local active = me.SaveActiveProfile()

  store[name] = DeepCopy(store[active])
  CooldownWatchConfiguration.activeProfile = name

  return true
end

--[[
  Reset the active profile to the factory settings: the shipped defaults are
  applied to the live configuration and mirrored into the active profile. The
  caller reloads the UI afterwards. This is what "reset to defaults" means since
  Default became an editable profile - loading Default no longer resets anything.
]]--
function me.ResetActiveProfile()
  me.ApplySnapshot(me.BuildDefaultSnapshot())
  me.SaveActiveProfile()
end
