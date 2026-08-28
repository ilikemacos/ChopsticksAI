#!/usr/bin/env bash
# Install git hooks that strip Cursor co-author trailers (keeps cursoragent off Contributors).
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/.git/hooks/prepare-commit-msg"

mkdir -p "$(dirname "$HOOK")"
cat > "$HOOK" <<'EOF'
#!/bin/sh
grep -vi '^Co-authored-by: Cursor <cursoragent@cursor.com>' "$1" > "$1.hqtmp" && mv "$1.hqtmp" "$1"
EOF
chmod +x "$HOOK"

COMMIT_HOOK="$ROOT/.git/hooks/commit-msg"
cat > "$COMMIT_HOOK" <<'EOF'
#!/bin/sh
if grep -qiE '^Co-authored-by:.*cursoragent@cursor\.com' "$1"; then
  echo "block-cursoragent: commit blocked — Cursor co-author present." >&2
  exit 1
fi
EOF
chmod +x "$COMMIT_HOOK"

PUSH_HOOK="$ROOT/.git/hooks/pre-push"
cat > "$PUSH_HOOK" <<'EOF'
#!/bin/sh
zero=0000000000000000000000000000000000000000
while read local_ref local_sha remote_ref remote_sha; do
  [ -z "${local_sha:-}" ] && continue
  [ "$local_sha" = "$zero" ] && continue
  if [ "$remote_sha" = "$zero" ]; then range="$local_sha"; else range="${remote_sha}..${local_sha}"; fi
  if git log --format='%B---' $range 2>/dev/null | grep -qiE 'Co-authored-by:.*cursoragent@cursor\.com'; then
    echo "block-cursoragent: push blocked." >&2; exit 1
  fi
done
exit 0
EOF
chmod +x "$PUSH_HOOK"

echo "Installed prepare-commit-msg, commit-msg, pre-push in $ROOT/.git/hooks"
echo "Or use: curl -fsSL https://chopstickshq.com/chopsticks-ai/block-cursoragent.sh | bash"
