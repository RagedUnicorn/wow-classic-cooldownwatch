# TC-SV-03 — Hand-edited / partial saved table heals

**Area:** SavedVariables | **Client:** Era | **Mandatory:** yes

> Covers the downgrade-then-upgrade and hand-edited-file paths: the reconcile runs
> unconditionally on every load, not behind a version check.

## Preconditions

- Client fully logged out
- A played-on `CooldownWatch.lua` with a few spells toggled, one manual override and a saved
  profile; back it up first

## Steps

1. Edit `WTF/.../SavedVariables/CooldownWatch.lua` while logged out:
   - delete the whole `globalAssumeWorstCase` line
   - delete the whole `lastNotifiedVersion` line
   - replace `lockTargetCooldownBar = false` with `lockTargetCooldownBar = { }` (deliberate type
     mismatch)
   - lower `addonVersion` to an older version string (e.g. `"v0.0.1"`)
2. Log in
3. Read the chat output
4. Open `/rgcw opt` → Options and Profiles
5. Log out and inspect the file again

## Expected

- No Lua errors on login
- The two deleted fields are back at their defaults (`globalAssumeWorstCase = false`,
  `lastNotifiedVersion = ""`)
- The type-mismatched `lockTargetCooldownBar` is reset to `false` and **one** warning is logged
  naming the field path; nothing else is discarded
- The per-spell toggles, the manual override and the saved profile are all still intact
- `addonVersion` is restamped to the current version
- Options opens with both checkboxes reflecting the reconciled values
