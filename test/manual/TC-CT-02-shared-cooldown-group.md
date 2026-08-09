# TC-CT-02 — Shared cooldown group fan-out

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> Two groups exist: `shaman_shocks` (Earth Shock / Frost Shock / Flame Shock) and `mage_wards`
> (Fire Ward / Frost Ward). Fan-out is **unconditional** - a sibling surfaces even when the player
> disabled it, because the enemy really is on cooldown for it.

## Preconditions

- Development checkout (`/rgcw test inject`), or a shaman/mage duel partner

## Steps

1. `/rgcw test inject`, `/target <yourname>`
2. Inject Earth Shock and watch the bar
3. Open `/rgcw opt` → Shaman, disable Frost Shock, and inject Earth Shock again
4. Repeat with a mage ward (inject Frost Ward, expect Fire Ward alongside)
5. Set a manual override on **one** group member (e.g. Frost Shock) and inject Earth Shock again

## Expected

- Injecting one shock queues all three shocks with the same start time - three slots, identical
  remaining time
- The disabled sibling still appears (fan-out ignores the per-sibling enabled flag), but injecting
  the *disabled* spell itself does nothing
- The mage wards behave the same way as a pair
- Each sibling resolves its **own** cooldown value: the overridden member shows the override, the
  others show their base value - one member's setting never propagates
- No Lua errors, no duplicated slot for the spell that actually fired
