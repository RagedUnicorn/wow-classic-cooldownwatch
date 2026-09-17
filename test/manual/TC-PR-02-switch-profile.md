# TC-PR-02 — Switch profiles without losing edits

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- TC-PR-01: `pvp` is the active profile, `Default` exists

## Steps

1. With `pvp` active, move the bar, change its scale and disable one more spell
2. Open Profiles, select `Default`, click "Load", read the confirm, answer Yes and wait for the
   reload
3. Set a manual override on a spell and enable the enemy proximity window
4. Open Profiles, select `pvp`, click "Load", answer Yes and wait for the reload
5. Walk through Options, the proximity panel and two spell categories
6. Select the active row and look at the Load button; then click somewhere outside the list so
   nothing is selected, and click "Load"

## Expected

- The Load confirm names both profiles: `Load profile "Default"? Your current settings stay
  saved in "pvp", then the UI reloads.`
- After step 2 the configuration is Default's own (its spell configuration, positions, options),
  the list reads "Default (active)"
- After step 4 the bar is where step 1 moved it, at the changed scale, with the extra spell
  disabled (the edits made while `pvp` was active were kept without any Save / Update step); the
  override and the proximity window of step 3 are gone (they belong to `Default`) and the list
  reads "pvp (active)"
- Any field a stored profile does not carry is backfilled with its default instead of ending up
  `nil` (no errors when opening panels afterwards)
- Load is greyed while the active row is selected and clicking it does nothing; with nothing
  selected Load, Rename, Delete and Export are greyed and clicking Load prints "No profile
  selected"
- No Lua errors during either switch or after the reloads
