# TC-CV-03 — Manual cooldown override

**Area:** Cooldown values | **Client:** Era | **Mandatory:** yes

> The manual override replaces the resolved cooldown entirely and beats both worst-case settings.
> It is free in both directions - a value above the *catalog* cooldown is stored as typed - up to the
> absolute limit of 60 minutes (3600s). Fractions are allowed.
> Enter **or leaving the box** applies; Escape abandons; an emptied box clears the override.

## Preconditions

- Development checkout (`/rgcw test inject`)

## Steps

1. `/rgcw opt` → any category, expand a spell row with a known base cooldown (e.g. Psychic Scream,
   30s). Note the `Cooldown` field before touching it
2. Click into the `Cooldown` field, type nothing, and click away again
3. Type `15` and press Enter; inject the spell and read the timer
4. Type `45` (**above** the base cooldown) and press Enter; inject the spell again
5. Type `20` and click somewhere outside the box instead of pressing Enter
6. Type `12.5` and press Enter; inject the spell and watch the bar timer
7. Type `120.5` and press Enter - check the box was not cut short while typing
8. On a deDE client, type `12,5` with a decimal **comma** and press Enter
9. Type `3600`, press Enter; then `3601`, press Enter
10. Type invalid input: `abc`, then `0`, then `-5`, then `0x10` - press Enter after each
11. Set a valid override, then type `abc` over it and press Enter
12. Press Escape while a half-typed value is in the box
13. Clear the box (empty) and press Enter; inject the spell again
14. Set an override again, then click the **reset key** that appeared right of the `s` suffix
15. Set an override on a spell that also has a worst case and turn "Use worst case" on
16. `/reload` and re-check the fields

## Expected

- Step 1: with no override set the number is **dimmed** - it is the catalog value being displayed,
  not a stored setting
- Step 2: nothing is stored; the number stays dimmed. An untouched field must never turn the
  displayed catalog value into an override
- Step 3: the box keeps `15` in **solid** text, the field is gold-bordered as the live value, and
  the injected cooldown runs 15s. The description line under the spell name switches from
  `30s cooldown` to `15s override (base 30s)` in **gold** - collapse the row and it still says so,
  which is the point of the line
- **On a spell with "Use worst case" ticked**, overriding the cooldown must not make the worst case
  disappear from the line. It reads `20s worst case / 15s override (base 30s)`, the worst-case
  segment in **cyan** and the override segment in **gold**. The two settings are independent;
  hiding one because the other is set loses information the player put there. (The override is what
  actually gets tracked - the gold field border in the strip still marks it, and the line is an
  inventory of what is switched on rather than a single verdict)
- Untick "Use worst case" on that same spell: the cyan segment disappears entirely, leaving
  `15s override (base 30s)`
- Step 4: `45` is stored as typed - no capping, no silent snap back to `30`. The injected cooldown
  runs 45s
- Step 5: leaving the box applies exactly like Enter - `20` is stored and rendered solid
- Step 6: the fraction survives as `12.5`, **not** `12`. The bar's big timer counts down with one
  decimal (`12.5`, `12.4`, …)
- Step 7: the whole of `120.5` can be typed - the box must not stop accepting characters at `120.`,
  which would commit `120` and look like the fraction was ignored
- Step 8: `12,5` is accepted and stored as `12.5` - a decimal comma is what a German keyboard layout
  produces and must not read as invalid input
- Step 9: `3600` (60 minutes) is accepted - the limit is inclusive, paladin Lay on Hands sits exactly
  on it. `3601` is rejected: red text, focus kept, nothing stored
- Step 10: each invalid input turns the text red and keeps focus; nothing is stored. `0x10` is
  rejected rather than silently becoming `16`. Clicking away from a rejected value restores the
  previous one
- Step 11: the rejected input leaves the **existing override intact** - a value that cannot be
  stored must never clear what was already there
- Step 12: Escape restores the persisted value - nothing is committed
- Step 13: the empty commit clears the override; the box drops back to the **dimmed** base cooldown
  and the injected cooldown runs the base value again. The description line returns to
  `30s cooldown` in the normal dim color
- Step 14: the reset key is **only** present while the field is overridden - it appears when the
  value is committed and disappears the instant it is reset or cleared. Clicking it restores the
  dimmed base cooldown, the dim description line, and the base timer, exactly as the empty commit
  in step 13 did. Hovering it shows a tooltip explaining what it resets
- The strip must not shuffle sideways when the key appears or disappears - the `Worst case` label
  and everything right of it stay put
- Step 15: the override wins - the `Cooldown` field keeps the gold border and the timer uses the
  override, not the worst case. The description line reads `15s override (base 30s)` in **gold**,
  not the cyan worst-case state
- All overrides survive the reload, fractions included
- No Lua errors
