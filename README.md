# heating-system

Control software for a zone-valve hydronic heating system. A BeagleBone runs it all and switches relays for the zone valves, the boiler and the pump.

## Parts

| Submodule | Role |
| --- | --- |
| `boiler-relay` | Runs a PID loop per zone and drives the GPIO and MQTT relay outputs. |
| `mqtt-bridge` | Copies sensor readings from the MQTT broker into redis. |
| `hb-heating-plugin` | Homebridge plugin. The UI for setpoints, modes and boost. |

Redis connects all of them. Sensors publish to mosquitto, `mqtt-bridge` writes the readings to redis, Homebridge writes setpoints, and `boiler-relay` reads both and switches the relays.

```mermaid
flowchart LR
    sensors[Zigbee sensors via Tasmota gateway] -->|publish| mqtt[(mosquitto)]
    mqtt -->|subscribe| bridge[mqtt-bridge]
    bridge -->|current_temperature<br/>humidity, battery| redis[(redis)]

    app[Home app] <--> hb[hb-heating-plugin<br/>Homebridge]
    hb -->|target_temperature<br/>target state, boost| redis
    redis -->|current_temperature, humidity<br/>battery level, heating_cooling_state| hb

    redis -->|current_temperature<br/>target, boost| relay[boiler-relay]
    relay -->|control_value<br/>heating_cooling_state| redis

    relay -->|GPIO| relays[Relay board<br/>zone valves, boiler, pump]
    relay -->|MQTT relay output| mqtt
    relays -->|end switches| relay
```

`boiler-relay` and `mqtt-bridge` track `more_better_modular`. `hb-heating-plugin` tracks `develop`.

## Clone

```
git clone --recurse-submodules git@github.com:GJMontreal/heating-system.git
```

In an existing clone, run `git submodule update --init`.

## Update the submodules

```
git submodule update --remote
git add boiler-relay mqtt-bridge hb-heating-plugin
git commit -m "Update submodules"
```

## Deploy

```
./deploy.sh <user> <host> boiler-relay mqtt-bridge
./deploy.sh <user> <host> all
```

The script runs the `deploy.sh` of each part you name, so a part without one cannot be deployed. A part that fails does not stop the others, and the script exits non-zero if any failed.

Each submodule has its own README with setup, running and deploy steps.
