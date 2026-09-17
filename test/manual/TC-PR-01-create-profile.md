# TC-PR-01 — Create a profile from the current settings

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A recognizable configuration (two spells disabled, an `items` entry enabled, a manual
  override, the global worst-case option checked, the bar moved)

## Steps

1. Open `/rgcw opt` → Profiles and look at the list
2. Click "Create new Profile", enter `pvp`, Accept
3. Click "Create new Profile" again and enter `pvp`; then `Default`; then a blank name; then
   try to type a name longer than 30 characters
4. `/reload` and reopen the page

## Expected

- Before step 2 the list reads "Default (active)" in gold; with nothing selected Load, Rename,
  Delete and Export are greyed while Create new Profile, Reset to defaults and Import are not
- After step 2 the list reads "Default" and "pvp (active)" (gold, selected), the chat says
  `Created profile "pvp" - it is now active`, and no UI reload happened - the spell
  configuration, the override and the bar position are exactly as before
- The taken name, `Default` and the blank name are each refused with a chat error and nothing
  is created; the prompt stops accepting input at 30 characters
- After `/reload` the list still shows "pvp (active)"; the SavedVariables hold both profiles
  under `CooldownWatchConfiguration.profiles` with the same settings (the mirror ran at the
  reload) and `CooldownWatchConfiguration.activeProfile` reads `pvp`
- The profile captures the full configuration: spell configuration and overrides per side, the
  global worst-case option, the friendly flags, both proximity window blocks, the bar scale and
  the frame positions - verify by changing settings afterwards and switching
  ([TC-PR-02](TC-PR-02-switch-profile.md))
- No Lua errors
