# TC-CV-01 — Global worst case default

**Area:** Cooldown values | **Client:** Era | **Mandatory:** yes

> Resolution order: manual override > per-spell worst-case toggle > global default > base cooldown.
> The global default applies only to spells the player never configured individually, and only to
> spells that actually have a `cooldownWorstCase`.

## Preconditions

- Development checkout (`/rgcw test inject`)
- No per-spell worst-case toggles and no manual overrides set (fresh profile, or apply `Default`)

## Steps

1. `/rgcw opt` → Options, leave "Assume worst case for all cooldowns" **unchecked**
2. Note the two values on a spell row that has a worst case (e.g. Blessing of Protection shows
   `300s cooldown / 180s worst case`)
3. `/rgcw test inject`, `/target <yourname>`, inject that spell and read the big timer
4. Check the global option, inject the spell again
5. Inject a spell **without** a worst case (e.g. Psychic Scream) in both states
6. `/reload` and confirm the option state persisted

## Expected

- With the option off, the injected cooldown runs the **base** value and the small hint timer shows
  the worst-case remaining
- With the option on, the cooldown runs the **worst-case** value and the small hint timer is gone
  (the resolved value is promoted into the single authoritative timer)
- In the expanded row, the gold-highlighted field follows: the `Cooldown` field while the option is
  off, the `Worst case` field while it is on
- Spells without a worst case are unaffected in both states
- The option state survives a reload
- No Lua errors
