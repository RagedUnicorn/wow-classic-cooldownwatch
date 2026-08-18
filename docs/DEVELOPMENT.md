# Development

## Project layout

```
code/                 production Lua
gui/                  XML frames + Lua UI controllers
localization/         enUS / deDE strings
test/                 in-game test framework (dev builds only)
  framework/          test logger, helpers, log window
  category/           per-class spell tests
  debug/              debug spell injector window (TOC-loaded in dev builds)
  headless/           busted bootstrap + specs (CI/local only, never TOC-loaded)
build-resources/      Maven assembly descriptors, TOC + Environment templates
docs/                 documentation and image assets
target/               Maven output (generated)
CooldownWatch.toc     live TOC consumed by WoW (auto-generated)
pom.xml               Maven build
renovate.json         dependency-update config
```

## Maven profiles

| Profile                                               | Purpose                                                                                                |
|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `development` (default)                               | Includes `code/Debug.lua` and the entire `test/` tree. `RGCW_ENVIRONMENT.DEBUG` and `TEST` are `true`. |
| `release`                                             | Strips debug + tests. `DEBUG` and `TEST` are `false`. Used for packaging.                              |
| `deploy-github` / `deploy-curseforge` / `deploy-wago` | Release packaging plus the matching publish step. Require auth tokens.                                 |

Build a development package:

```
mvn -P development clean package
```

The package goes to `target/CooldownWatch-development.zip`. Maven also writes the templated `CooldownWatch.toc` and
`code/Environment.lua` into `target/generated-development/` and copies them to the project root if they don't exist (
`generate.sources.overwrite=false`). Delete those two files first if you want them regenerated from the templates.

## Templated files

Three files are generated from `build-resources/` templates:

- `CooldownWatch.toc` — generated from `cooldownwatch-development.toc.tpl` or `cooldownwatch-release.toc.tpl`. The
  release template intentionally has no `# Test Framework` block.
- `code/Environment.lua` — generated from `environment.lua.tpl`, filled from `addon-development.properties` or
  `addon-release.properties`.
- `docs/wow_badge_classic.svg` — the README WoW version badge, generated from `wow-badge-classic.svg.tpl` and filled
  from the pom's `addon.supported.patch.classic` / `addon.interface.classic` properties (the per-flavor properties, not
  the aggregate `addon.interface`). Renovate bumps those properties and the `generate-sources` workflow commits the
  regenerated badge back onto the Renovate PR branch, so the badge never drifts. A TBC badge template joins once the
  spell catalog supports TBC.

When editing any of them, **edit the template + properties, not the generated file**, and re-run `mvn` (or update the
generated file in lockstep so day-to-day testing works without a rebuild).

## Environment flags

`RGCW_ENVIRONMENT` is built from `build-resources/addon-<profile>.properties`:

| Flag        | Dev    | Release | What it controls                                                                                               |
|-------------|--------|---------|----------------------------------------------------------------------------------------------------------------|
| `DEBUG`     | `true` | `false` | Verbose combat-log tracking via `code/Debug.lua`.                                                              |
| `TEST`      | `true` | `false` | Bypasses the SOD season filter in `SpellMapHelper.lua` so tests can exercise every spell regardless of season. |
| `LOG_LEVEL` | `4`    | `1`     | Logger verbosity.                                                                                              |
| `LOG_EVENT` | `true` | `false` | Whether log events are recorded to SavedVariables.                                                             |

## Adding a class to the spellMap

