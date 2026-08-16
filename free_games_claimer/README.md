# Home Assistant add-on: Free Games Claimer

I maintain this and other Home Assistant add-ons in my free time. Keeping up
with upstream changes, Home Assistant changes, and testing on real hardware
takes a significant amount of time.

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Add-on information

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffree_games_claimer%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffree_games_claimer%2Fconfig.yaml)

[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

## About

This add-on is based on
[Free Games Claimer Remaster](https://github.com/P-Adamiec/Free-Games-Claimer-Remaster).

The add-on uses the official upstream multi-architecture container image and
adds only the Home Assistant integration layer. Free Games Claimer Remaster
supports:

- Epic Games Store, including Epic mobile giveaways
- Amazon Prime Gaming
- GOG
- Steam
- AliExpress daily check-in
- GamerPower-supported stores, when explicitly enabled

The default configuration keeps the previous add-on selection of Epic Games,
Prime Gaming, and GOG. Store selection itself is handled directly by Remaster's
native `STORES` setting in `config.env`.

## Web interface

The add-on uses Remaster's upstream noVNC port `7080` both inside the container
and on Home Assistant.

```text
http://homeassistant:7080
```

The interface can be used for initial sign-in, CAPTCHA handling, or other
manual browser interaction. Set `VNC_PASSWORD` in `config.env` to protect the
VNC session.

## Add-on options

| Option | Default | Description |
|--------|---------|-------------|
| `CONFIG_LOCATION` | `/config/config.env` | Persistent Remaster environment configuration file |
| `RUN_ONCE` | `true` | Run all selected claimers once, then stop the add-on |
| `env_vars` | `[]` | Additional environment variables exported through the standard AlexBelgium environment module |

### Run modes

With `RUN_ONCE: true`, the add-on performs one claiming pass and stops.

With `RUN_ONCE: false`, Remaster remains running and uses its internal
scheduler. `SCHEDULER_HOURS`, `SCHEDULER_FIXED_TIMES`,
`SCHEDULER_TIMEZONE`, and `RUN_ON_STARTUP` can be configured in `config.env`.

## Environment configuration

The add-on keeps its configuration in `CONFIG_LOCATION`, which defaults to
`/config/config.env`. From Home Assistant this is stored in the add-on's
private `addon_configs` directory and can be edited with a compatible file
browser add-on.

A template is created on first start. Common examples are:

```env
# Native Remaster store selection
STORES=epic,prime,gog

# Epic Games
EG_EMAIL=your-email@example.com
EG_PASSWORD=your-password
EG_OTPKEY=
EG_MOBILE=true
EG_MOBILE_PLATFORMS=android,ios

# Amazon Prime Gaming
PG_EMAIL=your-amazon-email@example.com
PG_PASSWORD=your-password
PG_OTPKEY=

# GOG
GOG_EMAIL=your-gog-email@example.com
GOG_PASSWORD=your-password

# Optional Steam support
STEAM_USERNAME=your-steam-username
STEAM_PASSWORD=your-password

# Optional AliExpress support
AE_EMAIL=your-aliexpress-email@example.com
AE_PASSWORD=your-password

# Optional notifications
NOTIFY=tgram://bot-token/chat-id
# DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
```

See the
[upstream configuration reference](https://github.com/P-Adamiec/Free-Games-Claimer-Remaster#configuration)
for all available settings.

## Upgrade notes

Version 2.0 changed the application engine from
`vogler/free-games-claimer` (Node.js, Playwright, and Firefox) to
`P-Adamiec/Free-Games-Claimer-Remaster` (Python, nodriver, and Chromium).

Version 2.0.2 keeps the Home Assistant layer intentionally thin and no longer
ships application-specific converters for the former vogler JSON history or
Firefox profile. It also no longer migrates configuration from obsolete
pre-`addon_config` Home Assistant paths.

Existing Remaster data under `/data` remains persistent across add-on updates.
Users upgrading directly from a pre-2.0 release may need to recreate their
current `config.env` and perform a one-time browser login through noVNC.

The former Node.js `CMD_ARGUMENTS` option is no longer used. Configure store
selection directly with Remaster's native `STORES` setting in `config.env`.
The add-on fixes `NOVNC_PORT` to `7080` so Remaster and Home Assistant use the
same port end-to-end.

## Upstream update policy

The add-on is based directly on the official versioned Remaster container
image instead of rebuilding its Python, browser, VNC, and system runtime.

The repository updater tracks the full upstream release tag (for example
`v1.5`) and updates the base image reference. The add-on version remains
Home Assistant-safe even while the upstream project is still on a lower
version series.

This keeps future upstream updates focused on the image tag and add-on
metadata instead of manually synchronizing Remaster's Dockerfile and runtime
dependencies.

## Installation

1. Add this add-on repository to the Home Assistant add-on store.
2. Install **Free Games Claimer**.
3. Configure `config.env` and the add-on options as needed.
4. Start the add-on and review its log.
5. Open noVNC if an account needs manual authentication.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)

## Custom scripts and environment variables

- [Running custom scripts in add-ons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- [Passing environment variables to an add-on](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2)

## Support

Open an issue in the
[add-on repository](https://github.com/alexbelgium/hassio-addons/issues).
