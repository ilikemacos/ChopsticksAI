#!/usr/bin/env bash
# Update chopstickshq.com version.json from an existing zip — no compile, no Xcode.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SITE="$ROOT/../../chopstickshq-site/chopsticks-ai"
VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 v2.5.5b" >&2
  exit 1
fi

ZIP="chopsticksAI-${VERSION}.zip"
SRC="$ROOT/build/$ZIP"
if [[ ! -f "$SRC" ]]; then
  SRC="$SITE/$ZIP"
fi
[[ -f "$SRC" ]] || { echo "Zip not found: $ZIP (build it elsewhere or copy into $SITE/)" >&2; exit 1; }

SHA="$(shasum -a 256 "$SRC" | awk '{print $1}')"
mkdir -p "$SITE"
cp "$SRC" "$SITE/$ZIP"

payload=$(cat <<EOF
{
  "latest": "${VERSION#v}",
  "product": "chopsticksAI",
  "releases": {
    "stable": {
      "zip": "$ZIP",
      "sha256": "$SHA"
    }
  }
}
EOF
)
printf '%s\n' "$payload" > "$SITE/macos-version.json"
printf '%s\n' "$payload" > "$SITE/version.json"

echo "Published $ZIP to $SITE/"
echo "SHA-256: $SHA"
echo "latest: ${VERSION#v}"
