# TC-OP-03 — Accordion, scrollbar and canvas resize

**Area:** Options | **Client:** Era | **Mandatory:** yes

> The spell list is an accordion: at most one row is expanded at a time. Rows are anchored, not
> sized, so the list follows whatever space the settings canvas hands out at any resolution or UI
> scale.

## Preconditions

- Any character; a category with many spells (Warrior, Mage) and one with few (Racials)

## Steps

1. `/rgcw opt` → a large category. Click a row body to expand it, then click another row
2. Click the expanded row again (and its `-` key) to collapse it
3. Scroll the list with the mouse wheel and by dragging the scrollbar; scroll while a row is
   expanded
4. Open a category with fewer spells than fit the canvas
5. Change the UI scale (`/console uiScale 0.8`, then back) and/or the window size while the panel is
   open
6. Expand a row, switch category, switch back

## Expected

- Expanding a row unfolds its options strip and swaps its key glyph from `+` to `-`; expanding
  another row collapses the first
- The row layout accounts for the taller expanded row - no overlap, no gap
- The scrollbar overlays the right edge of the rows and the row controls stay clear of it
- A category that fits the canvas shows **no** scrollbar (auto-hide), and the list is not scrollable
- Resizing / rescaling re-widths the rows to the canvas without a reload; no clipped controls
- Switching category collapses the accordion - the recycled row in the new category shows no stale
  strip
- No Lua errors
