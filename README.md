# cs.AI / chopsticksAI

**Free Mac, web, and Terminal AI agent** — no OpenRouter API key on your side.  
Built-in Chromium browser · Cursor-style Agents window · MIT licensed.

Latest release: **cs.AI Online 4.1a** (Offline remains 3.6.10).

chopsticksAI (cs.AI) is the free AI assistant from Chopsticks HQ. Use it in the macOS app, in your browser, or from Terminal with `csai`. Live chat runs through chopstickshq.com — you never paste an OpenRouter or OpenAI key.

[![Download cs.AI 4.1a](https://img.shields.io/badge/download-cs.AI%204.1a-00ff80)](https://chopstickshq.com/chopsticks-ai/online/)
[![Product Hunt](https://img.shields.io/badge/Product%20Hunt-cs.AI-da552f)](https://www.producthunt.com/products/cs-ai)
[![AlternativeTo](https://img.shields.io/badge/AlternativeTo-listing-0f766e)](https://alternativeto.net/software/chopsticks-ai/about/)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111)](https://chopstickshq.com/chopsticks-ai/)
[![License: MIT](https://img.shields.io/badge/license-MIT-6b6b8a)](LICENSE)

**Online (live models):** [chopstickshq.com/chopsticks-ai/online/](https://chopstickshq.com/chopsticks-ai/online/)  
**Offline (on-device KB):** [chopstickshq.com/chopsticks-ai/offline/](https://chopstickshq.com/chopsticks-ai/offline/)  
**Web app:** [chopstickshq.com/chopsticks-ai/web/](https://chopstickshq.com/chopsticks-ai/web/) · [Upgrades](https://chopstickshq.com/chopsticks-ai/web/upgrades/) · [Enterprise](https://chopstickshq.com/chopsticks-ai/enterprise/)  
**GitHub:** [github.com/ilikemacos/ChopsticksAI](https://github.com/ilikemacos/ChopsticksAI)

---

## What's new in 4.1a

- **cs.AI-4.0-Air** uses GLM 5.2 free and Gemma 4 free only (no GLM 4.7 Flash).

## What's new in 4.1.0

- **cs.AI-4.0-Air** uses only GLM 4.7 Flash free.

## What's new in 4.0.8

- **Uptime:** [chopstickshq.com/chopsticks-ai/uptime/](https://chopstickshq.com/chopsticks-ai/uptime/) pings the live API. Web and Mac show whether cs.AI is up.

## What's new in 4.0.7

- Create account is **email, username, and password**. No email code.
- Live turns retry and race fallbacks so a dropped model almost never ends the reply.

## What's new in 4.0.6

- **cs.AI-4-Flash** is a plate in Everyday / cs.AI. Fast replies. Knowledge dated 13 September 2026.

## What's new in 4.0.4

- Attached images are read as pictures. Image output is unavailable.

## What's new in 4.0.3

- Search citations sit in a collapsed expandable bar, not an open source list.

## What's new in 4.0.2

- **PRO** plates: **cs.AI-4.0-Air** (best) and **csCode-Pro**. Either 10 Fathom Pro API keys **or** a Founder account.
- Other plates stay on the cs.AI-4 stack.

Full notes: [changelog.json](changelog.json)

---

## Plates

| Id | Sky name | Notes |
|----|----------|--------|
| `rice` | cs.AI 3.1 | Everyday |
| `tamago` | cs.AI 3.3-Fast | Default |
| `hibachi` | cs.AI 3.3-Thinking | |
| **`csai4flash`** | **cs.AI-4-Flash** | Fast |
| **`csai4air`** | **cs.AI-4.0-Air** | **PRO · best · 10 keys or Founder** |
| `chopcode` | csCode-Pro | **PRO · 10 keys or Founder** |
| `wagyua1`–`wagyua5` | Air II–VI / 3.5-Air | Signed-in |
| `kaji` | Kaji | Alpha · 5 keys |
| `max` | Max | |

---

## Install (macOS)

**Online**

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash
```

**Offline**

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai-offline.sh | bash
```

Or download **chopsticksAI-v4.1a.zip** / **chopsticksAI-offline-v3.6.10.zip** from the product pages or [Releases](https://github.com/ilikemacos/ChopsticksAI/releases).

---

## Terminal CLI (`csai`)

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-csai-cli.sh | bash
csai
```

From repo: `cli/install.sh`

---

## Layout

| Component | Path |
|-----------|------|
| macOS app (SwiftUI) | [`macos-app/`](macos-app/) |
| Terminal CLI (`csai`) | [`cli/`](cli/) |
| Offline KB + engine | [`engine/`](engine/) |
| API handler | [`server/chopsticks-ai.js`](server/chopsticks-ai.js) |
| Web app | [`web/`](web/) |

---

## Build macOS app

Requires macOS 14+ and Swift (`swiftc`). From `macos-app/`:

```bash
./build-app.sh v4.1a online
./build-app.sh v3.6.10 offline
```

---

## Hosted API

The live function is deployed from the Chopsticks HQ site repo (`api/_lib/`), not from this mirror alone. This tree includes `server/chopsticks-ai.js`, `signup-verify.js`, `usage-email.js`, and `chopsticks-ai-kb.json` so the layout is complete, but running your own copy still needs Supabase, Resend, OpenRouter/Groq keys, and HMAC secrets that are **not** in git.

Enterprise sales: chopstickshq@lam.ws · [enterprise page](https://chopstickshq.com/chopsticks-ai/enterprise/)

---

## License

MIT — see [LICENSE](LICENSE). Copyright Chopsticks HQ / ilikemacos.
