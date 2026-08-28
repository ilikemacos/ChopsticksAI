# Launch posts (copy-paste)

**Flagship product: cs.AI (chopsticksAI) 2.5.4**  
Public launch hub: https://chopstickshq.com/launch/  
Press kit: https://chopstickshq.com/press/

**Canonical links:**
- cs.AI product: https://chopstickshq.com/chopsticks-ai/
- cs.AI web app: https://chopstickshq.com/chopsticks-ai/web/
- cs.AI short: https://chopstickshq.com/csai/
- GitHub: https://github.com/ilikemacos/ChopsticksAI
- Terminal guide: https://chopstickshq.com/guides/csai-terminal-install.html
- HQ hub: https://chopstickshq.com/
- rNitro (secondary pitch): https://chopstickshq.com/rnitro/

Contact: chopstickshq@lam.ws

---

## Show HN — cs.AI (primary)

**Title:**
```
Show HN: cs.AI – free Mac/web/Terminal AI agent, no API key on your side
```

**Body:**
```
cs.AI (chopsticksAI) is a free AI assistant from Chopsticks HQ — native macOS app,
browser web app, and a full-screen Terminal CLI (csai).

You don't bring an OpenRouter/OpenAI key. Live chat goes through chopstickshq.com
with a free allowance (resets every 5 hours). Offline KB covers HQ product questions.

macOS app includes a Cursor-style Agents window with a Chromium browser rail.
Terminal CLI supports unlock keys, /search on|off, and csai ask "…" --json for scripts.

• macOS: curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash
• Web: https://chopstickshq.com/chopsticks-ai/web/
• CLI: curl -fsSL https://chopstickshq.com/chopsticks-ai/install-csai-cli.sh | bash
• Source (MIT): https://github.com/ilikemacos/ChopsticksAI

Happy to answer questions about the architecture, allowance model, or Keychain session storage.
```

**Best time:** Tuesday–Thursday, ~8–10am US Eastern.

---

## Lobsters (lobste.rs)

**Title:**
```
cs.AI – free Mac/web/Terminal AI agent without bringing your own LLM API key
```

**Body:**
```
I ship cs.AI under Chopsticks HQ: macOS SwiftUI app, browser agent, and Python Terminal CLI.

Unlike most "free AI" tools that still need your OpenRouter key, cs.AI routes live chat
through chopstickshq.com (server-side key, free tier with 5h allowance reset). Product
help falls back to an on-device keyword KB — no vector DB.

Open source (MIT): https://github.com/ilikemacos/ChopsticksAI
Web try: https://chopstickshq.com/chopsticks-ai/web/
```

**Tags:** `programming`, `mac`, `ai`, `show`

---

## Product Hunt — cs.AI (primary)

**Name:** cs.AI (chopsticksAI)  
**Tagline:** Free Mac AI agent — app, web & Terminal. No API key on your side.  
**Topics:** Artificial Intelligence, Mac, Developer Tools, Open Source, Productivity  

**Description:**
```
cs.AI is a free AI assistant from Chopsticks HQ.

• Native macOS app with Cursor-style Agents + Chromium browser
• Full web app in the browser — no install
• Terminal CLI (csai) with --json for scripting
• No OpenRouter key required from you — free allowance via chopstickshq.com
• Offline knowledge base for Chopsticks HQ products
• MIT open source

Install macOS:
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash

Try in browser: https://chopstickshq.com/chopsticks-ai/web/
GitHub: https://github.com/ilikemacos/ChopsticksAI
```

**First comment (maker):**
```
Maker here — cs.AI started as the in-house assistant for our free macOS tools (rNitro, Fathom, etc.).

The goal: a useful agent without asking users to paste API keys. Live mode uses chopstickshq.com;
we don't keep chat analytics. 2.5.4 adds CLI unlock keys, Keychain sessions, and deploy sha256 verification.

Feedback on allowance UX, Terminal CLI, and web app welcome. chopstickshq@lam.ws
```

**Gallery:** record 30s demo — Agents window + `csai ask "…" --json` in Terminal.

---

## Show HN — rNitro (secondary, separate launch)

**Title:**
```
Show HN: rNitro – free open-source macOS menu bar system monitor
```

**Body:**
```
rNitro is a free, open-source menu bar system monitor for macOS (14+).

It shows live CPU, temperature, battery %, GPU, RAM, and network — local sensors only,
no account, no product telemetry. Optional AI chat uses API keys you store in Keychain.

Install: App ZIP from the site or GitHub Releases. Builds are ad-hoc signed for now
(right-click → Open on first launch if Gatekeeper blocks).

Site: https://chopstickshq.com/rnitro/
GitHub: https://github.com/ilikemacos/rNitro

Also from the same lab: cs.AI (free Mac/web/Terminal AI) → https://chopstickshq.com/chopsticks-ai/
```

---

## Mac community / r/macapps — cs.AI

**Title:**
```
[Free][Open Source] cs.AI – Mac + web + Terminal AI agent, no API key on your side
```

**Body:**
```
I built cs.AI (chopsticksAI) — a free AI assistant that's native on Mac, runs in the browser,
and has a Terminal CLI (csai).

You don't need to paste an OpenRouter key. Live chat uses chopstickshq.com with a free allowance
(resets every 5 hours). macOS app has a Cursor-style Agents window + Chromium browser.

• macOS 14+ app (ZIP installer on the site)
• Web: https://chopstickshq.com/chopsticks-ai/web/
• CLI: csai (Python 3.9+)

MIT source: https://github.com/ilikemacos/ChopsticksAI
Guide: https://chopstickshq.com/guides/csai-terminal-install.html

Not notarized yet — right-click Open if Gatekeeper blocks. Feedback welcome.
```

---

## Reddit / r/LocalLLaMA — cs.AI CLI angle

**Title:**
```
Free Terminal AI agent (csai) — no local GPU, no API key from you, JSON output for scripts
```

**Body:**
```
Not a local LLM — cs.AI routes through chopstickshq.com so you don't bring keys.
But the Terminal CLI is useful if you want agent-style chat from SSH or scripts:

  csai ask "summarize this error" --json
  csai ask "…" -q

Unlock keys for higher tiers, /search on|off, same allowance as the Mac app.

Install: curl -fsSL https://chopstickshq.com/chopsticks-ai/install-csai-cli.sh | bash
Repo: https://github.com/ilikemacos/ChopsticksAI
```

---

## GitHub Release v2.5.4 (attach zip)

**Title:** cs.AI 2.5.4

**Body:**
```
## cs.AI 2.5.4

- Terminal CLI: unlock keys, /search on|off, --json / --quiet
- macOS: cloud session in Keychain
- Deploy sha256 verification for app zip
- Press kit, guides, blog at chopstickshq.com

Install: curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash
Web: https://chopstickshq.com/chopsticks-ai/web/
Full changelog: https://chopstickshq.com/chopsticks-ai/changelog.json
```

---

## NameMC / Discord bio

```
Minecraft server dev · Skript / WorldEdit
Portfolio: https://chopstickshq.com/minecraft/
cs.AI (free Mac AI): https://chopstickshq.com/chopsticks-ai/
rNitro (free Mac monitor): https://chopstickshq.com/rnitro/
```
