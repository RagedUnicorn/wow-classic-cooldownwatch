# TC-CV-02 — Per-spell worst case beats the global default

**Area:** Cooldown values | **Client:** Era | **Mandatory:** yes

> An explicit per-spell toggle wins **in both directions**: it opts a spell in while the global
> default is off, and opts it out while the global default is on.

## Preconditions

- Development checkout (`/rgcw test inject`)
- Two spells with a `cooldownWorstCase` (e.g. Blessing of Protection 300/180, Concussive Shot
  12/11)

## Steps

1. Global option **off**. Expand spell A's row and check "Use worst case"
2. Inject A and B, compare the timers
3. Turn the global option **on**. Expand spell B's row and **uncheck** "Use worst case"
4. Inject A and B again
5. `/reload` and re-open both rows
6. Expand a spell **without** a worst case and look for the toggle

## Expected

- Step 2: A runs its worst-case value, B runs its base value
- Step 4: A still runs worst case, B runs its base value despite the global default being on
- The checkbox states shown after the reload match what was set (explicit `true`/`false` is stored
  per spell, it is not derived from the global default)
- The lit field border in each row points at the value that will actually be used, in that field's
  own colour: gold on `Cooldown`, cyan on `Worst case`
- **Collapse both rows.** The description line under each spell name reports the state without
  needing the row open:
  - A (toggle **on**): `20s worst case / 30s cooldown`, the worst-case segment in **cyan**. Not
    gold: gold is reserved for a value typed into a field on this spell
  - B (toggle **off**): `30s cooldown` only - the worst-case segment is **gone**, not dimmed. An
    unticked checkbox means the worst case plays no part, and the line must say so
  The line flips the moment the toggle is clicked - it must not need a category switch or a
  `/reload` to catch up
- Spells without a worst case show no toggle and no worst-case field at all
- No Lua errors
