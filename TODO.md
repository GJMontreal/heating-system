# TODO

Work that spans more than one service. Each service keeps its own `TODO.md` for the rest.

- [ ] Compare legacy and shadow per zone and per ten-minute window: mean control value and on-fraction. It needs three pieces. The legacy `<sensor_path>/control_value` keys and the `heating/shadow/zones/<zone name>` keys already exist. The history sampler and the Compare page are open in `heating-web`. A static mockup of the page is in `docs/web-mockup/`.
- [ ] Verify every zone's end-switch pairing on the device before the switch to `v2`. Boost one zone, wait about four minutes and read the end-switch pins from sysfs. Common and Kitchen were measured on 2026-11-07 and are swapped: the Kitchen valve raises `P8_7` and the Common valve raises `P8_15`. The fix is in the `boiler-relay` config, and the legacy config on the device is unchanged. Study, BackRoom and Bedrooms are untested.
