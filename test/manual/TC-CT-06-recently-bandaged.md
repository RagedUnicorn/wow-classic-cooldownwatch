# TC-CT-06 — Recently Bandaged lockout

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> Bandage items carry no item cooldown - the 60s lockout is the *Recently Bandaged* debuff on the
> **bandaged** unit, so the entry tracks `SPELL_AURA_APPLIED` and is attributed to the dest unit.
> One entry covers every bandage rank. It lives in `misc` and is disabled by default.
>
> A bandage channel that is interrupted before it ticks applies **no** debuff while the item's cast
> event still fires - that is why this must never be switched to cast tracking.

## Preconditions

- A duel partner with bandages, or a battleground
- `misc` → Recently Bandaged enabled in `/rgcw opt`

## Steps

1. Enable Recently Bandaged in `/rgcw opt` → Misc
2. Duel a partner; have them bandage **themselves** and let the channel complete
3. Target them and watch the bar
4. Have them start a bandage and interrupt it (move, or take damage) before it completes
5. If a third player is available: have the partner bandage the *third* player, then check both
   players' bars

## Expected

- A completed self-bandage puts one 60s entry on the bandaging player's bar
- Ranks are irrelevant - any bandage produces the same single entry
- An interrupted (non-ticking) bandage produces **no** entry at all
- When one enemy bandages another, the entry is attributed to the unit that received the bandage,
  not the caster
- With the entry disabled, nothing is tracked at all
- No Lua errors
