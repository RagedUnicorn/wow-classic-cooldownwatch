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
  -- carefull target and targetName might be null if the caster is not your current target
  local _, event, _, caster, casterName, sourceFlags, _, target, targetName, _, _, spellId, spellName, _ = CombatLogGetCurrentEventInfo()

  mod.logger.LogError(me.tag, "Event: " .. event)

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
    local name, rank, iconId, _, _, _, spellUid = GetSpellInfo(spellId)
    local texture = GetSpellTexture(spellUid)
    local itemIcon = GetItemIcon(iconId)

    mod.logger.LogDebug(me.tag, "SpellId: " .. spellId)
    mod.logger.LogDebug(me.tag, "itemIcon: " .. iconId)
    mod.logger.LogDebug(me.tag, "Caster:" .. casterName)
    mod.logger.LogDebug(me.tag, "SourceFlags:" .. sourceFlags)

    local spell
    --[[
      If the caster of the detected spell is our current target we can speed up
      the process of searching for the spell in the spellmap by figuring out the
      targets class.
    ]]--
    if caster == mod.target.GetCurrentTarget() then
      local _, englishClass, _ = UnitClass("target");
      spell = mod.spellMap.FindSpell(spellId, englishClass)
    else
      spell = mod.spellMap.FindSpell(spellId)
    end

    me.TrackCooldown(caster, casterName, spell, castTime)
  end
end


--[[
  Add a cooldown to the cooldownqueue

  @param {string} caster
  @param {string} casterName
  @param {table} spell
  @param {number} castTime

]]--
function me.TrackCooldown(caster, casterName, spell, castTime)
  if spell ~= nil then
    mod.logger.LogInfo(me.tag, "Found tracked spell: " .. spell.spellName)
    spell.castTime = castTime -- add time when spell was detected
    mod.cooldownQueue.AddCooldown(caster, casterName, spell)
  else
    mod.logger.LogDebug(me.tag, "Spell is non-essential")
  end
end
