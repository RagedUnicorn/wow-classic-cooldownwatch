# TC-PR-05 — Corrupted import string rejected

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A valid export string from [TC-PR-04](TC-PR-04-export-import-round-trip.md) to mangle

## Steps

1. `/rgcw opt` → Profiles. Click "Import" with an empty string box
2. Import plain garbage (`hello world`)
3. Import the valid string with its `CooldownWatch1:` prefix removed
4. Import the valid string with a few characters in the middle changed (breaks the checksum)
5. Import a string whose prefix is intact but whose envelope claims another addon - e.g. an export
   string from a sibling addon (GearMenu, Pulse) if one is at hand
6. After each rejection, check the profile list and the live configuration

## Expected

- Empty box: "there is no profile string to import"
- Garbage and a stripped prefix: "the profile string is invalid or could not be read"
- Mangled body: "the profile string is corrupt (checksum mismatch)"
- Foreign addon envelope: "this profile string was not created by CooldownWatch"
- A string carrying a newer schema version: "created by a newer version of CooldownWatch"
- Every rejection leaves the profile list **and** the live configuration untouched, and prints a
  user-visible error rather than throwing
- No Lua errors
