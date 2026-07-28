# CooldownWatch

![](docs/cw_ragedunicorn_love_classic.png)

> CooldownWatch aims to track your enemies cooldowns and making them visible to the player

![](docs/wow_badge_classic.svg)
![](docs/license_mit.svg)
[![](docs/curseforge.svg)](https://curseforge.overwolf.com/?addonId=TODO&fileId=TODO)
![Lint](https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/lint.yaml/badge.svg?branch=master)
![Headless Tests](https://github.com/RagedUnicorn/wow-classic-cooldownwatch/actions/workflows/test.yaml/badge.svg?branch=master)

## Installation

WoW-Addons are installed directly in your WoW directory:

`[WoW-installation-directory]\Interface\AddOns`

Make sure to get the newest version of the Addon from the releases tab:

[CooldownWatch-Releases](https://github.com/RagedUnicorn/wow-classic-cooldownwatch/releases)


## What is CooldownWatch?

TODO

## Features of CooldownWatch

TODO

### Cooldowns vs Proximity Cooldowns
TODO
Proximity cooldowns are cooldowns that where detected within a certain proximity
but could not be matched to a caster. This means that we know that a certain spell
was casted but we don't know by what player. It can however still be very helpful
to see a notification about those spells. If the spell is specific to a class the
player can often guess himself who casted the spell. Only if there are multiple enemy
players with the same class it might get tricky to guess which one of them just used
his cooldown.

Proximity probably not needed there should always be a caster

## Profiles

CooldownWatch lets you save your configuration as named profiles, so you can switch between different setups or carry your settings to another character. Profiles are managed under the **Profiles** tab of the configuration interface (`/rgcw opt` or `/cooldownwatch opt`).

A profile captures all of your CooldownWatch settings – which cooldowns are tracked per category, the per-spell worst case and cooldown override values, the *Assume worst case for all cooldowns* default, the lock state of the Targetcooldownbar and its on-screen position.

- **Save current as...**: Snapshots your current settings into a new named profile (or overwrites an existing one of the same name).
- **Apply**: Loads the selected profile and applies its settings. This overwrites your current settings and reloads the UI.
- **Rename**: Renames the selected profile.
- **Delete**: Removes the selected profile.

### The Default Profile

Every character starts with a profile named **Default**. It holds CooldownWatch's shipped settings and is created automatically – you never have to save it yourself. It cannot be deleted, renamed or overwritten, so there is always a clean baseline to go back to: select **Default** and click **Apply** to reset CooldownWatch to its factory settings. The Rename and Delete buttons are greyed out while it is selected.

### Sharing Profiles (Export / Import)

Profiles can be shared as portable strings, making it easy to copy a setup between characters or hand it to another player.

- **Export**: Generates a copy-pasteable profile string for the selected profile in the *Profile String* field.
- **Import**: Paste a profile string into the field and import it as a new profile. Imported strings are validated, so an invalid, corrupted, or non-CooldownWatch string is rejected without changing any of your settings.

> Note: Profiles are stored per character. Use export/import to move a profile to another character.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — from reporting wrong cooldown data to contributing
SpellMap entries, including the lint and test gates every pull request must pass.

## Development

### Switching between Environments

Switching between development and release can be achieved with maven.

```
mvn generate-resources -D generate.sources.overwrite=true -P development
```

This generates and overwrites `CW_Environment.lua` and `CooldownWatch.toc`. You need to specifically specify that you want to overwrite to files to prevent data loss. It is also possible to omit the profile because development is the default profile that will be used.

Switching to release can be done as such:

```
mvn generate-resources -D generate.sources.overwrite=true -P release
```

In this case it is mandatory to add the release profile.

**Note:** Switching environments has the effect changing certain files to match an expected value depending on the environment. To be more specific this means that as an example test and debug files are not included when switching to release. It also means that variables such as loglevel change to match the environment.

As to not change those files all the time the repository should always stay in the development environment. Do not commit `CooldownWatch.toc` and `CW_Environment.lua` in their release state. Changes to those files should always be done inside `build-resources` and their respective template files marked with `.tpl`.

### Packaging the Addon

To package the addon use the `package` phase.

```
mvn package -D generate.sources.overwrite=true -P development
```

This generates an addon package for development. For generating a release package the release profile can be used.

```
mvn package -D generate.sources.overwrite=true -P release
```

**Note:** This packaging and switching resources can also be done one after another.

```
# switch environment to release
mvn generate-resources -D generate.sources.overwrite=true -P release
# package release
mvn package -P release
```

### Deploy GitHub Release

Before creating a new release update `addon.tag.version` in `pom.xml`. Afterwards to create a new release and deploy to GitHub the `deploy-github` profile has to be used.

```
# switch environment to release
mvn generate-resources -D generate.sources.overwrite=true -P release
# deploy release
mvn package -P deploy-github -D github.auth-token=[token]
```

**Note:** This is only intended for manual deployment to GitHub. With GitHub actions the token is supplied as a secret to the build process

### Deploy CurseForge Release

**Note:** It's best to create the release for GitHub first and only afterwards the CurseForge release. That way the tag was already created.

```
# switch environment to release
mvn generate-resources -D generate.sources.overwrite=true -P release
# deploy release
mvn package -P deploy-curseforge -D curseforge.auth-token=[token]
```

**Note:** This is only intended for manual deployment to CurseForge. With GitHub actions the token is supplied as a secret to the build process

### Deploy Wago.io Release

**Note:** It's best to create the release for GitHub first and only afterwards the Wago.io release. That way the tag was already created.

```
# switch environment to release
mvn generate-resources -D generate.sources.overwrite=true -P release
# deploy release
mvn package -P deploy-wago -D wago.auth-token=[token]
```

**Note:** This is only intended for manual deployment to Wago.io. With GitHub actions the token is supplied as a secret to the build process

### GitHub Action Profiles

This project has GitHub action profiles for different DevOps-related work such as linting and deployments to different providers. See `.github` folder for details.

## License

MIT License

Copyright (c) 2026 Michael Wiesendanger

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
