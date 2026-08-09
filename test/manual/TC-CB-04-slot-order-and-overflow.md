# TC-CB-04 — Slot order and overflow truncation

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

> The bar has 10 slots; the queue snapshot is sorted soonest-ready-first with the spellId as
> tiebreaker, so ordering is a function of the entries, never of Lua hash order.

## Preconditions

- Development checkout (`/rgcw test inject` available)

## Steps

1. `/rgcw test inject`, `/target <yourname>`
2. Inject a long cooldown first (e.g. Vanish 300s), then a short one (e.g. Kick 10s)
3. Watch where the short cooldown lands
4. Inject more than ten different tracked spells for the same caster, mixing long and short
   cooldowns
5. `/reload` and repeat step 4 to confirm the order is stable across sessions

## Expected

- The slot order is soonest-ready-first: the short cooldown injected second takes the **first**
  slot, pushing the long one right
- Icons do not jitter between ticks - the order only changes when the tracked set changes
- With more than ten entries only the ten that come back soonest are shown; the rest are queued but
  not rendered, and they appear as the earlier ones expire
- The same injection sequence produces the same order after a reload
- No Lua errors, no duplicate icon for the same spell (a re-injection refreshes the existing slot)
