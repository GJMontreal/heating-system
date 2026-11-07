# heating-system

Parent repo for a zone-valve heating system. It holds three submodules and no code of its own.

- `boiler-relay`: zone PID control and relay outputs. Has its own `CLAUDE.md`.
- `mqtt-bridge`: MQTT to redis bridge. No `CLAUDE.md` yet.
- `heating`: Homebridge plugin in TypeScript. Reads and writes the redis keys.

`boiler-relay` and `mqtt-bridge` track `more_better_modular`. `heating` tracks `develop`. Work inside a submodule on its own branch, commit and push there, then commit the new pointer here.

## Redis contract

Redis is the interface between `mqtt-bridge`, `boiler-relay` and the Homebridge plugin. The key names are listed in `boiler-relay/CLAUDE.md`. A change to a key in one repo needs the matching change in the others.

## Commands

- Sync submodules to their branch tips: `git submodule update --remote`
- Fresh clone: `git clone --recurse-submodules <url>`

Run tests from inside each submodule. See its own docs.
