#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
AI="$ROOT/../chopsticks-ai"
SITE="$ROOT/../chopstickshq-site/chopsticks-ai"
BUNDLE="chopsticksAI.app"
EXEC="chopsticksAI"
VERSION="${1:-v2.0.0}"
BUILD="$ROOT/build"
APP="$BUILD/$BUNDLE"
ZIP="chopsticksAI-${VERSION}.zip"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }

SWIFTC=""
SDK=""
resolve_toolchain() {
  local xcode candidate swift sdk
  if [[ -n "${CHOPSTICKS_AI_XCODE:-}" && -d "$CHOPSTICKS_AI_XCODE" ]]; then
    candidate="$CHOPSTICKS_AI_XCODE"
    swift="$candidate/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    sdk="$candidate/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
    if [[ -x "$swift" && -d "$sdk" ]]; then SWIFTC="$swift"; SDK="$sdk"; return 0; fi
  fi
  if swiftc -version >/dev/null 2>&1; then
    SWIFTC="$(command -v swiftc)"
    SDK="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
    return 0
  fi
  for xcode in \
    "$ROOT/../rnitro-dmg-staging/Applications/Xcode.app" \
    "/Applications/Xcode.app"; do
    [[ -d "$xcode" ]] || continue
    swift="$xcode/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    sdk="$xcode/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
    [[ -x "$swift" && -d "$sdk" ]] || continue
    SWIFTC="$swift"
    SDK="$sdk"
    echo "Using toolchain from $xcode (accept Xcode license to use default swiftc)"
    return 0
  done
  echo "No working Swift toolchain. Run: sudo xcodebuild -license accept" >&2
  return 1
}
resolve_toolchain

if [[ -f "$ROOT/AppIcon.icns" ]]; then
  echo "Reusing $ROOT/AppIcon.icns"
else
  python3 "$ROOT/create-icon-source.py"
  [[ -f "$ROOT/generate-icon.sh" ]] || cp "$ROOT/../chopsticks-hq-app/generate-icon.sh" "$ROOT/"
  chmod +x "$ROOT/generate-icon.sh"
  "$ROOT/generate-icon.sh"
fi

ARCH="$(uname -m)"
TARGET="arm64-apple-macos14.0"
[[ "$ARCH" == "arm64" ]] || TARGET="x86_64-apple-macos14.0"

echo "Building chopsticksAI $VERSION ($TARGET)..."

rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

SHARED="$ROOT/../macos-shared/AppAutoUpdate.swift"
BIN="$APP/Contents/MacOS/$EXEC"

SDK_ARGS=()
[[ -n "$SDK" && -d "$SDK" ]] && SDK_ARGS=(-sdk "$SDK")

SWIFT_CMD=("$SWIFTC" -O -parse-as-library)
if ((${#SDK_ARGS[@]})); then SWIFT_CMD+=("${SDK_ARGS[@]}"); fi
SWIFT_CMD+=(
  -target "$TARGET"
  -framework SwiftUI
  -framework AppKit
  -o "$BIN"
  "$AI/ChopsticksAIKB.swift"
  "$AI/ChopsticksAIEngine.swift"
  "$SHARED"
  "$ROOT/CursorTheme.swift"
  "$ROOT/AppStore.swift"
  "$ROOT/SupabaseCloud.swift"
  "$ROOT/WhatsNew.swift"
  "$ROOT/Attachments.swift"
  "$ROOT/CursorPages.swift"
  "$ROOT/ChopsticksAIApp.swift"
)
"${SWIFT_CMD[@]}"

[[ -f "$BIN" && -s "$BIN" ]] || { echo "Build failed: $BIN missing or empty" >&2; exit 1; }
chmod +x "$BIN"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION#v}" "$APP/Contents/Info.plist" 2>/dev/null || true
codesign --force --deep --sign - "$APP"

rm -f "$BUILD/$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$BUILD/$ZIP"
SHA="$(shasum -a 256 "$BUILD/$ZIP" | awk '{print $1}')"

CHECK="$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-ai-check.XXXXXX")"
trap 'rm -rf -- "$CHECK"' EXIT
unzip -q "$BUILD/$ZIP" -d "$CHECK"
[[ -f "$CHECK/$BUNDLE/Contents/MacOS/$EXEC" && -s "$CHECK/$BUNDLE/Contents/MacOS/$EXEC" ]] \
  || { echo "Zip sanity check failed: executable missing" >&2; exit 1; }

mkdir -p "$SITE"
cp "$BUILD/$ZIP" "$SITE/"
cp "$ROOT/install-chopsticks-ai.sh" "$SITE/"

/usr/bin/python3 - "$SITE/macos-version.json" "$VERSION" "$ZIP" "$SHA" <<'PY'
import json, sys
path, ver, zip_name, sha = sys.argv[1:5]
payload = {
    "latest": ver,
    "product": "chopsticksAI",
    "releases": {"stable": {"zip": zip_name, "sha256": sha}},
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY

echo "Built $BUILD/$ZIP"
echo "SHA-256: $SHA"
