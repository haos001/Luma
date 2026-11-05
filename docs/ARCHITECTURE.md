# Architecture

Luma is one Swift package with Apple-framework dependencies only.

## Boundaries

| Component | Responsibility |
| --- | --- |
| `LightCore/RGB` | Strict six-digit HEX parsing, HSV conversion, brightness scaling |
| `LightCore/LightProtocol` | Fixed-layout 16-byte static-color reports |
| `LightCore/HIDTransport` | Device matching, exclusive short-lived handle, sequential writes |
| `LightCore/LightTransition` | Eased frames and the fade-out / black / fade-in sequence |
| `LightCore/RecommendationFlow` | Token-based guard against duplicate or stale animation completions |
| `LightCore/PresetCatalog` | 40 built-in presets with stable identifiers |
| `LightCore/Localization` | Typed English/Russian UI strings, preset presentation, language resolution |
| `LightCore/RecommendationEngine` | Deterministic local date/season/time selection |
| `LightCore/StateStore` | Validated local JSON and atomic saves |
| `LumaApp/AppModel` | Main-thread UI state; serial queue for USB; cancellable live-preview debounce |
| `LumaApp/ContentView` | Native navigation, palette, custom color controls, action bar |
| `LumaApp/RecommendationGlow` | Temporary timeline during the visible wave; static tint afterwards |
| `LightCLI` | Small command dispatcher; no app UI or ongoing animation |

## Applying a selected color

The model validates HEX and snapshots the selected name, color, and brightness. That snapshot is the transition target: clicking the circle must never silently replace it with the current recommendation.

Only the completed rendered wave unlocks hardware transmission. An independent sleep timer is not used to guess when the wave has finished. A unique flow token rejects stale callbacks. Controls are locked while the transition is active.

IOKit work runs on a serial queue. On success, the model persists the sent target. On partial failure, it keeps the last successfully sent RGB in memory and reports failure. The persisted target is not presented as confirmed device readback.

Live preview is opt-in, off at launch, and coalesces input with an 80 ms debounce. It is a distinct immediate-write mode, not the main animated apply path.

## Lifetime and data

There is no LaunchAgent, daemon, menu-bar helper, login item, network client, or update service. The last window closing terminates the app. A short in-progress hardware transition may defer termination; no off report is sent just because the process exits.

The public package uses bundle ID `local.luma.desktop` and `~/Library/Application Support/Luma/state.json`. It does not automatically import earlier private-prototype preferences. `--preview` uses a separate temporary JSON file and skips USB operations.

The saved language is `system`, `en`, or `ru`. Missing or unknown language values fall back to the system preference without discarding old colors or favorites. Language changes only affect presentation and the local settings file; they do not send USB reports. Built-in names are localized by stable preset ID, while user favorite names remain verbatim. Historical Russian enum raw values remain unchanged for data compatibility. In preview mode, `--language en` or `--language ru` overrides the initial language without touching production preferences.

## Testing

`LightCoreChecks` is an executable test harness, not an XCTest target. This keeps checks runnable with Command Line Tools alone. It covers protocol bytes, color math, persistence, 365 days of recommendation inputs, transition endpoints/timing, and stale/duplicate flow tokens. It never sends USB reports.

UI layout, real hardware response, appearance changes, and process lifetime still need manual checks. A passing CI run does not establish device compatibility.
