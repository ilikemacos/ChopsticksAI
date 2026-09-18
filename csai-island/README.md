# cs.AI Island

Native macOS Dynamic Island for notched MacBooks — a compact pill anchored to the menu bar notch that expands on hover and click. **cs.AI** (Chopsticks HQ) is built in as the primary surface.

## Inspiration & licensing

Interaction patterns are inspired by [Atoll](https://github.com/Ebullioscopic/Atoll) (GPL-3.0). **This project is original MIT-licensed Swift** — we read public feature descriptions only and re-implemented behaviour here. **No Atoll, Boring.Notch, or other GPL source code** is copied or vendored into this repository.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac (notched MacBook recommended; falls back to menu-bar center on other displays)
- Xcode 15+ or Swift 5.9+ toolchain for local builds

## Build & run

From the repo root:

```bash
cd csai-island
chmod +x build-app.sh
./build-app.sh
open "build/cs.AI Island.app"
```

Or open `CSAIIsland.xcodeproj` in Xcode and run the **CSAIIsland** scheme.

> **Note:** Cloud/Linux CI cannot compile macOS SwiftUI apps. Sources and the Xcode project are complete; build on a Mac.

## Usage

| Action | Result |
|--------|--------|
| Hover near notch | Compact HUD expands (disable in Settings → General) |
| Click pill | Opens tabbed surface (cs.AI, Media, Stats, Timers) |
| **Control–Option–Space** | Open cs.AI tab |
| Menu bar icon → Settings | Island, appearance, plates, live events |
| Escape | Stop generation / close expanded surface |

### Tabs

1. **cs.AI** — Chat composer with streaming replies against `https://chopstickshq.com/api/chopsticks-ai`. Default plate **Flash**; picker offers Fast / Auto / Flash / Core (no provider names). Optional API key in Keychain; works without a key via HQ. **Clipboard** quick action sends pasteboard text for summary/explanation.
2. **Media** — Now playing with artwork, scrubber, transport controls (Music, Spotify, etc. via MediaRemote).
3. **Stats** — Live CPU, memory, and network status.
4. **Timers** — Simple countdown timers with HUD blips while running.

### Live HUD blips

Volume, brightness, battery/charging, now playing, downloads, network, and timers briefly expand the pill then settle back to idle — similar to Dynamic Island live activities.

## Permissions

The app runs as a **menu bar accessory** (no Dock icon). It may prompt for:

- **Accessibility** — global hotkey (Control–Option–Space) via Carbon
- **Notifications** — optional notification mirroring
- **Automation** — Music.app fallback when MediaRemote is unavailable

No network access beyond your configured cs.AI endpoint (default Chopsticks HQ). API keys are stored in the **Keychain** only — never committed to the repo.

## Login item

Toggle **Launch at login** in Settings or the menu bar menu. Implemented with `ServiceManagement` (`SMAppService`).

## Project layout

```
csai-island/
├── AI/                  CSAIService, ChatController, streaming parser
├── DynamicIsland/       NSPanel controller, notch geometry, state machine
├── Media/               Now playing (MediaRemote)
├── SystemEvents/        Volume, brightness, battery, network, stats, …
├── UI/                  Compact/expanded SwiftUI, tabbed surface, settings
├── App/                 AppDelegate, menu bar, hotkey
└── build-app.sh         Single-target swiftc build script
```

## Development

- Minimum deployment: **macOS 14.0**
- SwiftUI + AppKit `NSPanel` (non-activating, notch-aligned)
- Spring animations tuned in Settings (response/damping presets)

Do not commit secrets. Use Settings → AI → optional Keychain API key for authenticated HQ tiers.
