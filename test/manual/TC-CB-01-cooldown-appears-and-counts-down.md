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

## Expected

- An icon appears in the first free slot within a tick (50 ms) of the cast
- The icon is the spell icon; for item-triggered entries it is the item icon
  ([TC-CT-05](TC-CT-05-item-triggered-cooldown.md))
- The big timer counts down in tenths (`%.1f`) and matches the spell's catalog cooldown
- The radial cooldown sweep runs over the icon and Blizzard's own countdown numbers stay hidden
- The big timer sits in the wide position while above 10s and shifts to the narrow position below
  10s
- For a spell with a `cooldownWorstCase` a second, smaller timer shows the worst-case remaining in
  the upper-left corner and blanks out once it reaches 0; spells without one show no small timer
- No Lua errors while the bar renders
