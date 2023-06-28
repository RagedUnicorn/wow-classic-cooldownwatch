--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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
    Cooldown configuration
  ]]--
  ["cooldownConfiguration"] = {
    ["rogue"] = {},
    ["warrior"] = {},
    ["mage"] = {},
    ["warlock"] = {},
    ["hunter"] = {},
    ["paladin"] = {},
    ["priest"] = {},
    ["druid"] = {},
    ["shaman"] = {},
    ["misc"] = {}
  },
  --[[
    Initial addon version
  ]]--
  ["addonVersion"] = nil,
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
  -- if no version set so far make sure to set the current one
  if CooldownWatchConfiguration.addonVersion == nil then
    CooldownWatchConfiguration.addonVersion = GetAddOnMetadata(RGCW_CONSTANTS.ADDON_NAME, "Version")
  end

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
  @param {number} category
  @param {number} spellId
]]--
function me.UpdateCooldownConfigurationState(enabled, category, spellId)
  local config = CooldownWatchConfiguration.cooldownConfiguration
  local categoryName = RGCW_CONSTANTS.CATEGORIES[category].categoryName

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

  @param {number} category
  @param {number} spellId

  @return {nil | boolean}
    nil   - If no entry at all could be found
    true  - If cooldown is enabled
    false - If cooldown is disabled
]]--
function me.GetCooldownConfigurationState(category, spellId)
  local config = CooldownWatchConfiguration.cooldownConfiguration

  if category == nil then
    for _, configCategory in pairs(config) do
      if configCategory[spellId] then
        return true
      end
    end
  else
    local categoryName = RGCW_CONSTANTS.CATEGORIES[category].categoryName

    if config[categoryName] == nil then
      return nil -- no entry at all for category - abort
    end

    return config[categoryName][spellId]
  end
end
