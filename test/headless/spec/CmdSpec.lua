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
  Tests for the slash-command dispatch (code/Cmd.lua).

  SetupSlashCmdList registers the /rgcw and /cooldownwatch tokens and installs ParseSlashCommand as
  the COOLDOWNWATCH handler. ParseSlashCommand splits the message on whitespace and routes the first
  token: empty / "help" / no args -> ShowInfoMessage (four chat prints with DEBUG off); "rl" /
  "reload" -> ReloadUI; "opt" -> addonConfiguration.OpenMainCategory; "conf"/"configure" with
  "enable"/"disable" -> the targetCooldownBarPreview show/hide; anything else -> logger.PrintUserError.
  The handler is file-local (only reachable through SlashCmdList["COOLDOWNWATCH"]), so each spec
  installs the registry via SetupSlashCmdList and dispatches through the captured handler.

  The conf branches additionally cooperate with the test/place modes, whose mutual exclusivity is
  otherwise enforced only by the settings-window OnShow hook the slash path bypasses: "conf enable"
  finishes an active proximity place mode (both windows, reopen false - safeguard parity) but leaves
  the bar's own place mode running, because the example mode IS that mode's preview; "conf disable"
  with the bar place mode active finishes the mode (whose StopPreview hides the preview) instead of
  hiding the preview underneath it, which would strand the mode flag and its floating apply button.

  The `opt` case is the regression guard for CW-0042: code/Cmd.lua used to call the non-existent
  mod.addonConfiguration.OpenAddonPanel(), which is nil and threw. The OpenMainCategory spy asserts
  the call resolves to the function that actually exists in gui/AddonConfiguration.lua.

  The WoW globals it touches (SlashCmdList, SLASH_COOLDOWNWATCH1/2, ReloadUI, DEFAULT_CHAT_FRAME)
  are installed via WowStubs and restored afterwards. The collaborators it reaches through `rgcw`
  (logger, addonConfiguration, targetCooldownBarPreview, the L localization table) are absent or
  incomplete in the headless bootstrap, so they are installed as recording stubs and restored --
  they are deep fields of the shared `rgcw` table that busted's file insulation does not snapshot.
  The module is re-dofile'd in before_each per the bootstrap module-state convention.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each rgcw SLASH_COOLDOWNWATCH1 SLASH_COOLDOWNWATCH2 SlashCmdList
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Cmd", function()
  local cmd
  local handle
  local restore
  local prints
  local userErrors
  local reloadCalls
  local openCalls
  local showExampleCalls
  local hideExampleCalls
  local barPlaceModeActive
  local barFinishCalls
  local enemyFinishCalls
  local friendlyFinishCalls

  -- rgcw.logger / rgcw.addonConfiguration / rgcw.targetCooldownBarPreview / the place-mode wrappers
  -- / rgcw.L are deep fields of the shared `rgcw` table; file insulation snapshots only the
  -- top-level reference, so capture and restore them to avoid leaking the stubs into later specs
  -- (only logger exists in the bootstrap, and only with the LogDebug field).
  local originalLogger = rgcw.logger
  local originalAddonConfiguration = rgcw.addonConfiguration
  local originalTargetCooldownBarPreview = rgcw.targetCooldownBarPreview
  local originalTargetCooldownBarPlaceMode = rgcw.targetCooldownBarPlaceMode
  local originalProximityCooldownBarPreview = rgcw.proximityCooldownBarPreview
  local originalFriendlyProximityCooldownBarPreview = rgcw.friendlyProximityCooldownBarPreview
  local originalL = rgcw.L

  before_each(function()
    prints = {}
    userErrors = {}
    reloadCalls = 0
    openCalls = 0
    showExampleCalls = 0
    hideExampleCalls = 0

    -- SLASH_COOLDOWNWATCH1/2 are assigned by SetupSlashCmdList; installing them (as false) lets
    -- restore put the headless-absent globals back to their original (nil) afterwards.
    restore = wowStubs.install({
      SlashCmdList = {},
      SLASH_COOLDOWNWATCH1 = false,
      SLASH_COOLDOWNWATCH2 = false,
      ReloadUI = function() reloadCalls = reloadCalls + 1 end,
      DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, msg) prints[#prints + 1] = msg end
      }
    })

    rgcw.logger = {
      LogDebug = function() end,
      PrintUserError = function(msg) userErrors[#userErrors + 1] = msg end
    }
    rgcw.addonConfiguration = { OpenMainCategory = function() openCalls = openCalls + 1 end }
    rgcw.targetCooldownBarPreview = {
      ShowExampleTargetCooldownBar = function() showExampleCalls = showExampleCalls + 1 end,
      HideExampleTargetCooldownBar = function() hideExampleCalls = hideExampleCalls + 1 end
    }

    barPlaceModeActive = false
    barFinishCalls = {}
    enemyFinishCalls = {}
    friendlyFinishCalls = {}

    -- each FinishPlaceMode records the reopenOptions argument it was passed (false, not nil,
    -- is the contract - the slash path must never reopen the settings window)
    rgcw.targetCooldownBarPlaceMode = {
      IsPlaceModeActive = function() return barPlaceModeActive end,
      FinishPlaceMode = function(reopen) barFinishCalls[#barFinishCalls + 1] = reopen end
    }
    rgcw.proximityCooldownBarPreview = {
      FinishPlaceMode = function(reopen) enemyFinishCalls[#enemyFinishCalls + 1] = reopen end
    }
    rgcw.friendlyProximityCooldownBarPreview = {
      FinishPlaceMode = function(reopen) friendlyFinishCalls[#friendlyFinishCalls + 1] = reopen end
    }
    -- ShowInfoMessage / the error path read several L keys; fall back to the key name for any other
    rgcw.L = setmetatable({
      info_title = "CooldownWatch",
      reload = "reload help",
      opt = "opt help",
      conf = "conf help",
      invalid_argument = "invalid argument"
    }, { __index = function(_, key) return key end })

    -- re-run code/Cmd.lua to get a fresh module, then register and capture the slash handler
    dofile("code/Cmd.lua")
    cmd = rgcw.cmd
    cmd.SetupSlashCmdList()
    handle = SlashCmdList["COOLDOWNWATCH"]
  end)

  after_each(function()
    restore()
    rgcw.logger = originalLogger
    rgcw.addonConfiguration = originalAddonConfiguration
    rgcw.targetCooldownBarPreview = originalTargetCooldownBarPreview
    rgcw.targetCooldownBarPlaceMode = originalTargetCooldownBarPlaceMode
    rgcw.proximityCooldownBarPreview = originalProximityCooldownBarPreview
    rgcw.friendlyProximityCooldownBarPreview = originalFriendlyProximityCooldownBarPreview
    rgcw.L = originalL
  end)

  describe("SetupSlashCmdList", function()
    it("registers the /rgcw and /cooldownwatch tokens and the COOLDOWNWATCH handler", function()
      assert.are.equal("/rgcw", SLASH_COOLDOWNWATCH1)
      assert.are.equal("/cooldownwatch", SLASH_COOLDOWNWATCH2)
      assert.is_function(SlashCmdList["COOLDOWNWATCH"])
    end)
  end)

  describe("ParseSlashCommand", function()
    it("shows the info message for no argument", function()
      handle("")
      -- ShowInfoMessage prints the title plus the reload/opt/conf help lines (DEBUG off -> no test line)
      assert.are.equal(4, #prints)
      assert.are.equal(0, reloadCalls)
      assert.are.equal(0, openCalls)
    end)

    it("shows the info message for the 'help' argument", function()
      handle("help")
      assert.are.equal(4, #prints)
    end)

    it("reloads the UI for 'rl'", function()
      handle("rl")
      assert.are.equal(1, reloadCalls)
    end)

    it("reloads the UI for 'reload'", function()
      handle("reload")
      assert.are.equal(1, reloadCalls)
    end)

    it("opens the options category for 'opt'", function()
      handle("opt")
      assert.are.equal(1, openCalls)
    end)

    it("shows the example bar for 'conf enable'", function()
      handle("conf enable")
      assert.are.equal(1, showExampleCalls)
      assert.are.equal(0, hideExampleCalls)
    end)

    it("finishes both proximity place modes without reopening the settings window for 'conf enable'", function()
      handle("conf enable")
      -- unconditional wiring - FinishPlaceMode itself no-ops when the mode is inactive
      assert.are.same({ false }, enemyFinishCalls)
      assert.are.same({ false }, friendlyFinishCalls)
      assert.are.equal(1, showExampleCalls)
    end)

    it("leaves the bar's own place mode running for 'conf enable'", function()
      -- the example mode IS the bar place mode's preview - same surface, no conflict
      barPlaceModeActive = true
      handle("conf enable")
      assert.are.same({}, barFinishCalls)
      assert.are.equal(1, showExampleCalls)
    end)

    it("hides the example bar for 'conf disable'", function()
      handle("conf disable")
      assert.are.equal(1, hideExampleCalls)
      assert.are.equal(0, showExampleCalls)
      assert.are.same({}, barFinishCalls)
    end)

    it("finishes the bar place mode instead of hiding its preview for 'conf disable'", function()
      -- hiding the preview underneath the mode would strand the mode flag and the apply button
      barPlaceModeActive = true
      handle("conf disable")
      assert.are.same({ false }, barFinishCalls)
      assert.are.equal(0, hideExampleCalls)
    end)

    it("reports a user error for 'conf' without a sub-argument", function()
      handle("conf")
      assert.are.equal(1, #userErrors)
      assert.are.equal("invalid argument", userErrors[1])
      assert.are.equal(0, showExampleCalls)
      assert.are.equal(0, hideExampleCalls)
    end)

    it("dispatches on the first token and ignores trailing arguments", function()
      handle("rl now please")
      assert.are.equal(1, reloadCalls)
      assert.are.equal(0, openCalls)
    end)

    it("reports a user error for an unknown argument", function()
      handle("bogus")
      assert.are.equal(1, #userErrors)
      assert.are.equal("invalid argument", userErrors[1])
      assert.are.equal(0, reloadCalls)
      assert.are.equal(0, openCalls)
    end)
  end)
end)
