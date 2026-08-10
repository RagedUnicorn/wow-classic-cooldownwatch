# TC-OP-04 — Disabled row greys out its controls

**Area:** Options | **Client:** Era | **Mandatory:** yes

## Preconditions

- Any character

## Steps

1. `/rgcw opt` → a category; expand a row for a spell that has a worst case
2. Uncheck the spell's tracking checkbox while the row is expanded
3. Try to type into the `Cooldown` field and the `Worst case` field, and to click "Use worst case"
4. Re-check the spell, start typing a value, then uncheck the spell while the edit is in progress
5. Re-check the spell again
6. Switch to another category and back (rows are recycled across categories)

## Expected

- Unchecking greys out the spell name, the description line under it, the worst-case toggle, both
  value fields and their labels. **Every segment** of the description line dims - a row with both a
  cyan worst case and a gold override must go uniformly grey, with no colored segment surviving.
  An untracked row must not keep a highlight suggesting it is live
- Any reset key on the row is hidden while it is untracked; re-checking brings back the ones whose
  field is actually overridden
- The disabled controls do not accept input: neither field can be focused/edited, the toggle does
  not flip
- No gold live-value highlight remains on a disabled row - everything reads as dimmed
- The in-progress edit from step 4 is dropped, **not** committed. Untracking a spell is the addon
  taking focus away, not the player leaving the field, so the normal commit-on-blur must not fire
- Re-checking restores the colors, re-enables the controls and re-applies the gold highlight to the
  live value
- Step 6: the recycled row rebinds the correct state (nothing is left over from the spell the row
  showed in the other category), and an edit left in progress across the switch is not written onto
  the new spell
- No Lua errors
