# Testing

CooldownWatch ships a small in-game test framework that runs against the addon's real modules under WoW. Tests are only loaded in development builds (the release TOC excludes the entire `test/` tree).

## Running the tests

Reload your UI and run the full suite:

```
/reload
/run rgcw.testRunner.RunAllTests()
```

Results are written to chat and persisted to the `CooldownWatchTestLog` SavedVariable, which you can inspect from `WTF/Account/<account>/SavedVariables/CooldownWatch.lua` after `/reload` or logout.

A floating test log window is also available, but it does not open automatically. Toggle it manually:

```
/rgcw test log
```

The full set of slash commands (registered in development builds only):

| Command | Effect |
| --- | --- |
| `/rgcw test all` | Run every suite via the test runner. |
| `/rgcw test cooldownqueue` | Run the cooldown queue suite. |
| `/rgcw test cooldownqueue <TestName>` | Run a single cooldown queue test (e.g. `AddCooldown`). |
| `/rgcw test log` | Toggle the test log window. |
| `/rgcw test clear-logs` | Clear the persisted SavedVariable log. |
| `/rgcw debug` | Toggle debug log level. |

Or invoke a single suite directly from chat:

```
/run rgcw.testCooldownQueue.RunAllTests()
/run rgcw.testSpellMap.RunAllTests()
/run rgcw.testPriestSpells.RunAllTests()
```

For tests that exercise the cooldown bar UI (currently the `TestCooldownQueue` suite), target yourself first so the bar has somewhere to render:

```
/target <yourname>
```

## Suite layout

| File | What it covers |
| --- | --- |
| `test/TestCooldownQueue.lua` | Queue mechanics — add, multiple, duplicate-prevention, remove. |
| `test/TestSpellMap.lua` | Data integrity of `code/SpellMap.lua` — refIds resolve, `allRanks` lists are consistent, no spellId is a primary in two categories, shared-cooldown groups are coherent. No targeting required. |
| `test/category/TestPriestSpells.lua` | End-to-end per-spell tracking: drives `SearchBySpellId` → `AddCooldown` → `GetCooldownsByTarget` for every priest spell and asserts a non-primary rank resolves to its primary via the refId chain. |
| `test/framework/` | Shared helpers (`testLogger`, `testHelper`, log window, `/rgcw test ...` slash commands). |

## Adding a test for another class

Each per-class suite lives under `test/category/` and follows the priest pattern verbatim. To add Mage tests:

1. **Create `test/category/TestMageSpells.lua`.** Copy `TestPriestSpells.lua`, change `CATEGORY = "mage"`, and replace `PRIEST_BASE_SPELLS` with the mage spell list `{ spellId, name }` pairs. Update the rank-resolution test to reference a real mage non-primary rank.
2. **Register it in the test runner.** In `test/RunTests.lua`, add a wrapper after `me.TestPriestSpells`:

   ```lua
   function me.TestMageSpells()
     if mod.testMageSpells then
       mod.testMageSpells.RunAllTests()
     else
       mod.testLogger.LogError("TestRunner", "TestMageSpells module not loaded")
     end
   end
   ```

   Then call `me.TestMageSpells()` from `RunAllTests`.
3. **Add the file to the TOC.** Append `test/category/TestMageSpells.lua` to `build-resources/cooldownwatch-development.toc.tpl` and to the live `CooldownWatch.toc`. The release template stays empty of tests.

The data-integrity suite (`TestSpellMap`) automatically picks up new classes — no changes needed there.

## Linting

The project lints with [`ragedunicorn/luacheck`](https://github.com/RagedUnicorn/docker-luacheck):

```
docker run --rm -v "${PWD}:/workspace" ragedunicorn/luacheck:latest .
```

Linting is required before opening a PR.

## Test environment flag

`RGCW_ENVIRONMENT.TEST` is `true` in development builds and `false` in release builds. When `TEST` is true, the season filter in `code/SpellMapHelper.lua` allows SOD spells through even when the client isn't on Season of Discovery, so the test suite can exercise every spell regardless of server state.