The spell catalog lives in per-category slice files under `code/spellmap/base/` (`Priest.lua`, `Rogue.lua`, …,
`Racials.lua`, `Items.lua`, `Misc.lua`), each keyed by **primary spellId** → spell data. Rank aliases
(`[rankSpellId] = { refId = primarySpellId }`) are NOT written by hand — they are synthesized from each primary's
`allRanks` list after assembly (`SpellMap.SynthesizeRankAliases`), so a slice only ever carries an explicit
`refId` entry for an alias that is not derivable from `allRanks` (an aura id differing from the cast id, see the
buff-then-consume section). Every slice registers its category on the shared `mod.spellMapBaseClasses` table, and
`code/spellmap/Base.lua` assembles the slices (plus the central `sharedCooldownGroups`) into the Classic Era base
map. Per-branch differences (SoD / TBC) go into `code/spellmap/overlay/Sod.lua` / `Tbc.lua` as `remove` / `add` /
`replace` / `appendRanks` ops; `code/SpellMap.lua` is the orchestrator that detects the active branch, merges
base + overlays through `code/spellmap/Assemble.lua`, caches the assembled map per branch, and exposes the public
accessors (`GetSpellMap` and friends — consumers never read Base or overlays directly). Walk through with priest
as the model.

```lua
-- code/spellmap/base/Priest.lua
mod.spellMapBaseClasses = mod.spellMapBaseClasses or {}

mod.spellMapBaseClasses["priest"] = {
  [10890] = {                                  -- primary entry: highest-rank spellId
    name = "Psychic Scream",
    type = RGCW_CONSTANTS.SPELL_TYPE_BASE, -- BASE = always available, SOD = SoD-only
    cooldown = 30,
    cooldownWorstCase = 26, -- optional: worst case (talents/items)
    active = true, -- default tracked state on a fresh profile; an explicit player toggle always wins
    trackedEvents = { "SPELL_CAST_SUCCESS" }, -- SPELL_AURA_REMOVED for buff-then-consume spells, see below
    allRanks = { -- structured per-rank entries; MUST contain the primary's own id
      { spellId = 10890, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8122, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8124, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10888, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    },
    -- sharedCooldownGroup = "shaman_shocks"   -- optional, see below
  },
  -- no rank alias entries: [8122] = { refId = 10890 } etc. are synthesized
  -- from allRanks at assembly time
  -- ...next primary
}
```

### Required invariants (enforced by `SpellMapValidation`)

- Every `refId` must point at a primary entry in the same category.
- Every `allRanks` element must be a structured `{ spellId, type }` table with a positive integer `spellId` and a
  known spell type constant (`SPELL_TYPE_BASE` / `SPELL_TYPE_SOD` / `SPELL_TYPE_TBC`).
- Every primary's `allRanks` must include an entry for its own spellId.
- Every spellId in `allRanks` must exist in the same category as either the primary or a `refId` pointing back to
  that primary.
- A spellId cannot be primary in more than one category. (Rank aliases may repeat.)
- No base slice may hand-write a rank alias stub: a spellId listed in a primary's `allRanks` must not have its
  own entry in the base catalog — those aliases are synthesized at assembly. (Aura aliases, which are not in
  `allRanks`, stay hand-written and pass this check.)
- Base catalog entries (each primary's `type` and every `allRanks` entry's `type`) must be `SPELL_TYPE_BASE` —
  branch-specific spells live in their branch overlay, never in the base slices (see below).

These run in-game via `TestSpellMap` and headless under busted via `test/headless/spec/SpellMapSpec.lua`. See
`docs/TEST.md` for how to invoke them.

### Branch-specific spells (Season of Discovery / TBC)

Version-specific spell data never goes into `code/spellmap/base/` — it goes into the branch overlay
(`code/spellmap/overlay/Sod.lua` / `Tbc.lua`) as ops against the Classic Era base, applied per category in this
order:

- `remove` — drop a base spellId that does not exist (or was replaced) on the branch. When the branch merely
  *demotes* the removed primary to a rank of a new primary (the TBC healthstone rework), list the old id in
  the new entry's `allRanks` — it reappears as a synthesized rank alias, keeping the old casts tracked.
- `add` — add a branch-only spell (typed `SPELL_TYPE_SOD` / `SPELL_TYPE_TBC`); the spellId must not exist in the
  base.
