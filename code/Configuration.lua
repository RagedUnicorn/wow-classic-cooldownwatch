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
  every other backfill (upgrade, applied profile) goes through me.GetDefaults below,
  which must stay in sync with the values declared here.
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
  for SetupConfiguration's nil-guards and for the frozen default profile
  (see code/ConfigProfile.lua BuildDefaultSnapshot). addonVersion is deliberately
  absent; it is stamped by SetAddonVersion.

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
  Set default values if property is nil. This might happen after an addon upgrade
]]--
function me.SetupConfiguration()
  for field, defaultValue in pairs(me.GetDefaults()) do
    if CooldownWatchConfiguration[field] == nil then
      mod.logger.LogInfo(me.tag, field .. " has unexpected nil value")
      CooldownWatchConfiguration[field] = defaultValue
    end
  end

  --[[
    Set saved variables with addon version. This can be used later to determine whether
    a migration path applies to the current saved variables or not
  ]]--
  me.SetAddonVersion()
end

--[[
  Set addon version on addon options. Before setting a new version make sure
  to run through migration paths.
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
  Update the manual cooldown override for a spell in a certain category. The
  manual value replaces the resolved cooldown entirely and beats both
  worst-case settings (see CooldownQueue.ResolveCooldown).

  Validation lives here rather than in the GUI so it applies to every caller
  and is testable under the headless harness:
   - nil clears the override (sibling fields on the entry survive)
   - non-numbers, NaN and values <= 0 are rejected without touching the store
   - values above the spell's base cooldown are capped at the base — the
     override can only lower the tracked time. A genuinely longer cooldown is
     a SpellMap data bug and should be fixed in the catalog instead

  @param {number | nil} value
    The override in seconds, or nil to clear it
  @param {string} categoryName
  @param {number} spellId

  @return {number | nil}
    The value that was stored (after capping) — callers display this instead
    of the raw input. nil when the override was cleared or rejected.
]]--
function me.UpdateCooldownManualOverride(value, categoryName, spellId)
  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if value == nil then
    if overrides and overrides[categoryName] and overrides[categoryName][spellId] then
      overrides[categoryName][spellId].value = nil
      mod.logger.LogDebug(me.tag, "Cleared manual cooldown override: " .. categoryName .. " - " .. spellId)
    end

    return nil
  end

  if type(value) ~= "number" or value ~= value or value <= 0 then
    mod.logger.LogWarn(me.tag, "Rejected invalid manual cooldown override: "
      .. categoryName .. " - " .. spellId .. " - " .. tostring(value))

    return nil
  end

  local _, _, spell = mod.spellMapHelper.GetSpellById(spellId)

  if spell and value > spell.cooldown then
    value = spell.cooldown
  end

  --[[
    Lazily create the table chain: cooldownOverrides itself may be nil when
    SetupConfiguration never ran (headless test harness), and the per-spell
    entry is table-valued so the worst-case toggle survives an override edit.
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

  overrides[categoryName][spellId].value = value
  mod.logger.LogDebug(me.tag, "Set manual cooldown override: "
    .. categoryName .. " - " .. spellId .. " - " .. value)

  return value
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
  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if overrides == nil or overrides[categoryName] == nil or overrides[categoryName][spellId] == nil then
    return nil
  end

  return overrides[categoryName][spellId].value
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
