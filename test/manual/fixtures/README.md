# Manual test fixtures

Input files for the manual test cases in [../](..). They are test inputs only - nothing here ships
(the release assembly includes an explicit file list and never picks up `test/`).

## SavedVariables fixtures

[TC-SV-02](../TC-SV-02-upgrade-from-previous-release.md) needs the **previous release's**
SavedVariables file to prove that an upgrade reconciles cleanly. Naming:

```
TC-SV-02-cooldownwatch-v<previous-version>.lua
```

Produce it by playing on the previous release long enough to have a representative configuration -
a few spells toggled in both directions, a per-spell worst-case toggle, a manual cooldown override,
a moved and locked bar, and at least one saved profile - then copy
`WTF/Account/<ACCOUNT>/<Server>/<Character>/SavedVariables/CooldownWatch.lua` here while the client
is logged out.

Keep the fixture for the version that is currently published; drop older ones once a newer fixture
exists. There is no fixture for the initial release - it has no predecessor, which is why TC-SV-02
is skipped for it.