- `replace` — swap an existing base entry for branch-specific data, e.g. a rework or changed cooldown value.
  The replaced primary carries the branch type (`SPELL_TYPE_SOD` / `SPELL_TYPE_TBC`); ranks in its `allRanks`
  that also exist on Classic Era stay `SPELL_TYPE_BASE` (branch-only reranks still go through `appendRanks`).
  A rework with a **new** spellId is modeled as `remove` + `add` instead, so each client shows exactly one
  option for the spell.
- `appendRanks` — append a branch-only rank (`{ spellId, type }`) to an existing base entry's `allRanks`
  without duplicating the whole entry.

Ops are validated on assembly (`spellMapAssembler.Validate` logs every violation; `Apply` skips invalid ops),
and `ValidateBaseEntriesAreBaseType` fails the test suites if a branch-typed entry sneaks into the base.
PVPWarn's `code/spellmap/overlay/Sod.lua` is the worked reference for all op shapes.

**Type tags and overlays coexist** (PVPWarn parity): the overlay decides which entries
exist in the assembled map for a branch, while the `type` tag on each entry still drives
`SpellMapHelper.IsPrimaryAllowedInCurrentSeason` — season/UI gating of listings and lookups, plus TEST-mode
visibility (the helper carries one arm per branch type; a new `SPELL_TYPE_*` constant needs its arm added
there). Both an overlay op and a correct `type` tag are required when adding a branch-specific spell.

**Test surfaces for branch-only entries** (convention settled by the TBC warrior pilot): the in-game
category suites need **no edits** — `RunAllTests` derives its spell list from the live assembled map via
`GetSpellsForCategory`, so a client running the branch exercises the overlay entries automatically, and
`CategorySuiteCoverageSpec` is keyed by category (branch entries land in existing categories), so it is
unaffected too. Hardcoded extras in a suite (e.g. a rank-resolution check) stay pinned to base entries —
they must pass on every branch. The headless proof that a branch overlay's real data flows through the
orchestrator (branch seam, assembly, rank-alias synthesis, decoration) lives in the per-branch overlay spec
(`test/headless/spec/SpellMapTbcOverlaySpec.lua`, which derives all expectations from the overlay's own ops
and therefore covers new category blocks without spec edits); the per-branch consistency validators in
`SpellMapSpec.lua` cover the assembled data itself.

### Buff-then-consume spells: track `SPELL_AURA_REMOVED`

Next-spell-modifier buffs (Cold Blood, Presence of Mind, Inner Focus, Divine Favor, Nature's Swiftness,
Elemental Mastery, Combustion, Amplify Curse) start their cooldown when the buff **disappears** — consumed,
cancelled, or purged — not when it is cast. Their entries use
`trackedEvents = { "SPELL_AURA_REMOVED" }` instead of `SPELL_CAST_SUCCESS`; tracking the cast would queue the
cooldown too early.

Two things to check when adding such a spell:

- **Aura spellId vs cast spellId.** Verify on the wowhead spell page that the buff is applied by the same
  spellId ("Apply Aura" effect on the cast spell). If the cast *triggers* a separate buff spell, the removal
  event carries the **buff's** id — add a `refId` alias entry for the aura id pointing at the primary. The
  tell that no alias is needed: the cast id itself carries the DB2 "starts cooldown after aura fades"
  attribute (wowhead spell filter 63;1;0). Every current buff-then-consume entry does — including Combustion
  `11129`, whose lookalike buff spell `28682` is not player-used — so the catalog has no such alias today.
- **Supported events.** `CombatLog` only dispatches events listed in its `supportedEvents` table
  (`GetSupportedEvents`); the `ValidateTrackedEventsSupported` validator fails on anything else. Aura events
  attribute the acting player via the **dest** unit (the buff owner) since aura events may carry no source.

### Shared-cooldown groups

For spells the game treats as one cooldown (e.g. Shaman shocks):

```lua
[10473] = {
name = "Frost Shock",
-- ...
sharedCooldownGroup = "shaman_shocks",
},
-- ...

local sharedCooldownGroups = {
["shaman_shocks"] = { 10414, 10473, 29228 }, -- Earth Shock / Frost Shock / Flame Shock (primary spellIds)
}
```

