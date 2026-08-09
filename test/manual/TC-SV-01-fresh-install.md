# TC-SV-01 — Fresh install seeds defaults

**Area:** SavedVariables | **Client:** Era | **Mandatory:** yes

## Preconditions

- Client fully logged out
- Backup of the character's current `WTF/.../SavedVariables/CooldownWatch.lua` taken (to restore
  after the test)

## Steps

1. Delete `CooldownWatch.lua` (and `CooldownWatch.lua.bak`) from the character's `SavedVariables`
   folder
2. Log in with the character
3. Observe the screen and chat for errors
4. Open `/rgcw opt` and walk through every subpanel (Options, Profiles, all eleven spell
   categories, About)
5. Target an enemy player (or use `/rgcw test inject` against yourself) and confirm a cooldown
   renders
6. Log out and inspect the written SavedVariables file

## Expected

- No Lua errors on login; the welcome message prints
- Options shows both checkboxes unchecked (`lockTargetCooldownBar`, `globalAssumeWorstCase` both
  default to `false`)
- Every spell category lists its spells; class spells are checked (`active = true`), the whole
  `items` and `misc` categories are unchecked (`active = false`, opt-in) and Devour Magic is
  unchecked
- The bar renders at screen center (no saved frame position yet) and is draggable (unlocked
  default shows the dialog backdrop)
- `CooldownWatchConfiguration` contains every field from `Configuration.GetDefaults()`:
  `lockTargetCooldownBar`, `cooldownConfiguration`, `cooldownOverrides`, `globalAssumeWorstCase`,
  `frames`, `profiles`, `lastNotifiedVersion` - plus the stamped `addonVersion`
- `profiles` holds exactly one entry named `Default` (see
  [TC-PR-06](TC-PR-06-default-profile.md))
