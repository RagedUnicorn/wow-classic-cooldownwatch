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

-- luacheck: globals CreateFrame GetCVar GetTime UIParent

local mod = rgcw
local me = {}

mod.petOwner = me

me.tag = "PetOwner"

--[[
  Pet-cast cooldown attribution. Spells cast by a player's pet (felhunter
  Spell Lock) arrive in the combat log with the PET's guid as source, while the
  cooldown queue keys everything by the owning player's guid - pet guids change
  on every resummon, so the owner guid is the only stable key, and it is what
  the player actually targets. The resolution layers are side-agnostic: while
  friendly tracking is enabled, CombatLog feeds friendly summons and player
  sightings through the same paths, and a parked cast keeps its side because
  the friendly marker rides on the parked spellData itself.

  Owner resolution is layered, most authoritative first:

  1. SPELL_SUMMON bookkeeping (RecordSummon): the summon event carries the owner
     as source and the pet as dest - exact guids, but only for summons that
     happen within combat-log range.
  2. Sightings (RecordSighting): when the player targets a player pet, the
     owner guid is read off the unit (UnitOwnerGUID) and recorded here.
  3. Tooltip scan at cast time (ScanOwnerName): resolves the owner's NAME for
     any pet guid the client knows. The name is matched against a directory of
     hostile players already seen in the combat log (NotePlayer) to obtain the
     guid; until the directory can supply it, the mapping stays name-grade.

  Casts whose owner guid is still unknown are parked per pet guid and flushed
  into the queue as soon as any layer supplies the guid - at the latest when the
  pet itself is targeted, so a parked cast is never lost while it still matters.
]]--

-- petOwners[petGuid] = { ownerGuid = string|nil, ownerName = string|nil }
-- ownerGuid is nil while the mapping is name-grade (tooltip scan only)
local petOwners = {}
--[[
  Directory of players seen in the combat log, name -> guid. Fed by every
  hostile player event - and friendly ones while friendly tracking is on
  (NotePlayer) - so a tooltip-scanned owner name can be promoted to a guid
  without the owner ever being targeted. Combat-log names carry a "-Realm"
  suffix for cross-realm players while tooltip lines may not - a mismatch just
  delays promotion until the pet is sighted.
]]--
local playerGuidByName = {}
-- pendingCooldowns[petGuid] = array of { category, spellData } parked casts
local pendingCooldowns = {}
-- hidden scanning tooltip, created on first use (never in the headless harness)
local scanTooltip

