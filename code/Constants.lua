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

RGCW_CONSTANTS = {
  ADDON_NAME = "CooldownWatch",
  --[[
    Addon message prefix for the version broadcast (max 16 characters)
  ]]--
  ADDON_MESSAGE_PREFIX = "RGCW_VER",
  --[[
    Unit ids
  ]]--
  UNIT_ID_TARGET = "target",
  UNIT_ID_PLAYER = "player",
  --[[
    Spell types
  ]]--
  -- base game spell types
  SPELL_TYPE_BASE = "SPELL_TYPE_BASE",
  -- season of discovery spell types
  SPELL_TYPE_SOD = "SPELL_TYPE_SOD",
  -- the burning crusade spell types
  SPELL_TYPE_TBC = "SPELL_TYPE_TBC",
  --[[
    Update Intervals for tickers
  ]]--
  TARGET_COOLDOWN_BAR_UPDATE_INTERVAL = 0.05,
  --[[
    TargetCooldownFrame
  ]]--
  ELEMENT_TARGET_COOLDOWN_BAR_FRAME = "CW_TargetCooldownWatchBar",
  TARGET_COOLDOWN_BAR_WIDTH = 650,
  TARGET_COOLDOWN_BAR_HEIGHT = 70,
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT = "$parentSlot_",
  TARGET_COOLDOWN_BAR_SLOT_DEFAULT_SIZE = 60,
  TARGET_COOLDOWN_BAR_SLOT_X = 5,
  TARGET_COOLDOWN_BAR_SLOT_Y = 0,
  TARGET_COOLDOWN_BAR_SLOT_AMOUNT = 10,
  -- spellId used to populate the configuration preview (`/rgcw conf enable`). A pointer into
  -- SpellMap (rogue Blind); identity is resolved via GetSpellById, never restated here.
  EXAMPLE_COOLDOWN_SPELL_ID = 2094,
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT_ANIMATION = "CooldownWatchAnimation",
  TARGET_COOLDOWN_BAR_SLOT_FADE_DURATION = 2,
  --[[
    Grace period in seconds an expired cooldown survives in the queue before queue-side
    pruning removes it. Must exceed TARGET_COOLDOWN_BAR_SLOT_FADE_DURATION so a fade that
    is playing for a visible slot always completes before its entry is pruned underneath it.
  ]]--
  COOLDOWN_QUEUE_PRUNE_GRACE = 5,
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT_COOLDOWN_FRAME = "$parent_Cooldown",
  ELEMENT_TARGET_COOLDOWN_BAR_SLOT_ICON_TEXTURE_NAME = "$parent_Icon",
  ELEMENT_TARGET_COOLDOWN_BIG_COOLDOWN_TEXT = "$parent_BigText",
  TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_SIZE = 17,
  ELEMENT_TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT = "$parent_SmallText",
  TARGET_COOLDOWN_SMALL_COOLDOWN_TEXT_SIZE = 15,
  --[[
    Threshold in percent of the total cooldown time to trigger warning glow for the cooldown slot
  ]]--
  TARGET_COOLDOWN_WARN_THRESHOLD = 50,
  TARGET_COOLDOWN_ALERT_THRESHOLD = 20,
  --[[
    Positions
  ]]--
  TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_LOW = 17,
  TARGET_COOLDOWN_BIG_COOLDOWN_TEXT_HIGH = 12,
  --[[
    Addon configuration
  ]]--
  ELEMENT_ADDON_PANEL = "CW_AddonPanel",
  ELEMENT_TOOLTIP = "GameTooltip",
  --[[
    Addon Configuration General Elements
  ]]--
  --[[
    Design colour tokens as { r, g, b } in the 0-1 range. Mirrors Pulse's and GearMenu's
    COLOR table (derived from Quartermaster, with BODY / SUBNOTE brightened for the lighter
    stock settings canvas these panels render on). Distinct from COLORS below, which holds
    CooldownWatch-specific { r, g, b, a } slot colors for the target cooldown bar.
  ]]--
  COLOR = {
    TITLE_GOLD = { 1.0, 0.819, 0.0 },       -- #ffd100 panel titles
    SECTION_GOLD = { 0.851, 0.647, 0.129 }, -- #d9a521 section headers
    BODY = { 0.91, 0.87, 0.80 },            -- #e8decc body text / option labels (warm near-white)
    MUTED = { 0.541, 0.486, 0.392 },        -- #8a7c64 idle / dim text
    DISABLED = { 0.45, 0.41, 0.35 },        -- disabled control labels
    SUBNOTE = { 0.66, 0.60, 0.50 }          -- #a89980 option descriptions (warm mid gray)
  },
  CHECK_OPTION_SIZE = 24,
  -- keeps option descriptions from running the full settings canvas width
  CHECK_OPTION_DESCRIPTION_WIDTH = 540,
  --[[
    AboutMenu
  ]]--
  ELEMENT_ABOUT_LOGO = "CW_AboutLogo",
  ELEMENT_ABOUT_AUTHOR_FONT_STRING = "CW_AboutAuthor",
  ELEMENT_ABOUT_EMAIL_FONT_STRING = "CW_AboutEmail",
  ELEMENT_ABOUT_VERSION_FONT_STRING = "CW_AboutVersion",
  ELEMENT_ABOUT_ISSUES_FONT_STRING = "CW_AboutIssues",
  --[[
    GeneralMenu
  ]]--
  ELEMENT_GENERAL_SUB_OPTION_FRAME = "CW_GeneralMenuOptionsFrame",
  ELEMENT_GENERAL_OPT = "CW_Opt",
  ELEMENT_GENERAL_TITLE = "CW_GeneralTitle",
  ELEMENT_GENERAL_OPT_WINDOW_LOCK_TARGET_COOLDOWN_BAR = "CW_OptWindowLockTargetCooldownBar",
  ELEMENT_GENERAL_OPT_GLOBAL_ASSUME_WORST_CASE = "CW_OptGlobalAssumeWorstCase",
  --[[
    Profile (import/export and named profiles)
  ]]--
  ELEMENT_PROFILE_SUB_OPTION_FRAME = "CW_ProfileMenuOptionsFrame",
  ELEMENT_PROFILE_TITLE = "CW_ProfileTitle",
  ELEMENT_PROFILE_LIST_SCROLL_FRAME = "CW_ProfileListScrollFrame",
  ELEMENT_PROFILE_LIST_CONTENT_FRAME = "CW_ProfileListContentFrame",
  ELEMENT_PROFILE_LIST_ROW = "CW_ProfileListRow", -- suffixed with the row index
  ELEMENT_PROFILE_SAVE_BUTTON = "CW_ProfileSaveButton",
  ELEMENT_PROFILE_APPLY_BUTTON = "CW_ProfileApplyButton",
  ELEMENT_PROFILE_RENAME_BUTTON = "CW_ProfileRenameButton",
  ELEMENT_PROFILE_DELETE_BUTTON = "CW_ProfileDeleteButton",
  ELEMENT_PROFILE_EXPORT_BUTTON = "CW_ProfileExportButton",
  ELEMENT_PROFILE_IMPORT_BUTTON = "CW_ProfileImportButton",
  ELEMENT_PROFILE_STRING_SCROLL_FRAME = "CW_ProfileStringScrollFrame",
  --[[
    Profile layout sizing
  ]]--
  ELEMENT_PROFILE_LIST_WIDTH = 280,
  ELEMENT_PROFILE_LIST_HEIGHT = 160,
  ELEMENT_PROFILE_LIST_ROW_HEIGHT = 20,
  ELEMENT_PROFILE_ACTION_BUTTON_WIDTH = 150,
  ELEMENT_PROFILE_STRING_BUTTON_WIDTH = 110,
  ELEMENT_PROFILE_BUTTON_HEIGHT = 24,
  ELEMENT_PROFILE_STRING_WIDTH = 540,
  ELEMENT_PROFILE_STRING_HEIGHT = 90,
  --[[
    Cooldown spellList frame
  ]]--
  ELEMENT_SPELL_LIST_CONTENT_FRAME = "$parent_CW_SpellListContentFrame",
  SPELL_LIST_CONTENT_FRAME_WIDTH = 580,
  SPELL_LIST_CONTENT_FRAME_HEIGHT = 552,
  SPELL_LIST_MAX_ROWS = 9,
  SPELL_LIST_ROW_HEIGHT = 50,
  --[[
    Cooldown spellList scroll frame
  ]]--
  ELEMENT_SPELL_LIST_SCROLL_FRAME = "CW_SpellListScrollFrame",
  ELEMENT_SPELL_LIST_SPELL_ROW = "$parentRow",
  --[[
    Cooldown spellList row
  ]]--
  ELEMENT_CATEGORY_COOLDOWN_SPELL_ICON = "$parentIcon",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_STATUS = "$parentStatus",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE = "$parentWorstCase",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_MANUAL_OVERRIDE = "$parentManualOverride",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_VALUE = "$parentCooldownValue",
  CATEGORY_COOLDOWN_SPELL_ICON_SIZE = 32,
  -- used by the target cooldown bar slot overlay; the spell-list checkboxes size via CHECK_OPTION_SIZE
  COOLDOWN_SPELL_DEFAULT_SIZE = 32,
  MANUAL_OVERRIDE_EDIT_BOX_WIDTH = 45,
  MANUAL_OVERRIDE_EDIT_BOX_HEIGHT = 20,
  -- longest catalog cooldowns are four digits (e.g. 1800s racials)
  MANUAL_OVERRIDE_EDIT_BOX_MAX_LETTERS = 4,
  --[[
    Cooldown slot colors as {r, g, b, a} tuples for unpack() at the call sites
  ]]--
  COLORS = {
    -- alert highlight border (red) when a cooldown nears ready
    ALERT_BORDER = {1, 0.2, 0, 1},
    -- warning highlight border (yellow-green) at the earlier threshold
    WARN_BORDER = {0.8, 1, 0, 1},
    -- big timer text (yellow)
    TIMER_BIG_TEXT = {1, 1, 0},
    -- small worst-case timer text (cyan)
    TIMER_SMALL_TEXT = {0.01, 0.66, 0.95, 1},
  },
  --[[
    Shared backdrop geometry for cooldown slot widgets. Consumed by
    mod.guiHelper.MakeSlotBackdrop, which assembles the SetBackdrop table. Texture
    paths and backdrop colors stay at the call sites; only the geometry lives here.
  ]]--
  -- standard slot frame and config preview icon holder
  SLOT_BACKDROP = {
    TILE_SIZE = 32,
    EDGE_SIZE = 20,
    INSET = 12
  },
  -- inner glow highlight frame overlaid on a slot
  HIGHLIGHT_BACKDROP = {
    TILE_SIZE = 16,
    EDGE_SIZE = 16,
    INSET = 10
  },
}
