# TC-CB-02 — Warn and alert thresholds

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

> The thresholds are relative to the cooldown's own duration: warn at 50 % remaining, alert at
> 20 % remaining (`TARGET_COOLDOWN_WARN_THRESHOLD` / `TARGET_COOLDOWN_ALERT_THRESHOLD`).

## Preconditions

- Development checkout (`/rgcw test inject` available)

## Steps

1. `/rgcw test inject`, `/target <yourname>`
2. Inject a long cooldown (e.g. rogue Vanish, 300s) and a short one (e.g. Kick, 10s) so both a
   slow and a fast transition can be observed
3. Watch each slot's border through the whole countdown

## Expected

- Above 50 % remaining: no highlight border on the slot
- At or below 50 % remaining: the highlight frame shows in the warn color
- At or below 20 % remaining: the highlight frame switches to the alert color
- Both transitions happen at the same *relative* point for the 300s and the 10s cooldown - the
  thresholds are percentages, not fixed seconds
- The border clears when the slot is cleared (no stale highlight left on a reused slot)
- No Lua errors
