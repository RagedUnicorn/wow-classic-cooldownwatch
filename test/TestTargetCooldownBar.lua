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

local mod = rgcw
local me = {}

mod.testTargetCooldownBar = me

me.tag = "TestTargetCooldownBar"

--[[
  Smoke test for the TargetCooldownBar preview ("example") mode. This path is
  in-game-only (it touches UIParent and the live slot frames) so it lives in an
  in-game suite rather than the headless busted specs.

  ShowExampleTargetCooldownBar drives every slot through the exact slot-update
  contract the live OnUpdate path uses. A shape mismatch between the synthetic
  cooldown and what UpdateCooldownWatchSlot expects would raise a Lua error here
  - a regression that has happened before and that this test now guards
  against.
]]--
function me.TestShowExampleTargetCooldownBar()
  local testName = "TestTargetCooldownBar_ShowExample"
  mod.testLogger.StartTest(testName)

  --[[
    The core smoke assertion: invoking the preview must not raise. pcall so a
    thrown error becomes a clean test failure instead of aborting the suite.
  ]]--
  local ok, err = pcall(mod.targetCooldownBarPreview.ShowExampleTargetCooldownBar)

  if not ok then
    mod.testLogger.EndTest(testName, false,
      "ShowExampleTargetCooldownBar raised an error: " .. tostring(err))
    return
  end

  local cooldownSlots = mod.targetCooldownBar.GetCooldownSlots()

  if not mod.testAssert.NotNil(testName, cooldownSlots[1],
    "No cooldown slots found - was BuildUi called before the test ran?") then return end

  --[[
    Every slot must have been populated through the full update path: a non-nil
    iconHolderTexture whose spellId is the example spell, and a shown frame.
  ]]--
  for i = 1, RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT do
    local slot = cooldownSlots[i]

    if not mod.testAssert.NotNil(testName, slot,
      string.format("slot %d is nil", i)) then return end
    if not mod.testAssert.NotNil(testName, slot.iconHolderTexture,
      string.format("slot %d has a nil iconHolderTexture", i)) then return end
    if not mod.testAssert.Equal(testName, slot.iconHolderTexture.spellId,
      RGCW_CONSTANTS.EXAMPLE_COOLDOWN_SPELL_ID,
      string.format("slot %d iconHolderTexture.spellId", i)) then return end

    if not slot:IsShown() then
      mod.testLogger.EndTest(testName, false,
        string.format("slot %d is not shown after preview", i))
      return
    end
  end

  --[[
    Restore regular updates and clear the preview so the suite leaves the bar in
    its normal running state. Wrapped in pcall so cleanup trouble does not mask
    the (already passed) assertions above.
  ]]--
  pcall(mod.targetCooldownBarPreview.HideExampleTargetCooldownBar)

  mod.testLogger.EndTest(testName, true,
    string.format("ShowExampleTargetCooldownBar populated all %d slots without error",
      RGCW_CONSTANTS.TARGET_COOLDOWN_BAR_SLOT_AMOUNT))
end

--[[
  Run all TargetCooldownBar tests
]]--
function me.RunAllTests()
  mod.testLogger.LogInfo("TargetCooldownBar", "=== Running TargetCooldownBar Tests ===")

  me.TestShowExampleTargetCooldownBar()

  mod.testLogger.LogInfo("TargetCooldownBar", "=== TargetCooldownBar Tests Complete ===")
end

mod.testRunner.Register("targetcooldownbar", "target cooldown bar preview suite", me.RunAllTests)
