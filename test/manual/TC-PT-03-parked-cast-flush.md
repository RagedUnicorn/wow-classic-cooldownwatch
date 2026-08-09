# TC-PT-03 — Cast parked while the owner is unknown

**Area:** Pet-cast attribution | **Client:** Era | **Mandatory:** no (conditional)

> When a pet casts before its owner is known (the summon happened out of range, the owner was never
> seen in the combat log), the cast is **parked** per pet GUID and flushed as soon as any resolution
> layer supplies the owner GUID: a later summon, a sighting from targeting the pet, or the sentinel
> tooltip scan promoting the owner's name through the hostile-player directory.
>
> Run this case when `code/PetOwner.lua`, `code/Target.lua` or the pet branch of
> `code/CombatLog.lua` changed. It is timing-dependent and hard to force reliably.

## Preconditions

- A battleground (a felhunter summoned before you ever saw its owner is common there)
- `/rgcw debug` enabled so the parking / flushing debug lines are visible

## Steps

1. Enter a battleground and enable `/rgcw debug`
2. Watch for a Spell Lock from a felhunter whose owner you have not seen cast anything yet
3. Note whether the debug log reports the cast as parked
4. Target that pet (or wait until the owner casts something), then check the owner's bar

## Expected

- A cast with no resolvable owner is parked, not dropped silently and not attributed to the pet GUID
- The moment the owner becomes known, the parked cast is flushed into the owner's bucket with its
  original cast time - the timer reflects the elapsed time, it does not restart
- Long-stale parked casts (older than their own cooldown) are dropped instead of flushed
- No Lua errors
