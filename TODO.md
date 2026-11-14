# TODO

Work that spans more than one service. Each service keeps its own `TODO.md` for the rest.

## Open

- [ ] Review the week that began 2026-11-14 at 16:50, when the live controller restarted on `boiler-relay` v0.8.1 with the valve limiter. `heating-web` v0.13.0 was already running. Check these at the end of the week:
  - Calls under 5 minutes per zone should be about zero. The replay over the week before predicted about 21 calls in Study, 22 in Kitchen, 21 in Bedrooms and 19 in Common.
  - Each room still reaches its target. A zone below target for hours is the sign to roll back.
  - Peak overshoot after a heat-up with a steady target was 0.02 to 0.55 C before the limiter. It should be no worse.
  - Read the Trends curve on a few heat-ups and choose `pchip` or `linear` in `heating-web` `web/curve.js`.
- [ ] Roll back the limiter if rooms miss their targets. Remove the `valve_limits` block from `/var/lib/boiler_relay_v2/config/system_config.json` on the device, then restart `boiler_relay_v2` and `boiler_relay_v2_shadow`. The other way back is a clean clone of the `boiler-relay` `v0.6.0` tag deployed with `deploy.sh`.
- [ ] Decide whether the Study needs an off time above 13 minutes. Its end switch fell about 13 minutes after the close command in the three calls measured, and about 6 minutes on 2026-11-07. The `boiler-relay` `TODO.md` holds the same item.
- [ ] Report temperature faster on the hourly sensors. Bedrooms, Common and Kitchen send one reading about every 60 minutes, and the Study sends one every 6 to 12 minutes while it heats. A reading that arrives up to an hour late explains most of the 0.2 to 0.55 C overshoot, because the rooms rise 0.13 to 0.24 C per hour. Look up how to lower the reportable change on a Zigbee sensor through the Tasmota gateway before touching one, and check the battery cost.
- [ ] Choose between PID gains and a hysteresis loop for the hydronic zones once the faster reports are in. Hysteresis would need a lead term, closing at target minus the rise rate times the report delay. The shadow and the Compare page can run a candidate beside the live controller. The shadow now runs the same limiter as the live service, so Compare shows the effect of the gains alone.
- [ ] Look at the live integral cap. The live defaults are `kp 1, ki 0.01, kd 0.5, integral_cap 1.0`. After the 2026-11-14 restart cleared the controller's state, Bedrooms and Kitchen fell from a control value of 1.0 to 0.16 and 0.04. That suggests the integral held them open while the rooms were near target. The shadow profile is `kp 1, ki 0.001, kd 0, integral_cap 0.3`. The Study runs that profile in its own config block.
- [ ] Replace the BackRoom end switch. Until then a BackRoom call can leave `P8_27` high and keep the boiler on with no demand. Do not boost or heat BackRoom.
- [ ] Deploy the boost timer. `hb-heating-plugin` `2b5abff` on `develop` ends a boost after `boostMinutes`, 60 by default, with a per thermostat override in the Homebridge UI. The plugin has no deploy step yet, so the timer has not run on the device.
- [ ] Add a HomeKit service that shows the boost time remaining. Boost stays a Switch for now.
- [ ] Find out why `tele/tasmota_E3738F/LWT` holds a retained `Offline` while the Stairwell relay works.

## Done

- [x] Move live control from the legacy `boiler_relay` to `boiler_relay_v2` on 2026-11-08. The legacy unit is installed and disabled, and `boiler_relay_v2_shadow` runs beside `v2` and starts at boot.
- [x] Add a minimum valve on time of 5 minutes and off time of 13 minutes to the hydronic zones, in `boiler-relay` v0.8.1. A short demand accumulates and releases as one call. A restart or a power cut starts with both minimums satisfied, and an outage counts as time closed. It is live on the device from 2026-11-14.
- [x] Record each real temperature report in a `readings` table and draw the Trends curve from it, in `heating-web` v0.13.0. The device migrated the history on 2026-11-14.
- [x] Confirm the Stairwell relay from its own reports, send only on change and refresh every 60 seconds.
- [x] Verify every zone's end-switch pairing on the device. Common and Kitchen were swapped in the legacy config and are fixed in `v2`. Study, BackRoom and Bedrooms match. BackRoom's end switch is faulty, see the open item.
- [x] Set the second Bedrooms end switch, `P8_17`, to gpio mode with the pull off. The legacy patch is on `GJMontreal/boiler-relay` `main` at `da30afc`, and the `v2` fix is in `boiler-relay` `54b6bda`.
- [x] Prove that the SD card and the journal mount at boot with the 30 second device timeout. The second reboot on 2026-11-07 mounted both in 12 seconds.
- [x] Replace the README diagram with a draw.io SVG. The source is `docs/architecture.drawio.svg`.
