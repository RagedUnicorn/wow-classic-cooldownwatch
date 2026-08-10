# TC-CB-01 — Cooldown appears and counts down

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A duel partner or a battleground for the live-combat half of the case
- Default configuration (no manual overrides, worst case off)

## Steps

1. Target an enemy player and have them cast a tracked spell with a long cooldown
   (e.g. Psychic Scream, Blind, Frost Nova)
2. Watch the slot for the full duration of the cooldown
3. Repeat solo with the injector as a cross-check: `/rgcw test inject`, `/target <yourname>`,
   inject a spell that carries a `cooldownWorstCase` (e.g. Blessing of Protection, Concussive
   Shot)
4. Inject the **longest** cooldown in the catalog - paladin Lay on Hands, 3600s - and watch the
   slot, especially with a second cooldown running in the slot next to it

## Expected

- An icon appears in the first free slot within a tick (50 ms) of the cast
- The icon is the spell icon; for item-triggered entries it is the item icon
  ([TC-CT-05](TC-CT-05-item-triggered-cooldown.md))
- The radial cooldown sweep runs over the icon and Blizzard's own countdown numbers stay hidden
- The big timer counts down through three tiers and is horizontally **centered** in the slot at
  every one of them:
  - at or above 60s: whole minutes, rounded up (`60m`, `30m`, `2m`)
  - 10s to 59s: whole seconds (`59`, `10`)
  - below 10s: tenths (`9.9`, `0.4`)
- Step 4: `3600s` reads as `60m` and stays **inside its own slot**. It must not run over the slot
  edge or collide with the neighbouring slot's timer
- For a spell with a `cooldownWorstCase` a second, smaller timer shows the worst-case remaining in
  the upper-left corner in the same format, and blanks out once it reaches 0; spells without one
  show no small timer
- No Lua errors while the bar renders
