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
  Tests for the version broadcast and update notice (code/Comm.lua).

  The module broadcasts the running version over GUILD/RAID/PARTY on roster edges (with a
  cooldown so GROUP_ROSTER_UPDATE bursts stay within the native per-prefix throttle) and, on
  CHAT_MSG_ADDON, shows the localized update notice once per session when a strictly newer
  version is seen from another player, persisting it in
  CooldownWatchConfiguration.lastNotifiedVersion.

  The WoW surface (C_ChatInfo, C_AddOns, UnitName, group/guild predicates, GetTime) is
  stubbed via WowStubs; the notice itself is captured by replacing rgcw.logger.PrintUserMessage.
  Re-dofiling code/Configuration.lua in before_each yields a fresh CooldownWatchConfiguration
  (and the SemVer comparator IsVersionBefore that Comm reuses); re-dofiling code/Comm.lua resets
  its file-local state (broadcast cooldown, notified-this-session flag) per test. Deep fields of
  the shared `rgcw` table replaced below are restored manually in after_each - busted's file
  insulation only snapshots the top-level `rgcw` reference.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each rgcw RGCW_CONSTANTS CooldownWatchConfiguration
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Comm", function()
  local comm
  local restore
  -- captured C_ChatInfo traffic and update notices
  local registeredPrefixes
  local sentMessages
  local notices
  -- controllable stub state
  local now
  local inGuild
  local inRaid
  local inGroup

  -- deep fields of the shared `rgcw` table replaced below; busted's file insulation only
  -- snapshots the top-level `rgcw` reference, so restore them manually in after_each
  local originalConfiguration = rgcw.configuration
  local originalComm = rgcw.comm
  local originalL = rgcw.L
  local originalPrintUserMessage = rgcw.logger.PrintUserMessage

  before_each(function()
    registeredPrefixes = {}
    sentMessages = {}
    notices = {}
    now = 1000
    inGuild = false
    inRaid = false
    inGroup = false

    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "1.2.0", Title = "CooldownWatch" }),
      C_ChatInfo = {
        RegisterAddonMessagePrefix = function(prefix)
          registeredPrefixes[#registeredPrefixes + 1] = prefix
        end,
        SendAddonMessage = function(prefix, message, channel)
          sentMessages[#sentMessages + 1] = { prefix = prefix, message = message, channel = channel }
        end
      },
      UnitName = function() return "Selfplayer" end,
      IsInGuild = function() return inGuild end,
      IsInRaid = function() return inRaid end,
      IsInGroup = function() return inGroup end,
      GetTime = function() return now end
    })

    -- capture the user facing notice instead of printing it
    rgcw.logger.PrintUserMessage = function(msg) notices[#notices + 1] = msg end
    rgcw.L = { update_available = "New version %s is available" }

    -- fresh CooldownWatchConfiguration plus the real comparator (rgcw.configuration.IsVersionBefore)
    dofile("code/Configuration.lua")
    -- fresh file-local state (broadcast cooldown, notified-this-session flag)
    dofile("code/Comm.lua")
    comm = rgcw.comm

    -- backfill the defaults, including lastNotifiedVersion = ""
    rgcw.configuration.SetupConfiguration()
  end)

  after_each(function()
    restore()
    rgcw.configuration = originalConfiguration
    rgcw.comm = originalComm
    rgcw.L = originalL
    rgcw.logger.PrintUserMessage = originalPrintUserMessage
  end)

  describe("Initialize", function()
    it("registers the addon message prefix", function()
      comm.Initialize()

      assert.are.same({ RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX }, registeredPrefixes)
    end)
  end)

  describe("BroadcastVersion", function()
    it("broadcasts over GUILD and RAID when in a guild and a raid", function()
      inGuild = true
      inRaid = true

      comm.BroadcastVersion()

      assert.are.equal(2, #sentMessages)
      assert.are.same(
        { prefix = RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, message = "1.2.0", channel = "GUILD" },
        sentMessages[1]
      )
      assert.are.same(
        { prefix = RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, message = "1.2.0", channel = "RAID" },
        sentMessages[2]
      )
    end)

    it("broadcasts over GUILD and PARTY when in a guild and a party", function()
      inGuild = true
      inGroup = true

      comm.BroadcastVersion()

      assert.are.equal(2, #sentMessages)
      assert.are.equal("GUILD", sentMessages[1].channel)
      assert.are.equal("PARTY", sentMessages[2].channel)
    end)

    it("broadcasts nothing when solo and unguilded", function()
      comm.BroadcastVersion()

      assert.are.same({}, sentMessages)
    end)

    it("skips a broadcast within the cooldown and sends again after it elapsed", function()
      inGuild = true

      comm.BroadcastVersion()
      assert.are.equal(1, #sentMessages)

      -- a roster burst right after the first broadcast is swallowed by the cooldown
      comm.BroadcastVersion()
      assert.are.equal(1, #sentMessages)

      now = now + 60
      comm.BroadcastVersion()
      assert.are.equal(2, #sentMessages)
    end)
  end)

  describe("OnChatMsgAddon", function()
    it("notifies once for a strictly newer version and persists it", function()
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.3.0", "GUILD", "Otherplayer")

      assert.are.same({ "New version 1.3.0 is available" }, notices)
      assert.are.equal("1.3.0", CooldownWatchConfiguration.lastNotifiedVersion)

      -- even a newer version stays silent for the rest of the session
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.4.0", "GUILD", "Otherplayer")

      assert.are.equal(1, #notices)
    end)

    it("does not suppress the very first notice on the empty string default", function()
      assert.are.equal("", CooldownWatchConfiguration.lastNotifiedVersion)

      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.2.1", "PARTY", "Otherplayer")

      assert.are.equal(1, #notices)
    end)

    it("ignores an equal version", function()
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.2.0", "GUILD", "Otherplayer")

      assert.are.same({}, notices)
    end)

    it("ignores an older version", function()
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.1.9", "GUILD", "Otherplayer")

      assert.are.same({}, notices)
    end)

    it("ignores a foreign prefix", function()
      comm.OnChatMsgAddon("SOME_OTHER_ADDON", "9.9.9", "GUILD", "Otherplayer")

      assert.are.same({}, notices)
    end)

    it("ignores self-sent messages, realm-qualified or not", function()
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.3.0", "GUILD", "Selfplayer")
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.3.0", "GUILD", "Selfplayer-SomeRealm")

      assert.are.same({}, notices)
    end)

    it("does not re-nag after a reload for a version already announced", function()
      CooldownWatchConfiguration.lastNotifiedVersion = "1.3.0"

      -- simulate a /reload: fresh file-local session state, persisted saved variables
      dofile("code/Comm.lua")
      comm = rgcw.comm

      -- the announced version and anything older than it stay silent
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.3.0", "GUILD", "Otherplayer")
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.2.5", "GUILD", "Otherplayer")
      assert.are.same({}, notices)

      -- a version newer than the announced one notifies again
      comm.OnChatMsgAddon(RGCW_CONSTANTS.ADDON_MESSAGE_PREFIX, "1.4.0", "GUILD", "Otherplayer")
      assert.are.same({ "New version 1.4.0 is available" }, notices)
    end)
  end)
end)
