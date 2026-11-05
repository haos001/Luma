# Install Luma

English · [Русский](INSTALL.ru.md)

## Ready-to-run app

Download `Luma-0.5.0-macOS-arm64.zip` for **Apple Silicon** from [the Luma 0.5.0 release](https://github.com/haos001/Luma/releases/tag/v0.5.0). An Intel build is not provided yet. The minimum deployment target is macOS 13; Liquid Glass appears only on macOS 26+.

1. Get the ZIP and matching `.zip.sha256` from the same Luma GitHub release.
2. Optionally verify the download before opening it, using the command below.
3. Double-click the ZIP in Finder.
4. Drag **Luma.app** into **Applications** and launch it there.
5. Close other software controlling the same USB backlight before applying a color.

Xcode and Swift are only needed to build from source, not to run a release. `lumactl` is an optional command-line tool, not a service; you can leave it in the extracted folder or omit it entirely.

### Verify a download

Put the ZIP and its checksum file in the same folder. Open Terminal in that folder and run:

```sh
shasum -a 256 -c Luma-0.5.0-macOS-arm64.zip.sha256
```

The expected result ends in `OK`. If it says `FAILED`, do not open that archive; download it again from the intended release. Adjust the filename for later versions. A checksum detects file changes; it does not independently prove the publisher's identity.

### macOS security warning

The provided build script uses **ad-hoc signing**, not a Developer ID certificate or Apple notarization. Gatekeeper may warn about or block a downloaded build. Building from inspected source is an alternative until notarized releases are available.

Only if you have reviewed and trust the download, follow Apple's per-app guidance in [opening apps safely](https://support.apple.com/en-us/102445). Do not disable Gatekeeper, remove quarantine recursively, or turn off other system protections globally. If macOS reports malware, do not override that warning.

## Build from source

You need macOS, Xcode 26+ or corresponding Command Line Tools, macOS SDK 26+, and Swift 6.2+. From the repository root:

```sh
bash scripts/test.sh
bash scripts/build.sh
open dist/Luma.app
```

Drag `dist/Luma.app` to Applications. Build scripts do not install the app or change your backlight.

## First run

Luma supports **English and Russian**. Open **… → Language / Язык** to switch instantly, or choose **Follow macOS**. The language choice is saved. Your favorite names, RGB colors, and brightness are unaffected. Version 0.4.0 settings load without resetting them.

Quit any other application controlling the strip. Opening Luma does not automatically change the light. Pick a color and click the glowing circle or Turn on. Use `--preview` to explore without sending USB reports.

Only the specific 96-LED `1A86:FE07` controller has been tested. Other devices are not automatically supported just because they use USB or RGB LEDs.

## Update or uninstall

Quit Luma, then replace the old app in Applications with the new one. Preferences remain in `~/Library/Application Support/Luma/` and are not stored inside the app bundle. There is no automatic updater.

To uninstall, quit Luma and move it to Trash. You may optionally remove the preferences folder separately. There is no login item or background helper to uninstall. Quitting or removing the app does not send an off command to the light.
