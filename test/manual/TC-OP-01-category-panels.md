# TC-OP-01 — Every category panel opens and renders

**Area:** Options | **Client:** Era | **Mandatory:** yes

## Preconditions

- Any character

## Steps

1. `/rgcw opt`
2. Walk through every subpanel in order: Options, Profiles, and all eleven spell categories
   (Priest, Rogue, Mage, Hunter, Warlock, Paladin, Druid, Shaman, Warrior, Racials, Items, Misc)
3. On each category: check the panel title, scroll to the bottom of the list, hover a few row icons
4. Switch back and forth between two categories with very different spell counts (e.g. Warrior and
   Racials)
5. Read the About page on the main panel
6. Open the panel through the Blizzard interface options (AddOns tab) as well as through `/rgcw opt`

## Expected

- Every subpanel opens without a Lua error and is titled in the client language
- Each list shows one row per spell in that category, with icon, checkbox, spell name and the
  cooldown value line (`<n>s cooldown`, or `<n>s cooldown / <m>s worst case`)
- Row icons carry the correct tooltip (spell tooltip, or item tooltip for `itemId` entries)
- Switching categories re-tints the rows in the new category color, resets the scroll position to
  the top, collapses any expanded row and leaves no stale rows from the larger category visible
- The About page shows the addon version, author, e-mail and issues link
- No Lua errors
