# TC-CT-05 — Item-triggered cooldown shows the item icon

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> Entries in the `items` category carry an `itemId`, so both the options row and the bar slot show
> the recognizable **item** icon instead of the spell icon. Insignias resolve the **opposing**
> faction's item (tracked cooldowns belong to enemies).

## Preconditions

- Development checkout (`/rgcw test inject`)
- The whole `items` category defaults to disabled - enable the entries used below first

## Steps

1. `/rgcw opt` → Items, enable an insignia entry and an engineering entry (e.g. Net-o-Matic,
   Shadow Reflector)
2. Compare each enabled row's icon with the item on the tooltip (hover the row icon)
3. `/rgcw test inject`, `/target <yourname>`, inject the same entries
4. Check the icons rendered on the bar
5. Repeat the insignia check on a character of the **other** faction

## Expected

- The options row shows the item icon, and hovering it opens the **item** tooltip (not the spell
  tooltip) for entries with an `itemId`
- The bar slot uses the same item icon
- The insignia row/slot depicts the opposing faction's trinket: on an Alliance character the Horde
  insignia and vice versa
- Entries without an `itemId` still show their spell icon and spell tooltip
- No Lua errors
