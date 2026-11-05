# Changelog

## 0.5.0 — 2026-11-06

- English and Russian interfaces, with an instant in-app language selector and a Follow macOS option.
- Localized names/descriptions for all 40 presets, recommendation context, menus, tooltips, accessibility labels, status messages, and device errors.
- Preset search accepts both languages; user-authored favorite names are preserved.
- Saved language preference and backward-compatible loading of 0.4.0 settings.
- Four new hardware-free scenarios covering localization and migration (17 scenarios total).
- CLI messages and recommendations follow the app's saved language preference.

## 0.4.0 — 2026-11-05

### Open-source preparation

- Standalone Luma package and `lumactl` command.
- Separate public preferences namespace; no import of private-prototype settings.
- MIT license, English/Russian documentation, protocol notes, contribution and security guidance.
- Native build and release scripts, architecture-labelled ZIPs and SHA-256 checksums.
- Hardware-free macOS CI and issue/pull-request templates.
- Download-first English/Russian READMEs, bilingual install/update guides, and a first-release draft with asset and checksum instructions.

### Application baseline

- Native macOS sidebar and toolbar, system appearance, Liquid Glass controls on supported systems.
- 40 presets, local time/season recommendations, HSV/RGB/HEX input, brightness, and saved favorites.
- Selected-color wave followed by fade-out, a black interval, and fade-in.
- Direct IOKit HID transport for the tested 96-LED controller.
- Standalone CLI and 13 core test scenarios.
