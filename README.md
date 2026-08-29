# cs.AI / chopsticksAI

**Free Mac, web, and Terminal AI agent** — no OpenRouter API key on your side.  
Built-in Chromium browser · Cursor-style Agents window · MIT licensed.

Latest release: **cs.AI Online 3.7.5** (Offline remains 3.6.10).

chopsticksAI (cs.AI) is the free AI assistant from Chopsticks HQ. Use it in the macOS app, in your browser, or from Terminal with `csai`. Live chat runs through chopstickshq.com — you never paste an OpenRouter or OpenAI key.

[![Download cs.AI 3.7.5](https://img.shields.io/badge/download-cs.AI%203.7.5-00ff80)](https://chopstickshq.com/chopsticks-ai/online/)
[![Product Hunt](https://img.shields.io/badge/Product%20Hunt-cs.AI-da552f)](https://www.producthunt.com/products/cs-ai)
[![AlternativeTo](https://img.shields.io/badge/AlternativeTo-listing-0f766e)](https://alternativeto.net/software/chopsticks-ai/about/)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111)](https://chopstickshq.com/chopsticks-ai/)
[![License: MIT](https://img.shields.io/badge/license-MIT-6b6b8a)](LICENSE)

**Online (live models):** [chopstickshq.com/chopsticks-ai/online/](https://chopstickshq.com/chopsticks-ai/online/)  
**Offline (on-device KB):** [chopstickshq.com/chopsticks-ai/offline/](https://chopstickshq.com/chopsticks-ai/offline/)  
**Web app:** [chopstickshq.com/chopsticks-ai/web/](https://chopstickshq.com/chopsticks-ai/web/) · [Upgrades](https://chopstickshq.com/chopsticks-ai/web/upgrades/) · [Enterprise](https://chopstickshq.com/chopsticks-ai/enterprise/)  
**GitHub:** [github.com/ilikemacos/ChopsticksAI](https://github.com/ilikemacos/ChopsticksAI)

---

## What's new in 3.7.5

- Request analyzer and compute budget (cheap vs deep paths)
- Ranked web evidence, source conflicts, follow-up research
- OpenRouter `:free` only; Groq unrestricted
- Adversarial critic on harder questions

Full notes: [changelog.json](changelog.json)

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

Or download **chopsticksAI-v3.7.5.zip** / **chopsticksAI-offline-v3.6.10.zip** from the product pages or [Releases](https://github.com/ilikemacos/ChopsticksAI/releases).

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
./build-app.sh v3.7.5 online
./build-app.sh v3.6.10 offline
```

---

## Hosted API

The live function is deployed from the Chopsticks HQ site repo (`api/_lib/`), not from this mirror alone. This tree includes `server/chopsticks-ai.js`, `signup-verify.js`, `usage-email.js`, and `chopsticks-ai-kb.json` so the layout is complete, but running your own copy still needs Supabase, Resend, OpenRouter/Groq keys, and HMAC secrets that are **not** in git.

Enterprise sales: chopstickshq@lam.ws · [enterprise page](https://chopstickshq.com/chopsticks-ai/enterprise/)

---

## License

MIT — see [LICENSE](LICENSE). Copyright Chopsticks HQ / ilikemacos.
