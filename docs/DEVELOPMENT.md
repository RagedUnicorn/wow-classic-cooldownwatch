# Development

## Project layout

```
code/                 production Lua
gui/                  XML frames + Lua UI controllers
localization/         enUS / deDE strings
test/                 in-game test framework (dev builds only)
  framework/          test logger, helpers, log window
  category/           per-class spell tests
build-resources/      Maven assembly descriptors, TOC + Environment templates
docs/                 documentation and image assets
target/               Maven output (generated)
CooldownWatch.toc     live TOC consumed by WoW (auto-generated)
pom.xml               Maven build
renovate.json         dependency-update config
```

## Maven profiles

| Profile | Purpose |
| --- | --- |
| `development` (default) | Includes `code/Debug.lua` and the entire `test/` tree. `RGCW_ENVIRONMENT.DEBUG` and `TEST` are `true`. |
| `release` | Strips debug + tests. `DEBUG` and `TEST` are `false`. Used for packaging. |
| `deploy-github` / `deploy-curseforge` / `deploy-wago` | Release packaging plus the matching publish step. Require auth tokens. |

Build a development package:

```
mvn -P development clean package
```

The package goes to `target/CooldownWatch-development.zip`. Maven also writes the templated `CooldownWatch.toc` and `code/Environment.lua` into `target/generated-development/` and copies them to the project root if they don't exist (`generate.sources.overwrite=false`). Delete those two files first if you want them regenerated from the templates.

## Templated files

Two source files are generated from `build-resources/` templates:

- `CooldownWatch.toc` — generated from `cooldownwatch-development.toc.tpl` or `cooldownwatch-release.toc.tpl`. The release template intentionally has no `# Test Framework` block.
- `code/Environment.lua` — generated from `environment.lua.tpl`, filled from `addon-development.properties` or `addon-release.properties`.

When editing either, **edit the template + properties, not the generated file**, and re-run `mvn` (or update the generated file in lockstep so day-to-day testing works without a rebuild).

## Environment flags

`RGCW_ENVIRONMENT` is built from `build-resources/addon-<profile>.properties`:

| Flag | Dev | Release | What it controls |
| --- | --- | --- | --- |
| `DEBUG` | `true` | `false` | Verbose combat-log tracking via `code/Debug.lua`. |
| `TEST` | `true` | `false` | Bypasses the SOD season filter in `SpellMapHelper.lua` so tests can exercise every spell regardless of season. |
| `LOG_LEVEL` | `4` | `1` | Logger verbosity. |
| `LOG_EVENT` | `true` | `false` | Whether log events are recorded to SavedVariables. |

## Adding a class to the spellMap

`code/SpellMap.lua` is keyed by **category** (class name) → **primary spellId** → spell data, with rank aliases pointing at the primary via `refId`. Walk through with priest as the model.

```lua
local spellMap = {
  ["priest"] = {
    [10890] = {                                  -- primary entry: highest-rank spellId
      name = "Psychic Scream",
      type = RGCW_CONSTANTS.SPELL_TYPE_BASE,    -- BASE = always available, SOD = SoD-only
      cooldown = 30,
      cooldownWorstCase = 26,                    -- optional: worst case (talents/items)
      active = true,
      trackedEvents = { "SPELL_CAST_SUCCESS" },
      allRanks = { 10890, 8122, 8124, 10888 },   -- MUST contain the primary's own id
      -- sharedCooldownGroup = "shaman_shocks"   -- optional, see below
    },
    [8122]  = { refId = 10890 },                 -- rank alias entries
    [8124]  = { refId = 10890 },
    [10888] = { refId = 10890 },
    -- ...next primary
  },
}
```

### Required invariants (enforced by `SpellMapValidation`)

- Every `refId` must point at a primary entry in the same category.
- Every primary's `allRanks` must include its own spellId.
- Every id in `allRanks` must exist in the same category as either the primary or a `refId` pointing back to that primary.
- A spellId cannot be primary in more than one category. (Rank aliases may repeat.)

These run in-game via `TestSpellMap` and headless under busted via `test/headless/spec/SpellMapSpec.lua`. See `docs/TEST.md` for how to invoke them.

### Shared-cooldown groups

For spells the game treats as one cooldown (e.g. Shaman shocks):

```lua
[25464] = {
  name = "Frost Shock",
  -- ...
  sharedCooldownGroup = "shaman_shocks",
},
-- ...

local sharedCooldownGroups = {
  ["shaman_shocks"] = { 25464, 25457, 25530 }, -- list of primary spellIds
}
```

When any member fires, `code/CombatLog.lua` queues all siblings with the same `castTime`. Each sibling still respects its own per-spell enabled flag. `TestSpellMap.TestSharedCooldownGroupsConsistent` verifies all members share the same `cooldown`.

## Linting

```
docker compose run --rm luacheck
```

The configuration lives in `.luacheckrc`. The `luacheck` service is defined in `docker-compose.yml`. Lint must be clean before opening a PR.

## Renovate

`renovate.json` configures dependency updates. It tracks:

- Maven plugins (groups `com.ragedunicorn.tools.maven.*`).
- GitHub Actions in `.github/workflows/`.
- WoW interface, patch, and CurseForge game versions via custom datasources backed by `RagedUnicorn/wow-renovate-data`. The three `<!-- renovate: ... -->` marker comments in `pom.xml` tell Renovate which properties to update.
- Alpine base bumps for the `ragedunicorn/luacheck` and `ragedunicorn/busted` images in `docker-compose.yml`. Renovate's built-in `docker-compose` manager treats compound tags like `1.2.0-alpine3.22.1-1` as exact-match compatibility filters and won't bump them, so a `customManagers` regex extracts just the alpine `x.y.z` slice as the comparable version. The leading app-version (`1.2.0-`, `2.3.0-`) and trailing `-<rev>` are preserved verbatim on update — bumps to those parts still need a manual edit.

Renovate runs on Mondays UTC, max 2 concurrent PRs, prefix `chore(deps):`. Validate config changes locally:

```
npx --yes --package=renovate -- renovate-config-validator renovate.json
```