#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
AI="$REPO/engine"
SITE="${CHOPSTICKS_AI_SITE:-$REPO/../chopstickshq-site/chopsticks-ai}"
BUNDLE="chopsticksAI.app"
EXEC="chopsticksAI"
VERSION="${1:-v3.7.8b}"
EDITION="${2:-online}"
BUILD="$ROOT/build"
if [[ "$EDITION" == "offline" ]]; then
  BUNDLE="cs.AI Offline.app"
  ZIP="chopsticksAI-offline-${VERSION}.zip"
else
  BUNDLE="chopsticksAI.app"
  ZIP="chopsticksAI-${VERSION}.zip"
  EDITION="online"
fi
APP="$BUILD/$BUNDLE"

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

echo "Building chopsticksAI $VERSION ($EDITION) ($TARGET)..."

rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

SHARED="$REPO/shared/AppAutoUpdate.swift"
BIN="$APP/Contents/MacOS/$EXEC"

SDK_ARGS=()
[[ -n "$SDK" && -d "$SDK" ]] && SDK_ARGS=(-sdk "$SDK")

SWIFT_CMD=("$SWIFTC" -O -parse-as-library)
if ((${#SDK_ARGS[@]})); then SWIFT_CMD+=("${SDK_ARGS[@]}"); fi
SWIFT_CMD+=(
  -target "$TARGET"
  -framework SwiftUI
  -framework AppKit
  -framework WebKit
  -framework IOKit
  -framework Virtualization
  -o "$BIN"
  "$AI/ChopsticksAIKB.swift"
  "$AI/ChopsticksAIEngine.swift"
  "$SHARED"
  "$ROOT/CursorTheme.swift"
  "$ROOT/AppStore.swift"
  "$ROOT/KeychainStore.swift"
  "$ROOT/CloudAuth.swift"
  "$ROOT/Energy.swift"
  "$ROOT/NetworkStatus.swift"
  "$ROOT/Onboarding.swift"
  "$ROOT/WhatsNew.swift"
  "$ROOT/Attachments.swift"
  "$ROOT/CursorPages.swift"
  "$ROOT/ChromiumBrowser.swift"
  "$ROOT/MoreModelsStore.swift"
  "$ROOT/MoreModelsView.swift"
  "$ROOT/PlateCatalog.swift"
  "$ROOT/KajiApp.swift"
  "$ROOT/KajiMacFiles.swift"
  "$ROOT/KajiLinuxGuest.swift"
  "$ROOT/ChopsticksAIApp.swift"
)
"${SWIFT_CMD[@]}"

[[ -f "$BIN" && -s "$BIN" ]] || { echo "Build failed: $BIN missing or empty" >&2; exit 1; }
chmod +x "$BIN"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION#v}" "$APP/Contents/Info.plist" 2>/dev/null || true
BUNDLE_VER="${VERSION#v}"
BUNDLE_BUILD="$(python3 -c 'import re,sys; s=sys.argv[1].lower(); n=[int(x) for x in re.findall(r"\d+", s)[:3]]+[0,0,0]; extra=2 if s.rstrip().endswith("b") else (1 if s.rstrip().endswith("a") else 0); print(n[0]*1000+n[1]*100+n[2]+extra)' "$BUNDLE_VER")"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_BUILD" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CSAIEdition $EDITION" "$APP/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CSAIEdition string $EDITION" "$APP/Contents/Info.plist"
if [[ "$EDITION" == "offline" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName cs.AI Offline" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleName cs.AI Offline" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.chopstickshq.chopsticksai.offline" "$APP/Contents/Info.plist"
else
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName cs.AI Online" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleName chopsticksAI" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.chopstickshq.chopsticksai.online" "$APP/Contents/Info.plist"
fi
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
if [[ "$EDITION" == "offline" ]]; then
  MAC_JSON="$SITE/macos-offline-version.json"
  VER_JSON="$SITE/offline-version.json"
else
  MAC_JSON="$SITE/macos-version.json"
  VER_JSON="$SITE/version.json"
fi

PY="$(command -v python3.11 2>/dev/null || command -v python3 2>/dev/null || echo /usr/bin/python3)"
"$PY" - "$VER_JSON" "$MAC_JSON" "$VERSION" "$ZIP" "$SHA" "$EDITION" <<'PY'
import json, sys
path, mac_path, ver, zip_name, sha, edition = sys.argv[1:7]
payload = {
    "latest": ver.lstrip("v"),
    "product": "cs.AI " + edition,
    "edition": edition,
    "releases": {"stable": {"zip": zip_name, "sha256": sha}},
}
for p in (path, mac_path):
    with open(p, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")
PY

echo "Built $BUILD/$ZIP"
echo "SHA-256: $SHA"
