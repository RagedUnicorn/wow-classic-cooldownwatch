# TC-CV-04 — Change applies from the next cast

**Area:** Cooldown values | **Client:** Era | **Mandatory:** yes

> The cooldown value is resolved **once per enqueue**. Changing a setting never rewrites an entry
> that is already running - it takes effect on the next cast.

## Preconditions

- Development checkout (`/rgcw test inject`)
- A spell with a long cooldown and a worst case (e.g. Blessing of Protection 300/180)

## Steps

1. `/rgcw test inject`, `/target <yourname>`, inject the spell with default settings
2. While the timer is running, check "Use worst case" for that spell
3. Watch the running slot
4. Inject the same spell again (refresh) and read the timer
5. Repeat with a manual override: set one while an entry is running, then re-inject
6. Repeat with the global option

## Expected

- The in-flight entry keeps counting down with the value it was queued with - it does not jump
- The re-injection (step 4) refreshes the entry and now uses the new value from the full duration
- The same holds for the manual override and the global option
- No Lua errors, and no slot showing a negative or jumped timer