--[[
  Sentinel swapped into the UNITNAME_SUMMON_TITLE globals during a tooltip scan.
  The sentinel IS the match pattern, so the scan needs no parsing of localized
  "%s's Pet" / "%s's Minion" text (OmniBar's technique).
]]--
local SENTINEL_FORMAT = "CooldownWatch %s"
local SENTINEL_PATTERN = "^CooldownWatch (.+)"
local SUMMON_TITLE_COUNT = 3

--[[
  Queue every cast parked for a pet once its owner guid is known. Routed through
  CombatLog.TrackCooldown so shared-cooldown fan-out applies exactly as it would
  have at cast time. Parked casts whose cooldown already ran out are dropped -
  queueing them would only flash an expired entry.

  @param {string} petGuid
]]--
local function FlushPending(petGuid)
  local pending = pendingCooldowns[petGuid]
  local owner = petOwners[petGuid]

  if pending == nil or owner == nil or owner.ownerGuid == nil then return end

  pendingCooldowns[petGuid] = nil

  for _, parked in ipairs(pending) do
    if parked.spellData.castTime + parked.spellData.cooldown > GetTime() then
      mod.combatLog.TrackCooldown(
        owner.ownerGuid,
        owner.ownerName or owner.ownerGuid,
        parked.spellData,
        parked.spellData.castTime,
        parked.category
      )
    end
  end
end

--[[
  Park a cast until the pet's owner guid becomes known. A recast of the same
  spell refreshes the parked entry in place (mirroring AddCooldown's refresh
  semantics), so the buffer stays bounded by the pet's tracked spell count.

  @param {string} petGuid
  @param {string} category
  @param {table} spellData
]]--
local function ParkPending(petGuid, category, spellData)
  local pending = pendingCooldowns[petGuid]

  if pending == nil then
    pending = {}
    pendingCooldowns[petGuid] = pending
  end

  for _, parked in ipairs(pending) do
    if parked.spellData.spellId == spellData.spellId then
      parked.category = category
      parked.spellData = spellData

      return
    end
  end

  table.insert(pending, { category = category, spellData = spellData })

  mod.logger.LogDebug(me.tag,
    "Parked cast of '" .. spellData.name .. "' - owner of pet " .. petGuid .. " unknown")
end

--[[
  Record a player seen in the combat log. First sight of a name promotes
  every name-grade pet mapping waiting on it and flushes the parked casts. Called
  on the combat-log hot path: repeat sightings return after two table reads.

  @param {string} playerGuid
  @param {string} playerName
]]--
function me.NotePlayer(playerGuid, playerName)
  if playerGuid == nil or playerName == nil then return end
  if playerGuidByName[playerName] ~= nil then return end

  playerGuidByName[playerName] = playerGuid

  for petGuid, owner in pairs(petOwners) do
    if owner.ownerGuid == nil and owner.ownerName == playerName then
      owner.ownerGuid = playerGuid
      FlushPending(petGuid)
    end
  end
end

--[[
  Record the pet -> owner mapping revealed by a SPELL_SUMMON event (source is
  the owner, dest the freshly summoned pet).

  @param {string} petGuid
  @param {string} ownerGuid
  @param {string} ownerName
]]--
function me.RecordSummon(petGuid, ownerGuid, ownerName)
  petOwners[petGuid] = { ownerGuid = ownerGuid, ownerName = ownerName }

  me.NotePlayer(ownerGuid, ownerName)
  FlushPending(petGuid)
end

--[[
  Record a pet -> owner mapping read off a visible unit (Target.UpdateCurrentTarget
  resolves a targeted player pet via UnitOwnerGUID). ownerName is optional -
  the unit api may not know the owner's name when the owner was never seen.

  @param {string} petGuid
  @param {string} ownerGuid
  @param {string} ownerName - Optional
]]--
function me.RecordSighting(petGuid, ownerGuid, ownerName)
  if petGuid == nil or ownerGuid == nil then return end

  local owner = petOwners[petGuid]

  if owner == nil then
    owner = {}
    petOwners[petGuid] = owner
  end

  owner.ownerGuid = ownerGuid
  owner.ownerName = ownerName or owner.ownerName

  if owner.ownerName ~= nil then
    me.NotePlayer(ownerGuid, owner.ownerName)
  end

  FlushPending(petGuid)
end

--[[
  The recorded owner of a pet, if any.

  @param {string} petGuid

  @return ({string|nil} {string|nil})
    ownerGuid, ownerName. ownerGuid is nil while the mapping is name-grade.
]]--
function me.GetOwner(petGuid)
  local owner = petOwners[petGuid]

  if owner == nil then return nil, nil end

  return owner.ownerGuid, owner.ownerName
end

--[[
  Attribute a pet-cast cooldown to the pet's owner. Queues under the owner guid
  when any resolution layer can supply it; otherwise parks the cast until one
  does (see the module header for the layer order).

  @param {string} petGuid
  @param {string} category
  @param {table} spellData
    The cloned spell entry (SearchBySpellId), petCast = true
  @param {number} castTime
]]--
function me.AttributeCast(petGuid, category, spellData, castTime)
  spellData.castTime = castTime

  local owner = petOwners[petGuid]

  if owner == nil or owner.ownerGuid == nil then
    local ownerName = (owner and owner.ownerName) or me.ScanOwnerName(petGuid)

    if ownerName ~= nil then
      owner = { ownerGuid = playerGuidByName[ownerName], ownerName = ownerName }
      petOwners[petGuid] = owner
    end
  end

  if owner ~= nil and owner.ownerGuid ~= nil then
    mod.combatLog.TrackCooldown(
      owner.ownerGuid, owner.ownerName or owner.ownerGuid, spellData, castTime, category)

    return
  end

  ParkPending(petGuid, category, spellData)
end

--[[
  Resolve a pet guid to its owner's NAME by rendering the pet's unit tooltip
  with the UNITNAME_SUMMON_TITLE globals swapped to a sentinel ("<owner name>'s
  Pet/Guardian/Minion" becomes "CooldownWatch <owner name>"). Works for any guid
  the client currently knows - a pet that just produced a combat-log event in
  range qualifies - independent of locale (the sentinel replaces the localized
  format string itself). The owner line shifts down one when colorblind mode
  inserts the faction line, hence the line-index offset.

  Kept as a single seam function: it is the only WoW-api-touching path in this
  module, so headless specs stub exactly this.

  @param {string} petGuid

  @return {string|nil}
    The owner's name, or nil when the client does not know the guid (pet out of
    range or despawned).
]]--
function me.ScanOwnerName(petGuid)
  if scanTooltip == nil then
    scanTooltip = CreateFrame("GameTooltip", "CooldownWatchPetOwnerTooltip", nil, "GameTooltipTemplate")
  end

  local originalTitles = {}

  for i = 1, SUMMON_TITLE_COUNT do
    originalTitles[i] = _G["UNITNAME_SUMMON_TITLE" .. i]
    _G["UNITNAME_SUMMON_TITLE" .. i] = SENTINEL_FORMAT
  end

  scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
  scanTooltip:SetHyperlink("unit:" .. petGuid)

  local lineIndex = 2 + (tonumber(GetCVar("colorblindMode")) or 0)
  local line = _G["CooldownWatchPetOwnerTooltipTextLeft" .. lineIndex]
  local lineText = line and line:GetText()

  for i = 1, SUMMON_TITLE_COUNT do
    _G["UNITNAME_SUMMON_TITLE" .. i] = originalTitles[i]
  end

  scanTooltip:Hide()

  if lineText == nil then return nil end

  return string.match(lineText, SENTINEL_PATTERN)
end
