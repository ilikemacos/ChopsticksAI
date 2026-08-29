#!/usr/bin/env bash
# Sync shipped cs.AI sources into the open-source chopsticksAI mirror before GitHub push.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(cd "$ROOT/.." && pwd)"
APP="$WORK/chopsticks-ai-app"
SITE="$WORK/chopstickshq-site"
MIRROR="$ROOT"

echo "==> Sync macOS app (chopsticks-ai-app → macos-app/)"
shopt -s nullglob
for f in "$APP"/*.swift; do cp "$f" "$MIRROR/macos-app/"; done
cp "$APP/build-app.sh" "$MIRROR/macos-app/build-app.sh"
cp "$APP/install-chopsticks-ai.sh" "$MIRROR/macos-app/" 2>/dev/null || true

# Mirror build paths (engine/, shared/, site zip output)
sed -i '' \
  -e 's|AI="$WORK/chopsticks-ai"|AI="$REPO/engine"|' \
  -e 's|AI="$ROOT/../chopsticks-ai"|AI="$REPO/engine"|' \
  -e 's|SITE="$WORK/chopstickshq-site/chopsticks-ai"|SITE="${CHOPSTICKS_AI_SITE:-$REPO/../chopstickshq-site/chopsticks-ai}"|' \
  -e 's|macos-shared|shared|' \
  "$MIRROR/macos-app/build-app.sh" 2>/dev/null || \
sed -i \
  -e 's|AI="$WORK/chopsticks-ai"|AI="$REPO/engine"|' \
  -e 's|AI="$ROOT/../chopsticks-ai"|AI="$REPO/engine"|' \
  -e 's|SITE="$WORK/chopstickshq-site/chopsticks-ai"|SITE="${CHOPSTICKS_AI_SITE:-$REPO/../chopstickshq-site/chopsticks-ai}"|' \
  -e 's|macos-shared|shared|' \
  "$MIRROR/macos-app/build-app.sh"

echo "==> Sync API + changelog"
cp "$SITE/api/_lib/chopsticks-ai.js" "$MIRROR/server/chopsticks-ai.js"
cp "$SITE/api/_lib/chopsticks-intelligence.js" "$MIRROR/server/chopsticks-intelligence.js" 2>/dev/null || true
cp "$SITE/api/_lib/signup-verify.js" "$MIRROR/server/signup-verify.js"
cp "$SITE/api/_lib/signup-verify.js" "$MIRROR/server/signup-verify.js"
cp "$SITE/api/_lib/usage-email.js" "$MIRROR/server/usage-email.js"
cp "$SITE/api/_lib/chopsticks-ai-kb.json" "$MIRROR/server/chopsticks-ai-kb.json"
cp "$SITE/api/_lib/chopcode-ensemble.js" "$MIRROR/server/chopcode-ensemble.js" 2>/dev/null || true
mkdir -p "$MIRROR/js"
cp "$SITE/js/chopsticks-ai-cloud.js" "$MIRROR/js/chopsticks-ai-cloud.js"
cp "$SITE/chopsticks-ai/changelog.json" "$MIRROR/changelog.json"
cp "$SITE/chopsticks-ai/macos-version.json" "$MIRROR/macos-version.json"

echo "==> Sync CLI"
mkdir -p "$MIRROR/cli"
cp "$SITE/chopsticks-ai/cli/"* "$MIRROR/cli/" 2>/dev/null || \
  cp "$MIRROR/cli/"* "$MIRROR/cli/" 2>/dev/null || true
if [[ -d "$MIRROR/cli" ]]; then
  for f in csai csai.py csai_client.py csai_tui.py csai_update.py install.sh; do
    [[ -f "$MIRROR/cli/$f" ]] || cp "$ROOT/cli/$f" "$MIRROR/cli/" 2>/dev/null || true
  done
fi

echo "==> Sync web + Lab"
mkdir -p "$MIRROR/lab" "$MIRROR/web"
cp "$SITE/chopsticks-ai/web/index.html" "$MIRROR/web/index.html"
cp "$SITE/chopailab/index.html" "$MIRROR/lab/index.html"

echo "==> Sync KB engine (optional)"
if [[ -d "$WORK/chopsticks-ai" ]]; then
  cp "$WORK/chopsticks-ai/ChopsticksAIKB.swift" "$MIRROR/engine/" 2>/dev/null || true
  cp "$WORK/chopsticks-ai/ChopsticksAIEngine.swift" "$MIRROR/engine/" 2>/dev/null || true
fi

echo "Done. Review with: git -C $MIRROR status"
echo "Push via: $MIRROR/scripts/push-clean-github.py  (strips Co-authored-by)"
