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
  Development-only media capture. Loaded by the development .toc only - it must never
  ship in a release. Walks the generated RGCW_SHOTS manifest, sets the UI up for each
  shot, takes a screenshot and records the target frame's pixel rect so the post-process
  script can crop exactly instead of by eye.

  Driven by `shot <name>` / `shot all` / `shot next` / `shot in <seconds> <name>`.

  Registers a `shot` sub-command on the production command registry (code/Cmd.lua). The
  registry is not what /rgcw help prints - that is a hardcoded list in code/Cmd.lua - so
  the dev-only command stays invisible without any extra effort.

  See the wow-media-capture skill for the full pipeline.
]]--

-- luacheck: globals C_Timer Screenshot SetCVar GetPhysicalScreenSize InCombatLockdown
-- luacheck: globals Settings SettingsPanel CreateFrame UIParent time GetTime
-- luacheck: globals CooldownWatchShotLog RGCW_SHOTS

local mod = rgcw
local me = {}
mod.capture = me

me.tag = "Capture"

--[[
  Delay between setting the UI up and taking the screenshot. The frames need a moment to
  lay out - measuring too early yields a rect for the previous layout.
]]--
local SETTLE_DELAY = 0.5
--[[
  Delay before the UI chrome is restored. Must outlast SETTLE_DELAY so the chrome is still
  hidden when the screenshot is actually taken.
]]--
local RESTORE_DELAY = 1.0
--[[
  Spacing between shots in a `shot all` run.
]]--
local BATCH_INTERVAL = 2.5
--[[
  How long after a category is opened a row expansion is applied. CategoryMenu.MenuOnShow
  runs RefreshSpellList whenever Blizzard shows the panel, and UpdateCooldownUiState
  re-applies the accordion state from its own uiState - so a synchronous toggle would
  simply be overwritten. Must stay below SETTLE_DELAY.
]]--
local ROW_EXPAND_DELAY = 0.15

--[[
  Remaining cooldown, in seconds, staged into the n-th bar slot by previewTargetCooldownBar.
  Ascending because the live bar sorts soonest-ready-first (see CooldownQueue.CompareCooldowns) -
  a descending or flat stack would not look like anything the addon actually renders. The low
  entries also breach the warn/alert thresholds, so the shot shows the highlight states.
]]--
local PREVIEW_REMAINING = { 3, 9, 17, 26, 38, 52, 71, 94, 118, 147 }

--[[
  Default UI elements hidden for a clean capture. Guarded by existence - the set differs
  between Classic Era and TBC Anniversary.
]]--
local CHROME = {
  -- the primary action buttons do not follow MainMenuBar:Hide() on this client
  "ActionButton1",
  "ActionButton2",
  "ActionButton3",
  "ActionButton4",
  "ActionButton5",
  "ActionButton6",
  "ActionButton7",
  "ActionButton8",
  "ActionButton9",
  "ActionButton10",
  "ActionButton11",
  "ActionButton12",
  "MainActionBar",
  "MainActionBar.ActionBarPageNumber",
  "ChatFrame1",
  "ChatFrame1Tab",
  "ChatFrame1ButtonFrame",
  "ChatFrame1EditBox",
  "GeneralDockManager",
  "MinimapCluster",
  "MainMenuBar",
  "MultiBarBottomLeft",
  "MultiBarBottomRight",
  "MultiBarLeft",
  "MultiBarRight",
  "MultiBar5",
  "MultiBar6",
  "MultiBar7",
  "StanceBar",
  "StanceBarFrame",
  "PetActionBar",
  "PetActionBarFrame",
  "PossessActionBar",
  -- the 1.15 client splits the micro menu, bag buttons and xp bar into own frames
  "MicroMenuContainer",
  "MicroButtonAndBagsBar",
  "BagsBar",
  "StatusTrackingBarManager",
  "PlayerFrame",
  "TargetFrame",
  "PetFrame",
  "PartyMemberFrame1",
  "PartyMemberFrame2",
  "PartyMemberFrame3",
  "PartyMemberFrame4",
  "BuffFrame",
  "DebuffFrame",
  "TicketStatusFrame"
}

