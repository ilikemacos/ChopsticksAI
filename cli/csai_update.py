"""Self-update and version info for the cs.AI CLI."""

from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path

VERSION = "3.3.10"
MANIFEST_URL = os.environ.get(
    "CS_AI_CLI_MANIFEST",
    "https://chopstickshq.com/chopsticks-ai/cli-version.json",
)
CLI_BASE = os.environ.get(
    "CS_AI_CLI_BASE",
    "https://chopstickshq.com/chopsticks-ai/cli",
)

DEFAULT_FILES = [
    "csai",
    "csai.py",
    "csai_tui.py",
    "csai_client.py",
    "csai_update.py",
    "csai.cmd",
]


def install_dir() -> Path:
    return Path(__file__).resolve().parent


def _display_version(v: str) -> str:
    s = v.strip().lstrip("vV")
    if s.lower().startswith("cs.ai"):
        s = s[5:].lstrip(" ")
    if s.lower().startswith("csai"):
        s = s[4:].lstrip(" -")
    return s.strip()


def _version_numbers(v: str) -> list[int]:
    s = _display_version(v)
    nums = re.findall(r"\d+", s)
    return [int(n) for n in nums]


def _version_suffix(v: str) -> str:
    s = _display_version(v)
    past = False
    out: list[str] = []
    for ch in s:
        if ch.isdigit():
            past = True
        elif past:
            out.append(ch)
    return "".join(out).lower()


def is_newer(remote: str, current: str) -> bool:
    r = _display_version(remote)
    c = _display_version(current)
    if r == c:
        return False
    rn, cn = _version_numbers(r), _version_numbers(c)
    count = max(len(rn), len(cn))
    for i in range(count):
        rv = rn[i] if i < len(rn) else 0
        cv = cn[i] if i < len(cn) else 0
        if rv != cv:
            return rv > cv
    rs, cs = _version_suffix(r), _version_suffix(c)
    if rs == cs:
        return False
    if not cs and rs:
        return True
    if not rs and cs:
        return False
    return rs > cs


def _fetch_json(url: str, timeout: float = 30.0) -> dict:
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode("utf-8")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise RuntimeError("Invalid manifest JSON")
    return data


def _download(url: str, dest: Path, timeout: float = 60.0) -> None:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = resp.read()
    dest.write_bytes(data)


def fetch_manifest() -> dict:
    return _fetch_json(MANIFEST_URL)


def cmd_version() -> int:
    dest = install_dir()
    print(f"cs.AI CLI {VERSION}")
    print(f"Install: {dest}")
    try:
        manifest = fetch_manifest()
        latest = str(manifest.get("latest") or "")
        if latest:
            if is_newer(latest, VERSION):
                print(f"Update available: {latest}  (run: csai update)")
            else:
                print(f"Latest: {latest}")
    except (OSError, urllib.error.URLError, json.JSONDecodeError, RuntimeError) as exc:
        print(f"Could not check for updates: {exc}")
    return 0


def cmd_update(*, check_only: bool = False, force: bool = False) -> int:
    try:
        manifest = fetch_manifest()
    except (OSError, urllib.error.URLError, json.JSONDecodeError, RuntimeError) as exc:
        print(f"Update check failed: {exc}", file=__import__("sys").stderr)
        return 1

    latest = str(manifest.get("latest") or VERSION)
    base = str(manifest.get("base") or CLI_BASE).rstrip("/")
    files = manifest.get("files") or DEFAULT_FILES
    if not isinstance(files, list):
        files = DEFAULT_FILES

    if not force and not is_newer(latest, VERSION):
        print(f"cs.AI CLI {VERSION} is up to date.")
        return 0

    if check_only:
        print(f"Update available: {latest} (you have {VERSION})")
        print("Run: csai update")
        return 0

    dest = install_dir()
    print(f"Updating cs.AI CLI {VERSION} → {latest}…")
    for name in files:
        if not isinstance(name, str) or not name.strip():
            continue
        name = name.strip()
        if "/" in name or name.startswith("."):
            continue
        url = f"{base}/{name}"
        target = dest / name
        try:
            _download(url, target)
        except (OSError, urllib.error.URLError) as exc:
            print(f"Failed to download {name}: {exc}", file=__import__("sys").stderr)
            return 1
        if name in ("csai", "csai.py"):
            try:
                target.chmod(0o755)
            except OSError:
                pass
        print(f"  ✓ {name}")

    print(f"✅ Updated to cs.AI CLI {latest}")
    return 0
