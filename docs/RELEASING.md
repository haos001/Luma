# Release checklist

No workflow publishes a release automatically. The included CI only checks, builds, packages, and uploads workflow artifacts to the same GitHub repository.

## Prepare

1. Review the diff and update `CHANGELOG.md`.
2. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in `Resources/Info.plist`.
3. Run `bash scripts/test.sh`, `bash scripts/build.sh`, and `bash scripts/package-release.sh`.
4. Inspect the ZIP in `dist/releases/`; it should contain the app, `lumactl`, MIT license, and English/Russian installation notes—not caches, logs, user settings, or debug symbols.
5. Verify its checksum and signature. A local signature is not notarization.

## Manual validation

- [ ] Light/dark appearance, minimum window size, sidebar, both color-selection tabs.
- [ ] Preset selection and invalid HEX input.
- [ ] Recommendation does not override the selected target.
- [ ] Saved favorites survive restart.
- [ ] Wave reaches the window edges; Reduce Motion remains usable.
- [ ] Hardware fades through black and reaches the selected color.
- [ ] Black/off and brightness work on the tested firmware.
- [ ] Unplugged/busy/multiple-device failures are understandable.
- [ ] Closing cancels a pending wave or finishes an active USB transition safely.
- [ ] Quit leaves no Luma process and does not switch the strip off.
- [ ] Tested OS versions, architecture, and hardware are recorded accurately.

Core checks and CI never substitute for the hardware checklist. Do not mark unchecked environments as supported by testing.

## Publish deliberately

Create the release/tag only after reviewing the generated artifacts. Attach the architecture-labelled ZIP and matching `.sha256` file. State whether the release is ad-hoc signed, Developer ID signed, and/or notarized; do not imply those are equivalent.

For the first release, use [the v0.4.0 notes](releases/v0.4.0.md) as the release body. Upload binary archives under **Releases**, not into Git history. GitHub's automatically generated “Source code” archives are not installable apps.

Before publishing the draft:

- Update the versioned release and download URLs in both READMEs and installation guides. Keep these edits local until the matching release assets are ready.
- Verify the README's install entry against the actual release; never leave a placeholder owner or a download URL for a missing asset in the published README.
- Check all attached filenames against the release notes and verify each checksum.
- Download the published app archive again and verify its structure and checksum. Test installation on a separate machine or fresh user account when available.

Workflow artifacts in Actions expire and are intended for development. They are not a substitute for a public, versioned Release with install notes.

For a notarized release, maintainers need their own Apple Developer credentials and a reviewed signing/notarization process. This repository does not include credentials, provisioning files, or an automated signing workflow.

## CI maintenance

CI uses GitHub's `macos-26` runner with a recent SDK. Actions are pinned to reviewed full commit SHAs, credentials are not persisted by checkout, and repository permissions are read-only. Review pins periodically against the upstream release notes:

- [GitHub macOS runner images](https://github.com/actions/runner-images)
- [actions/checkout v7.0.0](https://github.com/actions/checkout/releases/tag/v7.0.0)
- [actions/upload-artifact v7.0.0](https://github.com/actions/upload-artifact/releases/tag/v7.0.0)
