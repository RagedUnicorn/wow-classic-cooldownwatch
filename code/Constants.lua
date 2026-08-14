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

    Horizontal inset the big timer keeps from both slot edges. It spans the
    slot and centers itself (see TargetCooldownBarSlot.CreateBigTimerCooldown),
    which replaced a pair of hardcoded left offsets that only approximated
    centering for the string lengths they were tuned against.
  ]]--
  TARGET_COOLDOWN_TEXT_INSET = 4,
  --[[
    ProximityCooldownWindow (cross-caster cooldown window, fed by
    CooldownQueue.GetAllCooldowns)
  ]]--
  ELEMENT_PROXIMITY_COOLDOWN_WINDOW_FRAME = "CW_ProximityCooldownWindow",
  --[[
    Cooldowns above this many seconds are hidden from the proximity cooldown
    window while the hideLongCooldowns option is enabled (the shipped default) -
    long cooldowns rarely decide the next engagement and would crowd out the
    short ones the window exists for. The target cooldown bar is not affected.
  ]]--
  PROXIMITY_LONG_COOLDOWN_THRESHOLD = 60,
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
    SPELL_TITLE = { 0.95, 0.95, 0.95 },     -- #f2f2f2 spell names in the per-spell lists
    MUTED = { 0.541, 0.486, 0.392 },        -- #8a7c64 idle / dim text
    DISABLED = { 0.45, 0.41, 0.35 },        -- disabled control labels
    SUBNOTE = { 0.66, 0.60, 0.50 },         -- #a89980 option descriptions (warm mid gray)
    REJECTED = { 1.0, 0.25, 0.20 },         -- value field holding input that could not be stored
    --[[
      A spell row whose description line reports the worst case being tracked.
      Same cyan as the bar's small worst-case timer (COLORS.TIMER_SMALL_TEXT),
      so "worst case" reads as one colour across both surfaces. Deliberately
      NOT gold: gold is reserved for a value the player set on this one spell,
      and the worst case can equally come from the global default, where gold
      would falsely claim the spell had been customized.
    ]]--
    WORST_CASE = { 0.01, 0.66, 0.95 }
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
  --[[
    Name of the profile that is seeded on first login and can never be deleted,
    renamed or overwritten. It holds a frozen snapshot of the shipped defaults so
    every character keeps a baseline to fall back to
  ]]--
  DEFAULT_PROFILE_NAME = "Default",
  --[[
    Upper bound for a user chosen profile name, counted in characters (not bytes) so a
    localized name is not cut short. Keeps the name readable in the profile list and in
    the chat messages that quote it
  ]]--
  PROFILE_NAME_MAX_LENGTH = 30,
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
  ELEMENT_CATEGORY_TITLE = "CW_CategoryTitle",
  ELEMENT_SPELL_LIST_CONTENT_FRAME = "$parent_CW_SpellListContentFrame",
  --[[
    Fallback width for the scroll child until the settings canvas reports a size - the
    list stretches to the canvas from there on (see CooldownMenu.UpdateContentWidth)
  ]]--
  SPELL_LIST_CONTENT_FRAME_WIDTH = 580,
  --[[
    Insets of the content frame against the settings canvas. The top left corner is set
    by the caller, the bottom right one always tracks the canvas
  ]]--
  SPELL_LIST_CONTENT_FRAME_INSET_RIGHT = 5,
  SPELL_LIST_CONTENT_FRAME_INSET_BOTTOM = 10,
  --[[
    The scrollbar overlays the rows instead of sitting next to them so the row background
    runs all the way to the border of the list. SPELL_LIST_ROW_INSET_RIGHT keeps the row
    controls clear of it.
  ]]--
  SPELL_LIST_SCROLL_BAR_GAP = 6,
  SPELL_LIST_ROW_INSET_RIGHT = 22,
  SPELL_LIST_ROW_HEIGHT = 50,
  --[[
    Alpha of the category-colored gradient laid over a row. Alternating the two
    values between odd and even rows is what produces the zebra striping (PVPWarn
    parity) - the base color underneath stays the same on every row.
  ]]--
  SPELL_LIST_ROW_TINT_ALPHA_ODD = 0.38,
  SPELL_LIST_ROW_TINT_ALPHA_EVEN = 0.20,
  -- height of the options strip below an expanded row (expanded row = ROW_HEIGHT + this)
  SPELL_LIST_ROW_EXPANSION_HEIGHT = 40,
  --[[
    Styled "slate key" buttons (Quartermaster's stepper-key look, see
    gui/GuiHelper.lua CreateSlateKey). SLATE_KEY_FONT renders the glyph at a
    custom size (Blizzard font objects are fixed size). SLATE_KEY holds the
    per-kind palette as { r, g, b } 0-1: face gradient top / bot, border rim,
    glyph colour, and additive hover glow.
  ]]--
  SLATE_KEY_SIZE = 22,
  --[[
    Reset keys sit inline between the expansion strip's value fields, where the
    full size would cost width the strip does not have to spare.
  ]]--
  SLATE_KEY_SIZE_SMALL = 18,
  SLATE_KEY_FONT = "Fonts\\FRIZQT__.TTF",
  SLATE_KEY = {
    -- expand/collapse: muted gold / brown face, frame-gold rim, BODY glyph
    expand = {
      top = { 0.20, 0.17, 0.11 }, bot = { 0.07, 0.06, 0.03 },
      rim = { 0.435, 0.36, 0.21 },     -- frame gold #6f5c37
      glyph = { 0.91, 0.87, 0.80 },    -- COLOR.BODY
      glow = { 0.851, 0.647, 0.129 }   -- COLOR.SECTION_GOLD
    },
    -- reset to default: the same slate face pulled towards red, so clearing a
    -- value reads as destructive without shouting on a list of quiet rows
    reset = {
      top = { 0.20, 0.12, 0.10 }, bot = { 0.08, 0.04, 0.03 },
      rim = { 0.45, 0.25, 0.20 },
      glyph = { 0.91, 0.87, 0.80 },    -- COLOR.BODY
      glow = { 0.85, 0.35, 0.25 }
    }
  },
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
  ELEMENT_CATEGORY_COOLDOWN_SPELL_EXPAND_BUTTON = "$parentExpandButton",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_EXPANSION = "$parentExpansion",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE_VALUE = "$parentWorstCaseValue",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_MANUAL_OVERRIDE_RESET = "$parentManualOverrideReset",
  ELEMENT_CATEGORY_COOLDOWN_SPELL_WORST_CASE_VALUE_RESET = "$parentWorstCaseValueReset",
  CATEGORY_COOLDOWN_SPELL_ICON_SIZE = 32,
  -- used by the target cooldown bar slot overlay; the spell-list checkboxes size via CHECK_OPTION_SIZE
  COOLDOWN_SPELL_DEFAULT_SIZE = 32,
  --[[
    Upper limit for any cooldown in seconds - 60 minutes. Enforced in three
    places against this one constant: the catalog (ValidateCooldownsWithinLimit
    fails the suites on a longer entry), and both per-spell value overrides
    (Configuration.IsValidOverrideValue). Inclusive: paladin Lay on Hands sits
    exactly on it at 3600s, so a `>=` comparison would reject its own base
    value. Nothing in Classic Era has a longer cooldown; a value past it is a
    data error or a typo, not a spell.
  ]]--
  COOLDOWN_MAX_SECONDS = 3600,
  --[[
    Shared by both value fields of a spell row's expansion strip. Sized for the
    longest input the limit above allows plus two decimals ("3600.99") - the
    catalog holds fractional cooldowns and the player may enter them too, so a
    letter limit that only fits whole seconds would cut "120.5" down to "120."
    and store a plausible wrong number.
  ]]--
  VALUE_FIELD_WIDTH = 58,
  VALUE_FIELD_HEIGHT = 24,
  VALUE_FIELD_MAX_LETTERS = 7,
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
    --[[
      Expansion strip value fields: flat dark box with a 1px border that turns
      the field's own "live" colour while it holds the value being tracked.

      The live colour differs per field on purpose and mirrors the description
      line's palette: gold for the cooldown field (a value the player set on
      this spell) and cyan for the worst-case field (the worst case is being
      assumed - possibly from the global default, which is not customization).
      The cyan is COLOR.WORST_CASE / COLORS.TIMER_SMALL_TEXT, so worst case
      keeps one colour across the bar, the description line and the strip.
    ]]--
    VALUE_FIELD_BG = {0.05, 0.04, 0.03, 1},
    VALUE_FIELD_BORDER = {0.29, 0.24, 0.17, 1},
    VALUE_FIELD_ACTIVE = {1, 0.819, 0, 1},
    VALUE_FIELD_WORST_CASE = {0.01, 0.66, 0.95, 1},
    -- fallback for categories without a CATEGORY entry
    CATEGORY_NEUTRAL = {0.5, 0.5, 0.5, 1},
    --[[
      Uniform warm near-black base every spell list row is drawn on. The zebra
      striping is not done here but through the category-tinted gradient on top of
      it (see SPELL_ROW_TINT_ALPHA), so the base stays the same on every row.
    ]]--
    SPELL_ROW_BACKGROUND = {0.05, 0.04, 0.03, 0.9},
    --[[
      Spell icon border colors keyed by categoryName. Values mirror PVPWarn's
      RGPVPW_COLORS.CATEGORIES - the class categories carry the class colors.
    ]]--
    CATEGORY = {
      priest = {1.00, 1.00, 1.00, 1},
      rogue = {1.00, 0.96, 0.41, 1},
      mage = {0.25, 0.78, 0.92, 1},
      hunter = {0.67, 0.83, 0.45, 1},
      warlock = {0.53, 0.53, 0.93, 1},
      paladin = {0.96, 0.55, 0.73, 1},
      druid = {1.00, 0.49, 0.04, 1},
      shaman = {0.00, 0.44, 0.87, 1},
      warrior = {0.78, 0.61, 0.43, 1},
      racials = {0.94, 0.37, 0.36, 1},
      items = {0, 0.96, 0.83, 1}
    },
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
