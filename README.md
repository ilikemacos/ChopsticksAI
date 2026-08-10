# cs.AI / chopsticksAI

**Fully open source** (MIT) — native macOS Agents app, Terminal CLI, web Lab, and Netlify API for [Chopsticks HQ](https://chopstickshq.com/).

Latest release: **cs.AI 2.5.1** (macOS app) · Terminal CLI **2.3.9b**

## What's new in 2.5.1

- **Chromium browser** rail in the Agents Window — in-app WKWebView plus Chromium search API (Google + DuckDuckGo)
- Drag-and-drop chats into folders; **shift-click** and **⌘-click** multi-select for bulk move
- Keyword retrieval and Chromium web search — no vector embeddings
- Full-screen Terminal CLI (`csai`) with `csai update` self-updater

## Repositories

| Component | Path in this repo |
|-----------|-------------------|
| macOS app (SwiftUI) | [`macos-app/`](macos-app/) |
| **Terminal CLI** (`csai`) | [`cli/`](cli/) |
| Offline KB + engine | [`engine/`](engine/) |
| Auto-update helper | [`shared/AppAutoUpdate.swift`](shared/) |
| API handler | [`server/chopsticks-ai.js`](server/chopsticks-ai.js) |
| Web app (cs.AI 2.5.1) | [`web/`](web/) on [chopstickshq.com](https://chopstickshq.com/chopsticks-ai/web/) |
| Web Lab (legacy) | [`lab/index.html`](lab/) |
| Site mirror (full HQ pages) | [chopstickshq-mirror](https://github.com/ilikemacos/chopstickshq-mirror) |

## Web app

Open **cs.AI in your browser** (no install):

https://chopstickshq.com/chopsticks-ai/web/

Short link: https://chopstickshq.com/csai/

## Install (macOS app)

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash
```

Or download the zip from [chopstickshq.com/chopsticks-ai/](https://chopstickshq.com/chopsticks-ai/) or [Releases](https://github.com/ilikemacos/ChopsticksAI/releases).

## Terminal CLI

Full-screen terminal agent (Grok Build style). Requires Python 3.9+.

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-csai-cli.sh | bash
csai
```

Commands: `csai ask`, `csai login`, `csai update`, `csai version`. From repo: `cli/install.sh`.

## Build macOS app

Requires macOS 14+ and Swift (`swiftc`). From `macos-app/`:

```bash
./build-app.sh v2.5.1
```

## Run your own API

Deploy `server/chopsticks-ai.js` as a Netlify/serverless function (see [chopstickshq-mirror](https://github.com/ilikemacos/chopstickshq-mirror) for `netlify.toml` reference). Set `OPENROUTER_API_KEY` in the host environment — **never commit keys**.

## Sync to GitHub

Before pushing the open-source mirror:

```bash
./scripts/sync-to-github.sh
./scripts/install-git-hooks.sh   # strips Cursor co-author from commits
./scripts/push-clean-github.py   # optional: force-push clean history via API
```

## License

MIT — see [LICENSE](LICENSE). Copyright Chopsticks HQ / ilikemacos.

## Links

- Product page: https://chopstickshq.com/chopsticks-ai/
- Lab: https://chopstickshq.com/chopailab/
- Open-source hub: https://chopstickshq.com/opensource/
- GitHub: https://github.com/ilikemacos/ChopsticksAI
