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

Two source files are generated from `build-resources/` templates:

- `CooldownWatch.toc` — generated from `cooldownwatch-development.toc.tpl` or `cooldownwatch-release.toc.tpl`. The
  release template intentionally has no `# Test Framework` block.
- `code/Environment.lua` — generated from `environment.lua.tpl`, filled from `addon-development.properties` or
  `addon-release.properties`.

When editing either, **edit the template + properties, not the generated file**, and re-run `mvn` (or update the
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
`Racials.lua`, `Items.lua`), each keyed by **primary spellId** → spell data, with rank aliases pointing at the
primary via `refId`. Every slice registers its category on the shared `mod.spellMapBaseClasses` table, and
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
    active = true,
    trackedEvents = { "SPELL_CAST_SUCCESS" }, -- SPELL_AURA_REMOVED for buff-then-consume spells, see below
    allRanks = { -- structured per-rank entries; MUST contain the primary's own id
      { spellId = 10890, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8122, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 8124, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
      { spellId = 10888, type = RGCW_CONSTANTS.SPELL_TYPE_BASE },
    },
    -- sharedCooldownGroup = "shaman_shocks"   -- optional, see below
  },
  [8122] = { refId = 10890 }, -- rank alias entries
  [8124] = { refId = 10890 },
  [10888] = { refId = 10890 },
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
- Base catalog entries (each primary's `type` and every `allRanks` entry's `type`) must be `SPELL_TYPE_BASE` —
  branch-specific spells live in their branch overlay, never in the base slices (see below).

These run in-game via `TestSpellMap` and headless under busted via `test/headless/spec/SpellMapSpec.lua`. See
`docs/TEST.md` for how to invoke them.

### Branch-specific spells (Season of Discovery / TBC)

Version-specific spell data never goes into `code/spellmap/base/` — it goes into the branch overlay
(`code/spellmap/overlay/Sod.lua` / `Tbc.lua`) as ops against the Classic Era base, applied per category in this
order:

- `remove` — drop a base spellId that does not exist (or was replaced) on the branch.
- `add` — add a branch-only spell (typed `SPELL_TYPE_SOD` / `SPELL_TYPE_TBC`); the spellId must not exist in the
  base.
- `replace` — swap an existing base entry for branch-specific data, e.g. a SoD rework that changes a cooldown.
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
visibility. Both an overlay op and a correct `type` tag are required when adding a branch-specific spell.

### Buff-then-consume spells: track `SPELL_AURA_REMOVED`

Next-spell-modifier buffs (Cold Blood, Presence of Mind, Inner Focus, Divine Favor, Nature's Swiftness,
Elemental Mastery, Combustion, Amplify Curse) start their cooldown when the buff **disappears** — consumed,
cancelled, or purged — not when it is cast. Their entries use
`trackedEvents = { "SPELL_AURA_REMOVED" }` instead of `SPELL_CAST_SUCCESS`; tracking the cast would queue the
cooldown too early.

Two things to check when adding such a spell:

- **Aura spellId vs cast spellId.** Verify on the wowhead spell page that the buff is applied by the same
  spellId ("Apply Aura" effect on the cast spell). If the cast *triggers* a separate buff spell (Combustion
  `11129` triggers buff `28682`), the removal event carries the **buff's** id — add a `refId` alias entry for
  the aura id pointing at the primary.
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

1. **Manual override** (`cooldownOverrides[category][spellId].value`, set via the numeric input in the cooldown
   menu) — replaces the cooldown entirely and beats both worst-case settings. Validation lives in
   `Configuration.UpdateCooldownManualOverride` (not the GUI) so it is headless-testable and applies to every
   caller: non-numbers, NaN and values `<= 0` are rejected; values above the spell's base cooldown are capped at
   the base — the override can only lower the tracked time, a genuinely longer cooldown is a SpellMap data bug.
2. **Per-spell toggle** (`cooldownOverrides[category][spellId].worstCase`, set via the cooldown menu) — an explicit
   `true`/`false` always wins over the global default.
3. **Global default** (`globalAssumeWorstCase`, set via the general menu) — applies to spells whose per-spell entry was
   never configured (`worstCase == nil`). `Configuration.GetCooldownWorstCaseOverride` exposes this tri-state; the
   boolean `IsCooldownWorstCaseAssumed` collapses it and is only suitable for UI checkbox state.
4. **Base cooldown** — spells without a `cooldownWorstCase` value are never affected by the worst-case settings
   (the manual override applies to every spell).

When the manual override or the worst case applies the value is promoted into `cooldown` and `cooldownWorstCase` is
cleared, so the bar renders a single authoritative timer. Changing a setting only affects future casts — in-flight
queue entries keep their resolved value.

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
- **Space-constrained list rows** — the cooldown menu's per-spell worst-case toggle and manual-override input —
  deliberately keep their descriptions on hover tooltips: the rows have no vertical room for an extra line. They still
  build their checkboxes through `GuiHelper.CreateCheckBox` (label only, tooltip scripts re-attached after creation).
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
