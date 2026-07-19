# Testing

CooldownWatch ships two test layers:

- An **in-game test framework** that runs against the addon's real modules under WoW (loaded in development builds
  only — the release TOC excludes the entire `test/` tree).
- A **headless busted harness** that runs pure-Lua specs (SpellMap data integrity, cooldown queue, event bus, command
  dispatch, localization parity) outside WoW, used by CI on every push and pull request.

## Running the in-game tests

Reload your UI and run the full suite:

```
/reload
/run rgcw.testRunner.RunAllTests()
```

Results are written to chat and persisted to the `CooldownWatchTestLog` SavedVariable, which you can inspect from
`WTF/Account/<account>/<realm>/<character>/SavedVariables/CooldownWatch.lua` after `/reload` or logout.

A floating test log window is also available, but it does not open automatically. Toggle it manually:

```
/rgcw test log
```

The full set of slash commands (registered in development builds only):

| Command                               | Effect                                                                                                                                                                                                              |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/rgcw test`                          | Print the help text, including one line per registered suite slug.                                                                                                                                                  |
| `/rgcw test all`                      | Run every suite via the test runner.                                                                                                                                                                                |
| `/rgcw test <suite>`                  | Run a single suite by its registry slug (e.g. `spellmap`, `cooldownqueue`, `priestspells`, `targetcooldownbar`). The slug list comes from the testRunner registry — `/rgcw test` shows what's currently registered. |
| `/rgcw test cooldownqueue <TestName>` | Run a single cooldown queue test (e.g. `AddCooldown`).                                                                                                                                                              |
| `/rgcw test inject`                   | Toggle the debug spell injector window.                                                                                                                                                                             |
| `/rgcw test log`                      | Toggle the test log window.                                                                                                                                                                                         |
| `/rgcw test clear-logs`               | Clear the persisted SavedVariable log.                                                                                                                                                                              |
| `/rgcw debug`                         | Toggle debug log level.                                                                                                                                                                                             |

Or invoke a single suite directly from chat:

```
/run rgcw.testCooldownQueue.RunAllTests()
/run rgcw.testSpellMap.RunAllTests()
/run rgcw.testPriestSpells.RunAllTests()
```

For tests that exercise the cooldown bar UI (currently the `TestCooldownQueue` suite), target yourself first so the bar
has somewhere to render:

```
/target <yourname>
```

## Running the headless tests

The pure-Lua specs (including the SpellMap data-integrity validators) run
under [busted](https://lunarmodules.github.io/busted/) — no WoW client required. The busted image is defined as a
service in `docker-compose.yml`; configuration lives in `.busted`.

```
docker compose run --rm busted
```

This loads `test/headless/Bootstrap.lua`, which stubs the WoW globals the production files reach for at load time, then
`dofile`s `code/Constants.lua`, `code/Event.lua`, `code/Common.lua`, `code/Categories.lua`, the SpellMap modules
(`code/SpellMap/Base.lua`, the `code/SpellMap/Overlay/` files, `code/SpellMap/Assemble.lua`, `code/SpellMap.lua`),
`code/SpellMapHelper.lua`, `code/CooldownQueue.lua`, and `test/SpellMapValidation.lua`. Specs in `test/headless/spec/`
are then discovered by busted's `Spec` pattern.

CI runs the same specs on every push and pull request via `.github/workflows/test.yaml`, using [
`RagedUnicorn/action-busted`](https://github.com/RagedUnicorn/action-busted) — the GitHub Action equivalent of the local
`docker compose run --rm busted` command. A matching IntelliJ run configuration lives in `.run/busted[run].run.xml`.

## Suite layout

| File                                  | What it covers                                                                                                                                                                                                                                                                      |
|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `test/SpellMapValidation.lua`         | Pure-data validators for the assembled spellMap (`code/SpellMap/` + orchestrator; no WoW APIs, no logging). Source of truth for both the in-game `TestSpellMap` suite and the busted spec.                                                                                                                              |
| `test/TestSpellMap.lua`               | In-game wrapper — runs the validators and reports through `testLogger`. No targeting required.                                                                                                                                                                                      |
| `test/headless/spec/`                 | Busted specs (`*Spec.lua`) — SpellMap validators, cooldown queue, event bus, command dispatch, common helpers, localization parity. Run headlessly under busted (locally and in CI).                                                                                                |
| `test/TestCooldownQueue.lua`          | Queue mechanics — add, multiple, duplicate-prevention, remove. In-game only.                                                                                                                                                                                                        |
| `test/TestTargetCooldownBar.lua`      | Target cooldown bar preview suite. In-game only.                                                                                                                                                                                                                                    |
| `test/category/Test<Class>Spells.lua` | End-to-end per-spell tracking, one file per SpellMap category (all eleven exist): drives `SearchBySpellId` → `AddCooldown` → `GetCooldownsByTarget` for every spell the category declares and asserts a non-primary rank resolves to its primary via the refId chain. In-game only. |
| `test/framework/`                     | Shared helpers (`testLogger`, `testHelper`, log window, `/rgcw test ...` slash commands).                                                                                                                                                                                           |
| `test/debug/DebugInjectorWindow.lua`  | Debug spell injector window, toggled with `/rgcw test inject`.                                                                                                                                                                                                                      |

## Adding a test suite for a new category

Every category currently in `code/Categories.lua` already has a suite under `test/category/`. These steps apply when a *
*new** category is added to the SpellMap (see the "Adding new spells or a new category" checklist in `CLAUDE.md`):

1. **Create `test/category/Test<Category>Spells.lua`.** Copy an existing suite — `TestRacialsSpells.lua` for single-rank
   categories, `TestPriestSpells.lua` for multi-rank ones — and change `CATEGORY`. There is no hand-written spell list
   to maintain: `RunAllTests` iterates `mod.testHelper.GetSpellsForCategory(CATEGORY)`, so new SpellMap entries are
   picked up automatically. For multi-rank categories, point the rank-resolution test at a real non-primary rank with
   the longest refId chain.
2. **Self-register the suite.** At the bottom of the new file (after `function me.RunAllTests`), append:

   ```lua
   mod.testRunner.Register("<category>spells", "<category> spell tracking suite", me.RunAllTests)
   ```

   The runner, the `/rgcw test ...` dispatcher, and the help output all iterate this registry — no edits to
   `test/RunTests.lua` or `test/framework/TestCmd.lua` are required.
3. **Add the file to the TOC.** Append `test/category/Test<Category>Spells.lua` to
   `build-resources/cooldownwatch-development.toc.tpl` and to the live `CooldownWatch.toc`. The release template stays
   empty of tests.

The data-integrity suite (`TestSpellMap`) automatically picks up new classes — no changes needed there.

Tests get cooldown-queue isolation for free: `mod.testLogger.StartTest` fires a setUp hook (registered in
`test/RunTests.lua`) that calls `mod.cooldownQueue.ClearCooldownQueue()` before every test. Don't re-add manual clears
at the top of test bodies — they'd be redundant and reintroduce the "negotiated" pattern the framework was built to
replace.

## Adding a new SpellMap validator

All SpellMap data-integrity checks live in `test/SpellMapValidation.lua` so they run identically in-game and headless.

1. Add a `Validate*` function to `test/SpellMapValidation.lua` that takes the spellMap (and any extra accessors it
   needs) and returns a list of failure description strings. An empty list means the check passed. Do **not** call
   `mod.testLogger`, `mod.logger`, or any WoW API — these run under busted too.
2. Add a wrapper in `test/TestSpellMap.lua` using the existing
   `RunValidator(testName, getFailures, successMsg, failurePrefix)` helper, and call it from `RunAllTests`.
3. Add an `it("...", function() assert.same({}, ...) end)` block to `test/headless/spec/SpellMapSpec.lua`.

## Linting

The project lints with [`ragedunicorn/luacheck`](https://github.com/RagedUnicorn/docker-luacheck), wired up as a service
in `docker-compose.yml`:

```
docker compose run --rm luacheck
```

A JUnit report variant is also available:

```
docker compose run --rm luacheck-report
```

This writes `target/luacheck-junit.xml`. Linting must be clean before opening a PR.

## Test environment flag

`RGCW_ENVIRONMENT.TEST` is `true` in development builds and `false` in release builds. When `TEST` is true, the season
filter in `code/SpellMapHelper.lua` allows SOD spells through even when the client isn't on Season of Discovery, so the
test suite can exercise every spell regardless of server state.
