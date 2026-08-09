# TC-SOD-01 — Loads on Season of Discovery

**Area:** Season of Discovery | **Client:** Era | **Mandatory:** no (conditional)

> The SoD overlay is currently **data-empty**: the assembled catalog on a SoD realm is the same as
> on a regular Era realm. What this case verifies is that the branch determination, the season gate
> and the per-branch assembly cache behave on a live SoD realm - not that SoD content is tracked.
>
> Run it when a SoD character is available, or when `code/Season.lua`,
> `code/SpellMapHelper.lua` (`IsPrimaryAllowedInCurrentSeason`), `code/SpellMap.lua`
> (`DetermineActiveBranch`) or `code/spellmap/overlay/Sod.lua` changed.

## Preconditions

- A Season of Discovery character on the Era client
- Development checkout (`TEST = true` lets season-gated spells through - note that difference when
  comparing against a release build)

## Steps

1. Log in on the SoD character and read the chat output
2. `/rgcw opt` and walk through every spell category
3. Compare a category's spell list against the same category on a non-SoD Era character
4. `/rgcw test all`
5. `/rgcw test inject`, `/target <yourname>`, inject a few spells from different categories
6. Target an enemy player and have them cast a tracked spell (duel or battleground)

## Expected

- The addon loads with no Lua errors
- The branch resolves to `sod` (visible in the debug log with `/rgcw debug`) and the catalog is
  assembled once for that branch
- Every category lists the same spells as on a regular Era character (the overlay adds and removes
  nothing yet)
- The in-game suites pass
- Injection and live tracking behave exactly as on a non-SoD realm
- No Lua errors
