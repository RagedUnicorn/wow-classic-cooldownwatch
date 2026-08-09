# TC-BD-01 — Packaged release build loads clean

**Area:** Release build | **Client:** Era | **Mandatory:** yes

> The whole manual catalog otherwise runs against the dev checkout, which has `DEBUG = true` and
> `TEST = true`. A release build has both `false`, ships **no** `test/` tree and no `code/Debug.lua`,
> and registers only the `CooldownWatchConfiguration` SavedVariable. This case is the only one that
> exercises that build - it catches a test-only reference leaking into production code and a TOC or
> assembly descriptor that forgot a file.

## Preconditions

- A clean `mvn -P release clean package` producing `target/CooldownWatch-release.zip`
- The dev checkout moved aside (rename the AddOn folder) so the packaged copy is what loads
- Back up the character's SavedVariables first

## Steps

1. Build the release package and extract it into `Interface/AddOns/CooldownWatch`
2. Log in and read the chat output
3. `/rgcw` and `/rgcw test`
4. `/rgcw opt` and walk through every subpanel
5. `/rgcw conf enable` / `disable`
6. Target a friendly player, then an enemy player; have the enemy cast a tracked spell
7. Save, apply and export a profile
8. `/reload`, then log out and inspect the SavedVariables file

## Expected

- The addon loads with no Lua errors and prints the welcome message with the packaged version
- No file referenced by the TOC is missing (a missing file would error at load) - in particular the
  `code/spellmap/` and `code/spellmap/base/` slices are all present
- `/rgcw` prints the info block **without** the `test` line; `/rgcw test` is rejected as an invalid
  argument
- Every options subpanel opens and every spell category lists its spells
- Targeting a **friendly** player shows an empty bar and tracks nothing - the friendly-target
  fallback is dev-only
- The enemy's tracked cast renders normally
- Profiles work end to end
- The SavedVariables file holds `CooldownWatchConfiguration` only - no `CooldownWatchTestLog`, no
  `CooldownWatchLogTracker`