When any member fires, `code/CombatLog.lua` queues all siblings with the same `castTime`. Fan-out is unconditional:
shared cooldowns are a game-mechanics fact, so siblings are queued regardless of the user's per-sibling enabled flag —
otherwise the UI would falsely show a sibling as available. `TestSpellMap.TestSharedCooldownGroupsConsistent` verifies
all members share the same `cooldown`.

### Cooldown resolution

`CooldownQueue.ResolveCooldown` decides once per enqueue which cooldown value a spell runs with. Resolution order:

1. **Manual override** (`cooldownOverrides[category][spellId].value`, set via the `Cooldown` input in the cooldown
   menu) — replaces the cooldown entirely and beats both worst-case settings.
2. **Per-spell toggle** (`cooldownOverrides[category][spellId].worstCase`, set via the cooldown menu) — an explicit
   `true`/`false` always wins over the global default.
3. **Global default** (`globalAssumeWorstCase`, set via the general menu) — applies to spells whose per-spell entry was
   never configured (`worstCase == nil`). `Configuration.GetCooldownWorstCaseOverride` exposes this tri-state.
   `IsWorstCaseEffective` folds steps 2 and 3 into the single "is the worst case switched on for this spell" answer and
   is what both `ResolveCooldown` and the config menu's description line ask. The similarly-named
   `IsCooldownWorstCaseAssumed` collapses only the per-spell tri-state and is suitable **only** for the checkbox's own
   state — it must not fold in the global default, or ticking the global option would make every checkbox appear
   individually set.
4. **Base cooldown** — spells without a `cooldownWorstCase` value are never affected by the worst-case settings
   (the manual override applies to every spell).

Whichever worst-case value is used comes from `cooldownOverrides[category][spellId].worstCaseValue` when the player
set one (the `Worst case` input in the cooldown menu), and from the catalog's `cooldownWorstCase` otherwise. That
substitution happens before the toggle is consulted, so a corrected value also shows up on the bar's hint timer while
the worst case is *not* assumed. Whether a spell has a worst case at all stays the catalog's call — a stored
`worstCaseValue` for a spell without a catalog `cooldownWorstCase` is stale data and stays inert.

When the manual override or the worst case applies the value is promoted into `cooldown` and `cooldownWorstCase` is
cleared, so the bar renders a single authoritative timer. Changing a setting only affects future casts — in-flight
queue entries keep their resolved value.

Both numeric fields share one store helper, so they cannot drift apart in validation: non-numbers, NaN, values `<= 0`
and values above `RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS` are rejected, `nil` clears the field, and nothing else is
refused. Validation lives in `Configuration` (not the GUI) so it is headless-testable and applies to every caller.

For the **cooldown** field, values above the catalog cooldown for the spell are **deliberately allowed** — the player
watching the enemy may know better than the catalog, and a silent clamp re-renders the pre-filled catalog value, which
is indistinguishable from the edit having been ignored.

The **worst-case** field carries one extra rule on top (`UpdateCooldownWorstCaseValue`): it must be **strictly below**
the spell's base cooldown. A worst case at or above the base describes nothing — assuming it would make the tracked
cooldown longer than the spell can possibly have, and at exactly the base the toggle would silently do nothing. The
comparison is against the *catalog* cooldown, never a manual override: an override replaces the resolution wholesale
(worst-case settings included), so it is not the value this field is a worst case of. Spells unknown to SpellMap have
no base to compare against and skip the check. `SpellMapValidation.ValidateCooldownWorstCaseSane` holds the catalog to
the identical rule, so the catalog cannot ship a shape the UI would refuse for it.

### The 60 minute cooldown limit

`RGCW_CONSTANTS.COOLDOWN_MAX_SECONDS` (3600) is the ceiling for **any** cooldown in the addon, enforced in two places
against the one constant so they cannot disagree:

