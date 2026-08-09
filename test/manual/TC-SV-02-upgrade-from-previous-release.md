# TC-SV-02 — Upgrade from previous release reconciles cleanly

**Area:** SavedVariables | **Client:** Era | **Mandatory:** yes, from the second release onward

> **Not applicable to the initial release.** There is no shipped predecessor for the first version,
> so this case is skipped for it. From the following release on it is mandatory, and the previous
> release's SavedVariables file must be kept as a fixture under
> [fixtures/](fixtures/) named `TC-SV-02-cooldownwatch-v<previous-version>.lua`.

## Preconditions

- Client fully logged out
- The fixture file for the previous release (a real, played-on SavedVariables file with a few
  spells toggled, a manual override set, a moved bar and at least one saved profile)

## Steps

1. Copy the fixture over `WTF/.../SavedVariables/CooldownWatch.lua`
2. Log in with the current dev checkout
3. Observe chat for reconcile warnings and Lua errors
4. Open `/rgcw opt` and check that the customizations from the fixture are still there
5. Check the Profiles panel: the stored profiles from the fixture are listed
6. Apply one of the fixture's profiles
7. Log out and inspect the written file

## Expected

- No Lua errors on login
- Every configured value from the fixture survives untouched: per-spell enabled states, per-spell
  worst-case toggles, manual overrides, the bar position, the lock state
- Fields the new version added are present with their default values (`ReconcileWithDefaults`
  backfills them); no `nil`-access errors when opening any panel
- Stored profile snapshots are **not** rewritten on login - they stay at the shape they were saved
  with; the applied one is reconciled through `ApplySnapshot` → `SetupConfiguration` and the
  post-apply reload comes up clean
- `addonVersion` is restamped to the current version
- A reconcile warning appears only if the fixture holds a type-mismatched value (table where a
  scalar is expected or vice versa); in that case the field resets to its default and nothing else
  is discarded
