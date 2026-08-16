# Release Testing

> This document describes the test procedure that must pass before a new CooldownWatch release is created.
> Deployment steps live in [RELEASE.md](../RELEASE.md); this document is the testing gate referenced there.
> The testing *surface* (how to run the harnesses, how to add suites) is [docs/TEST.md](../docs/TEST.md) -
> this document only says what has to be exercised before shipping.

A release passes when:

* All automated gates are green
* All mandatory manual test cases in [test/manual/](manual/) pass on Classic Era
* The packaged release build loads clean ([TC-BD-01](manual/TC-BD-01-release-build-loads.md))
* Zero Lua errors occurred during the whole run

Before starting the in-game runs, enable script errors so nothing is swallowed:

```
/console scriptErrors 1
```

## 1. Automated gates

Run locally (Docker required):

```bash
# lua linting
docker compose run --rm luacheck

# busted unit tests (test/headless/spec/)
docker compose run --rm busted
```

Additionally verify that CI is green on `master` for the latest commit:

* `lint.yaml` - luacheck
* `test.yaml` - busted

Both must pass with zero failures before any in-game testing starts.

Then run the in-game suite once on the dev checkout - it covers the data-integrity validators, the queue mechanics and
per-spell tracking for all eleven categories:

```
/reload
/target <yourname>
/rgcw test all
```

Every suite must report success. `/rgcw test log` opens the log window if the chat output scrolled away; the same
results persist in the `CooldownWatchTestLog` SavedVariable.

## 2. In-game test matrix

The dev checkout in `Interface/AddOns/CooldownWatch` is what gets tested for the manual catalog - it carries
`RGCW_ENVIRONMENT.DEBUG = true`, which is what makes the debug injector and the friendly-target fallback
available. [TC-BD-01](manual/TC-BD-01-release-build-loads.md) is the one case that must run against the packaged build
instead.

| Client                    | Interface | Coverage                                      |
|---------------------------|-----------|-----------------------------------------------|
| Classic Era               | 11509     | Full manual catalog ([test/manual/](manual/)) |
| Season of Discovery (Era) | 11509     | `TC-SOD-01` - conditional, see note below     |
| TBC Anniversary           | 20506     | Smoke checklist (below) - every release       |

`TC-SOD-01` is **conditional**: run it only if a Season of Discovery character is available or if season-gating code
(`code/Season.lua`, `code/SpellMapHelper.lua`, `code/spellmap/overlay/Sod.lua`)
was touched since the last release.

TBC Anniversary is a **published target** with the Classic spell catalog as its baseline: the tbcc properties in
`pom.xml` feed the shipped interface line and store versions, but `code/spellmap/overlay/Tbc.lua` is still data-empty -
cooldowns reworked in TBC and TBC-only ranks are not tracked yet. Run the smoke checklist below before every release,
and additionally whenever the tbcc properties or anything branch-aware (`SpellMap.DetermineActiveBranch`,
`code/spellmap/overlay/Tbc.lua`) changed.

## 3. Smoke checklist (TBC Anniversary)

- [ ] Addon loads without errors on login; the welcome message prints
- [ ] `/rgcw opt` opens the options panel; every category subpanel opens without errors
- [ ] `/rgcw conf enable` shows the example bar, `/rgcw conf disable` hides it
- [ ] An enemy player cast puts an icon with a running timer on the bar
- [ ] `/reload` produces no Lua errors

## 4. Manual test case catalog (Classic Era)

One file per test case under [test/manual/](manual/). Case IDs follow `TC-<AREA>-<NN>`.

Most bar and tracking cases can be driven solo with the debug injector (`/rgcw test inject`, which queues the selected
spell with **you** as the caster - target yourself to see it render). Cases that must prove real combat-log attribution
say so explicitly and need a duel partner or a battleground.

### SavedVariables lifecycle (mandatory every release)

| ID                                                           | Case                                     |
|--------------------------------------------------------------|------------------------------------------|
| [TC-SV-01](manual/TC-SV-01-fresh-install.md)                 | Fresh install seeds defaults             |
| [TC-SV-02](manual/TC-SV-02-upgrade-from-previous-release.md) | Upgrade from previous release reconciles |
| [TC-SV-03](manual/TC-SV-03-partial-saved-table.md)           | Hand-edited / partial saved table heals  |

### TargetCooldownBar

| ID                                                              | Case                                        |
|-----------------------------------------------------------------|---------------------------------------------|
| [TC-CB-01](manual/TC-CB-01-cooldown-appears-and-counts-down.md) | Cooldown appears and counts down            |
| [TC-CB-02](manual/TC-CB-02-warn-and-alert-thresholds.md)        | Warn and alert thresholds                   |
| [TC-CB-03](manual/TC-CB-03-expiry-fade-and-recast.md)           | Expiry fade and mid-fade recast             |
| [TC-CB-04](manual/TC-CB-04-slot-order-and-overflow.md)          | Slot order and overflow truncation          |
| [TC-CB-05](manual/TC-CB-05-target-switching.md)                 | Target switching and losing the target      |
| [TC-CB-06](manual/TC-CB-06-drag-lock-and-position.md)           | Drag, lock and position persistence         |
| [TC-CB-07](manual/TC-CB-07-preview-mode.md)                     | Preview mode via `/rgcw conf`               |
| [TC-CB-08](manual/TC-CB-08-render-ticker-lifecycle.md)          | Render ticker runs only while there is work |

### Cooldown tracking

