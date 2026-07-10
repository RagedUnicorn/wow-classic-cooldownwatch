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

-- luacheck: globals GetAddOnMetadata

local mod = rgcw
local me = {}
mod.configuration = me

me.tag = "Configuration"

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
          worstCase = {boolean}
          -- true if the runtime should assume the worst-case cooldown
        }
      }
    }
  ]]--
  ["cooldownOverrides"] = nil,
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
  ["frames"] = {}
}

--[[
  Set default values if property is nil. This might happen after an addon upgrade
]]--
function me.SetupConfiguration()
  if CooldownWatchConfiguration.lockTargetCooldownBar == nil then
    mod.logger.LogInfo(me.tag, "lockTargetCooldownBar has unexpected nil value")
    CooldownWatchConfiguration.lockTargetCooldownBar = false
  end

  if CooldownWatchConfiguration.cooldownConfiguration == nil then
    mod.logger.LogInfo(me.tag, "cooldownConfiguration has unexpected nil value")
    CooldownWatchConfiguration.cooldownConfiguration = mod.profile.GetDefaultProfile()
  end

  if CooldownWatchConfiguration.cooldownOverrides == nil then
    mod.logger.LogInfo(me.tag, "cooldownOverrides has unexpected nil value")
    CooldownWatchConfiguration.cooldownOverrides = mod.profile.GetDefaultCooldownOverrides()
  end

  if CooldownWatchConfiguration.frames == nil then
    mod.logger.LogInfo(me.tag, "frames has unexpected nil value")
    CooldownWatchConfiguration.frames = {}
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
  CooldownWatchConfiguration.addonVersion = GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
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

  @param {string} categoryName
  @param {number} spellId

  @return {boolean}
    true  - If the cooldown is tracked (enabled) in the category
    false - Otherwise (disabled, or never configured in the category)
]]--
function me.GetCooldownConfigurationState(categoryName, spellId)
  local config = CooldownWatchConfiguration.cooldownConfiguration

  if config[categoryName] == nil then
    return false -- no entry for this category yet
  end

  return config[categoryName][spellId] == true
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
  Get whether the worst-case cooldown should be assumed for a spell in a
  certain category

  @param {string} categoryName
  @param {number} spellId

  @return {boolean}
    true  - If the worst-case cooldown should be assumed
    false - Otherwise (disabled, or never configured)
]]--
function me.IsCooldownWorstCaseAssumed(categoryName, spellId)
  local overrides = CooldownWatchConfiguration.cooldownOverrides

  if overrides == nil or overrides[categoryName] == nil or overrides[categoryName][spellId] == nil then
    return false
  end

  return overrides[categoryName][spellId].worstCase == true
end
