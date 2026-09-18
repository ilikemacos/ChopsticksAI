# cs.AI Island

Native macOS Dynamic Island (SwiftUI + AppKit `NSPanel`). Inspired by the interaction idea of Atoll, implemented originally for Chopsticks HQ **cs.AI**.

Build:

```bash
cd csai-island
chmod +x build-app.sh
./build-app.sh
open "build/cs.AI Island.app"
```

Or open `CSAIIsland.xcodeproj` in Xcode (macOS 14+).

The island is a menu-bar accessory. Click it or press **Control-Option-Space** for cs.AI. Settings live in the status item menu.

cs.AI talks to `https://chopstickshq.com/api/chopsticks-ai` by default (Flash plate). Optional API key is stored in Keychain.