- **The catalog** — `SpellMapValidation.ValidateCooldownsWithinLimit` fails the suites on a primary whose `cooldown`
  or `cooldownWorstCase` is not a positive number of at most 3600 seconds.
- **Both per-spell overrides** — `Configuration.IsValidOverrideValue`.

It is **inclusive**: paladin Lay on Hands sits exactly on the limit at 3600s, so a `>=` comparison would reject the
spell's own catalog value. Nothing in Classic Era runs longer, so a value past it is a typo (wrong unit, stray digit)
rather than a spell — and an accepted one would sit on the bar for the rest of the session.

### Fractional cooldowns

The catalog holds fractional values (priest Mind Blast `cooldownWorstCase = 5.5`, mage `6.5`) and typed overrides may
be fractional too. Three places have to agree for that to work, and all three are exercised:

- **Display** goes through one of the two formatters below, both of which keep fractions.
- **Parsing** is `Common.ParseSeconds`, not a bare `tonumber`. `tonumber` accepts hex (`0x10` → 16) and scientific
  notation (`1e5` → 100000), neither of which anyone types into a seconds box and both of which land far from what
  the text looks like. It also normalizes a decimal comma (`12,5`) because the addon ships a deDE locale.

`VALUE_FIELD_MAX_LETTERS` is sized for the longest input the limit allows plus two decimals (`3600.99`). This is not
cosmetic: with a limit that only fit whole seconds, `120.5` was cut to `120.` and `tonumber` read that back as `120` —
a silently wrong value the player had no way to notice.

### Two cooldown formatters, two different constraints

`Common` owns both. They are deliberately **not** one function — the difference is the space they render into, and
collapsing them would force one of the two surfaces to accept a bad trade.

| | `FormatCooldownTime` | `FormatCooldownDuration` |
|---|---|---|
| Renders into | a 60px bar slot at font size 17 | the description line under a spell name |
| Optimised for | staying inside the slot | being read at a glance |
| `>= 60s` | `60m` `30m` `2m` (ceil) | `1m 30s`, or `2m` on the dot |
| `10s`–`59s` | `59` `10` | `30s` |
| `< 10s` | `9.9` `0.4` | `5.5s` |
| Longest output | 4 characters | — |

The bar formatter's length bound is the actual fix for the overflow, and `CommonSpec` asserts it by walking every
tenth of a second up to `COOLDOWN_MAX_SECONDS` rather than by spot-checking the values the catalog happens to hold
today. The second half of the fix is in `TargetCooldownBarSlot.CreateBigTimerCooldown`: the font string spans the slot
(`TARGET_COOLDOWN_TEXT_INSET` from both edges) and centers, replacing a left anchor at one of two hardcoded x offsets
chosen by whether the value was above or below 10s. That was an approximation of centering that only held for the
string lengths it was tuned against — `3600.0` blew straight past it into the neighbouring slot.

The editable value fields in the options menu are the one place that stays raw seconds: they are inputs, and a unit
suffix inside the box would have to be parsed back out.

## Configuration panel design (family convention)

The configuration panels follow the shared design of Pulse and GearMenu (derived from Quartermaster):

- **Colors** come from the `RGCW_CONSTANTS.COLOR` token table (`TITLE_GOLD`, `SECTION_GOLD`, `BODY`, `MUTED`,
  `DISABLED`, `SUBNOTE`), applied via `GuiHelper.SetColor`. The table mirrors Pulse's and GearMenu's values exactly —
  when a token changes, change it in the whole family. It is distinct from `RGCW_CONSTANTS.COLORS`, the
  CooldownWatch-specific `{ r, g, b, a }` slot colors of the target cooldown bar.
- **Panel titles** are `GameFontNormalLarge` font strings anchored `TOPLEFT 16, -16` in `TITLE_GOLD` — not centered,
  not `STANDARD_TEXT_FONT`.
