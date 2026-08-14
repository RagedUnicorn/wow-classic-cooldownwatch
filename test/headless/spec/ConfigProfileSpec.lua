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

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup before_each after_each CooldownWatchConfiguration RGCW_CONSTANTS
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("ConfigProfile", function()
  local configProfile
  local restore
  local savedFields

  --[[
    Every CooldownWatchConfiguration field the fixture touches. The spec runs
    against the real global table the production module reads (replacing the
    global would only shadow it in busted's per-file environment), so each
    field is saved and restored around every test.
  ]]--
  local MANAGED_FIELDS = {
    "lockTargetCooldownBar",
    "globalAssumeWorstCase",
    "trackFriendlyCooldowns",
    "cooldownConfiguration",
    "cooldownOverrides",
    "friendlyCooldownConfiguration",
    "friendlyCooldownOverrides",
    "proximityCooldowns",
    "frames",
    "addonVersion",
    "profiles"
  }

  setup(function()
    configProfile = rgcw.configProfile
  end)

  before_each(function()
    -- ApplySnapshot calls Configuration.SetupConfiguration, which reaches for
    -- C_AddOns.GetAddOnMetadata to stamp the addon version
    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "v9.9.9" })
    })

    savedFields = {}

    for _, field in ipairs(MANAGED_FIELDS) do
      savedFields[field] = CooldownWatchConfiguration[field]
    end

    CooldownWatchConfiguration.lockTargetCooldownBar = true
    CooldownWatchConfiguration.globalAssumeWorstCase = false
    CooldownWatchConfiguration.trackFriendlyCooldowns = true
    CooldownWatchConfiguration.cooldownConfiguration = { priest = { [10890] = true } }
    CooldownWatchConfiguration.cooldownOverrides = { priest = { [10890] = { worstCase = true, value = 20 } } }
    CooldownWatchConfiguration.friendlyCooldownConfiguration = { priest = { [10890] = false } }
    CooldownWatchConfiguration.friendlyCooldownOverrides = { priest = { [10890] = { value = 12 } } }
    CooldownWatchConfiguration.proximityCooldowns = {
      enabled = true, locked = true, scale = 1.5, maxDisplayedCooldowns = 5, hideLongCooldowns = false
    }
    CooldownWatchConfiguration.frames = { CW_TargetCooldownWatchBar = { posX = 10, posY = -20, point = "CENTER" } }
    CooldownWatchConfiguration.addonVersion = "vLive"
    CooldownWatchConfiguration.profiles = {}
  end)

  after_each(function()
    for _, field in ipairs(MANAGED_FIELDS) do
      CooldownWatchConfiguration[field] = savedFields[field]
    end

    restore()
  end)

  it("BuildSnapshot captures exactly the profile fields", function()
    local snapshot = configProfile.BuildSnapshot()

    for _, field in ipairs(configProfile.PROFILE_FIELDS) do
      assert.same(CooldownWatchConfiguration[field], snapshot[field])
    end

    -- bookkeeping and the store itself must never leak into a profile
    assert.is_nil(snapshot.addonVersion)
    assert.is_nil(snapshot.profiles)
  end)

  it("BuildSnapshot deep-copies so the snapshot never aliases the live config", function()
    local snapshot = configProfile.BuildSnapshot()

    snapshot.cooldownOverrides.priest[10890].value = 999

    assert.equal(20, CooldownWatchConfiguration.cooldownOverrides.priest[10890].value)
  end)

  it("ApplySnapshot writes the profile fields and backfills missing ones", function()
    local payload = {
      lockTargetCooldownBar = false,
      globalAssumeWorstCase = true,
      cooldownConfiguration = { rogue = { [2094] = true } }
      -- cooldownOverrides and frames deliberately absent (older-schema profile)
    }
    local liveOverrides = CooldownWatchConfiguration.cooldownOverrides

    configProfile.ApplySnapshot(payload)

    assert.is_false(CooldownWatchConfiguration.lockTargetCooldownBar)
    assert.is_true(CooldownWatchConfiguration.globalAssumeWorstCase)
    --[[
      The applied bucket survives verbatim; the category buckets the older-schema profile
      did not carry are filled empty by the reconcile inside SetupConfiguration.
    ]]--
    assert.same({ [2094] = true }, CooldownWatchConfiguration.cooldownConfiguration.rogue)

    for _, category in ipairs(rgcw.categories.GetCategories()) do
      assert.is_table(CooldownWatchConfiguration.cooldownConfiguration[category.categoryName])
    end

    -- present fields the profile omitted are left alone, the reconcile only fills what is nil
    assert.equal(liveOverrides, CooldownWatchConfiguration.cooldownOverrides)
    -- SetupConfiguration ran and restamped the addon version via the stub
    assert.equal("v9.9.9", CooldownWatchConfiguration.addonVersion)
  end)

  it("ApplySnapshot restores a stored proximityCooldowns block", function()
    local payload = {
      proximityCooldowns = {
        enabled = false, locked = false, scale = 0.8, maxDisplayedCooldowns = 3, hideLongCooldowns = true
      }
    }

    configProfile.ApplySnapshot(payload)

    assert.same(payload.proximityCooldowns, CooldownWatchConfiguration.proximityCooldowns)
  end)

  it("ApplySnapshot deep-copies so a stored profile never aliases the live config", function()
    local payload = { frames = { CW_TargetCooldownWatchBar = { posX = 1, posY = 2, point = "CENTER" } } }

    configProfile.ApplySnapshot(payload)
    CooldownWatchConfiguration.frames.CW_TargetCooldownWatchBar.posX = 555

    assert.equal(1, payload.frames.CW_TargetCooldownWatchBar.posX)
  end)

  it("ApplySnapshot ignores a non-table payload", function()
    assert.has_no.errors(function()
      configProfile.ApplySnapshot(nil)
      configProfile.ApplySnapshot("not a table")
    end)

    assert.is_true(CooldownWatchConfiguration.lockTargetCooldownBar)
  end)

  it("round-trips a snapshot through export and import", function()
    local snapshot = configProfile.BuildSnapshot()
    local exported = configProfile.ExportString(snapshot, "My Setup")

    local envelope, err = configProfile.ImportString(exported)

    assert.is_nil(err)
    assert.equal("CooldownWatch", envelope.addon)
    assert.equal("My Setup", envelope.name)
    assert.equal("vLive", envelope.addonVersion)
    assert.same(snapshot, envelope.payload)
  end)

  it("imports a string with pasted-in whitespace and line breaks", function()
    local exported = configProfile.ExportString(configProfile.BuildSnapshot(), "Wrapped")
    local wrapped = "  " .. string.sub(exported, 1, 30) .. "\n" .. string.sub(exported, 31) .. " \n"

    local envelope, err = configProfile.ImportString(wrapped)

    assert.is_nil(err)
    assert.equal("Wrapped", envelope.name)
  end)

  it("rejects non-string and empty input", function()
    local envelope, err = configProfile.ImportString(nil)
    assert.is_nil(envelope)
    assert.equal("profile_error_invalid", err)

    envelope, err = configProfile.ImportString("   \n  ")
    assert.is_nil(envelope)
    assert.equal("profile_error_empty", err)
  end)

  it("rejects garbage and foreign-prefix strings", function()
    local envelope, err = configProfile.ImportString("complete garbage")
    assert.is_nil(envelope)
    assert.equal("profile_error_invalid", err)

    envelope, err = configProfile.ImportString("Pulse1:QUJDRA==")
    assert.is_nil(envelope)
    assert.equal("profile_error_invalid", err)
  end)

  it("rejects a corrupted string with the checksum error", function()
    local exported = configProfile.ExportString(configProfile.BuildSnapshot(), "Corrupt")
    local prefixLength = #"CooldownWatch1:"
    local corruptIndex = prefixLength + 8
    local original = string.sub(exported, corruptIndex, corruptIndex)
    local replacement = original == "A" and "B" or "A"
    local corrupted = string.sub(exported, 1, corruptIndex - 1)
      .. replacement
      .. string.sub(exported, corruptIndex + 1)

    local envelope, err = configProfile.ImportString(corrupted)

    assert.is_nil(envelope)
    assert.equal("profile_error_checksum", err)
  end)

  --[[
    Craft an import string that passes the encoder framing but carries an
    arbitrary envelope, to exercise the envelope validation paths.

    @param {table} envelope
    @return {string}
  ]]--
  local function CraftImportString(envelope)
    return "CooldownWatch1:" .. rgcw.encoder.Encode(rgcw.serializer.Serialize(envelope))
  end

  it("rejects an envelope created by another addon", function()
    local crafted = CraftImportString({
      addon = "Pulse",
      schemaVersion = 1,
      payload = {}
    })

    local envelope, err = configProfile.ImportString(crafted)

    assert.is_nil(envelope)
    assert.equal("profile_error_wrong_addon", err)
  end)

  it("rejects an envelope with a newer schema version", function()
    local crafted = CraftImportString({
      addon = "CooldownWatch",
      schemaVersion = 99,
      payload = {}
    })

    local envelope, err = configProfile.ImportString(crafted)

    assert.is_nil(envelope)
    assert.equal("profile_error_version", err)
  end)

  it("rejects an envelope without a table payload", function()
    local crafted = CraftImportString({
      addon = "CooldownWatch",
      schemaVersion = 1,
      payload = "not a table"
    })

    local envelope, err = configProfile.ImportString(crafted)

    assert.is_nil(envelope)
    assert.equal("profile_error_invalid", err)
  end)

  it("manages the named profile store", function()
    assert.same({}, configProfile.ListProfiles())
    assert.is_false(configProfile.ProfileExists("Raid"))

    configProfile.SaveProfile("Raid", { lockTargetCooldownBar = true })
    configProfile.SaveProfile("Arena", { lockTargetCooldownBar = false })

    assert.same({ "Arena", "Raid" }, configProfile.ListProfiles())
    assert.is_true(configProfile.ProfileExists("Raid"))
    assert.same({ lockTargetCooldownBar = false }, configProfile.GetProfile("Arena"))

    configProfile.DeleteProfile("Raid")

    assert.same({ "Arena" }, configProfile.ListProfiles())
    assert.is_nil(configProfile.GetProfile("Raid"))
  end)

  it("SaveProfile deep-copies the payload", function()
    local payload = { frames = { CW_TargetCooldownWatchBar = { posX = 1 } } }

    configProfile.SaveProfile("Copy", payload)
    payload.frames.CW_TargetCooldownWatchBar.posX = 999

    assert.equal(1, configProfile.GetProfile("Copy").frames.CW_TargetCooldownWatchBar.posX)
  end)

  it("renames a stored profile and reports a missing source", function()
    configProfile.SaveProfile("Old", { lockTargetCooldownBar = true })

    assert.is_true(configProfile.RenameProfile("Old", "New"))
    assert.same({ "New" }, configProfile.ListProfiles())
    assert.is_false(configProfile.RenameProfile("Missing", "Anything"))
  end)

  it("lazily creates the profile store when a legacy config lacks it", function()
    CooldownWatchConfiguration.profiles = nil

    assert.same({}, configProfile.ListProfiles())
    assert.same({}, CooldownWatchConfiguration.profiles)
  end)

  describe("name length", function()
    local maxLength = RGCW_CONSTANTS.PROFILE_NAME_MAX_LENGTH

    it("accepts a name up to the limit", function()
      assert.is_false(configProfile.IsNameTooLong(""))
      assert.is_false(configProfile.IsNameTooLong(string.rep("a", maxLength)))
    end)

    it("refuses a name past the limit", function()
      assert.is_true(configProfile.IsNameTooLong(string.rep("a", maxLength + 1)))
    end)

    it("counts characters and not bytes so a localized name is not cut short", function()
      -- multibyte characters: every one of them is a single character to the user
      assert.is_false(configProfile.IsNameTooLong(string.rep("ü", maxLength)))
      assert.is_true(configProfile.IsNameTooLong(string.rep("ü", maxLength + 1)))
    end)

    it("tolerates a non string name", function()
      assert.is_false(configProfile.IsNameTooLong(nil))
    end)
  end)

  describe("default profile", function()
    local defaultName = RGCW_CONSTANTS.DEFAULT_PROFILE_NAME

    it("seeds the default profile when the store does not hold one yet", function()
      assert.same({}, configProfile.ListProfiles())

      configProfile.EnsureDefaultProfile()

      assert.same({ defaultName }, configProfile.ListProfiles())
      assert.is_true(configProfile.ProfileExists(defaultName))
    end)

    it("seeds it from the shipped defaults, not from the live configuration", function()
      -- the customized live configuration of the fixture must not bleed into the baseline
      configProfile.EnsureDefaultProfile()

      local payload = configProfile.GetProfile(defaultName)

      assert.is_false(payload.lockTargetCooldownBar)
      assert.is_false(payload.globalAssumeWorstCase)
      -- the fixture enables friendly tracking; the factory baseline keeps it off
      assert.is_false(payload.trackFriendlyCooldowns)
      assert.same({}, payload.frames)
      assert.same(rgcw.profile.GetDefaultProfile(), payload.cooldownConfiguration)
      assert.same(rgcw.profile.GetDefaultCooldownOverrides(), payload.cooldownOverrides)
      assert.same(rgcw.profile.GetDefaultProfile(), payload.friendlyCooldownConfiguration)
      assert.same(rgcw.profile.GetDefaultCooldownOverrides(), payload.friendlyCooldownOverrides)
      -- the fixture's customized proximity block must not bleed into the baseline
      assert.is_false(payload.proximityCooldowns.enabled)
      assert.same(rgcw.configuration.GetDefaults().proximityCooldowns, payload.proximityCooldowns)
    end)

    it("leaves an already seeded default untouched on a second call", function()
      configProfile.EnsureDefaultProfile()
      local seeded = configProfile.GetProfile(defaultName)

      configProfile.EnsureDefaultProfile()

      assert.is_true(rawequal(seeded, configProfile.GetProfile(defaultName)))
    end)

    it("refuses to delete the default profile", function()
      configProfile.EnsureDefaultProfile()

      assert.is_false(configProfile.DeleteProfile(defaultName))
      assert.is_true(configProfile.ProfileExists(defaultName))
    end)

    it("refuses to rename the default profile", function()
      configProfile.EnsureDefaultProfile()

      assert.is_false(configProfile.RenameProfile(defaultName, "MyDefault"))
      assert.is_true(configProfile.ProfileExists(defaultName))
      assert.is_false(configProfile.ProfileExists("MyDefault"))
    end)

    it("refuses to rename another profile onto the default name", function()
      configProfile.EnsureDefaultProfile()
      configProfile.SaveProfile("alpha", configProfile.BuildSnapshot())

      assert.is_false(configProfile.RenameProfile("alpha", defaultName))
      assert.is_true(configProfile.ProfileExists("alpha"))
      assert.same(configProfile.BuildDefaultSnapshot(), configProfile.GetProfile(defaultName))
    end)

    it("refuses to overwrite the default profile through SaveProfile", function()
      configProfile.EnsureDefaultProfile()

      assert.is_false(configProfile.SaveProfile(defaultName, configProfile.BuildSnapshot()))
      -- the live config the fixture set up has the bar locked; the baseline must not
      assert.is_false(configProfile.GetProfile(defaultName).lockTargetCooldownBar)
    end)

    it("still saves, renames and deletes user created profiles", function()
      configProfile.EnsureDefaultProfile()

      assert.is_true(configProfile.SaveProfile("alpha", configProfile.BuildSnapshot()))
      assert.is_true(configProfile.RenameProfile("alpha", "beta"))
      assert.is_true(configProfile.DeleteProfile("beta"))
      assert.same({ defaultName }, configProfile.ListProfiles())
    end)

    it("recognizes only the reserved name as the default profile", function()
      assert.is_true(configProfile.IsDefaultProfile(defaultName))
      assert.is_false(configProfile.IsDefaultProfile("default"))
      assert.is_false(configProfile.IsDefaultProfile(nil))
    end)
  end)

  it("never uses loadstring or load", function()
    local file = assert(io.open("code/ConfigProfile.lua", "r"))
    local source = file:read("*a")
    file:close()

    -- match call sites only - the module comments legitimately mention
    -- loadstring when explaining why it is not used
    assert.is_nil(string.match(source, "loadstring%s*%("))
    -- %f[%w] guards against matching the load inside identifiers like payload
    assert.is_nil(string.match(source, "%f[%w]load%s*%("))
  end)
end)
