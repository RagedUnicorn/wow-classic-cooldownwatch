--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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
mod.combatLog = me

me.tag = "CombatLog"

--[[
  Processing the details of the current combat log event. Invoked when 'COMBAT_LOG_EVENT_UNFILTERED' is fired
]]--
function me.ProcessUnfilteredCombatLogEvent()
  local _, event, _, caster, casterName, sourceFlags, _, _, _, _, _, _, spellName = CombatLogGetCurrentEventInfo()

  --[[
    While debug mode is active we also allow friendly events to be processed. Otherwise only hostile player events are
    considered for processing.
  ]]--
  if not RGCW_ENVIRONMENT.DEBUG and not CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS)
    and not bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then

    mod.logger.LogDebug(me.tag, "Ignored non-hostile combatlog")
    return
  end

  if event == "SPELL_CAST_SUCCESS" then
    mod.logger.LogEvent(me.tag, "SPELL_CAST_SUCCESS")

    local castTime = GetTime()
    local normalizedSpellName = mod.common.NormalizeSpellname(spellName)
    local spell
    local englishClass
    --[[
      If the caster of the detected spell is our current target we can speed up
      the process of searching for the spell in the spellmap by figuring out the
      targets class.
    ]]--
    if caster == mod.target.GetCurrentTargetGuid() then
      _, englishClass = UnitClass(RGCW_CONSTANTS.UNIT_ID_TARGET)
      spell = mod.spellMap.FindSpell(normalizedSpellName, englishClass)
    else
      spell = mod.spellMap.FindSpell(normalizedSpellName)
    end

    if spell == nil then
      mod.logger.LogDebug(me.tag, "Spell is non-essential - aborting...")
      return
    end

    if me.IsCooldownTracked(spell.spellId, englishClass) then
      local name, _, iconId, _, _, _, spellUid = GetSpellInfo(spell.spellId)

      me.TrackCooldown(caster, casterName, spell, spell.spellId, castTime, iconId)
    else
      mod.logger.LogError(me.tag, "Spell is not enabled - aborting...")
      return
    end
  end
end

--[[
  @param {number} spellId
  @param {string} englishClass
    Optional class name - speeds up the searching process

  @return {boolean}
    true  - If the cooldown is enabled
    false - If the cooldown is disabled
]]--
function me.IsCooldownTracked(spellId, englishClass)
  assert(type(spellId) == "number",
    string.format("bad argument #1 to `IsCooldownTracked` (expected number got %s)", type(spellId)))

  if englishClass ~= nil then
    local category

    for i = 1, table.getn(RGCW_CONSTANTS.CATEGORIES) do
      if string.lower(englishClass) == RGCW_CONSTANTS.CATEGORIES[i].categoryName then
        category = i
        break
      end
    end

    return mod.configuration.GetCooldownConfigurationState(category, spellId)
  end

  return mod.configuration.GetCooldownConfigurationState(nil, spellId)
end

--[[
  Add a cooldown to the cooldownqueue

  @param {string} caster
  @param {string} casterName
  @param {table} spell
  @param {number} spellId
  @param {number} castTime
  @param {number} iconId
]]--
function me.TrackCooldown(caster, casterName, spell, spellId, castTime, iconId)
  btest = spell
  spell.castTime = castTime -- add time when spell was detected
  spell.spellId = spellId
  spell.iconId = iconId
  mod.cooldownQueue.AddCooldown(caster, casterName, spell)
end
