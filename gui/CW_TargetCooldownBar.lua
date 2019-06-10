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

mod.targetCooldownBar = me

me.tag = "TargetCooldownBar"

--[[
  Local references to heavily accessed targetcastbar ui elements
]]--
local targetCooldownBarFrame


function me.BuildUi()
  targetCooldownBarFrame = CreateFrame("Frame", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_FRAME, UIParent)
  targetCooldownBarFrame:SetWidth(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_WIDTH)
  targetCooldownBarFrame:SetHeight(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_HEIGHT)

  targetCooldownBarFrame:SetBackdrop({
    bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]
  })
  targetCooldownBarFrame:SetBackdropColor(0, 0, 0, .5);
  targetCooldownBarFrame:SetBackdropBorderColor(0, 0, 0, .8);
  targetCooldownBarFrame:SetPoint("CENTER", 0, 0)
  targetCooldownBarFrame:SetMovable(true)
  targetCooldownBarFrame:SetClampedToScreen(true)















  me.SetupDragFrame(targetCooldownBarFrame)

  for i = 1, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_AMOUNT do
    me.CreateCooldownWatchSlot(targetCooldownBarFrame, i)
  end
end

function me.CreateCooldownWatchSlot(frame, position)
  local cooldownWatchSlot = CreateFrame("FRAME", RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT .. position, frame)
  local _, _, icon_texture = GetSpellInfo(6673)

  cooldownWatchSlot:SetFrameLevel(1)
  cooldownWatchSlot:SetSize(RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE, RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE)
  cooldownWatchSlot:SetPoint(
    "LEFT",
    frame,
    "LEFT",
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_X + (position -1) * RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_SIZE,
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_Y
  )

  local backdrop = {
    bgFile = "Interface\\AddOns\\rSetBackdrop\\tga\\background_flat",
    edgeFile = "Interface\\AddOns\\rSetBackdrop\\tga\\glow",
    tile = false,
    tileSize = 32,
    edgeSize = 12,
    insets = {
      left = 12,
      right = 12,
      top = 12,
      bottom = 12,
    },
  }

  cooldownWatchSlot:SetBackdrop(backdrop)
  cooldownWatchSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  cooldownWatchSlot:SetBackdropBorderColor(0, 0, 0, 1)

  local t = cooldownWatchSlot:CreateTexture(nil, "LOW", nil, -8)
  t:SetPoint("TOPLEFT", cooldownWatchSlot, "TOPLEFT", 4, -4)
  t:SetPoint("BOTTOMRIGHT", cooldownWatchSlot, "BOTTOMRIGHT", -4, 4)
  t:SetTexture(icon_texture)
  t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  cooldownWatchSlot.t = t

  local s = CreateFrame("FRAME", "somename",cooldownWatchSlot)
  s:SetFrameLevel(2)
  s:SetPoint("TOPLEFT", cooldownWatchSlot, "TOPLEFT", 1, -1)
  s:SetPoint("BOTTOMRIGHT", cooldownWatchSlot, "BOTTOMRIGHT", -1, 1)

  backdrop_innerglow = {
    bgFile = "Interface\\AddOns\\rSetBackdrop\\tga\\background_flat",
    edgeFile = "Interface\\AddOns\\rSetBackdrop\\tga\\inner_glow",
    tile = false,
    tileSize = 16,
    edgeSize = 16,
    insets = {
      left = 10,
      right = 10,
      top = 10,
      bottom = 10,
    },
  }

  s:SetBackdrop(backdrop_innerglow)
  s:SetBackdropColor(1, 1, 1, 0)
  s:SetBackdropBorderColor(0, 0, 0, 1)

  cooldownWatchSlot.g = s

  local myCooldown = CreateFrame(
    "Cooldown",
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT_COOLDOWN_FRAME,
    cooldownWatchSlot,
    "CooldownFrameTemplate"
  )
  myCooldown:SetSize(32, 32)
  myCooldown:SetAllPoints()
  myCooldown:SetCooldown(GetTime(), 10)
end

--[[
  @param {table} frame
    the frame to attach drag handlers
]]--
function me.SetupDragFrame(frame)
  frame:SetScript("OnMouseDown", me.StartDragFrame)
  frame:SetScript("OnMouseUp", me.StopDragFrame)
end

--[[
  Frame callback to start moving the passed (self) frame

  @param {table} self
]]--
function me.StartDragFrame(self)
  -- if mod.configuration.IsTargetCastBarLocked() then return end

  self:StartMoving()
end

--[[
  Frame callback to stop moving the passed (self) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  -- if mod.configuration.IsTargetCastBarLocked() then return end

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint();

  mod.configuration.SaveUserPlacedFramePosition(
    RGCW_CONSTANTS.ELEMENT_TARGET_COOLDOWN_WATCH_BAR_SLOT,
    point,
    relativeTo,
    relativePoint,
    posX,
    posY
  )
end
