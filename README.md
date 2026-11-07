# heating-system

Control software for a house with two heating systems. A BeagleBone runs it all.

- **Hydronic:** a boiler and pump feed radiators through zone valves. The BeagleBone switches them with GPIO relays. Each valve reports back through an end switch, and the boiler runs while any end switch is high.
- **Electric:** a radiator on a Zigbee relay, switched over MQTT. It has no end switch and no other feedback, so its state is never confirmed.

The same sensors, setpoints and control loop serve both. A zone belongs to one system, set by its `system` field in the `boiler-relay` config.

## Parts

| Submodule | Role |
| --- | --- |
| `boiler-relay` | Runs a PID loop per zone. Drives the hydronic GPIO outputs and the boiler, and the electric MQTT relay. Despite the name it controls both systems. |
| `mqtt-bridge` | Copies sensor readings from the MQTT broker into redis. |
| `hb-heating-plugin` | Homebridge plugin. The UI for setpoints, modes and boost. |
| `heating-web` | Read-only API and web interface. Reads redis and is deployed on its own, apart from `boiler-relay`. |

Redis connects all of them. Sensors publish to mosquitto, `mqtt-bridge` writes the readings to redis, Homebridge writes setpoints, and `boiler-relay` reads both and switches the relays. `heating-web` only reads redis and the systemd journal, and serves the API and the web interface. Dotted lines are the version keys each service writes at startup.

```mermaid
flowchart LR
    sensors[Zigbee sensors<br/>via Tasmota gateway] -->|publish| mqtt[(mosquitto)]
    mqtt -->|subscribe| bridge[mqtt-bridge]
    bridge -->|current_temperature<br/>humidity, battery| redis[(redis)]

    app[Home app] <--> hb[hb-heating-plugin<br/>Homebridge]
    hb -->|target_temperature<br/>target state, boost| redis
    redis -->|current_temperature, humidity<br/>battery level, heating_cooling_state| hb

    redis -->|current_temperature<br/>target, boost| relay[boiler-relay]
    relay -->|control_value, heating_cooling_state<br/>heating/mode/ zones, boiler, heartbeat| redis

    relay -->|GPIO, hydronic| relays[Relay board<br/>zone valves, boiler, pump]
    relays -->|end switches| relay
    relay -->|MQTT relay output, electric| mqtt
    mqtt -->|command, no feedback| zrelay[Zigbee relay<br/>electric radiator]

    browser[Browser] <--> web[heating-web<br/>API and web UI]
    redis -->|sensor, target, status<br/>and version keys| web
    journal[systemd units<br/>and journal] -->|state, logs| web

    bridge -.->|version| redis
    relay -.->|version| redis
    web -.->|version| redis
    hb -.->|version| redis
```

The keys, payloads and who writes and reads each are in [docs/redis-contract.md](docs/redis-contract.md).

`boiler-relay` and `mqtt-bridge` track `more_better_modular`. `hb-heating-plugin` tracks `develop`. `heating-web` tracks `main`.

## Clone

```
git clone --recurse-submodules git@github.com:GJMontreal/heating-system.git
```

In an existing clone, run `git submodule update --init`.

## Update the submodules

```
git submodule update --remote
git add boiler-relay mqtt-bridge hb-heating-plugin heating-web
git commit -m "Update submodules"
```

## Deploy

```
./deploy.sh <user> <host> heating-web
./deploy.sh <user> <host> boiler-relay mqtt-bridge
./deploy.sh <user> <host> all
```

The script runs the `deploy.sh` of each part you name, so a part without one cannot be deployed. A part that fails does not stop the others, and the script exits non-zero if any failed.

The script creates the `heating` user on the device first. `boiler-relay` and `mqtt-bridge` install as separate `_v2` services beside the legacy ones and never touch the legacy directories. Their `deploy/switch.sh` moves between the legacy and v2 services. `heating-web` is new and has no legacy twin, so it has no switch. It also reads the control config, so deploy `boiler-relay` first. A deploy copies files and builds the virtualenv. It does not install or start the units. Each part prints the commands to install them. Because `heating-web` has its own unit and directory, it redeploys and restarts without touching the control service.

## Device setup

The deploy scripts do not set up the storage or the logging. Do these once on the device, as root.

The root filesystem is a 3.6 GB eMMC. History and the journal go on an SD card so the control software never writes them to the eMMC.

1. Format the card as ext4 with the label `heating-history`: `mkfs.ext4 -L heating-history /dev/mmcblk0p1`. Check the device name with `lsblk` first, because this erases the card.
2. Mount it at `/var/lib/heating_history` by UUID with `defaults,noatime,commit=60,nofail,x-systemd.device-timeout=5`, and create `data` there owned by `heating`. `heating-web` writes `data/history.sqlite3` only while the path is a mount point.
3. Create `/var/lib/heating_history/journal` as `root:systemd-journal` with mode `2755`, and bind mount it onto `/var/log/journal` in `/etc/fstab` with `bind,nofail,x-systemd.requires-mounts-for=/var/lib/heating_history`.
4. Add `/etc/systemd/journald.conf.d/heating.conf` with `Storage=persistent` and `SystemMaxUse=200M`. Keep the cap small, because without the card journald writes to the eMMC.
5. Disable rsyslog with `systemctl disable --now rsyslog`. It duplicated every journal line into `daemon.log` and `syslog`, which reached 184 MB.

Order matters in step 4. Copy any existing journal files to the card and remove them from `/var/log/journal` before you mount the bind, or the mount hides them. Then run `chgrp -R systemd-journal /var/lib/heating_history/journal` and `systemd-tmpfiles --create --prefix /var/log/journal`. Journal files copied with `cp -a` stay `root:root`, and `heating-web` cannot read them as `systemd-journal`. Restarting `systemd-journald` disconnects the output of services already running. They stay healthy but log nothing to the journal until they restart.

Each submodule has its own README with setup, running and deploy steps.
