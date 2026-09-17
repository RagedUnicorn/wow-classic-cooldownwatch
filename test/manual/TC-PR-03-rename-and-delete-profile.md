# TC-PR-03 — Rename and delete a profile, the active one too

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- TC-PR-02: `pvp` is active with its own spell configuration and bar position, `Default` holds
  a different setup

## Steps

1. Open `/rgcw opt` → Profiles, select `pvp` (the active row) and rename it to `arena`
2. Rename it again and try to type a name longer than 30 characters; then try the name
   `Default`; then an empty name; then a name that already exists
3. Click "Create new Profile", enter `temp` (it becomes active); select `arena`, Load, Yes,
   wait for the reload; then select `temp`, click "Delete", cancel the confirm, repeat and
   answer Yes
4. Select `arena` (the active row), click "Delete", read the confirm, answer Yes and wait for
   the reload
5. Click "Rename" and "Delete" with no profile selected
6. `/reload` and re-check the list

## Expected

- The rename prompt stops accepting input at 30 characters; `Default` as the new name is
  refused with `"Default" is a reserved profile name`; an empty name with the "cannot be
  empty" error; an existing name with the "already exists" error - both profiles stay
- Rename: the list shows "arena (active)" - the active marker followed the rename - the list
  re-sorts alphabetically below Default, a success message names the new name and the profile's
  content is unchanged (spot-check by re-exporting); `/reload` keeps `arena` as the active
  profile
- Deleting the inactive `temp` in step 3 asks the plain `Delete profile "temp"?` question;
  cancelling keeps it, confirming removes it without a reload, drops the selection and leaves
  `arena` active and the live configuration untouched
- The confirm in step 4 says `arena` is the active profile and that `Default` takes over the
  settings before the UI reloads
- After the reload the list reads "Default (active)" and `arena` is gone; the spell
  configuration, positions and options are `Default`'s own
- Rename/Delete with no selection are greyed; reaching them anyway prints the "no profile
  selected" error
- Neither profile returns after `/reload`
- No Lua errors
