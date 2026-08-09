# TC-PT-02 — Targeting the pet renders the owner's cooldowns

**Area:** Pet-cast attribution | **Client:** Era | **Mandatory:** yes

> A targeted hostile player-controlled pet resolves to its owner via `UnitOwnerGUID`
> (Classic Era 1.15.8+), so `currentTargetGuid` becomes the **owner's** GUID - targeting the pet
> shows the owner's full cooldown bucket, not a pet-only one.

## Preconditions

- A warlock or hunter duel partner with a pet, or a battleground
- Spell Lock enabled (default)

## Steps

1. Duel the partner; have them use a few tracked cooldowns themselves (e.g. Death Coil, Fear on
   cooldown-carrying spells) and have the pet cast Spell Lock
2. Target the **pet**
3. Compare the bar with what is shown while targeting the **owner**
4. Switch back and forth between pet and owner a few times
5. Have the partner resummon the pet and target the fresh pet

## Expected

- Targeting the pet shows the owner's complete bucket - the owner's own cooldowns *and* the
  pet-cast ones, identical to what targeting the owner shows
- Timers do not restart when switching between pet and owner
- A freshly summoned pet resolves to the same owner immediately
- If the client predates `UnitOwnerGUID` support, targeting the pet simply shows an empty bar - no
  Lua error
- No Lua errors
