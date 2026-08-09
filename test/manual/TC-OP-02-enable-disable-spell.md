# TC-OP-02 — Enabling and disabling a spell

**Area:** Options | **Client:** Era | **Mandatory:** yes

> The player's toggle is the authority; the catalog's `active` flag only applies while a spell was
> never configured. An explicit toggle wins in both directions - including enabling a spell that
> ships disabled.

## Preconditions

- Development checkout (`/rgcw test inject`)

## Steps

1. `/rgcw opt` → Priest: uncheck a spell that ships enabled (e.g. Psychic Scream)
2. `/rgcw test inject`, `/target <yourname>`, inject that spell
3. `/rgcw opt` → Items or Misc: check an entry that ships **disabled** (e.g. a healing potion,
   Net-o-Matic)
4. Inject that entry
5. `/reload` and re-open both categories
6. Check the disabled spell again and inject once more

## Expected

- The unchecked spell is not tracked - injecting it produces no slot
- The explicitly checked `active = false` entry **is** tracked - it produces a slot (this is the
  regression guard: the enqueue path must not re-add a hard `active` gate)
- Both toggle states survive the reload and are reflected by the checkboxes
- Re-checking the disabled spell restores tracking immediately, without a reload
- No Lua errors
