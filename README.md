# CooldownWatch

![](docs/cw_ragedunicorn_love_classic.png)

> CooldownWatch aims to track your enemies cooldowns and making them visible to the player

![](docs/wow_badge.svg)
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

### Deploy a Release

Before creating a new release update `addon.tag.version` in `pom.xml`. Afterwards to create a new release and deploy to GitHub the `deploy` profile has to be used.

```
# switch environment to release
mvn generate-resources -D generate.sources.overwrite=true -P release
# deploy release to GitHub
mvn package -P deploy
```

For this to work an oauth token for GitHub is required and has to be configured in your `.m2` settings file.

### GitHub Action Profiles

Both `deploy-github-action` and `deploy-curseforge-action` should not be deployed manually. They are solely intended for being used by GitHub actions

## License

MIT License

Copyright (c) 2023 Michael Wiesendanger

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
