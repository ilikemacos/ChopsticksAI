#!/usr/bin/env bash
# Install git hooks that strip Cursor co-author trailers (keeps cursoragent off Contributors).
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/.git/hooks/prepare-commit-msg"

mkdir -p "$(dirname "$HOOK")"
cat > "$HOOK" <<'EOF'
#!/bin/sh
# Strip Cursor agent co-author — GitHub counts it as a contributor.
grep -vi '^Co-authored-by: Cursor <cursoragent@cursor.com>' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
EOF
chmod +x "$HOOK"
echo "Installed $HOOK"
