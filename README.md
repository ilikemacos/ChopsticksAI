# chopsticksAI

Native macOS assistant for [Chopsticks HQ](https://chopstickshq.com/) — live model via chopstickshq.com, offline knowledge-base fallback, auto-updates.

## Install

```bash
curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash
```

Or download the App ZIP from [Releases](https://github.com/ilikemacos/chopsticks/releases).

## Build

Requires macOS 14+ and Xcode Command Line Tools (`swiftc`, `iconutil`).

```bash
./scripts/build-app.sh v1.0.3
```

Regenerate the offline knowledge base from `kb/kb.source.json`:

```bash
python3 kb/build-kb.py
```

## How it was built:
ChopsticksAI is built on Nvidia Nemotron 3 Ultra/Super


## Site

https://chopstickshq.com/chopsticks-ai/
