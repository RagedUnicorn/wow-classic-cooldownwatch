# TC-CB-08 — Render ticker runs only while there is work

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

> The 20 Hz render ticker is not started at login. It wakes on three edges only (target change,
> enqueue, preview hand-back) and stops itself in the render pass that clears the last slot.
> The `Started`/`Stopped 'TargetCooldownBarTicker'` log lines make this observable in a
> development build.

## Preconditions

- Development checkout (info-level logging visible in chat)

## Steps

1. `/reload` and watch chat - do not target anything
2. Target a friendly/enemy unit that has no tracked cooldowns, then tab through a few more
3. `/rgcw test inject`, `/target <yourname>`, inject one short cooldown
4. Let it expire and the fade finish; keep the target selected
5. Inject again, then clear the target before the cooldown ends

## Expected

- No "Started 'TargetCooldownBarTicker'" line at login - the ticker is idle
- Targeting cooldown-less units does not start the ticker
- The injection starts the ticker exactly once ("Started" logged); further injections do not log a
  second start
- After the last cooldown's fade finishes the ticker logs "Stopped" - and the bar is fully cleared
  at that point (no leftover icon, timer or highlight)
- Clearing the target in step 5 also stops the ticker after clearing the slots
- No Lua errors, and never two tickers running at once
