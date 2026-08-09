# TC-PR-07 — Profile name length limit

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

> The limit is 30 **characters, not bytes** - the guard counts utf-8 lead bytes so a localized name
> is not cut short. The popups cap typing; the explicit guard is defense in depth for names that did
> not come from typing (e.g. an imported envelope from an older, laxer version).

## Preconditions

- Any character
- Optionally a hand-built export string carrying an over-long profile name

## Steps

1. `/rgcw opt` → Profiles → "Save current as...", try to type a 40-character name
2. Save a name of exactly 30 characters
3. Repeat both in the "Rename" popup and in the import-name popup
4. Type a 30-character name using multi-byte characters (e.g. German umlauts, Cyrillic)
5. If available: import a string whose envelope name exceeds 30 characters

## Expected

- The popups stop accepting input at 30 characters - the typed name cannot exceed the limit
- A 30-character name saves normally
- A 30-character multi-byte name is accepted in full (it is not cut off at ~15 characters, which
  would be the byte-counting bug)
- An over-long name arriving through import is refused with the "cannot be longer than 30
  characters" error instead of being stored
- Existing longer profiles (if any) are untouched by the limit
- No Lua errors
