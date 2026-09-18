#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/cs.AI Island.app"
BIN="$APP/Contents/MacOS/CSAIIsland"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }

SWIFTC="$(command -v swiftc || true)"
SDK="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
if [[ -z "$SWIFTC" || ! -x "$SWIFTC" ]]; then
  for xcode in /Applications/Xcode.app; do
    candidate="$xcode/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    [[ -x "$candidate" ]] && SWIFTC="$candidate"
    SDK="$xcode/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
  done
fi
[[ -x "$SWIFTC" ]] || { echo "swiftc not found"; exit 1; }

ARCH="$(uname -m)"
TARGET="arm64-apple-macos14.0"
[[ "$ARCH" == "arm64" ]] || TARGET="x86_64-apple-macos14.0"

rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

SRC=()
while IFS= read -r f; do SRC+=("$f"); done < <(find "$ROOT" -name '*.swift' -not -path '*/build/*' | sort)

CMD=("$SWIFTC" -O -parse-as-library)
[[ -n "$SDK" && -d "$SDK" ]] && CMD+=(-sdk "$SDK")
CMD+=(
  -target "$TARGET"
  -framework SwiftUI
  -framework AppKit
  -framework Combine
  -framework CoreAudio
  -framework IOKit
  -framework IOBluetooth
  -framework Network
  -framework SystemConfiguration
  -framework AVFoundation
  -framework UserNotifications
  -framework Intents
  -framework ServiceManagement
  -framework Carbon
  -framework Security
  -o "$BIN"
)
CMD+=("${SRC[@]}")
"${CMD[@]}"

chmod +x "$BIN"
codesign --force --deep --sign - "$APP" 2>/dev/null || true
echo "Built $APP"
