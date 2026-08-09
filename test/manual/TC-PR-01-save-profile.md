# TC-PR-01 — Save current configuration as profile

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- Any character

## Steps

1. Make a set of recognizable changes: disable two spells, enable an `items` entry, set a manual
   override, check the global worst-case option, move the bar and lock it
2. `/rgcw opt` → Profiles → "Save current as...", enter a name (e.g. `pvp`)
3. Confirm the list and the success message
4. Save a second profile under a different name
5. Try to save under an existing name
6. Try to save with an empty name
7. `/reload` and re-open the Profiles panel

## Expected

- The profile appears in the list and a success message names it
- The snapshot holds the configurable fields (spell configuration, overrides, global option, frame
  positions, lock state) - verify by changing settings afterwards and applying the profile
  ([TC-PR-02](TC-PR-02-apply-profile.md))
- Saving under an existing name is refused with the "already exists" error and leaves the stored
  profile untouched
- An empty name is refused with the "cannot be empty" error
- Both profiles are still listed after the reload
- No Lua errors