| ID                                                     | Case                                      |
|--------------------------------------------------------|-------------------------------------------|
| [TC-CT-01](manual/TC-CT-01-rank-resolution.md)         | Lower rank cast tracks as its primary     |
| [TC-CT-02](manual/TC-CT-02-shared-cooldown-group.md)   | Shared cooldown group fan-out             |
| [TC-CT-03](manual/TC-CT-03-cooldown-reset.md)          | Cooldown reset (Preparation / Cold Snap)  |
| [TC-CT-04](manual/TC-CT-04-buff-then-consume.md)       | Buff-then-consume tracks the aura removal |
| [TC-CT-05](manual/TC-CT-05-item-triggered-cooldown.md) | Item-triggered cooldown shows item icon   |
| [TC-CT-06](manual/TC-CT-06-recently-bandaged.md)       | Recently Bandaged lockout                 |
| [TC-CT-07](manual/TC-CT-07-hostile-players-only.md)    | Only hostile player casts are tracked     |

### Pet-cast attribution

| ID                                                  | Case                                          |
|-----------------------------------------------------|-----------------------------------------------|
| [TC-PT-01](manual/TC-PT-01-pet-cast-attribution.md) | Pet cast queues under the owning player       |
| [TC-PT-02](manual/TC-PT-02-targeting-the-pet.md)    | Targeting the pet renders the owner cooldowns |
| [TC-PT-03](manual/TC-PT-03-parked-cast-flush.md)    | Cast parked while the owner is unknown        |

### Cooldown value resolution

| ID                                                       | Case                                  |
|----------------------------------------------------------|---------------------------------------|
| [TC-CV-01](manual/TC-CV-01-global-worst-case.md)         | Global worst case default             |
| [TC-CV-02](manual/TC-CV-02-per-spell-worst-case.md)      | Per-spell worst case beats the global |
| [TC-CV-03](manual/TC-CV-03-manual-cooldown-override.md)  | Manual cooldown override              |
| [TC-CV-04](manual/TC-CV-04-change-applies-next-cast.md)  | Change applies from the next cast     |
| [TC-CV-05](manual/TC-CV-05-worst-case-value-override.md) | Per-spell worst case value override   |

### Options and spell list

| ID                                                     | Case                                   |
|--------------------------------------------------------|----------------------------------------|
| [TC-OP-01](manual/TC-OP-01-category-panels.md)         | Every category panel opens and renders |
| [TC-OP-02](manual/TC-OP-02-enable-disable-spell.md)    | Enabling and disabling a spell         |
| [TC-OP-03](manual/TC-OP-03-accordion-and-scrolling.md) | Accordion, scrollbar and canvas resize |
| [TC-OP-04](manual/TC-OP-04-disabled-row-controls.md)   | Disabled row greys out its controls    |

### Profiles

| ID                                                       | Case                                  |
|----------------------------------------------------------|---------------------------------------|
| [TC-PR-01](manual/TC-PR-01-save-profile.md)              | Save current configuration as profile |
| [TC-PR-02](manual/TC-PR-02-apply-profile.md)             | Apply profile restores configuration  |
| [TC-PR-03](manual/TC-PR-03-rename-and-delete-profile.md) | Rename and delete a profile           |
| [TC-PR-04](manual/TC-PR-04-export-import-round-trip.md)  | Export / import round-trip            |
| [TC-PR-05](manual/TC-PR-05-corrupted-import-rejected.md) | Corrupted import string rejected      |
| [TC-PR-06](manual/TC-PR-06-default-profile.md)           | Default profile seeded and immutable  |
| [TC-PR-07](manual/TC-PR-07-profile-name-length.md)       | Profile name length limit             |

### Slash commands

| ID                                              | Case                  |
|-------------------------------------------------|-----------------------|
| [TC-CMD-01](manual/TC-CMD-01-slash-commands.md) | /rgcw command surface |

### Release build

| ID                                                 | Case                               |
|----------------------------------------------------|------------------------------------|
| [TC-BD-01](manual/TC-BD-01-release-build-loads.md) | Packaged release build loads clean |

### Version broadcast (conditional)

| ID                                               | Case                                      |
|--------------------------------------------------|-------------------------------------------|
| [TC-VB-01](manual/TC-VB-01-version-broadcast.md) | Version broadcast and update notification |

### Season of Discovery (conditional)

| ID                                             | Case                         |
|------------------------------------------------|------------------------------|
| [TC-SOD-01](manual/TC-SOD-01-season-gating.md) | Loads on Season of Discovery |

## 5. Notes

* Localization is covered by the busted spec `LocalizationParitySpec` (key parity and
  `string.format` placeholder parity of `deDE` against `enUS`) - no manual locale pass is required.
* Spell **data** correctness (ids, ranks, tracked events, shared groups, reset targets) is covered by
  `test/SpellMapValidation.lua` through both busted and `/rgcw test spellmap`. The manual cases below verify behavior,
  not catalog contents - do not re-check spellIds by hand here.
* The dev checkout differs from a release build in two ways that matter for testing:
  `RGCW_ENVIRONMENT.DEBUG = true` loads the test/debug files and lets `Target.UpdateCurrentTarget`
  accept **friendly** targets (so the injector can render against yourself), and `TEST = true`
  lets season-gated spells through. Both are false in a release build - that is what
  [TC-BD-01](manual/TC-BD-01-release-build-loads.md) exists for.
* Keep a copy of the previous release's `CooldownWatch.lua` SavedVariables file around - it is the input
  for [TC-SV-02](manual/TC-SV-02-upgrade-from-previous-release.md). Fixtures live in
  [manual/fixtures/](manual/fixtures/).
* SavedVariables live at
  `WTF/Account/<ACCOUNT>/<Server>/<Character>/SavedVariables/CooldownWatch.lua`. Only touch this file while the client
  is fully logged out.
