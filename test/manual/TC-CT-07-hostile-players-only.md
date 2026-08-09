# TC-CT-07 — Only hostile player casts are tracked

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> The combat-log filter accepts hostile **players** and hostile player **pets** only. Friendly
> players, neutral/hostile NPCs and your own casts must never queue.
>
> Note the development-build difference: `DEBUG = true` lets the *target* be friendly (so the
> injector can render against yourself), but it does **not** widen the combat-log filter. The
> release build restricts targets to enemies - see [TC-BD-01](TC-BD-01-release-build-loads.md).

## Preconditions

- A party member of the same faction who can cast tracked spells (e.g. a priest with Psychic
  Scream)
- An NPC that casts a spell sharing an id with a tracked entry is not needed - NPC lookalikes are
  covered by the filter, not by data

## Steps

1. Party with the friendly player, target them, and have them cast a tracked spell repeatedly
2. Target yourself and cast a tracked spell of your own class
3. Pull an NPC caster, target it, and let it cast
4. Enter a battleground, target an enemy player and have them cast the same spell as in step 1

## Expected

- The friendly party member's casts queue **nothing** - the bar stays empty while targeting them
- Your own casts queue nothing
- NPC casts queue nothing
- The enemy player's cast in step 4 does queue, proving the filter is not simply off
- No Lua errors
