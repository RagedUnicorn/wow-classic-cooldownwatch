# TC-OP-04 — Disabled row greys out its controls

**Area:** Options | **Client:** Era | **Mandatory:** yes

## Preconditions

- Any character

## Steps

1. `/rgcw opt` → a category; expand a row for a spell that has a worst case
2. Uncheck the spell's tracking checkbox while the row is expanded
3. Try to type into the `Cooldown` field and to click "Use worst case"
4. Start typing a value, then uncheck the spell while the edit is in progress
5. Re-check the spell
6. Scroll the list so the row is recycled to a different spell, then scroll back

## Expected

- Unchecking greys out the spell name, the worst-case toggle, both value fields and their labels
- The disabled controls do not accept input: the field cannot be focused/edited, the toggle does not
  flip
- No gold live-value highlight remains on a disabled row - everything reads as dimmed
- The in-progress edit from step 4 is dropped, not committed
- Re-checking restores the colors, re-enables the controls and re-applies the gold highlight to the
  live value
- Scrolling away and back rebinds the correct state to the row (states are never left over from a
  recycled row)
- No Lua errors
