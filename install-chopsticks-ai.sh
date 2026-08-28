#!/usr/bin/env bash
set -Eeuo pipefail

echo "cs.AI Online installer (App ZIP)"

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Do not run as root"; exit 1; }

BASE="https://chopstickshq.com/chopsticks-ai"
APP="chopsticksAI.app"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-ai-install.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT

json_get() {
  grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$1" \
    | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//'
}

echo "Resolving latest version..."
curl -fsSL "$BASE/macos-version.json" -o "$TMP/version.json" \
  || { echo "Could not reach $BASE/macos-version.json"; exit 1; }

VER="$(json_get "$TMP/version.json" latest)"
ZIP="$(json_get "$TMP/version.json" zip)"
WANT_SHA="$(json_get "$TMP/version.json" sha256)"

[[ -n "$VER" && -n "$ZIP" ]] || { echo "Malformed macos-version.json"; exit 1; }
[[ ${#WANT_SHA} -eq 64 ]] || { echo "macos-version.json is missing a valid sha256 — refusing to install."; exit 1; }
echo "Latest is $VER"

echo "Downloading ${ZIP}..."
curl --progress-bar -fL "${BASE}/${ZIP}" -o "$TMP/chopsticks-ai.zip"

GOT_SHA="$(shasum -a 256 "$TMP/chopsticks-ai.zip" | awk '{print $1}')"
if [[ "$GOT_SHA" != "$WANT_SHA" ]]; then
  echo "Checksum mismatch - refusing to install."
  echo "  expected $WANT_SHA"
  echo "  got      $GOT_SHA"
  exit 1
fi
echo "Checksum verified."

unzip -qo "$TMP/chopsticks-ai.zip" -d "$TMP/out"
[[ -d "${TMP}/out/${APP}" ]] || { echo "Archive did not contain $APP"; exit 1; }

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/${APP:?}"
ditto "${TMP}/out/${APP}" "${HOME}/Applications/${APP}"
xattr -cr "${HOME}/Applications/${APP}" 2>/dev/null || true

echo "Installed $VER to ~/Applications/$APP"
open "${HOME}/Applications/${APP}"
