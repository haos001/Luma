# Hardware & USB protocol

This document records behavior observed on one ROBOBLOQ monitor-backlight controller. It is not a vendor specification or a promise of compatibility with all products sharing these IDs.

## Tested device

| Property | Value |
| --- | --- |
| USB vendor ID | `0x1A86` |
| USB product ID | `0xFE07` |
| Preferred HID usage page | `0xFF00` |
| Product string observed | `USBHID` / ROBOBLOQ USBHID |
| LED layout tested | 96 LEDs |
| Transport | USB HID output report, report ID `0` |

There is no verified model/firmware inventory yet. Luma prefers the vendor-specific interface and refuses to choose arbitrarily when multiple candidate devices are found. It does not probe random USB devices.

Start with `lumactl status` (enumeration only), then `lumactl dry-run '#C98758' 100` (packet generation only). Sending a color requires explicit `color` or app activation. Do not run protocol experiments on unrelated hardware.

## Static-color report

The implementation is in `Sources/LightCore/Color.swift`. The 16-byte report used by the tested firmware is:

```text
52 42 10 02 86 01 RR GG BB 60 61 00 00 00 FE CC
```

| Offset | Value | Observed interpretation |
| --- | --- | --- |
| 0–1 | `52 42` | `RB` header |
| 2 | `10` | Report length: 16 bytes |
| 3 | `02` | Two color ranges |
| 4 | `86` | Static-color action, decimal 134 |
| 5 | `01` | First range starts at LED 1 |
| 6–8 | `RR GG BB` | Scaled RGB color |
| 9 | `60` | First range ends at LED 96 |
| 10 | `61` | Second range starts at LED 97 |
| 11–13 | `00 00 00` | Black for the unused range |
| 14 | `FE` | Second range ends at LED 254 |
| 15 | `CC` | Sum of bytes 0–14 modulo 256 |

Example for `#BD00FF` at 100%:

```text
52 42 10 02 86 01 BD 00 FF 60 61 00 00 00 FE A8
```

IOKit receives report ID `0` as a **separate argument** to `IOHIDDeviceSetReport`. Do not prepend a zero byte to this buffer. See [Apple's API reference](https://developer.apple.com/documentation/iokit/1588656-iohiddevicesetreport).

## Brightness and off

The tested firmware did not reliably apply hardware-brightness action 135 to static colors. Each RGB channel is instead multiplied by the requested percentage and rounded. At 100%, the original RGB is sent unchanged; perceived intensity still varies by hue.

The nominal off action 151 did not reliably turn the strip off. `off` sends a black static color through the same report.

## App transition

1. A 2.6-second visual wave expands from the selected-color circle. No USB write happens until the wave reaches the edges.
2. The last known output fades to black over 1.2 seconds (30 intervals).
3. A 0.12-second dark pause separates the colors.
4. The new color appears over 1.6 seconds (40 intervals).

An already-black start skips fade-out. A black target skips fade-in. The USB handle stays open for the short transition and closes afterwards. These are software-timed writes, not a firmware animation; actual timing includes USB/OS overhead.

Closing during the visual wave cancels it. Closing during USB transmission waits for the short transition to finish. Closing a handle does not itself send black.

## Limitations

- Only this 96-LED layout and static-color report have been validated on hardware.
- Successful USB writes are not color readback or optical measurements.
- The app starts fading from its last known output. Another controller, a power cycle, or an unplugged strip may make that value stale.
- A partial write failure can leave an intermediate color on the strip. Luma reports the error; it does not claim the target was applied.
- Only one controller should write at a time. Quit other backlight apps; Luma will not kill their processes.
- The strip keeps its color while powered, but retention after power loss is not guaranteed.
- Screen sync, audio sync, dynamic effects, arbitrary LED counts, and arbitrary HID reports are not exposed.
- Apple Silicon has been exercised locally. Older macOS versions and Intel Macs need additional validation.

For a compatibility report, include USB IDs, product name, LED count, macOS version, CPU architecture, and the exact observed behavior. Omit device serial numbers and personal paths.
