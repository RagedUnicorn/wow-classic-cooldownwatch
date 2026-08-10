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
2. Note the description line on a spell row that has a worst case (e.g. Blessing of Protection
   shows `5m cooldown / 3m worst case` - readable durations, not raw seconds)
3. `/rgcw test inject`, `/target <yourname>`, inject that spell and read the big timer
4. Check the global option, inject the spell again
5. Inject a spell **without** a worst case (e.g. Psychic Scream) in both states
6. `/reload` and confirm the option state persisted

## Expected

- With the option off, the injected cooldown runs the **base** value and the small hint timer shows
  the worst-case remaining
- With the option on, the cooldown runs the **worst-case** value and the small hint timer is gone
  (the resolved value is promoted into the single authoritative timer)
- In the expanded row, the lit field follows: the `Cooldown` field in **gold** while the option is
  off, the `Worst case` field in **cyan** while it is on. The worst-case field never lights gold -
  gold means the player set a value on this spell, which the global default does not do
- Back on the category panel, the description line follows too, and does so on **collapsed** rows:
  `5m cooldown` alone with the option off, and `3m worst case / 5m cooldown` with the worst-case
  segment in **cyan** with it on. The global default counts as the worst case being switched on for
  a spell that was never configured individually, so the segment appears for those spells too.
  (The global option lives on another panel, so the line is rebound when the category panel is
  shown again - it cannot update while it is not on screen.)
- **No segment may turn gold here.** Gold means "I set a value on this spell"; a spell pulled to
  worst case purely by the global default was not customized, and claiming otherwise is the
  confusion the line exists to remove. Cyan is the worst-case color, matching the bar's small
  worst-case timer and the strip's worst-case field border
- No reset key appears on either value field - the global option is not a per-field override
- Spells without a worst case are unaffected in both states, description line included
- The option state survives a reload
- No Lua errors
