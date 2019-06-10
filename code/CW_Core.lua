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

rgcw = rgcw or {}
local me = rgcw

me.tag = "Core"

--[[
  Addon load

  @param {table} self
]]--
function me.OnLoad(self)
  me.RegisterEvents(self)
end

--[[
  Register addon events

  @param {table} self
]]--
function me.RegisterEvents(self)
  -- Register to player login event also fires on /reload
  self:RegisterEvent("PLAYER_LOGIN")
  --[[
    Register to combat event unfiltered

    COMBAT_LOG_EVENT_UNFILTERED - show all logs independent of what the player has configured
    COMBAT_LOG_EVENT - shows only the logs that the player has configured
  ]]--
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  -- Register to the event that fires when the players target changes
  self:RegisterEvent("PLAYER_TARGET_CHANGED")


  -- self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") probably not the way to go
end

--[[
  MainFrame OnEvent handler

  @param {string} event
]]--
function me.OnEvent(event)
  if event == "PLAYER_LOGIN" then
    me.logger.LogEvent(me.tag, "PLAYER_LOGIN")
    me.Initialize()
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    me.logger.LogEvent(me.tag, "COMBAT_LOG_EVENT_UNFILTERED")
    me.combatLog.ProcessUnfilteredCombatLogEvent()
  elseif event == "PLAYER_TARGET_CHANGED" then
    me.logger.LogEvent(me.tag, "PLAYER_TARGET_CHANGED")
    me.target.UpdateCurrentTarget()
  end
end

--[[
  Initialize addon
]]--
function me.Initialize()
  me.logger.LogDebug(me.tag, "Initialize addon")
  me.Test()
end

function me.Test()
  me.logger.LogDebug(me.tag, "lets do it")

    local f = CreateFrame("FRAME", "exampleframe", UIParent)
    local _, _, icon_texture = GetSpellInfo(6673)

    f:SetFrameLevel(1)
    f:SetSize(64, 64)
    f:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)

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

    f:SetBackdrop(backdrop)
    f:SetBackdropColor(0.15, 0.15, 0.15, 1)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    if true then
      local t = f:CreateTexture(nil, "LOW",nil,-8)
      t:SetPoint("TOPLEFT",f,"TOPLEFT", 3,-3)
      t:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-3, 3)
      t:SetTexture(icon_texture)
      t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
      f.t = t
    end


    if true and true then

      local s = CreateFrame("FRAME", "somename",f)
      s:SetFrameLevel(2)
      s:SetPoint("TOPLEFT",f,"TOPLEFT", 1, -1)
      s:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT", -1, 1)

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
      -- s:SetBackdropBorderColor(0.15, 0.3, 0.4, 1)

      f.g = s

    end


end
