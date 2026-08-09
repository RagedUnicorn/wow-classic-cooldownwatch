# TC-PR-02 — Apply profile restores configuration

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- Two saved profiles with clearly different settings (see [TC-PR-01](TC-PR-01-save-profile.md))

## Steps

1. `/rgcw opt` → Profiles, select a profile and click "Apply"
2. Read the confirmation popup, cancel it first, then repeat and confirm
3. After the reload, walk through Options and two spell categories to verify the applied values
4. Check the bar position and lock state
5. Apply the other profile and verify the switch
6. Click "Apply" with no profile selected

## Expected

- The confirmation popup names the profile and states that current settings are overwritten and the
  UI reloads
- Cancelling changes nothing
- Confirming applies the snapshot and reloads the UI: spell configuration, per-spell overrides, the
  global worst-case option, the frame position and the lock state all match the profile
- Any field the snapshot does not carry is backfilled with its default instead of ending up `nil`
  (no errors when opening panels afterwards)
- Applying with no selection prints the "no profile selected" error
- No Lua errors before or after the reload
