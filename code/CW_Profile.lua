--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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
mod.profile = me

me.tag = "Profile"

-- allow for a maximum of 10 profiles
local maxProfiles = 10
local maxProfileNameLength = 25

--[[
  ["type"] = {
    -- e.g. paladin, racials etc
    ["spellName"] = {
      -- e.g. lay_on_hands as found in SpellMap
      ["spellActive"] = false
    }
  }
]]--
local defaultProfile = {
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
}

function me.GetDefaultProfile()
  return mod.common.Clone(defaultProfile)
end

function me.GetMaxProfileNameLength()
  return maxProfileNameLength
end

--[[
  Add a new profile to the list of profiles

  @param {string} profileName
  @param {table} spellConfiguration
  @param {table} selfAvoidSpellConfiguration
  @param {table} spellEnemyAvoidList
]]--
function me.AddNewProfile(profileName, spellConfiguration, selfAvoidSpellConfiguration, enemyAvoidSpellConfiguration)
  if table.getn(CooldownWatchProfiles) >= maxProfiles then
    mod.logger.PrintUserError(
      string.format(pvpw.L["user_message_add_new_profile_max_reached"], maxProfiles) -- TODO
    )
    return
  end

  for i = 1, table.getn(CooldownWatchProfiles) do
    if CooldownWatchProfiles[i].name == profileName then
      mod.logger.PrintUserError(pvpw.L["user_message_select_profile_already_exists"])
      return
    end
  end

  local profile = {
    name = profileName,
    ["spellConfiguration"] = mod.common.Clone(spellConfiguration),
    ["selfAvoidSpellConfiguration"] = mod.common.Clone(selfAvoidSpellConfiguration),
    ["enemyAvoidSpellConfiguration"] = mod.common.Clone(enemyAvoidSpellConfiguration)
  }

  table.insert(CooldownWatchProfiles, profile)
  mod.logger.LogDebug(me.tag, "Created new profile with name - " .. profileName)
end

--[[
  Delete the profile on the passed index

  @param {number} index
]]--
function me.DeleteProfile(index)
  table.remove(CooldownWatchProfiles, index)
  mod.logger.LogDebug(me.tag, "Removed profile on index " .. index)
end

--[[
  Activate the profile found at the passed index
  Important! Values have to be cloned because lua does not copy by value on tables

  @param {number} index
]]--
function me.ActivateProfile(index)
  PVPWarnOptions.spellList = nil
  PVPWarnOptions.spellList = mod.common.Clone(CooldownWatchProfiles[index].spellConfiguration)
  PVPWarnOptions.spellSelfAvoidList = nil
  PVPWarnOptions.spellSelfAvoidList = mod.common.Clone(CooldownWatchProfiles[index].selfAvoidSpellConfiguration)
  PVPWarnOptions.spellEnemyAvoidList = nil
  PVPWarnOptions.spellEnemyAvoidList = mod.common.Clone(CooldownWatchProfiles[index].enemyAvoidSpellConfiguration)
end

--[[
  Activate the profile found at the passed index
  Important! Values have to be cloned because lua does not copy by value on tables

  @param {number} index
]]--
function me.ActivateDefaultProfile()
  PVPWarnOptions.spellList = nil
  -- get the default configuration based on the current class
  PVPWarnOptions.spellList = mod.common.Clone(me.GetDefaultProfile())
  PVPWarnOptions.spellSelfAvoidList = nil
  PVPWarnOptions.spellSelfAvoidList = mod.common.Clone(defaultProfileSelfAvoidSpells)
  PVPWarnOptions.spellEnemyAvoidList = nil
  PVPWarnOptions.spellEnemyAvoidList = mod.common.Clone(defaultProfileEnemyAvoidSpells)
end