-- frames hidden by the current shot, restored afterwards
local hidden = {}
-- cursor for the keybind-safe `shot next` driver
local cursor = 1

-- forward declarations
local FindShot
local RunSetup
local HideChrome
local HideFrames
local RestoreChrome
local ResolveFrame
local MeasureFrame
local MeasureShotRect
local RecordShot
local TakeShot
local HandleShotCommand

--[[
  Collect one primary spell per catalog category, in category order, up to `amount`.
  Everything is derived from the SpellMap through its public accessors - no spellId, name
  or cooldown is ever restated in this file.

  @param {number} amount

  @return {table}
    Array of { categoryName, spellData } - the spellData is a clone and safe to mutate
]]--
local function CollectPreviewSpells(amount)
  local spells = {}

  for _, category in ipairs(mod.categories.GetCategories()) do
    if #spells >= amount then break end

    local categorySpells = mod.testHelper.GetSpellsForCategory(category.categoryName)

    if categorySpells[1] ~= nil then
      local categoryName, _, spellData = mod.spellMapHelper.GetSpellById(categorySpells[1].spellId)

      if spellData ~= nil then
        table.insert(spells, { ["categoryName"] = categoryName, ["spellData"] = spellData })
      end
    end
  end

  return spells
end

--[[
  Setup verbs referenced by the manifest's capture.setup array. Keep this vocabulary small -
  add a verb only when a shot genuinely needs it.
]]--
local setupVerbs = {
  --[[
    Open a Settings subcategory. Settings.OpenToCategory requires the numeric category id -
    passing a name errors ("outside of expected range"). The addon exposes its ids via
    mod.addonConfiguration.GetCategoryId(key): "main", "general", "profile" or a catalog
    categoryName such as "rogue".
  ]]--
  ["openCategory"] = function(key)
    local id = mod.addonConfiguration.GetCategoryId(key)

    if id == nil then
      mod.logger.PrintUserError("Unknown category key: " .. tostring(key))
      return
    end

    Settings.OpenToCategory(id)
  end,

  ["closeSettings"] = function()
    if SettingsPanel ~= nil then
      SettingsPanel:Hide()
    end
  end,

  ["showFrame"] = function(name)
    local frame = _G[name]

    if frame ~= nil then
      frame:Show()
    end
  end,

  --[[
    Unfold the options strip of the n-th row of the currently open category panel, so a shot
    can show the per-spell worst case toggle and cooldown override field.

    Deferred by ROW_EXPAND_DELAY - the panel's OnShow refreshes the list and re-applies the
    accordion state, which would swallow a synchronous toggle. Idempotent: ToggleRowExpansion
    would COLLAPSE an already unfolded row, and the accordion state survives re-opening the
    same category, so the strip is checked before toggling.
  ]]--
  ["expandSpellRow"] = function(position)
    local index = tonumber(position)

    if index == nil then
      mod.logger.PrintUserError("expandSpellRow expects a row number, got: " .. tostring(position))
      return
    end

    C_Timer.After(ROW_EXPAND_DELAY, function()
      local row = mod.cooldownMenu.GetSpellRow(index)

      if row == nil then
        mod.logger.PrintUserError("No spell row at position " .. index .. " (is the category panel open?)")
        return
      end

      if not row.expansion:IsShown() then
        mod.cooldownMenu.ToggleRowExpansion(row)
      end
    end)
  end,

  --[[
    Fold the accordion back up. The expansion state is NOT reset by re-opening the same
    category - only by switching to a different one - so a `shot all` run that expanded a row
    for one shot would leave it unfolded in the next one. The collapsed shot therefore states
    what it needs instead of depending on shot order.

    At most one row is expanded at a time, hence the early return after the first hit.
  ]]--
  ["collapseSpellRows"] = function()
    C_Timer.After(ROW_EXPAND_DELAY, function()
      local position = 1
      local row = mod.cooldownMenu.GetSpellRow(position)

      while row ~= nil do
        if row.expansion:IsShown() then
          mod.cooldownMenu.ToggleRowExpansion(row)
          return
        end

        position = position + 1
        row = mod.cooldownMenu.GetSpellRow(position)
      end
    end)
  end,

  --[[
    Stage a static, varied target cooldown bar.

    Deliberately NOT targetCooldownBarPreview.ShowExampleTargetCooldownBar (`/rgcw conf
    enable`): that seeds every one of the ten slots from CooldownQueue.BuildExampleCooldown,
    which is pinned to EXAMPLE_COOLDOWN_SPELL_ID at a flat cooldown - ten identical icons
    counting down in lockstep, which reads as a rendering bug in a store screenshot. Its
    preview ticker also repaints every slot from its own table at 20 Hz, so anything painted
    over the top is gone within one frame.

    So the bar is driven directly instead, the way PVPWarn's previewDetectionBar bypasses
    live detections: one real spell per category, each with its catalog cooldown, staggered
    castTimes from PREVIEW_REMAINING, and no ticker at all. A frozen bar is exactly what a
    screenshot wants.
  ]]--
  ["previewTargetCooldownBar"] = function()
    local slots = mod.targetCooldownBar.GetCooldownSlots()
    local slotAmount = RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT
    local spells = CollectPreviewSpells(slotAmount)

    if #spells < slotAmount then
      mod.logger.PrintUserError("Only " .. #spells .. " preview spell(s) available for " .. slotAmount .. " slots")
    end

    --[[
      Take the slots away from the live path first: the queue is emptied so no real cooldown
      is bound into a slot underneath the staged stack, and the render ticker is stopped so it
      cannot repaint over it. Both are restored by the next target change / enqueue.
    ]]--
    mod.cooldownQueue.ClearCooldownQueue()
    mod.ticker.StopTickerTargetCooldownBar()

    local now = GetTime()

    for position = 1, slotAmount do
      local entry = spells[position]

      if entry ~= nil then
        local spellData = entry.spellData
        --[[
          Back-date the cast so the slot renders the intended remaining time. A spell whose
          catalog cooldown is shorter than the staged remainder is simply shown freshly cast.
        ]]--
        local remaining = math.min(PREVIEW_REMAINING[position], spellData.cooldown)

        spellData.castTime = now - (spellData.cooldown - remaining)

        mod.targetCooldownBarSlot.UpdateCooldownWatchSlot(slots[position], {
          ["sourceGuid"] = "capture",
          ["sourceName"] = "Example",
          ["categoryName"] = entry.categoryName,
          ["spellData"] = spellData
        })
      end
    end

    mod.targetCooldownBar.GetTargetCooldownBarFrame():Show()
  end
}

--[[
  @param {string} name

  @return {table}, {number}
    The manifest entry and its index, or nil
]]--
FindShot = function(name)
  for i = 1, #RGCW_SHOTS do
    if RGCW_SHOTS[i].name == name or RGCW_SHOTS[i].shot == name then
      return RGCW_SHOTS[i], i
    end
  end

  return nil, nil
end

--[[
  @param {table} entry
]]--
RunSetup = function(entry)
  for _, step in ipairs(entry.setup) do
    local verb, argument = string.match(step, "^(%w+):?(.*)$")
    local handler = setupVerbs[verb]

    if handler == nil then
      mod.logger.PrintUserError("Unknown setup verb: " .. tostring(verb))
    else
      handler(argument)
    end
  end
end

--[[
  Hide the default chrome for a clean capture. Frames named in keepFrames (the shot's
  capture.includeFrames) are spared so a shot can deliberately keep, e.g., the TargetFrame
  next to the target cooldown bar.

  @param {table | nil} keepFrames
    Array of frame names to leave visible
]]--
HideChrome = function(keepFrames)
  local keep = {}

  if keepFrames ~= nil then
    for _, name in ipairs(keepFrames) do
      keep[name] = true
    end
  end

  for _, name in ipairs(CHROME) do
    if not keep[name] then
      local frame = ResolveFrame(name)

      if frame ~= nil and frame.IsShown ~= nil and frame:IsShown() then
        -- alpha 0 on top of Hide: the modern action bar controller re-Shows bars on state
        -- changes (stance, paging) mid-capture - the alpha keeps them invisible
        frame:SetAlpha(0)
        frame:Hide()
        table.insert(hidden, frame)
      end
    end
  end
end

RestoreChrome = function()
  for _, frame in ipairs(hidden) do
    frame:SetAlpha(1)
    frame:Show()
  end

  hidden = {}
end

--[[
  Hide specific frames named by the shot's capture.hideFrames, right before the screenshot
  and restored afterwards (queued onto the same `hidden` list as the chrome). Used to
  suppress a frame an earlier shot's setup left visible - for CooldownWatch that is above
  all the target cooldown bar, which ghosts through the semi-transparent settings window on
  the three panel shots.

  @param {table | nil} names
    Array of frame names to hide
]]--
HideFrames = function(names)
  if names == nil then return end

  for _, name in ipairs(names) do
    local frame = ResolveFrame(name)

    if frame ~= nil and frame.IsShown ~= nil and frame:IsShown() then
      frame:SetAlpha(0)
      frame:Hide()
      table.insert(hidden, frame)
    end
  end
end

--[[
  Resolve a manifest frame name to a live frame.

  @param {string} name

  @return {table | nil}
    The frame or nil
]]--
ResolveFrame = function(name)
  local frame = _G[name]

  if frame ~= nil then
    return frame
  end

  --[[
    Dotted paths reach non-global children the retail-style UI stopped exposing as globals -
    e.g. MainActionBar.ActionBarPageNumber (found via /fstack).
  ]]--
  if string.find(name, ".", 1, true) ~= nil then
    local current = _G

    for part in string.gmatch(name, "[^.]+") do
      current = current[part]

      if current == nil then
        return nil
      end
    end

    return current
  end

  return nil
end

--[[
  Convert a frame's UI coordinates to screenshot pixel coordinates. Two conversions are
  needed:

    1. WoW UI coordinates live in a virtual space that is a fixed 768 units tall at scale 1.0
       (UIParent:GetHeight() * UIParent:GetEffectiveScale() == 768), independent of the render
       resolution. A frame's GetLeft/GetTop/GetWidth/GetHeight are in that space, so UI units
       must be mapped up to real pixels via screenHeight / 768. Omitting this factor is the
       classic bug - crops come out ~2.6x too small and mispositioned.
    2. The UI origin is bottom-left while the screenshot's is top-left, so the y edge is
       flipped against screenHeight.

  @param {table} frame

  @return {number}, {number}, {number}, {number}, {number}, {number}
    x, y, width, height, screenWidth, screenHeight
]]--
MeasureFrame = function(frame)
  local screenWidth, screenHeight = GetPhysicalScreenSize()

  -- referenceHeight is 768; derived live rather than hardcoded so it survives any future
  -- change to WoW's virtual UI height
  local referenceHeight = UIParent:GetHeight() * UIParent:GetEffectiveScale()
  local uiToPixel = frame:GetEffectiveScale() * (screenHeight / referenceHeight)

  local x = frame:GetLeft() * uiToPixel
  local y = screenHeight - (frame:GetTop() * uiToPixel)
  local width = frame:GetWidth() * uiToPixel
  local height = frame:GetHeight() * uiToPixel

  return x, y, width, height, screenWidth, screenHeight
end

--[[
  Compute the crop rect for a shot: the primary frame's pixel rect, expanded to the union of
  any capture.includeFrames rects. This lets a shot capture a group - e.g. the target
  cooldown bar together with the TargetFrame - instead of a single frame. Include frames that
  are missing, hidden or unpositioned are skipped so the crop degrades to the primary frame.

  @param {table} entry
  @param {table} frame
    The primary (already validated) frame

  @return {number}, {number}, {number}, {number}, {number}, {number}
    x, y, width, height, screenWidth, screenHeight
]]--
MeasureShotRect = function(entry, frame)
  local x, y, width, height, screenWidth, screenHeight = MeasureFrame(frame)
  local left, top, right, bottom = x, y, x + width, y + height

  if entry.includeFrames ~= nil then
    for _, name in ipairs(entry.includeFrames) do
      local extra = ResolveFrame(name)

      if extra ~= nil and extra.GetLeft ~= nil and extra:GetLeft() ~= nil and extra:IsShown() then
        local ex, ey, ew, eh = MeasureFrame(extra)

        left = math.min(left, ex)
        top = math.min(top, ey)
        right = math.max(right, ex + ew)
        bottom = math.max(bottom, ey + eh)
      end
    end
  end

  return left, top, right - left, bottom - top, screenWidth, screenHeight
end

--[[
  Append a shot record to the SavedVariable. Written as a JSON string so the post-process
  script needs no Lua table parser.

  @param {table} entry
  @param {table} frame
]]--
RecordShot = function(entry, frame)
  if CooldownWatchShotLog == nil then
    CooldownWatchShotLog = {}
  end

  local x, y, width, height, screenWidth, screenHeight = MeasureShotRect(entry, frame)

  table.insert(CooldownWatchShotLog, string.format(
    '{"name":"%s","x":%d,"y":%d,"w":%d,"h":%d,"padding":%d,'
      .. '"uiScale":%.4f,"screenW":%d,"screenH":%d,"ts":%d}',
    entry.name,
    math.floor(x),
    math.floor(y),
    math.floor(width),
    math.floor(height),
    entry.padding,
    frame:GetEffectiveScale(),
    screenWidth,
    screenHeight,
    time()
  ))
end

--[[
  @param {table} entry
]]--
TakeShot = function(entry)
  if InCombatLockdown() then
    mod.logger.PrintUserError("Refusing to capture in combat - hiding protected frames would taint the UI")
    return
  end

  RunSetup(entry)

  C_Timer.After(SETTLE_DELAY, function()
    local frame = ResolveFrame(entry.frame)

    if frame == nil then
      mod.logger.PrintUserError("Frame not found: " .. entry.frame .. " (is it shown?)")
      return
    end

    if frame:GetLeft() == nil then
      mod.logger.PrintUserError("Frame has no position: " .. entry.frame .. " (it is probably hidden)")
      return
    end

    if entry.hideChrome then
      HideChrome(entry.includeFrames)
    end

    HideFrames(entry.hideFrames)

    RecordShot(entry, frame)
    Screenshot()

    print(rgcw.L["info_title"] .. " captured " .. entry.name)
  end)

  C_Timer.After(RESTORE_DELAY, RestoreChrome)
end

--[[
  Capture a single shot by name.

  @param {string} name
]]--
function me.Shot(name)
  local entry = FindShot(name)

  if entry == nil then
    mod.logger.PrintUserError("Unknown shot: " .. tostring(name) .. " - try /rgcw shot list")
    return
  end

  TakeShot(entry)
end

--[[
  Capture every shot in the manifest, spaced far enough apart that each one settles.
  Requires Screenshot() to work from a timer callback - if it does not, use me.Next()
  bound to a key instead.
]]--
function me.ShotAll()
  me.Clear()

  for i = 1, #RGCW_SHOTS do
    C_Timer.After(BATCH_INTERVAL * (i - 1), function()
      TakeShot(RGCW_SHOTS[i])
    end)
  end

  print(rgcw.L["info_title"] .. " capturing " .. #RGCW_SHOTS .. " shot(s), /reload when done")
end

--[[
  Keybind-safe driver: capture the shot at the cursor and advance. Use this when
  Screenshot() turns out to require a hardware event - and for shots that need the mouse to
  stay where it is.
]]--
function me.Next()
  if cursor > #RGCW_SHOTS then
    print(rgcw.L["info_title"] .. " all shots captured - /reload to flush the log")
    return
  end

  local entry = RGCW_SHOTS[cursor]
  cursor = cursor + 1

  print(rgcw.L["info_title"] .. " shot " .. (cursor - 1) .. "/" .. #RGCW_SHOTS .. " - " .. entry.name)
  TakeShot(entry)
end

--[[
  Capture a shot after a delay - for scenes the mouse has to hold open when the screenshot
  fires: type the command, set the scene up, the shot announces itself.

  @param {number} delay
    Seconds before the shot is set up and taken
  @param {string} name
]]--
function me.ShotIn(delay, name)
  if type(delay) ~= "number" or delay <= 0 then
    mod.logger.PrintUserError("Usage: /rgcw shot in <seconds> <name>")
    return
  end

  local entry = FindShot(name)

  if entry == nil then
    mod.logger.PrintUserError("Unknown shot: " .. tostring(name) .. " - try /rgcw shot list")
    return
  end

  print(rgcw.L["info_title"] .. " capturing " .. entry.name .. " in " .. delay .. "s - set up the scene now")

  C_Timer.After(delay, function()
    TakeShot(entry)
  end)
end

--[[
  Hide the chrome without taking a shot - for a screen recording, where the recorder rather
  than this module decides when to capture.
]]--
function me.Hide()
  if InCombatLockdown() then
    mod.logger.PrintUserError("Refusing to hide frames in combat - it would taint the UI")
    return
  end

  HideChrome(nil)
  print(rgcw.L["info_title"] .. " chrome hidden - /rgcw shot restore to bring it back")
end

--[[
  Restore the chrome a `hide` left hidden.
]]--
function me.Restore()
  RestoreChrome()
  print(rgcw.L["info_title"] .. " chrome restored")
end

--[[
  Reset the shot log and the cursor. The post-process script pairs log records with the
  newest screenshot files, so a stale log breaks the pairing.
]]--
function me.Clear()
  CooldownWatchShotLog = {}
  cursor = 1
end

--[[
  Print the manifest.
]]--
function me.List()
  print(rgcw.L["info_title"] .. " " .. #RGCW_SHOTS .. " shot(s)")

  for i = 1, #RGCW_SHOTS do
    local entry = RGCW_SHOTS[i]

    print("  |cFFFFC300" .. entry.name .. "|r - " .. entry.shows .. " (" .. entry.frame .. ")")
  end
end

--[[
  Handle the `shot` sub-command of /rgcw. Receives the remaining arguments from the command
  registry, the sub-command name already removed.

  @param {table} args
]]--
HandleShotCommand = function(args)
  if args[1] == nil or args[1] == "help" then
    print(rgcw.L["info_title"] .. " media capture (development only)")
    print("  |cFFFFC300list|r - show the shot manifest")
    print("  |cFFFFC300all|r - capture every shot")
    print("  |cFFFFC300next|r - capture the next shot (bind this if `all` does not work)")
    print("  |cFFFFC300in <seconds> <name>|r - capture a shot after a delay")
    print("  |cFFFFC300hide|r - hide the chrome without capturing")
    print("  |cFFFFC300restore|r - restore the chrome")
    print("  |cFFFFC300clear|r - reset the shot log")
    print("  |cFFFFC300<name>|r - capture a single shot")
  elseif args[1] == "list" then
    me.List()
  elseif args[1] == "all" then
    me.ShotAll()
  elseif args[1] == "next" then
    me.Next()
  elseif args[1] == "in" then
    me.ShotIn(tonumber(args[2]), args[3])
  elseif args[1] == "hide" then
    me.Hide()
  elseif args[1] == "restore" then
    me.Restore()
  elseif args[1] == "clear" then
    me.Clear()
    print(rgcw.L["info_title"] .. " shot log cleared")
  else
    me.Shot(args[1])
  end
end

--[[
  Register the `shot` subcommand on load, the same way test/framework/TestCmd.lua registers
  its own - the toc loads code/Cmd.lua long before this file, and RegisterCommand is
  available as soon as it has.
]]--
mod.cmd.RegisterCommand("shot", HandleShotCommand)

--[[
  Screenshots default to JPEG, which is lossy on UI panels. PNG is the right format for media
  that ends up in a README. The CVar is set after login so it sticks.
]]--
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
  SetCVar("screenshotFormat", "png")
end)
