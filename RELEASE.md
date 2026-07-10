# Release

> This document explains how a new release is created for CooldownWatch

* Push all commits before proceeding
* Make sure `build-resources/release-notes.md` are up-to-date
* Create a GitHub deployment
  * Invoke GitHub action
    * https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/release_github.yaml
* Create a CurseForge deployment
  * Invoke CurseForge action
    * https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/release_curseforge.yaml
  * **Currently blocked:** `addon.curseforge.projectId` in `pom.xml` is still `TODO` — the CurseForge project has to be registered and its id filled in first

> Note: When updating the addon for a new WoW release the following properties have to be updated in `pom.xml`
> * addon.curseforge.gameVersionClassic / addon.curseforge.gameVersionTbcc
> * addon.interface.classic / addon.interface.tbcc
> * addon.supported.patch.classic / addon.supported.patch.tbcc
>
> `addon.interface` is derived from the variant interface properties and must not be edited directly. These properties are normally bumped automatically by Renovate ("WoW Updates" group).
>
> TBC is not released yet: the spell catalog is Classic-only, so the TBC properties are maintained but excluded from the `addon.interface` aggregate, the CurseForge game versions and the Wago supported patches until TBC support ships (flip points are marked in `pom.xml`).
