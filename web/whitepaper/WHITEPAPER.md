# chopsticksAI (cs.AI) White Paper

**Chopsticks HQ** · September 2026  
**Product:** chopsticksAI / cs.AI · **Site:** [chopstickshq.com/chopsticks-ai](https://chopstickshq.com/chopsticks-ai/) · **Source:** [github.com/ilikemacos/ChopsticksAI](https://github.com/ilikemacos/ChopsticksAI) (MIT)

---

## Abstract

chopsticksAI (branded **cs.AI**) is Chopsticks HQ’s free multi-surface AI assistant: a full-page web chat, a macOS Agents app, and a Terminal CLI (`csai`). Live inference is hosted by Chopsticks HQ so users do not paste provider API keys. Capability is exposed as **plates**—named product modes such as Fast, Auto, Flash, Core, Swift, Lite, and gated Pro plates—rather than as a single foundation model trained by Chopsticks.

This paper describes the product problem, surfaces, plate system (including intent-aware Auto routing), online versus offline modes, access and donor gates, open-source posture, and published benchmark orientation. Benchmark figures cited here are taken only from the public [cs.AI benchmark page](https://chopstickshq.com/chopsticks-ai/benchmark/); suites and harnesses differ and must not be read as one bake-off. cs.AI is a **product and routing layer**, not a claim that Chopsticks trains a frontier base model from scratch.

---

## 1. Problem

People who want a capable coding-and-chat agent usually face one of three frictions:

1. **Key friction** — every serious model behind a personal OpenRouter, OpenAI, Anthropic, or cloud key.
2. **Surface friction** — web-only chat, or a desktop IDE agent, or a CLI, but rarely the same product across all three with one account story.
3. **Mode friction** — “one model does everything,” which either burns latency on trivial turns or underperforms on debugging and long planning.

cs.AI targets that gap: HQ-hosted live models, consistent web / Mac / CLI entry points, and explicit plates so Fast stays quick, Flash/Core carry heavier work, and Auto can classify intent instead of gambling on a random free backend at reply time.

---

## 2. Product overview

### 2.1 Surfaces

| Surface | Role |
|--------|------|
| **Web chat** | Primary interface at `/chopsticks-ai/web/` — plates, search, files, account sync. |
| **macOS app** | Desktop Agents window with Chromium rail; Online builds talk to the same HQ API. |
| **Terminal (`csai`)** | CLI install from the site; same Online path for live turns. |
| **Offline KB** | Separate on-device knowledge product for Chopsticks lab docs (MacBar, Fathom, CSR, etc.) — no live model. |

Latest Online packaging is advertised as **cs.AI Online 4.1h**; Offline remains on its own version line (3.6.10 in the open README at time of writing).

### 2.2 What users do not bring

Live chat is billed and keyed on the HQ side. The product promise is: open the web app or Mac Online build and talk—without pasting an OpenRouter or OpenAI key into the client. Self-hosting the open API tree still requires the operator’s own datastore, mail, and inference credentials; those secrets are not in the public git mirror.

### 2.3 Enterprise

Large deployments (custom capacity, admin, invoice) are handled through the [Enterprise](https://chopstickshq.com/chopsticks-ai/enterprise/) page and `chopstickshq@lam.ws`.

---

## 3. Architecture (high level)

```
User (Web / Mac / csai)
        │
        ▼
Chopsticks HQ API  (Netlify functions + shared lib)
        │
        ├─ Auth / signup / usage limits
        ├─ Plate resolve + aliases + gates
        ├─ Auto intent classify → concrete plate chain
        ├─ Fallbacks / live-miss rescue → Fast
        └─ Vision path (images as input; image generation not offered)
        │
        ▼
HQ-hosted model backends (not named in customer UI)
```

**Design rules for the public product:**

- Customer-facing plate names stay **Fast, Auto, Flash, Core, Core-Pro, Pro, Swift, Lite** (plus gated ChopCode / Kaji / Max / Wagyu where enabled).
- Provider brand names are not used in the hero or plate picker labels.
- **Fast** is the everyday default (`DEFAULT_TIER`).
- Unsigned attempts at donor plates fall back to Fast; durable live-miss rescue also returns to Fast.

### 3.1 Intent-aware Auto

Auto is not “pick any free model at call time.” Before a model call, the server classifies the turn (code/debug, vision, long reasoning/planning, light chat, trivial) and routes to an existing plate chain while keeping the **Auto** label in the UI. Coding and stack-trace heavy turns prefer **Core**; multi-step planning and hard analysis prefer **Flash**; short or trivial turns stay on **Fast** / **Lite** as appropriate. Prompt and sampling knobs (for example lower temperature on coding turns) are tuned per path.

### 3.2 Online vs Offline

- **Online** — live plates through HQ; knowledge freshness and tool behaviour follow the live stack.
- **Offline** — packaged documentation KB for Chopsticks products; useful without network model calls; not a substitute for Online coding chat.

---

## 4. Plates and access

### 4.1 Everyday plates (everyone)

| Plate | Intent |
|-------|--------|
| **Fast** | Default everyday chat; also fallback. |
| **Auto** | Intent router over existing chains. |
| **Flash** (4.7-Flash) | Flagship open plate for harder chat / reasoning paths. |
| **Core** | Strong coding / grounded path. |
| **Swift / Lite** | Lighter / faster everyday variants. |

### 4.2 Donor and Pro gates

- **Core-Pro** and **4.7-Pro** — Ko-fi supporters (same login email) and founder-style grants; sign-in required where configured; locked requests return a clear donor/Pro error instead of silently upgrading.
- Historical Pro paths (for example Air / ChopCode keyed by Fathom Pro keys or Founder) remain part of the product family as documented on the site and changelog.

Exact rate budgets and tip windows can change; the product UI and Usage surfaces are authoritative for a given account.

---

## 5. Safety, privacy, and operations (product level)

- **Accounts** — email / username / password signup is supported; Google OAuth exists on web where enabled.
- **Vision** — attached images can be read; the product does not advertise image generation.
- **Search** — citations are presented in a collapsed expandable bar rather than a permanent open list.
- **Uptime** — a public uptime ping helps Mac and web show whether the live API is reachable.
- **Deploy habit** — site updates are drafted on Netlify and promoted deliberately; Mac app builds are shipped separately from the static site.

This paper does not describe internal admin tools, secret material, or provider account layout.

---

## 6. Open source

The [ChopsticksAI](https://github.com/ilikemacos/ChopsticksAI) repository is **MIT**-licensed and includes:

- `macos-app/` — SwiftUI Agents app  
- `cli/` — `csai`  
- `server/` — API handler sources mirrored for layout completeness  
- `web/` — web chat assets  
- `engine/` — offline KB engine pieces  

The live production function is deployed from the Chopsticks HQ site tree. Running a private clone still needs operator-owned infrastructure and keys.

---

## 7. Benchmarks (published orientation only)

cs.AI publishes a [benchmark page](https://chopstickshq.com/chopsticks-ai/benchmark/) that charts **vendor-published** numbers next to **cs.AI 4.7-Flash** where a comparable citation exists. Important caveats:

1. **cs.AI is a plate**, not a separately trained foundation model card.  
2. Where Flash shares an Ultra stack citation, Flash and Nemotron 3 Ultra bars may match on purpose.  
3. **Suites differ** (HLE vs GPQA Diamond vs Terminal-Bench 2.0 vs 2.1 vs SWE-Bench Multilingual).  

### 7.1 Coding agents tab

The **Coding agents** tab highlights **cs.AI 4.7-Flash** among coding-oriented published figures (as of 18 Sep 2026 on the site):

| Entry | Suite (as labeled on site) | Value |
|-------|----------------------------|------:|
| GLM 5.3 | Terminal-Bench (lab card) | 88.2% |
| Claude Sonnet 5 | Terminal-Bench (lab card) | 80.4% |
| Composer 2.5 | SWE-Bench Multilingual (Cursor) | 79.8% |
| Composer 2.5 | Terminal-Bench 2.0 (Cursor) | 69.3% |
| **cs.AI 4.7-Flash** | **Terminal-Bench 2.1 BF16 (Ultra stack)** | **56.4%** |
| Nemotron 3 Ultra | Terminal-Bench 2.1 BF16 | 56.4% |

Flash is highlighted on this tab. Composer 2.5’s higher Terminal-Bench number is a **2.0** figure; Flash’s is **2.1** BF16—do not treat them as identical harnesses.

### 7.2 Other published Flash anchors

From the same scores file (not exhaustive of every peer bar):

- **HLE (no tools):** cs.AI 4.7-Flash **41.3%** (plate score on the chart).  
- **GPQA:** cs.AI 4.7-Flash **87.0%** cited via the Ultra “GPQA no tools” stack (not labeled Diamond on that citation).  

Cursor has not published HLE or GPQA for Composer 2.5 on this page, so those Composer bars are omitted from those charts.

---

## 8. Limitations

- **Not a base-model lab.** Chopsticks routes and products; published Ultra-linked scores are not a claim of Chopsticks-trained weights.  
- **Benchmark mixing.** The Coding tab exists for orientation; it is explicitly not a single bake-off.  
- **Capacity and free backends.** Free plates depend on HQ capacity and upstream availability; fallbacks exist but quality can vary under load.  
- **README drift.** Open-source README plate tables can lag the live picker (Fast / Auto / Flash / Core naming). The live web/Mac UI is authoritative.  
- **Offline ≠ Online.** Offline KB does not provide the Online coding agent experience.

---

## 9. Future work

Directions consistent with the current product:

1. Keep Auto’s intent map honest with eval samples (code vs planning vs chat).  
2. Narrow harness gaps on the public Coding tab only when Flash has a clean citation on the same suite.  
3. Keep Mac and web plate catalogues in lockstep after server edits.  
4. Expand enterprise admin and capacity without breaking the free everyday path.

---

## 10. Conclusion

chopsticksAI / cs.AI is Chopsticks HQ’s attempt to make a serious multi-surface assistant **usable without personal model keys**, while still exposing clear modes—Fast for everyday, Flash and Core for harder work, Auto for intent routing, and donor Pro plates for supporters. The white paper’s benchmark section points at the public Coding agents tab where **cs.AI 4.7-Flash** sits beside peer lab and Composer figures with harness labels intact.

For the live product: [chopstickshq.com/chopsticks-ai](https://chopstickshq.com/chopsticks-ai/) · chat: [/chopsticks-ai/web/](https://chopstickshq.com/chopsticks-ai/web/) · benchmarks: [/chopsticks-ai/benchmark/](https://chopstickshq.com/chopsticks-ai/benchmark/) · source: [github.com/ilikemacos/ChopsticksAI](https://github.com/ilikemacos/ChopsticksAI).

---

*Document version: 2026-09-18 · Chopsticks HQ*
