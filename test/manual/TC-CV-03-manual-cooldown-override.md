# TC-CV-03 — Manual cooldown override

**Area:** Cooldown values | **Client:** Era | **Mandatory:** yes

> The manual override replaces the resolved cooldown entirely and beats both worst-case settings.
> It can only **lower** the tracked time - a value above the base cooldown is capped.

## Preconditions

- Development checkout (`/rgcw test inject`)

## Steps

1. `/rgcw opt` → any category, expand a spell row with a known base cooldown (e.g. Psychic Scream,
   30s)
2. Type `15` into the `Cooldown` field and press Enter; inject the spell and read the timer
3. Type a value **above** the base cooldown (e.g. `999`) and press Enter
4. Type invalid input: `abc`, then `0`, then `-5` - press Enter after each
5. Press Escape while a half-typed value is in the box, then click away from a half-typed value
6. Clear the box (empty) and press Enter; inject the spell again
7. Set an override on a spell that also has a worst case and turn "Use worst case" on
8. `/reload` and re-check the fields

## Expected

- Step 2: the box keeps `15`, the field is gold-highlighted as the live value, and the injected
  cooldown runs 15s
- Step 3: the stored value is capped at the base cooldown and the box re-renders the capped value
- Step 4: each invalid input turns the text red and keeps focus; nothing is stored
- Step 5: Escape and click-away both restore the persisted value - nothing is committed
- Step 6: the empty commit clears the override and the box drops back to the base cooldown; the
  injected cooldown runs the base value again
- Step 7: the override wins - the `Cooldown` field stays gold and the timer uses the override, not
  the worst case
- All overrides survive the reload
- No Lua errors
