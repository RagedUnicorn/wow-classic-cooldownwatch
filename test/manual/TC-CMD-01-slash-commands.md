# TC-CMD-01 — /rgcw command surface

**Area:** Slash commands | **Client:** Era | **Mandatory:** yes

## Preconditions

- Development checkout for the `test` subcommand; a release build has no `test` line
  ([TC-BD-01](TC-BD-01-release-build-loads.md))

## Steps

1. `/rgcw` with no arguments
2. `/rgcw help`
3. `/cooldownwatch` (the long alias) with no arguments
4. `/rgcw opt`
5. `/rgcw conf enable`, then `/rgcw conf disable`
6. `/rgcw conf`, `/rgcw conf bogus`, `/rgcw bogus`
7. `/rgcw test` (dev build only), then `/rgcw test log`, `/rgcw test inject`,
   `/rgcw test clear-logs`
8. `/rgcw debug` twice
9. `/rgcw rl` / `/rgcw reload` (last - it reloads the UI)

## Expected

- The bare command and `help` print the info block: title, `reload`, `opt`, `conf` - plus `test`
  in a development build only
- Both slash aliases behave identically
- `opt` opens the addon options panel (main category)
- `conf enable` / `conf disable` show and hide the example bar
- `conf` without an argument, `conf bogus` and an unknown top-level argument each print the
  invalid-argument error and do nothing else
- `test` prints the test menu with one line per registered suite; `test log` toggles the log window,
  `test inject` toggles the injector, `test clear-logs` empties the persisted log
- `debug` toggles the debug log level and confirms the new state in chat
- `rl` / `reload` reload the UI
- No Lua errors for any input, including the invalid ones
