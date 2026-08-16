# Release

> This document explains how a new release is created for CooldownWatch

## Pre-release testing

Complete the test procedure in [test/TESTING.md](test/TESTING.md) before creating any deployment:

* Automated gates - luacheck and busted must be green (locally and in CI)
* The in-game suite (`/rgcw test all`) green on the dev checkout
* Full manual test case catalog ([test/manual/](test/manual/)) on Classic Era
* Smoke checklist on TBC Anniversary
* `TC-BD-01` against the packaged release build
* `TC-VB-01` (version broadcast) if a second account/client is available
* `TC-SOD-01` if a Season of Discovery character is available or season-gating code was touched

## Deployment

* Push all commits before proceeding
* Make sure `build-resources/release-notes.md` are up-to-date
* Make sure Metadata https://github.com/RagedUnicorn/wow-cooldownwatch-meta is up-to-date
* Create a GitHub deployment
  * Invoke GitHub action
    * https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/release_github.yaml
* Create a CurseForge deployment
  * Invoke CurseForge action
    * https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/release_curseforge.yaml
* Create a Wago.io deployment
  * Invoke GitHub action
    * https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/release_wago.yaml

> Note: When updating the addon for a new WoW release the following properties have to be updated in `pom.xml`
> * addon.curseforge.gameVersionClassic / addon.curseforge.gameVersionTbcc
> * addon.interface.classic / addon.interface.tbcc
> * addon.supported.patch.classic / addon.supported.patch.tbcc
>
> `addon.interface` is derived from the variant interface properties and must not be edited directly. These properties are normally bumped automatically by Renovate ("WoW Updates" group).
>
> TBC Anniversary ships with the Classic spell catalog as its baseline: `code/spellmap/overlay/Tbc.lua` is still data-empty, so cooldowns reworked in TBC and TBC-only ranks are not tracked until the overlay gains data.
