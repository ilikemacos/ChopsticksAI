#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ICON_SRC:-$ROOT/Sources/AppIcon-source.png}"
OUT="${ICON_OUT:-$ROOT/Sources/AppIcon.icns}"
ICONSET="$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-ai-icon.XXXXXX")"
PADDED="$(mktemp "${TMPDIR:-/tmp}/chopsticks-ai-pad.XXXXXX.png")"
SCALED="$(mktemp "${TMPDIR:-/tmp}/chopsticks-ai-scale.XXXXXX.png")"
trap 'rm -rf "$ICONSET" "$PADDED" "$SCALED"' EXIT
SAFE=768

[[ -f "$SRC" ]] || { echo "missing icon source: $SRC" >&2; exit 1; }
command -v sips >/dev/null || { echo "sips not found" >&2; exit 1; }
command -v iconutil >/dev/null || { echo "iconutil not found" >&2; exit 1; }

# Inset artwork ~75% so macOS squircle masking does not clip corners.
sips -z "$SAFE" "$SAFE" "$SRC" --out "$SCALED" >/dev/null
sips --padToHeightWidth 1024 1024 --padColor 0A0A0C "$SCALED" --out "$PADDED" >/dev/null

rm -rf "$ICONSET"
mkdir -p "$ICONSET"
mkdir -p "$(dirname "$OUT")"

make() {
  sips -z "$1" "$1" "$PADDED" --out "$ICONSET/$2" >/dev/null
}

make 16   icon_16x16.png
make 32   icon_16x16@2x.png
make 32   icon_32x32.png
make 64   icon_32x32@2x.png
make 128  icon_128x128.png
make 256  icon_128x128@2x.png
make 256  icon_256x256.png
make 512  icon_256x256@2x.png
make 512  icon_512x512.png
make 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o "$OUT"
echo "wrote $OUT"