- **Checkboxes** are built through `GuiHelper.CreateCheckBox` (`SettingsCheckboxTemplate`, sized by
  `CHECK_OPTION_SIZE`): the template's list-row hover scripts are removed, a `BODY`-colored label is created as
  `.text` (the template ships none), and an optional always-visible `SUBNOTE` description renders beneath the box
  (width-capped by `CHECK_OPTION_DESCRIPTION_WIDTH`) instead of a hover `GameTooltip`. `UICheckButtonTemplate` is not
  used anywhere in the family anymore. The description strings reuse the former `*_tooltip` localization keys; the key
  names are kept to avoid churning every locale.
- **Space-constrained list rows** — the cooldown menu's per-spell worst-case toggle and its two numeric inputs —
  deliberately keep their descriptions on hover tooltips: the rows have no vertical room for an extra line. They still
  build their checkboxes through `GuiHelper.CreateCheckBox` (label only, tooltip scripts re-attached after creation).
- **Numeric value fields** in the cooldown menu's expansion strip are built by `CooldownMenu.CreateValueField`, which
  wires one shared set of scripts; each caller points `GetOverride` / `SetOverride` / `GetCatalogValue` at its own
  configuration field. Editing semantics are uniform and match ordinary form inputs: **Enter or leaving the box
  applies**, Escape abandons, and an emptied box clears the override. Two rules keep that safe. Text identical to
  `boundText` (what the field was last bound to) is a no-op, so clicking into an unconfigured field and back out
  cannot turn the displayed catalog value into a stored override. And when the *addon* takes focus away rather than
  the player — a recycled row rebinding onto another spell, a row being locked because the spell was untracked — the
  commit is skipped via `DropFieldEdit`, never a plain `ClearFocus`.
- **Two visual channels per value field** (`ApplySingleFieldHighlight`): the lit border marks the value the runtime
  will actually use for the spell, while solid vs. dimmed text marks the player's own value vs. the catalog value
  merely displayed in the box. The dimmed state reads as placeholder text, which is what it is — without it there is
  no way to tell a configured spell from an untouched one.

  The border lights in the field's **own** colour (`valueField.liveBorderColor`) — gold for the cooldown field, cyan
  for the worst-case field — so it says *which kind* of value is live, not merely that one is. Lighting the worst-case
  field gold would have it claim the player set a value on this spell when the global default may be what switched it
  on. Same palette as the description line, and the same cyan as the bar's small worst-case timer.
- **The collapsed row's description line** (`BuildCooldownValueSegments` / `UpdateCooldownValueLine`) lists **every**
  value the spell has, worst case first, joined with ` / `:

  | State | Line |
  |---|---|
  | plain | `30s cooldown` |
  | "Use worst case" **on** | `20s worst case / 30s cooldown` |
  | …and the cooldown overridden | `20s worst case / 15s override (base 30s)` |
  | "Use worst case" **off** | `30s cooldown` |

  The worst-case segment tracks the **toggle**, not the resolution: it appears whenever the worst case is switched on
  for the spell (per-spell toggle, or the global default for a spell that was never configured) and disappears the
  moment it is switched off. A cooldown override beats the worst case at resolution time but does **not** hide it here
  — the two are independent settings, and an earlier version that hid the worst case whenever an override existed lost
  information the player had put in.

  Because segments need different colours in one font string, they are wrapped in inline escapes via
  `Common.ColorText`; the font string's own colour (`SUBNOTE`) shows through on the separators. Colour says what kind
  of value each segment is — `WORST_CASE` cyan for a worst case, `TITLE_GOLD` for a cooldown the player set on this
  spell, `SUBNOTE` for an untouched catalog value.

  So gold only ever means "the player set this value on **this** spell" and is never reached by the global worst-case
  default; marking a spell as customized when the player never touched it is the confusion the line exists to remove.
  The cyan is the one the bar's small worst-case timer and the strip's worst-case field border use, so worst case
  keeps one hue across all three surfaces.

  An untracked row emits its segments **without** escapes so `SetTextColor(DISABLED)` can dim the whole line — an
  inline escape would survive it and leave a greyed-out row still showing live colours.

  Whether the worst case is switched on comes from `Configuration.IsWorstCaseEffective`, which is the same accessor
  `ResolveCooldown` uses, so the line and the runtime cannot disagree about it. (`IsCooldownWorstCaseAssumed` is its
  deliberately different sibling: it collapses only the per-spell tri-state and drives the checkbox's own checked
  state, which must *not* fold in the global default or ticking the global option would make every checkbox appear
  individually set.) The gold border in the expansion strip still marks the truly-live value via a scratch
  `ResolveCooldown`, so with an override set the line shows the worst case while the border sits on the cooldown
  field — the line is an inventory of settings, the border marks the winner. The line is rebound from
  `UpdateRowControlsState` (which covers the row rebind and the tracking checkbox), and from `RefreshRowResolvedState`
  on the three paths that change the resolution without touching that checkbox (`WorstCaseToggleOnClick`,
  `CommitValueField`, `ValueFieldResetOnClick`). Escape and a rejected value restore rather than change it, so they
  deliberately do not refresh it.
