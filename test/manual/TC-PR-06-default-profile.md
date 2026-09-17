# TC-PR-06 — Default profile is editable, Reset to defaults restores the factory settings

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

> The reserved `Default` profile is seeded from the **shipped defaults** only when the store has
> none, and from then on it is the editable home profile: while it is the active one the live
> configuration is mirrored into it, so it holds the player's own settings. The factory settings
> come back through "Reset to defaults", not by loading Default.

## Preconditions

- A character that has never seen the Default profile (fresh install per
  [TC-SV-01](TC-SV-01-fresh-install.md)) for step 1, otherwise any character

## Steps

1. Log in and open `/rgcw opt` → Profiles without creating anything
2. Select "Default" and try "Rename", then "Delete"
3. With `Default` active, disable a spell, set a manual override, move the bar and enable the
   enemy proximity window; `/reload` and check the SavedVariables
4. Click "Create new Profile" and enter `Default`; then create `scratch` (it becomes active) and
   change one more option
5. With nothing selected click "Reset to defaults", read the confirm, answer Yes and wait for
   the reload
6. Select `Default`, Load, Yes, wait for the reload
7. Export the "Default" profile, then import it under the name `Default`; then rename `scratch`
   to `Default`

## Expected

- "Default (active)" is present in gold on the very first login, without the user creating it
- While "Default" is selected the Rename and Delete buttons are greyed out; clicking them anyway
  (or reaching them by any other route) prints the "cannot be renamed" / "cannot be deleted"
  error and changes nothing
- Default is editable: after step 3 the stored `CooldownWatchConfiguration.profiles.Default`
  holds the disabled spell, the override, the bar position and the enabled window (the mirror
  ran at the reload) - it was not re-seeded with the shipped values
- Creating under the name `Default` is refused with `"Default" is a reserved profile name`
- "Reset to defaults" is never greyed; the confirm names `scratch` and says every option goes
  back to its default before the UI reloads
- After the reload of step 5 the character is in the fresh-install state: the curated set of
  spells tracks, no overrides, global worst case off, the bar and both windows at their default
  scale and position, both proximity windows disabled; the list still reads "scratch (active)"
- `Default` was not touched by the reset: after step 6 the disabled spell, the override, the bar
  position and the enabled window of step 3 are back
- Importing under the name `Default` and renaming onto `Default` are each refused with the
  reserved-name error and leave every profile untouched
- After `/reload` the list still holds "Default" plus the user profiles; other profiles can
  still be created, loaded, renamed and deleted as usual
- No Lua errors
