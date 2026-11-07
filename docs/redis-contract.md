# Redis contract

Redis is the interface between `mqtt-bridge`, `boiler-relay` and `hb-heating-plugin`. A key name or payload shape change in one repo needs the matching change in the others.

## Prefix

Every key starts with a sensor path such as `/home/sensors/kitchen`. Three settings must name the same path:

- `<name>` in `mqtt-bridge`, the gateway device `Name`, or the device id such as `0xE1AC` when it has none.
- `sensor_path` of the zone in `boiler-relay/config/system_config.json`.
- `path` of the device in the `hb-heating-plugin` platform config.

The status keys in the second table do not start with a sensor path. They start with `heating/<mode>/`.

## Keys

`SET+PUB` means the writer calls `SET` and then `PUBLISH` on the same key with the same payload. A `PUB` subscriber sees changes. A `GET` reader sees the last value.

| Key suffix | Payload | Writer | Delivery | Readers |
| --- | --- | --- | --- | --- |
| `current_temperature` | JSON `{"value", "units", "time"}`, `units` is `C` | `mqtt-bridge` | SET+PUB | `boiler-relay` GET, plugin PUB |
| `current_relative_humidity` | JSON `{"value", "units", "time"}`, `units` is `%` | `mqtt-bridge` | SET+PUB | plugin PUB |
| `current_battery_level` | JSON `{"value", "units", "time"}`, `units` is `%` | `mqtt-bridge` | SET+PUB | plugin PUB |
| `current_battery_voltage` | JSON `{"value", "units", "time"}`, `units` is `V` | `mqtt-bridge` | SET+PUB | none |
| `target_temperature` | JSON `{"value", "units"}`, `units` is `C` | plugin | SET+PUB | `boiler-relay` GET, plugin GET at startup |
| `target_heatingcooling_state` | integer, 0 off, 1 heat | plugin | SET+PUB | `boiler-relay` GET, plugin GET at startup |
| `boost` | `true` or `false` | plugin | SET | `boiler-relay` GET |
| `control_value` | float from 0 to 1 | `boiler-relay` | SET | none |
| `heating_cooling_state` | integer, 0 or 1 | `boiler-relay` | SET+PUB | plugin PUB, plugin GET at startup |

`time` is UTC ISO 8601 to the second with a `Z` suffix. `boiler-relay` treats a `current_temperature` whose `time` has not changed for two hours as no heat. `boiler-relay` treats any `target_heatingcooling_state` other than 1 as off.

## Status keys

`<mode>` is `active` for the running service or `shadow` for `python -m boiler_relay --shadow`. A shadow run writes only under `heating/shadow/`. Every payload is JSON with a `time` field. Delivery is SET only.

| Key | Payload | Writer | Readers |
| --- | --- | --- | --- |
| `heating/<mode>/zones/<zone name>` | `{"system", "control_value", "state", "time"}`, `system` is `hydronic` or `electric`, `state` is 0, 1 or null | the zone thread | `boiler-relay` API |
| `heating/<mode>/hydronic/boiler` | `{"call", "time"}`, `call` is 0 or 1 | the boiler thread, once per poll | none |
| `heating/<mode>/heartbeat` | `{"time"}` | the boiler thread, once per poll | none |

`<zone name>` is the zone `name` in `system_config.json`, not the sensor path. `state` is null until the zone has a target state. In shadow mode `call` comes from the zones' decided states, not from the end-switch pins. The boiler key sits under `hydronic` because the electric system has no boiler.

## Version keys

Each service writes its version once at startup. Delivery is SET only. Every key is `heating/versions/<service name>`, and the payload is `{"version", "commit", "time"}`. `time` is the start time. `commit` is the short git hash of the deployed source, with `-dirty` appended for uncommitted changes, or `unknown`. A service that starts while redis is down runs without its key until the next restart.

| Key | Writer | Readers |
| --- | --- | --- |
| `heating/versions/boiler-relay` | `boiler-relay`, in active and shadow mode | none |
| `heating/versions/mqtt-bridge` | `mqtt-bridge`, after its redis ping succeeds | none |

## Rules

- Do not rename a key or change a payload field without changing every reader in the table.
- A reader ignores fields it does not use. `boiler-relay` ignores `units`.
- A new key gets a row here in the same change that adds it.

## Open items

- The plugin reads no `current_temperature` at startup, only subscribes. After a plugin restart the temperature is empty until the next sensor report.
- `current_battery_voltage` and `control_value` have no reader.
- The API reads only the zone keys. `hydronic/boiler` and `heartbeat` have no reader yet.
- Nothing checks this table against the code. A contract test that reads each repo's key names would catch a rename.
