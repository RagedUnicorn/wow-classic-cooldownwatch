# TC-PT-01 — Pet cast queues under the owning player

**Area:** Pet-cast attribution | **Client:** Era | **Mandatory:** yes

> Felhunter Spell Lock (30s in Classic Era) and Devour Magic fire the combat-log event with the
> **pet's** GUID as source. Pet GUIDs are re-minted on every resummon, so the cooldown must queue
> under the owning player's GUID. Devour Magic is disabled by default.
>
> This case cannot be driven by the injector - it needs a real combat log.

## Preconditions

- A warlock duel partner with a felhunter, or a battleground with warlocks
- `warlock` → Spell Lock enabled (default); enable Devour Magic for the second half

## Steps

1. Duel the warlock, target the **warlock** (not the pet), and have the felhunter cast Spell Lock
2. Watch the bar
3. Have the warlock dismiss and resummon the felhunter, then cast Spell Lock again
4. Enable Devour Magic in `/rgcw opt` → Warlock and have the pet cast it
5. If the partner is below level 52: have them cast the lower rank of Spell Lock

## Expected

- Spell Lock appears on the **warlock's** bar with a 30s timer (not 24s - that is the TBC value)
- Nothing is attributed to the pet as its own caster
- After the resummon the next Spell Lock lands on the same warlock bucket - the new pet GUID does
  not create a second bucket
- Devour Magic tracks once enabled and is ignored while disabled
- A lower-rank Spell Lock tracks like the primary rank
- No Lua errors
