# cs.AI / chopsticksAI

**Fully open source** (MIT) — native macOS Agents app, web Lab, and Netlify API for [Chopsticks HQ](https://chopstickshq.com/).

Latest release: **v2.2.9**

## Repositories

| Component | Path in this repo |
|-----------|-------------------|
| macOS app (SwiftUI) | [`macos-app/`](macos-app/) |
| Offline KB + engine | [`engine/`](engine/) |
| Auto-update helper | [`shared/AppAutoUpdate.swift`](shared/) |
| API handler | [`server/chopsticks-ai.js`](server/chopsticks-ai.js) |
| Web Lab | [`lab/index.html`](lab/) |
| Site mirror (full HQ pages) | [chopstickshq-mirror](https://github.com/ilikemacos/chopstickshq-mirror) |

## Install (macOS)

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash
```

Or download the zip from [chopstickshq.com/chopsticks-ai/](https://chopstickshq.com/chopsticks-ai/) or [Releases](https://github.com/ilikemacos/ChopsticksAI/releases).

## Build macOS app

Requires macOS 14+ and Swift (`swiftc`). From `macos-app/`:

```bash
./build-app.sh v2.2.9
```

## Run your own API

Deploy `server/chopsticks-ai.js` as a Netlify/serverless function (see [chopstickshq-mirror](https://github.com/ilikemacos/chopstickshq-mirror) for `netlify.toml` reference). Set `OPENROUTER_API_KEY` in the host environment — **never commit keys**.

## License

MIT — see [LICENSE](LICENSE). Copyright Chopsticks HQ / ilikemacos.

## Links

- Product page: https://chopstickshq.com/chopsticks-ai/
- Lab: https://chopstickshq.com/chopailab/
- Open-source hub: https://chopstickshq.com/opensource/
