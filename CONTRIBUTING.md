# Contributing to Luma

Small, focused contributions are welcome. The goal is a dependable native tool that can be closed after setting a static color—not a permanent background service.

## Before changing code

- Read the [architecture](docs/ARCHITECTURE.md) and [hardware notes](docs/HARDWARE.md).
- For a new controller, provide a hardware report before changing the shared packet layout.
- Use `--preview` for UI work. Do not make tests or CI send physical USB commands.
- Keep credentials, personal favorites, device serial numbers, and local machine paths out of commits and screenshots.

## Local checks

```sh
bash scripts/test.sh
bash scripts/build.sh
open dist/Luma.app --args --preview
```

The test runner is `LightCoreChecks`; `swift test` is not this project's test entry point. Use Xcode 26+ or corresponding Command Line Tools with macOS SDK 26+ for app builds.

## Pull requests

Explain the user-visible change, how it was tested, and which hardware was involved, if any. Include light/dark screenshots for UI changes. Add core tests for protocol, color, transition, and recommendation changes. Update documentation when behavior changes.

Keep external dependencies optional and justified. Do not add auto-start, analytics, broad USB probing, or continuous background work as incidental changes.

The current UI is Russian-language. An English localization that preserves stable preset identifiers is a good candidate for a separate focused contribution.

Be respectful, discuss the work rather than the person, and avoid harassment or sharing private information. Contributions are submitted under the project's [MIT license](LICENSE), without a separate contributor agreement.
