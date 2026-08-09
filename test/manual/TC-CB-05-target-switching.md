# TC-CB-05 — Target switching and losing the target

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A battleground (several enemies casting) for the live half
- Development checkout for the injector cross-check

## Steps

1. In a battleground, watch two different enemy players cast tracked spells
2. Target the first enemy, then the second, then back to the first
3. Clear the target (Escape) while cooldowns are still running
4. Tab-target rapidly through several enemies who have **no** tracked cooldowns
5. Target an enemy who has cooldowns running, then let the enemy (and its cooldowns) expire fully
   before retargeting

## Expected

- Each target shows only its own cooldowns; switching targets swaps the whole bar content within a
  tick
- Cooldowns keep running while their caster is not targeted - retargeting shows the correct
  remaining time, not a restarted timer
- Clearing the target empties every slot and the bar stops updating
- Tab-targeting through cooldown-less enemies leaves the bar empty and produces no flicker
- A fully expired bucket does not resurrect anything on retarget
- No Lua errors during rapid target switching
