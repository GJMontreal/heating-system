# heating-system

Parent repo for a zone-valve heating system. It holds three submodules and no code of its own.

- `boiler-relay`: zone PID control for both heating systems. Has its own `CLAUDE.md`.
- `mqtt-bridge`: MQTT to redis bridge. Has its own `CLAUDE.md`.
- `hb-heating-plugin`: Homebridge plugin in TypeScript. Reads and writes the redis keys.

The house has two systems. Hydronic is a boiler, pump and zone valves on GPIO, with an end switch on each valve. Electric is a radiator on a Zigbee relay over MQTT, with no feedback. The name `boiler-relay` covers both. Each zone has a `system` field, `hydronic` or `electric`.

`boiler-relay` and `mqtt-bridge` track `more_better_modular`. `hb-heating-plugin` tracks `develop`. Work inside a submodule on its own branch, commit and push there, then commit the new pointer here.

## Redis contract

Redis is the interface between `mqtt-bridge`, `boiler-relay` and the Homebridge plugin. `docs/redis-contract.md` lists every key, its payload, its writer and its readers. A change to a key in one repo needs the matching change in the others and in that file.

## Commands

- Sync submodules to their branch tips: `git submodule update --remote`
- Fresh clone: `git clone --recurse-submodules <url>`

Run tests from inside each submodule. See its own docs.
