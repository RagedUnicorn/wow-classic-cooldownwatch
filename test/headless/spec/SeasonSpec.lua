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
  Tests for the season and client-branch predicates (code/Season.lua), the inputs the
  SpellMap orchestrator's branch decision rests on.

  Bootstrap installs a stub rgcw.season that pins both predicates to false; this spec
  dofiles the real module per test against WowStubs-installed C_Seasons / Enum /
  WOW_PROJECT_* globals and restores the stub in after_each - busted's file insulation
  only snapshots the top-level `rgcw` reference. The numeric ids below are stand-ins: the
  module only ever compares against the client's own constants, never against literals.
]]--

local wowStubs = require("WowStubs")

describe("Season", function()
  local SEASON_SOD = 2
  local SEASON_HARDCORE = 3
  local PROJECT_CLASSIC = 2
  local PROJECT_TBC = 5

  local season
  local restore
  local originalSeason = rgcw.season

  local function InstallClient(hasActiveSeason, activeSeason, projectId)
    restore = wowStubs.install({
      C_Seasons = {
        HasActiveSeason = function() return hasActiveSeason end,
        GetActiveSeason = function() return activeSeason end,
      },
      Enum = { SeasonID = { Placeholder = SEASON_SOD, Hardcore = SEASON_HARDCORE } },
      WOW_PROJECT_ID = projectId,
      WOW_PROJECT_BURNING_CRUSADE_CLASSIC = PROJECT_TBC,
    })

    dofile("code/Season.lua")
    season = rgcw.season
  end

  after_each(function()
    restore()
    rgcw.season = originalSeason
  end)

  it("reports plain Classic Era as neither SoD nor TBC", function()
    InstallClient(false, nil, PROJECT_CLASSIC)

    assert.is_false(season.IsSodActive())
    assert.is_false(season.IsTbcActive())
  end)

  it("reports Season of Discovery when it is the active season", function()
    InstallClient(true, SEASON_SOD, PROJECT_CLASSIC)

    assert.is_true(season.IsSodActive())
    assert.is_false(season.IsTbcActive())
  end)

  it("does not report Season of Discovery on another active season", function()
    InstallClient(true, SEASON_HARDCORE, PROJECT_CLASSIC)

    assert.is_false(season.IsSodActive())
  end)

  it("does not report Season of Discovery while no season is active", function()
    -- a stale season id must not count when the client reports no active season
    InstallClient(false, SEASON_SOD, PROJECT_CLASSIC)

    assert.is_false(season.IsSodActive())
  end)

  it("reports TBC on the Burning Crusade Classic client", function()
    InstallClient(false, nil, PROJECT_TBC)

    assert.is_true(season.IsTbcActive())
    assert.is_false(season.IsSodActive())
  end)
end)
