# TC-PR-03 — Rename and delete a profile

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- At least two saved profiles

## Steps

1. `/rgcw opt` → Profiles, select a profile and click "Rename"; enter a new unused name
2. Rename a profile to a name that already exists
3. Rename a profile with an empty name
4. Select a profile and click "Delete"; cancel the confirmation, then repeat and confirm
5. Click "Rename" and "Delete" with no profile selected
6. `/reload` and re-check the list

## Expected

- The rename succeeds, the list re-sorts alphabetically, a success message names the new name and
  the profile's payload is unchanged (apply it to verify)
- Renaming onto an existing name is refused with the "already exists" error; both profiles stay
- An empty name is refused with the "cannot be empty" error
- The delete confirmation names the profile; cancelling keeps it, confirming removes it from the list
  with a success message
- Rename/Delete with no selection print the "no profile selected" error
- The list state after the reload matches what was left behind
- No Lua errors
