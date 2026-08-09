# TC-CT-01 — Lower rank cast tracks as its primary

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> Rank aliases are synthesized from each primary's `allRanks`, and the per-spell enabled gate
> resolves against the **primary** spellId - so a low-rank cast by a low-level enemy tracks like
> its max rank.

## Preconditions

- A duel partner on a lower-level character, or a battleground bracket with low-level enemies
- Alternatively: the `spellmap` and per-category in-game suites, which assert the alias chain
  (`/rgcw test spellmap`, `/rgcw test priestspells`, …)

## Steps

1. Have the low-level partner cast a spell at a rank below max (e.g. Frost Nova rank 1,
   Psychic Scream rank 1, Concussive Shot at its single rank)
2. Watch the bar
3. Disable that spell in `/rgcw opt` → its category, have the partner cast the low rank again
4. Re-enable it and repeat

## Expected

- The low-rank cast produces exactly one slot, showing the **primary** (max-rank) entry's icon and
  its cooldown duration (the value the options row lists for the primary)
- No second slot appears for the rank id, and no "not found in spellMap" debug line is logged for a
  known rank
- With the spell disabled, the low-rank cast is ignored - the enabled gate reads the primary's
  configuration, not the rank's
- Re-enabling restores tracking
- No Lua errors
