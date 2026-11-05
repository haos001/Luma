# Privacy

## No network features

The app and CLI contain no telemetry, analytics, account system, HTTP client, remote configuration, automatic updater, or cloud synchronization. They do not request screen recording, camera, microphone, location, contacts, or calendar access.

GitHub may process repository visits, issue submissions, and CI runs under its own policies. Those are separate from running Luma.

## Local access

Luma enumerates matching USB HID interfaces and writes color reports when requested. Recommendations read the local date, time zone, and calendar. Seasons assume the Northern Hemisphere; no physical location is inferred or fetched.

## Stored preferences

`~/Library/Application Support/Luma/state.json` contains:

- Last successfully sent RGB and brightness.
- Whether the last explicit command was off.
- Last-applied timestamp.
- Saved preset names and colors.

The file is ordinary local JSON, not encrypted. It stays until you remove it. App removal alone does not remove preferences. The UI also follows normal macOS window-state behavior.

Demo mode uses `luma-ui-preview.json` in the system temporary directory. It does not open the HID transport. Preview preferences are separate from real preferences.

Do not attach your entire preferences file to a public issue if favorite names contain personal information. Share only the minimal redacted details needed to reproduce a problem.
