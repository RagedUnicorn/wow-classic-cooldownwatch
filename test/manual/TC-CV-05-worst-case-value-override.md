# TC-CV-05 — Per-spell worst case value override

**Area:** Cooldown values | **Client:** Era | **Mandatory:** yes

> The `Worst case` field corrects the **value** the catalog carries. Whether the worst case is
> assumed at all stays with the toggle next to it. Editing semantics are identical to the
> `Cooldown` field: Enter or leaving the box applies, Escape abandons, an emptied box falls back
> to the catalog value.

## Preconditions

- Development checkout (`/rgcw test inject`)
- A spell with a `cooldownWorstCase` (e.g. Blessing of Protection 300/180)

## Steps

1. `/rgcw opt` → expand the spell's row. Note the `Worst case` field before touching it
2. With "Use worst case" **off**, type a new worst-case value (e.g. `200`) and press Enter; inject
   the spell and read both timers on the bar
3. Turn "Use worst case" **on** and inject the spell again
4. Type a value **at** the base cooldown (`300` for Blessing of Protection), press Enter; then one
   **above** it (`400`), press Enter
5. Type `12.5`, press Enter; then `3601`, press Enter
6. Type invalid input: `abc`, then `0` - press Enter after each
7. Set a value again, then click the **reset key** right of the field's `s` suffix
8. Empty the box and press Enter; inject again
9. Raise the `Cooldown` override well above the base (e.g. `600`), then try a `Worst case` value
   between the base and that override (e.g. `400`)
10. Clear the `Cooldown` override again, then set both a `Cooldown` override and a `Worst case`
    value, with "Use worst case" on
11. `/reload` and re-check both fields
12. Expand a spell **without** a catalog worst case

## Expected

- Step 1: with no value set the number is **dimmed** - it is the catalog's `cooldownWorstCase`
  being displayed, not a stored setting
- Step 2: the field shows `200` in **solid** text. The main timer still runs the base cooldown, but
  the bar's small hint timer shows the corrected `200` - the value substitution happens whether or
  not the worst case is assumed. The description line shows no worst-case segment yet, because the
  checkbox is off
- Step 3: the live border moves to the `Worst case` field and lights up **cyan**, not gold - the
  worst-case colour, matching the description line and the bar's small worst-case timer. Gold on
  this field would claim the player set the value, which the global default alone can also do. The
  injected cooldown runs `200`
- Step 4: **both** are rejected - red text, focus kept, nothing stored. A worst case must be
  strictly **below** the base cooldown: above it the tracked time would exceed what the spell can
  possibly have, and exactly at it the "Use worst case" toggle would silently do nothing
- Step 5: `12.5` keeps its fraction; `3601` is rejected
- Step 6: each invalid input turns the text red and keeps focus; nothing is stored, and an existing
  value is left intact
- Step 7: this field has its **own** reset key, present only while it is overridden. Clicking it
  clears the worst-case value alone and leaves the `Cooldown` override and the "Use worst case"
  toggle untouched - each key resets exactly its own field
- Step 8: the field drops back to the **dimmed** catalog value and the injected cooldown uses it
- Step 9: `400` is **still rejected**, even though the `Cooldown` override is `600`. The rule
  compares against the spell's catalog cooldown, never against an override - an override replaces
  the resolution wholesale, worst-case settings included, so it is not the value this field is a
  worst case of. Raising it must not widen what the worst-case field accepts
- Step 10: the `Cooldown` override wins - it keeps the gold border and the timer uses it, the
  worst-case value is ignored. With "Use worst case" ticked the description line still shows
  **both**: the worst-case segment in cyan and the override segment in gold. The corrected
  worst-case value must be the one displayed there, not the catalog's
- Both values survive the reload, fractions included
- Step 12: no toggle and no worst-case field at all - the catalog decides whether a spell has a
  worst case, the player only what it is. Such spells use the `Cooldown` override instead. No reset
  key is left visible from a previously shown row
- No Lua errors
