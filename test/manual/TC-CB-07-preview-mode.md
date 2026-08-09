# TC-CB-07 — Preview mode via `/rgcw conf`

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

> Preview mode owns the slot widgets: the live render ticker must stay down while it runs, even
> though combat log events keep enqueueing. Enabling the preview **clears the cooldown queue**.

## Preconditions

- Development checkout (so the ticker start/stop log lines are visible in chat)

## Steps

1. `/rgcw test inject`, `/target <yourname>`, inject two spells so the bar has live content
2. `/rgcw conf enable`
3. Watch the bar for at least 30s
4. While the preview runs, inject more spells (they go through the combat-log path)
5. `/rgcw conf disable`
6. Target an enemy with running cooldowns (or inject again) and confirm the live bar is back
7. `/rgcw conf` with no argument, and `/rgcw conf bogus`

## Expected

- Enabling the preview fills all ten slots with example cooldowns and drops the live queue
- The preview animates and **loops**: each slot expires, fades and is reseeded - it never goes
  permanently empty
- Injections during the preview do not take over the slots and do not start a second ticker
  (no "Started 'TargetCooldownBarTicker'" line while the preview ticker runs)
- Disabling the preview clears every slot, cancels any playing fade and does not leave a
  half-faded icon; the live ticker starts again only once there is something to render
- `/rgcw conf` and `/rgcw conf bogus` print the invalid-argument error and change nothing
- No Lua errors on either transition
