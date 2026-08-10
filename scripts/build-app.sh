#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Sources"
BUNDLE="chopsticksAI.app"
EXEC="chopsticksAI"
VERSION="${1:-v1.0.0}"
BUILD="$ROOT/build"
APP="$BUILD/$BUNDLE"
ZIP="chopsticksAI-${VERSION}.zip"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }
command -v swiftc >/dev/null || { echo "swiftc not found"; exit 1; }

if [[ ! -f "$SRC/AppIcon.icns" ]]; then
  if [[ ! -f "$SRC/AppIcon-source.png" ]]; then
    python3 "$ROOT/scripts/create-icon-source.py"
  fi
  chmod +x "$ROOT/scripts/generate-icon.sh"
  ICON_SRC="$SRC/AppIcon-source.png" ICON_OUT="$SRC/AppIcon.icns" \
    "$ROOT/scripts/generate-icon.sh"
fi

ARCH="$(uname -m)"
TARGET="arm64-apple-macos14.0"
[[ "$ARCH" == "arm64" ]] || TARGET="x86_64-apple-macos14.0"

echo "Building chopsticksAI $VERSION ($TARGET)..."

rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$SRC/Info.plist" "$APP/Contents/Info.plist"
cp "$SRC/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

swiftc -O \
  -parse-as-library \
  -target "$TARGET" \
  -framework SwiftUI \
  -framework AppKit \
  -o "$APP/Contents/MacOS/$EXEC" \
  "$SRC/ChopsticksAIKB.swift" \
  "$SRC/ChopsticksAIEngine.swift" \
  "$SRC/AppAutoUpdate.swift" \
  "$SRC/ChopsticksAIApp.swift"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION#v}" "$APP/Contents/Info.plist" 2>/dev/null || true
codesign --force --sign - "$APP" 2>/dev/null || true

rm -f "$BUILD/$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$BUILD/$ZIP"
SHA="$(shasum -a 256 "$BUILD/$ZIP" | awk '{print $1}')"

mkdir -p "$ROOT/releases"
cp "$BUILD/$ZIP" "$ROOT/releases/"

python3 - "$ROOT/version.json" "$VERSION" "$ZIP" "$SHA" <<'PY'
import json, sys
path, ver, zip_name, sha = sys.argv[1:5]
payload = {
    "latest": ver,
    "product": "chopsticksAI",
    "releases": {"stable": {"zip": f"releases/{zip_name}", "sha256": sha}},
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY

echo "Built $BUILD/$ZIP"
echo "SHA-256: $SHA"
