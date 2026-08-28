#!/usr/bin/env bash
# block-cursoragent.sh — block Cursor co-author commits & scrub cursoragent from GitHub Contributors.
#
# One-liner (from any chopsticksAI / git repo clone):
#   curl -fsSL https://chopstickshq.com/chopsticks-ai/block-cursoragent.sh | bash
#
# Options (pass after bash -s --):
#   --fix-github [owner/repo]   squash main to ilikemacos-only history (default: origin remote)
#   --global                    install hooks for ALL repos (~/.config/git/hooks-no-cursoragent)
#   --local                     install hooks in current repo only (default)
#
set -Eeuo pipefail

CURSOR_TRAILER='^Co-authored-by: Cursor <cursoragent@cursor.com>'
CURSOR_EMAIL='cursoragent@cursor.com'
GITHUB_AUTHOR_NAME='ilikemacos'
GITHUB_AUTHOR_EMAIL='287112028+ilikemacos@users.noreply.github.com'

MODE=local
FIX_GITHUB=auto
GITHUB_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global) MODE=global ;;
    --local) MODE=local ;;
    --fix-github)
      FIX_GITHUB=yes
      if [[ "${2:-}" == */* ]]; then GITHUB_REPO="$2"; shift; fi
      ;;
    --no-fix-github) FIX_GITHUB=no ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
  esac
  shift
done

install_hooks() {
  local dir="$1"
  mkdir -p "$dir"

  cat > "$dir/prepare-commit-msg" <<'HOOK'
#!/bin/sh
# Remove Cursor agent co-author — GitHub counts it as a contributor.
grep -vi '^Co-authored-by: Cursor <cursoragent@cursor.com>' "$1" > "$1.hqtmp" && mv "$1.hqtmp" "$1"
HOOK

  cat > "$dir/commit-msg" <<'HOOK'
#!/bin/sh
# Reject commits that still credit cursoragent (after prepare-commit-msg).
if grep -qiE '^Co-authored-by:.*cursoragent@cursor\.com' "$1"; then
  echo "block-cursoragent: commit blocked — Cursor co-author trailer present." >&2
  echo "Re-run commit outside Cursor agent mode, or use: GIT_AUTHOR_NAME=you git commit ..." >&2
  exit 1
fi
if grep -qiE '^Co-authored-by:.*cursor\.com' "$1"; then
  echo "block-cursoragent: commit blocked — Cursor co-author trailer present." >&2
  exit 1
fi
HOOK

  cat > "$dir/pre-push" <<'HOOK'
#!/bin/sh
# Block push if any outgoing commit credits cursoragent.
zero=0000000000000000000000000000000000000000
while read local_ref local_sha remote_ref remote_sha; do
  [ -z "${local_sha:-}" ] && continue
  [ "$local_sha" = "$zero" ] && continue
  if [ "$remote_sha" = "$zero" ]; then
    range="$local_sha"
  else
    range="${remote_sha}..${local_sha}"
  fi
  if git log --format='%B---' $range 2>/dev/null | grep -qiE 'Co-authored-by:.*cursoragent@cursor\.com'; then
    echo "block-cursoragent: push blocked — outgoing commits contain Cursor co-author." >&2
    exit 1
  fi
  if git log --format='%an <%ae>' $range 2>/dev/null | grep -qi 'cursoragent'; then
    echo "block-cursoragent: push blocked — outgoing commits authored by cursoragent." >&2
    exit 1
  fi
done
exit 0
HOOK

  chmod +x "$dir/prepare-commit-msg" "$dir/commit-msg" "$dir/pre-push"
  echo "Installed hooks in $dir"
}

repo_root() {
  local d="${PWD:-$(pwd)}"
  while [[ "$d" != "/" ]]; do
    if [[ -d "$d/.git" ]]; then
      echo "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  git rev-parse --show-toplevel 2>/dev/null || true
}

detect_github_repo() {
  local root="$1"
  local url
  url="$(git -C "$root" remote get-url origin 2>/dev/null || true)"
  [[ -n "$url" ]] || return 1
  if [[ "$url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

contributors_has_cursoragent() {
  local repo="$1"
  command -v gh >/dev/null 2>&1 || return 1
  gh api "repos/$repo/contributors" --jq '.[].login' 2>/dev/null | grep -qx 'cursoragent'
}

fix_github_contributors() {
  local repo="$1"
  local root="${2:-}"

  command -v gh >/dev/null 2>&1 || { echo "Need GitHub CLI (gh) for --fix-github"; return 1; }

  echo "==> Scrubbing $repo contributors (force-push clean main)…"

  if [[ -n "$root" && -f "$root/scripts/push-clean-github.py" ]]; then
    REPO="$repo" python3 "$root/scripts/push-clean-github.py"
    return $?
  fi

  # Inline fallback when push-clean-github.py is not present
  python3 - "$repo" "$root" <<'PY'
import base64, json, os, subprocess, sys
from datetime import datetime, timezone

repo = sys.argv[1]
root = sys.argv[2] or os.getcwd()
skip_dirs = {".git", "build", ".DS_Store"}
author = {"name": "ilikemacos", "email": "287112028+ilikemacos@users.noreply.github.com", "date": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}

def gh(method, path, data=None):
    cmd = ["gh", "api", "-X", method, path]
    if data is not None:
        cmd += ["--input", "-"]
    p = subprocess.run(cmd, input=json.dumps(data).encode() if data else None, capture_output=True)
    if p.returncode:
        raise RuntimeError(p.stderr.decode() or p.stdout.decode())
    return json.loads(p.stdout) if p.stdout else {}

files = []
for dp, dns, fns in os.walk(root):
    dns[:] = [d for d in dns if d not in skip_dirs]
    for fn in fns:
        if fn == ".DS_Store":
            continue
        full = os.path.join(dp, fn)
        rel = os.path.relpath(full, root).replace("\\", "/")
        if any(p in skip_dirs for p in rel.split("/")):
            continue
        files.append((rel, full))

blobs = {}
for rel, full in sorted(files):
    with open(full, "rb") as f:
        content = f.read()
    blobs[rel] = gh("POST", f"repos/{repo}/git/blobs", {"content": base64.b64encode(content).decode(), "encoding": "base64"})["sha"]

tree = {}
for rel, sha in blobs.items():
    node = tree
    parts = rel.split("/")
    for part in parts[:-1]:
        node = node.setdefault(part, {})
    node[parts[-1]] = sha

def make_tree(node):
    items = []
    for name in sorted(node):
        val = node[name]
        if isinstance(val, dict):
            items.append({"path": name, "mode": "040000", "type": "tree", "sha": make_tree(val)})
        else:
            items.append({"path": name, "mode": "100644", "type": "blob", "sha": val})
    return gh("POST", f"repos/{repo}/git/trees", {"tree": items})["sha"]

tree_sha = make_tree(tree)
msg = "chopsticksAI — clean history (no Cursor co-author)\n\nAttribution: ilikemacos only."
commit = gh("POST", f"repos/{repo}/git/commits", {"message": msg, "tree": tree_sha, "author": author, "committer": author})
gh("PATCH", f"repos/{repo}/git/refs/heads/main", {"sha": commit["sha"], "force": True})
print("Force-pushed main:", commit["sha"][:7])
PY
}

# --- main ---
ROOT="$(repo_root || true)"

if [[ "$MODE" == global ]]; then
  HOOKS="$HOME/.config/git/hooks-no-cursoragent"
  install_hooks "$HOOKS"
  git config --global core.hooksPath "$HOOKS"
  echo "Global hooksPath → $HOOKS (all git repos on this machine)"
elif [[ -n "$ROOT" ]]; then
  install_hooks "$ROOT/.git/hooks"
  echo "Local hooks installed in $ROOT"
else
  echo "Not inside a git repo — use --global or cd into your repo first." >&2
  exit 1
fi

if [[ "$FIX_GITHUB" == no ]]; then
  echo "Skipping GitHub contributor scrub (--no-fix-github)."
  exit 0
fi

if [[ -z "$GITHUB_REPO" && -n "$ROOT" ]]; then
  GITHUB_REPO="$(detect_github_repo "$ROOT" || true)"
fi

if [[ -z "$GITHUB_REPO" ]]; then
  echo "No GitHub repo detected; hooks only."
  exit 0
fi

if [[ "$FIX_GITHUB" == auto ]]; then
  if contributors_has_cursoragent "$GITHUB_REPO"; then
    echo "cursoragent found on $GITHUB_REPO contributors — scrubbing…"
    fix_github_contributors "$GITHUB_REPO" "$ROOT"
  else
    echo "Contributors OK on $GITHUB_REPO (no cursoragent)."
  fi
else
  fix_github_contributors "$GITHUB_REPO" "$ROOT"
fi

echo "Done."
