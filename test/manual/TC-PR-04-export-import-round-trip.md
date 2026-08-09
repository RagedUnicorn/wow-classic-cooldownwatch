# TC-PR-04 — Export / import round-trip

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A saved profile with recognizable settings (disabled spells, a manual override, a moved bar)
- Ideally a second character to import into (the store is per character)

## Steps

1. `/rgcw opt` → Profiles, select the profile and click "Export"
2. Copy the string out of the string box (Ctrl+A / Ctrl+C)
3. Delete the profile, paste the string back into the box and click "Import"; enter a name in the
   prompt
4. Apply the imported profile and verify every setting
5. Log in on a second character, paste the same string and import it there
6. Import the same string again under a name that already exists
7. Paste a string with leading/trailing whitespace and newlines and import it

## Expected

- The export box holds a single copy-pasteable string starting with `CooldownWatch1:`
- The import prompt pre-fills the name carried in the envelope; the entered name is what gets saved
- The imported profile applies to exactly the same configuration as the original - round-trip is
  lossless
- The import works on a different character
- Importing under an existing name is refused with the "already exists" error
- Whitespace and newlines around/inside the pasted string are tolerated
- No Lua errors