- **Per-field reset keys** (`CreateValueFieldResetButton`) sit right of each value field's unit suffix and are shown
  only while that field carries an override, so their presence doubles as the answer to "did I override this one?".
  Emptying the box and leaving it does the same thing, but that gesture is not discoverable by looking.

  They are small `SLATE_KEY_SIZE_SMALL` keys rather than a labelled "Default" button because the strip's controls form
  one left-to-right anchor chain that already runs close to the width of the settings canvas — a labelled button would
  either push the chain past the edge or, right-aligned, collide with the worst-case toggle's label on a narrower
  canvas. The elements after each key anchor **past** it rather than to the field's suffix, so the space is reserved
  whether the key is shown or not and the strip does not shuffle sideways when a value is overridden. Their
  `OnEnter`/`OnLeave` are `HookScript`ed, not `SetScript`ed — `CreateSlateKey` owns those for the hover glow.
- **Scrollbars** are minimal: a bare `ScrollFrame` plus a `MinimalScrollBar` EventFrame anchored 8px to its right,
  wired with `ScrollUtil.InitScrollFrameWithScrollBar` (handles the wheel too). `UIPanelScrollFrameTemplate` and
  `FauxScrollFrameTemplate` are not used anymore — the spell list keeps one real row per spell in the scroll child
  (rows created on demand, surplus rows hidden, scroll range driven by the content height) instead of faux-scroll row
  recycling. The export/import box keeps `InputScrollFrameTemplate`'s own bar (family precedent; it only appears on
  overflow).

## Linting

```
docker compose run --rm luacheck
```

The configuration lives in `.luacheckrc`. The `luacheck` service is defined in `docker-compose.yml`. Lint must be clean
before opening a PR.

## Renovate

`renovate.json` configures dependency updates. It tracks:

- Maven plugins (groups `com.ragedunicorn.tools.maven.*`).
- GitHub Actions in `.github/workflows/`.
- WoW interface, patch, and CurseForge game versions via custom datasources backed by `RagedUnicorn/wow-renovate-data`.
  The three `<!-- renovate: ... -->` marker comments in `pom.xml` tell Renovate which properties to update.
- Alpine base bumps for the `ragedunicorn/luacheck` and `ragedunicorn/busted` images in `docker-compose.yml`. Renovate's
  built-in `docker-compose` manager treats compound tags like `1.2.0-alpine3.22.1-1` as exact-match compatibility
  filters and won't bump them, so a `customManagers` regex extracts just the alpine `x.y.z` slice as the comparable
  version. The leading app-version (`1.2.0-`, `2.3.0-`) and trailing `-<rev>` are preserved verbatim on update — bumps
  to those parts still need a manual edit.

Renovate runs on Mondays UTC, max 2 concurrent PRs, prefix `chore(deps):`. Validate config changes locally:

```
npx --yes --package=renovate -- renovate-config-validator renovate.json
```
