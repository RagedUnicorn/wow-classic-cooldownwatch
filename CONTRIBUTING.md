# Contributing to CooldownWatch

Thanks for helping improve CooldownWatch! The most valuable contribution most players can make is
**spell data**: a cooldown that's wrong, a rank that's missing, a talent reduction the addon
doesn't know about. This guide explains how to contribute — whether that's filing an issue or
opening a pull request.

## Reporting wrong or missing spell data

You don't need to touch any code to help. Open an issue on the
[issue tracker](https://github.com/RagedUnicorn/wow-classic-cooldownwatch/issues) and pick the
**⏱️ Spell Data Report** template — it asks for everything needed:

- The spell (and rank, if relevant) and its class/category.
- What CooldownWatch shows vs. what actually happens in-game.
- A link to the spell on [Wowhead Classic](https://www.wowhead.com/classic/) if you have one —
  spell data is verified against Wowhead, so this saves a round-trip.

## Before you open a pull request

Every `.lua` change must pass two gates, and both run locally through Docker — no local Lua,
luacheck, or busted installation is required, only Docker Desktop:

```
docker compose run --rm luacheck
docker compose run --rm busted
```

- **Lint must be clean.** `luacheck` lints every `.lua` file against `.luacheckrc`.
- **Headless tests must be green.** `busted` runs the pure-Lua specs in `test/headless/spec/`,
  including the SpellMap data-integrity validators. CI runs the same suites on every push and
  pull request, so a red local run means a red PR.

See [docs/TEST.md](docs/TEST.md) for the full testing surface, including the in-game test
framework available in development builds.

## Contributing SpellMap entries

The spell catalog under `code/spellmap/` is the single source of truth for spell data — tests
and combat-log handling all derive from it, so a data contribution is usually a small, contained
change. The essentials:

- **Entries live in per-category slice files** under `code/spellmap/base/` (`Priest.lua`,
  `Rogue.lua`, …, `Racials.lua`, `Items.lua`). Each spell has one **primary entry** (highest
  rank) with `name`, `type`, `cooldown`, `active`, `trackedEvents`, and a structured `allRanks`
  list, plus one **alias entry** (`[rankSpellId] = { refId = primarySpellId }`) per non-primary
  rank.
- **Verify every spellId on Wowhead Classic** (`https://www.wowhead.com/classic/spell=<id>`).
  The `name` must match what `GetSpellInfo(spellId)` returns — the spell name, not an item name.
  Watch out for NPC variants with contiguous spellIds that look like player ranks but aren't.
- **`cooldownWorstCase` encodes the *common* worst case**, not the absolute floor: include a
  talent or set-bonus reduction when its source is easy to get and commonly used, exclude rare
  setups almost nobody runs. Users can set a per-spell manual override for anything else.
- **Branch-specific spells (Season of Discovery / TBC) never go into the base slices** — they go
  into the branch overlay (`code/spellmap/overlay/Sod.lua` / `Tbc.lua`) as ops against the base.
- Some spells start their cooldown when a buff **disappears** rather than on cast (Cold Blood,
  Presence of Mind, …) and track `SPELL_AURA_REMOVED` — check this class of spell carefully.

The worked walkthrough with a full example entry, the overlay op shapes, and the list of
invariants lives in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) ("Adding a class to the
spellMap").

**Acceptance gate:** the validators in `test/SpellMapValidation.lua` check every entry's
structure automatically (rank aliases resolve, `allRanks` is complete and well-typed, tracked
events are supported, and more) — they run headless via `docker compose run --rm busted` and
in-game via the `TestSpellMap` suite. The per-category test suites (`test/category/`) derive
their spell lists from the live catalog, so a new entry is exercised on the next test run with
no test edits required. If your entry passes `busted`, its structure is sound; what the
validators can't check is whether the numbers match the real game, which is why the Wowhead
verification above matters.

## Generated files — edit the template, not the output

`CooldownWatch.toc` and `code/Environment.lua` are generated from templates in
`build-resources/`. Never edit the generated files directly — change the `.tpl` (and matching
`.properties`) file instead, and keep the repository in its development-environment state. See
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) ("Templated files") for details.

## Pull request flow

1. Fork and branch from `master`.
2. Make your change; for spell data, include the Wowhead links you verified against in the PR
   description.
3. Run both gates locally (`luacheck` + `busted`) until green.
4. Open the PR — CI runs the same lint and test workflows against it.
