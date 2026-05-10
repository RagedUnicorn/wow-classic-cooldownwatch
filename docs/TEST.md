# Testing

CooldownWatch ships two test layers:

- An **in-game test framework** that runs against the addon's real modules under WoW (loaded in development builds only — the release TOC excludes the entire `test/` tree).
- A **headless busted harness** that runs the SpellMap data-integrity validators outside WoW, used by CI on every push and pull request.

## Running the in-game tests

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

## Running the headless data-integrity tests

The pure-data SpellMap validators run under [busted](https://lunarmodules.github.io/busted/) — no WoW client required. The busted image is defined as a service in `docker-compose.yml`; configuration lives in `.busted`.

```
docker compose run --rm busted
```

This loads `test/headless/Bootstrap.lua`, which stubs the WoW globals the production files reach for at load time, then `dofile`s `code/Constants.lua`, `code/Common.lua`, `code/SpellMap.lua`, `code/SpellMapHelper.lua`, and `test/SpellMapValidation.lua`. Specs in `test/headless/spec/` are then discovered by busted's `Spec` pattern.

CI runs the same command on every push and pull request via `.github/workflows/test.yaml`. A matching IntelliJ run configuration lives in `.run/busted[run].run.xml`.

## Suite layout

| File | What it covers |
| --- | --- |
| `test/SpellMapValidation.lua` | Pure-data validators for `code/SpellMap.lua` (no WoW APIs, no logging). Source of truth for both the in-game `TestSpellMap` suite and the busted spec. |
| `test/TestSpellMap.lua` | In-game wrapper — runs the validators and reports through `testLogger`. No targeting required. |
| `test/headless/spec/SpellMapSpec.lua` | Busted spec — one `it` block per validator. Runs headlessly under busted (locally and in CI). |
| `test/TestCooldownQueue.lua` | Queue mechanics — add, multiple, duplicate-prevention, remove. In-game only. |
| `test/category/TestPriestSpells.lua` | End-to-end per-spell tracking: drives `SearchBySpellId` → `AddCooldown` → `GetCooldownsByTarget` for every priest spell and asserts a non-primary rank resolves to its primary via the refId chain. In-game only. |
| `test/framework/` | Shared helpers (`testLogger`, `testHelper`, log window, `/rgcw test ...` slash commands). |

## Adding a test for another class

Each per-class suite lives under `test/category/` and follows the priest pattern verbatim. To add Mage tests:

1. **Create `test/category/TestMageSpells.lua`.** Copy `TestPriestSpells.lua`, change `CATEGORY = "mage"`, and replace `PRIEST_BASE_SPELLS` with the mage spell list `{ spellId, name }` pairs. Update the rank-resolution test to reference a real mage non-primary rank.
2. **Self-register the suite.** At the bottom of the new file (after `function me.RunAllTests`), append:

   ```lua
   mod.testRunner.Register("magespells", "mage spell tracking suite", me.RunAllTests)
   ```

   The runner, the `/rgcw test ...` dispatcher, and the help output all iterate this registry — no edits to `test/RunTests.lua` or `test/framework/TestCmd.lua` are required.
3. **Add the file to the TOC.** Append `test/category/TestMageSpells.lua` to `build-resources/cooldownwatch-development.toc.tpl` and to the live `CooldownWatch.toc`. The release template stays empty of tests.

The data-integrity suite (`TestSpellMap`) automatically picks up new classes — no changes needed there.

## Adding a new SpellMap validator

All SpellMap data-integrity checks live in `test/SpellMapValidation.lua` so they run identically in-game and headless.

1. Add a `Validate*` function to `test/SpellMapValidation.lua` that takes the spellMap (and any extra accessors it needs) and returns a list of failure description strings. An empty list means the check passed. Do **not** call `mod.testLogger`, `mod.logger`, or any WoW API — these run under busted too.
2. Add a wrapper in `test/TestSpellMap.lua` using the existing `RunValidator(testName, getFailures, successMsg, failurePrefix)` helper, and call it from `RunAllTests`.
3. Add an `it("...", function() assert.same({}, ...) end)` block to `test/headless/spec/SpellMapSpec.lua`.

## Linting

The project lints with [`ragedunicorn/luacheck`](https://github.com/RagedUnicorn/docker-luacheck), wired up as a service in `docker-compose.yml`:

```
docker compose run --rm luacheck
```

A JUnit report variant is also available:

```
docker compose run --rm luacheck-report
```

This writes `target/luacheck-junit.xml`. Linting must be clean before opening a PR.

## Test environment flag

`RGCW_ENVIRONMENT.TEST` is `true` in development builds and `false` in release builds. When `TEST` is true, the season filter in `code/SpellMapHelper.lua` allows SOD spells through even when the client isn't on Season of Discovery, so the test suite can exercise every spell regardless of server state.