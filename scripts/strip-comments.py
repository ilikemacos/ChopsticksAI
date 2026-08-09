#!/usr/bin/env python3
"""Remove comments from source files (string-aware; JS-safe for regex literals)."""
from __future__ import annotations

import re
import sys
from pathlib import Path


def strip_c_like(text: str, strip_line_comments: bool = True) -> str:
    out: list[str] = []
    i = 0
    n = len(text)
    quote: str | None = None
    while i < n:
        ch = text[i]
        if quote:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in ("'", '"', "`"):
            quote = ch
            out.append(ch)
            i += 1
            continue
        if strip_line_comments and text.startswith("//", i):
            while i < n and text[i] != "\n":
                i += 1
            continue
        if text.startswith("/*", i):
            i += 2
            while i < n - 1 and not text.startswith("*/", i):
                i += 1
            i += 2
            continue
        out.append(ch)
        i += 1
    return re.sub(r"\n{3,}", "\n\n", "".join(out))


def strip_js(text: str) -> str:
    text = strip_c_like(text, strip_line_comments=False)
    lines: list[str] = []
    for line in text.splitlines(keepends=True):
        if re.match(r"^\s*//", line):
            continue
        lines.append(line)
    return re.sub(r"\n{3,}", "\n\n", "".join(lines))


def strip_shell(text: str) -> str:
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    for idx, line in enumerate(lines):
        if idx == 0 and line.startswith("#!"):
            out.append(line)
            continue
        if line.lstrip().startswith("#"):
            continue
        out.append(line)
    return "".join(out)


def strip_html(text: str) -> str:
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)

    def strip_script(m: re.Match[str]) -> str:
        return m.group(1) + strip_js(m.group(2)) + m.group(3)

    text = re.sub(
        r"(<script\b[^>]*>)([\s\S]*?)(</script>)",
        strip_script,
        text,
        flags=re.IGNORECASE,
    )
    return re.sub(r"\n{3,}", "\n\n", text)


def process(path: Path) -> bool:
    raw = path.read_text(encoding="utf-8")
    suffix = path.suffix.lower()
    if suffix == ".js" or suffix == ".mjs":
        cleaned = strip_js(raw)
    elif suffix in {".swift", ".ts"}:
        cleaned = strip_c_like(raw)
    elif suffix == ".sh":
        cleaned = strip_shell(raw)
    elif suffix in {".html", ".htm"}:
        cleaned = strip_html(raw)
    else:
        return False
    if cleaned != raw:
        path.write_text(cleaned, encoding="utf-8")
        return True
    return False


def main() -> int:
    changed = 0
    for arg in sys.argv[1:]:
        p = Path(arg)
        if p.is_dir():
            for f in p.rglob("*"):
                if f.suffix.lower() in {".swift", ".js", ".ts", ".mjs", ".sh", ".html", ".htm"}:
                    if process(f):
                        print(f"stripped {f}")
                        changed += 1
        elif p.is_file() and process(p):
            print(f"stripped {p}")
            changed += 1
    print(f"done — {changed} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
