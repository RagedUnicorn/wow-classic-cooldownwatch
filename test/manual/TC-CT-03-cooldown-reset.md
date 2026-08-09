# TC-CT-03 — Cooldown reset (Preparation / Cold Snap)

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> Rogue Preparation clears the queued rogue cooldowns (Adrenaline Rush, Blade Flurry, Blind, Cold
> Blood, Evasion, Gouge, Kick, Kidney Shot, Riposte, Sprint, Vanish); mage Cold Snap clears Frost
> Nova, Cone of Cold, Ice Block, Ice Barrier, Frost Ward and Fire Ward. The reset runs **before**
> the per-spell enabled gate, so it applies even when the trigger itself is not tracked.

## Preconditions

- Development checkout (`/rgcw test inject`)

## Steps

1. `/rgcw test inject`, `/target <yourname>`
2. Inject several rogue cooldowns from the Preparation list (e.g. Evasion, Sprint, Vanish, Kick)
   plus one control cooldown that is **not** on the list - a spell from another category works
   best, e.g. mage Frost Nova
3. Inject Preparation
4. Repeat with the mage side: inject Frost Nova, Ice Block, Ice Barrier, Frost Ward, then Cold Snap
5. Disable Preparation in `/rgcw opt` → Rogue, redo steps 2-3
6. Inject Preparation on a caster with an empty bucket (fresh `/reload`, no other injections)

## Expected

- Preparation removes every listed rogue cooldown from the bar in the same tick; the control
  cooldown from another category stays
- Cold Snap removes the frost list **and** Fire Ward (the wards share a timer in Classic Era)
- With Preparation disabled the resets still happen (displayed info is corrected), but Preparation's
  own cooldown does **not** appear on the bar
- Injecting Preparation with nothing queued is a no-op - no error, no empty slot
- No Lua errors
