Initial WORKING

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
      t:SetPoint("TOPLEFT",f,"TOPLEFT", 12,-12)
      t:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-12, 12)
      t:SetTexture(icon_texture)
      t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
      f.t = t
    end


    if true and true then

      local s = CreateFrame("FRAME",nil,f)
      s:SetFrameLevel(2)
      s:SetPoint("TOPLEFT",f,"TOPLEFT", 6, -6)
      s:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT", -6, 6)

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

      f.g = s

    end


end






Change to my liking

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
