# TC-CB-03 — Expiry fade and mid-fade recast

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

> Expiry is a data-layer event (one-shot timer per enqueue), the render pass only plays the 2s
> fade and the fade's `OnFinished` removes the entry.

## Preconditions

- Development checkout (`/rgcw test inject` available)
- A short-cooldown spell to work with (e.g. Kick 10s, Gouge 10s)

## Steps

1. `/rgcw test inject`, `/target <yourname>`
2. Inject a short cooldown and let it run out while the target stays selected
3. Inject the same spell again **while the fade is still playing** (within the 2s fade window)
4. Let it run out again, then inject it once more *after* the fade finished
5. Repeat step 2, but deselect the target before the cooldown ends, then reselect the target after
   more than 5s (the prune grace)

## Expected

- When the cooldown reaches 0: both timer texts blank, the icon fades out over 2s and the slot
  clears; the entry leaves the queue when the fade finishes
- The recast in step 3 cancels the fade: the icon goes back to full opacity and the timer restarts
  from the full cooldown - the entry is **not** removed when the old fade would have ended
- The post-fade injection in step 4 binds a fresh slot with a full timer
- After step 5 the reselected target shows no expired leftovers - the target-change sweep removed
  the entry that expired while unrenderable
- No Lua errors, and no slot left stuck at partial alpha
