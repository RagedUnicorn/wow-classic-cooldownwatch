# TC-PR-06 — Default profile is seeded and immutable

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

> The reserved `Default` profile is seeded from the **shipped defaults**, not from the live config,
> so it stays a pristine factory baseline even on a customized character. Applying and exporting it
> are allowed - that is the "reset to factory settings" path.

## Preconditions

- A character that has never seen the default profile (fresh install per
  [TC-SV-01](TC-SV-01-fresh-install.md)) for step 1, otherwise any character

## Steps

1. Log in and open `/rgcw opt` → Profiles without saving anything
2. Select "Default" and try "Rename", then "Delete"
3. Change settings (disable a spell, set an override, lock the bar), then "Save current as..." with
   the name `Default`
4. Select "Default", click "Apply" and confirm
5. Save a profile under another name and try to rename it to `Default`
6. Export "Default", then import it under the name `Default`
7. `/reload` and re-check the list

## Expected

- "Default" is present on the very first login, without the user creating it
- While "Default" is selected, Rename and Delete are greyed out; reaching them anyway prints the
  "cannot be renamed" / "cannot be deleted" error and changes nothing
- Saving under the name `Default` is refused with the "cannot be overwritten" error; the stored
  Default keeps the shipped values (no per-spell configuration, no overrides, global worst case off,
  bar unlocked, no frame positions)
- Applying "Default" resets the live configuration to those shipped values and reloads the UI - the
  character is back to the fresh-install state
- Renaming another profile to `Default` is refused with a user-visible error and leaves both
  profiles untouched
- Importing under the name `Default` is refused with a user-visible error
- After `/reload` the list still holds "Default" plus any user profiles, and those can still be
  saved, applied, renamed and deleted as usual
- No Lua errors
