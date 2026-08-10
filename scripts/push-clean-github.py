#!/usr/bin/env python3
"""Push chopsticksAI tree as a single clean commit (no Co-authored-by trailers)."""
import base64
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

REPO = "ilikemacos/ChopsticksAI"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {".git", "build", ".DS_Store"}
SKIP_SUFFIXES = {".iconset"}


def gh_api(method: str, path: str, data: dict | None = None) -> dict:
    cmd = ["gh", "api", "-X", method, path]
    if data is not None:
        cmd.extend(["--input", "-"])
    proc = subprocess.run(
        cmd,
        input=json.dumps(data).encode() if data else None,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"gh api {method} {path} failed:\n{proc.stderr.decode()}")
    return json.loads(proc.stdout) if proc.stdout else {}


def should_include(rel: str) -> bool:
    parts = rel.split("/")
    if any(p in SKIP_DIRS for p in parts):
        return False
    if any(rel.endswith(s) for s in SKIP_SUFFIXES):
        return False
    return True


def collect_files() -> list[tuple[str, str]]:
    files: list[tuple[str, str]] = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name == ".DS_Store":
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, ROOT).replace("\\", "/")
            if should_include(rel):
                files.append((rel, full))
    return sorted(files)


def create_blob(path: str) -> str:
    with open(path, "rb") as f:
        content = f.read()
    resp = gh_api(
        "POST",
        f"repos/{REPO}/git/blobs",
        {"content": base64.b64encode(content).decode(), "encoding": "base64"},
    )
    return resp["sha"]


def build_tree(entries: list[tuple[str, str]]) -> str:
    # path -> { type, sha } or nested dict for dirs
    tree: dict = {}
    blob_shas: dict[str, str] = {}
    for rel, full in entries:
        print(f"  blob {rel}")
        blob_shas[rel] = create_blob(full)

    for rel in blob_shas:
        parts = rel.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = ("blob", blob_shas[rel])

    def make_tree(node: dict) -> str:
        items = []
        for name in sorted(node.keys()):
            val = node[name]
            if isinstance(val, dict):
                items.append({"path": name, "mode": "040000", "type": "tree", "sha": make_tree(val)})
            else:
                _, sha = val
                items.append({"path": name, "mode": "100644", "type": "blob", "sha": sha})
        resp = gh_api("POST", f"repos/{REPO}/git/trees", {"tree": items})
        return resp["sha"]

    return make_tree(tree)


def main() -> None:
    print("Collecting files…")
    entries = collect_files()
    print(f"{len(entries)} files")

    print("Creating tree…")
    tree_sha = build_tree(entries)

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    author = {
        "name": "ilikemacos",
        "email": "287112028+ilikemacos@users.noreply.github.com",
        "date": now,
    }
    message = """cs.AI 2.5.1 — open source release

macOS Agents app, Terminal CLI, Lab, and API source.
Chromium browser rail, chat folders with drag-and-drop, multi-select bulk move."""

    print("Creating commit…")
    commit = gh_api(
        "POST",
        f"repos/{REPO}/git/commits",
        {
            "message": message,
            "tree": tree_sha,
            "author": author,
            "committer": author,
        },
    )
    commit_sha = commit["sha"]
    print(f"Commit: {commit_sha}")

    print("Updating main (force)…")
    gh_api(
        "PATCH",
        f"repos/{REPO}/git/refs/heads/main",
        {"sha": commit_sha, "force": True},
    )
    print("Done.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
