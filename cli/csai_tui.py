"""Full-screen terminal UI for cs.AI (Grok Build / Claude Code style)."""

from __future__ import annotations

import curses
import textwrap
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from csai_client import CsAIClient

from csai_update import VERSION  # noqa: E402

MIN_COLS = 52
MIN_ROWS = 14


@dataclass
class Block:
    role: str
    text: str
    meta: str = ""


@dataclass
class Pending:
    thread: threading.Thread
    started: float
    error: str | None = None
    body: dict[str, Any] | None = None
    done: bool = False


def _cwd_label() -> str:
    try:
        return str(Path.cwd().name) or "~"
    except OSError:
        return "~"


def _wrap(text: str, width: int) -> list[str]:
    if width < 8:
        return [text[: max(1, width)]]
    out: list[str] = []
    for para in text.split("\n"):
        if not para.strip():
            out.append("")
            continue
        out.extend(
            textwrap.wrap(
                para,
                width=width,
                break_long_words=False,
                break_on_hyphens=False,
            )
            or [""]
        )
    return out or [""]


def _safe_addstr(win: curses.window, y: int, x: int, text: str, attr: int = 0) -> None:
    if y < 0 or x < 0:
        return
    try:
        max_y, max_x = win.getmaxyx()
    except curses.error:
        return
    if y >= max_y or x >= max_x:
        return
    width = max_x - x - 1
    if width <= 0:
        return
    try:
        win.addstr(y, x, text[:width], attr)
    except curses.error:
        pass


def _hline(win: curses.window, y: int, x: int, w: int, char: str = "─", attr: int = 0) -> None:
    if w <= 0:
        return
    _safe_addstr(win, y, x, char * max(1, w - 1), attr)


class CsAITui:
    def __init__(self, client: CsAIClient, tier: str | None) -> None:
        self.client = client
        self.tier = tier or client.tier
        self.messages: list[dict[str, str]] = []
        self.blocks: list[Block] = []
        self.input_buf = ""
        self.scroll = 0
        self.follow = True
        self.pending: Pending | None = None
        self.status = "Ready"
        self.spinner_i = 0
        self.login_step: str | None = None
        self.login_email = ""
        self.quit = False
        self.usage_hint = ""

    def push_system(self, text: str) -> None:
        self.blocks.append(Block("system", text))

    def push_user(self, text: str) -> None:
        self.messages.append({"role": "user", "content": text})
        self.blocks.append(Block("user", text))

    def push_assistant(self, body: dict[str, Any]) -> None:
        mode = body.get("mode") or "live"
        reply = body.get("reply") or body.get("error") or body.get("message") or ""
        if mode in ("cooldown", "limited", "auth_required", "error", "unconfigured"):
            msg = str(reply or f"Blocked ({mode})")
            self.blocks.append(Block("system", msg))
            return
        if not reply:
            self.blocks.append(Block("system", "(empty reply)"))
            return
        self.messages.append({"role": "assistant", "content": str(reply)})
        meta_parts: list[str] = []
        sources = body.get("sources") or []
        if sources:
            meta_parts.append(f"{len(sources)} source(s)")
        budget = body.get("budget") or body.get("usage")
        if isinstance(budget, dict) and budget.get("limit"):
            used = int(budget.get("used", 0))
            limit = int(budget.get("limit", 0))
            meta_parts.append(f"{used:,}/{limit:,} tok")
            self.usage_hint = f"{used:,}/{limit:,}"
        files = body.get("files") or []
        if files:
            meta_parts.append(f"{len(files)} file(s)")
        self.blocks.append(Block("assistant", str(reply), " · ".join(meta_parts)))

        for item in files:
            if not isinstance(item, dict):
                continue
            name = item.get("name") or "file"
            content = (item.get("content") or "").rstrip()
            lang = item.get("language") or "text"
            self.blocks.append(Block("code", content, f"{name} ({lang})"))

        if sources:
            lines = []
            for src in sources[:4]:
                if not isinstance(src, dict):
                    continue
                title = src.get("title") or src.get("url") or "link"
                url = src.get("url") or ""
                lines.append(f"· {title}" + (f"  {url}" if url else ""))
            if lines:
                self.blocks.append(Block("sources", "\n".join(lines)))

    def start_request(self) -> None:
        if self.pending:
            return
        payload_messages = list(self.messages)

        def worker() -> None:
            try:
                body = self.client.chat(payload_messages, tier=self.tier)
            except Exception as exc:  # noqa: BLE001
                if self.pending:
                    self.pending.error = str(exc)
                    self.pending.done = True
                return
            if self.pending:
                self.pending.body = body
                self.pending.done = True

        t = threading.Thread(target=worker, daemon=True)
        self.pending = Pending(thread=t, started=time.time())
        t.start()
        self.status = "Thinking"

    def finish_pending(self) -> None:
        if not self.pending or not self.pending.done:
            return
        if self.pending.error:
            self.push_system(f"Error: {self.pending.error}")
        elif self.pending.body:
            self.push_assistant(self.pending.body)
        self.pending = None
        self.status = "Ready"
        self.follow = True
        self.scroll = 0

    def handle_slash(self, line: str) -> bool:
        parts = line[1:].split(maxsplit=1)
        cmd = parts[0].lower()
        arg = parts[1].strip() if len(parts) > 1 else ""

        if cmd in ("exit", "quit", "q"):
            self.quit = True
            return True
        if cmd == "help":
            self.push_system(
                "Commands: /help /clear /login /logout /usage /tier [name] /search <q> /update /version /exit\n"
                "Keys: Enter send · PgUp/PgDn scroll · Ctrl+L clear · Ctrl+D quit"
            )
            return True
        if cmd == "clear":
            self.messages.clear()
            self.blocks.clear()
            self.push_system("Conversation cleared.")
            return True
        if cmd == "login":
            self.login_step = "email"
            self.login_email = ""
            self.input_buf = ""
            self.status = "Login — email"
            return True
        if cmd == "logout":
            self.client.sign_out()
            self.push_system("Signed out.")
            return True
        if cmd == "usage":
            body = self.client.usage()
            usage = body.get("usage") or body
            tier = usage.get("tier") or {}
            label = tier.get("label") or tier.get("id") or "Free"
            used = int(usage.get("used", body.get("used", 0)))
            limit = int(usage.get("limit", body.get("limit", 0)))
            msg = f"Plan: {label}\nTokens: {used:,}" + (f" / {limit:,}" if limit else "")
            if body.get("cooldown"):
                msg += "\nCooldown active."
            self.push_system(msg)
            return True
        if cmd == "tier":
            if arg:
                self.tier = arg.lower()
                self.client.tier = self.tier
                self.push_system(f"Tier set to {self.tier}")
            else:
                self.push_system(f"Current tier: {self.tier}")
            return True
        if cmd == "search":
            if not arg:
                self.push_system("Usage: /search your query")
                return True
            self.status = "Searching"
            body = self.client.search(arg)
            self.status = "Ready"
            results = body.get("results") or body.get("sources") or []
            if results:
                lines = []
                for idx, item in enumerate(results[:6], 1):
                    if not isinstance(item, dict):
                        continue
                    title = item.get("title") or "Result"
                    url = item.get("url") or ""
                    lines.append(f"{idx}. {title}" + (f"\n   {url}" if url else ""))
                self.push_system("\n".join(lines))
            else:
                self.push_assistant(body)
            return True
        if cmd == "update":
            from csai_update import cmd_update

            self.status = "Updating…"
            code = cmd_update()
            self.status = "Ready" if code == 0 else "Update failed"
            self.push_system(
                "CLI updated — quit and run csai again to load the new version."
                if code == 0
                else "Update failed — try: csai update"
            )
            return True
        if cmd == "version":
            from csai_update import install_dir

            self.push_system(f"cs.AI CLI {VERSION}\nInstall: {install_dir()}")
            return True
        self.push_system(f"Unknown /{cmd} — try /help")
        return True

    def submit(self) -> None:
        line = self.input_buf.strip()
        self.input_buf = ""
        if not line:
            return

        if self.login_step == "email":
            self.login_email = line
            self.login_step = "password"
            self.status = "Login — password (hidden)"
            return

        if self.login_step == "password":
            self.login_step = None
            self.status = "Signing in…"
            try:
                self.client.sign_in(self.login_email, line)
                self.push_system(f"Signed in as {self.client.email}")
            except RuntimeError as exc:
                self.push_system(f"Login failed: {exc}")
            self.status = "Ready"
            return

        if line.startswith("/"):
            self.handle_slash(line)
            return

        if self.pending:
            self.push_system("Wait for the current reply…")
            return

        self.push_user(line)
        self.start_request()

    def _render_lines(self, width: int) -> list[tuple[str, str, int]]:
        """Return (kind, line, attr_key) rows for scrollback."""
        rows: list[tuple[str, str, int]] = []
        inner = max(20, width - 4)
        for block in self.blocks:
            if block.role == "user":
                rows.append(("label", "You", "user"))
            elif block.role == "assistant":
                rows.append(("label", "cs.AI", "assistant"))
            elif block.role == "code":
                rows.append(("label", block.meta or "code", "code"))
            elif block.role == "sources":
                rows.append(("label", "Sources", "dim"))
            else:
                rows.append(("label", "·", "dim"))

            key = block.role if block.role in ("user", "assistant", "code") else "dim"
            for ln in _wrap(block.text, inner):
                rows.append(("text", ln, key))
            if block.meta and block.role == "assistant":
                rows.append(("meta", block.meta, "dim"))
            rows.append(("gap", "", "dim"))
        return rows

    def draw(self, stdscr: curses.window, pairs: dict[str, int]) -> None:
        self.finish_pending()
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        if h < MIN_ROWS or w < MIN_COLS:
            _safe_addstr(stdscr, 0, 0, f"Terminal too small — need {MIN_COLS}×{MIN_ROWS}", pairs["dim"])
            stdscr.refresh()
            return

        auth = self.client.email if self.client.signed_in else "guest"
        tier = self.tier
        cwd = _cwd_label()
        left = f" cs.AI {VERSION} "
        mid = f" {tier} · {auth} · {cwd} "
        usage = f" {self.usage_hint} " if self.usage_hint else ""
        header = left + mid
        if len(header) + len(usage) > w - 2:
            header = header[: w - len(usage) - 4] + "…"
        _safe_addstr(stdscr, 0, 0, "┌", pairs["border"])
        _safe_addstr(stdscr, 0, 1, header, pairs["header"] | curses.A_BOLD)
        fill = max(0, w - 2 - len(header) - len(usage))
        _safe_addstr(stdscr, 0, 1 + len(header), "─" * fill, pairs["border"])
        if usage:
            _safe_addstr(stdscr, 0, w - 1 - len(usage), usage, pairs["dim"])
        _safe_addstr(stdscr, 0, w - 2, "┐", pairs["border"])

        input_h = 3
        status_y = h - input_h - 1
        chat_y = 1
        chat_h = max(1, status_y - chat_y)

        rows = self._render_lines(w)
        total = len(rows)
        visible = max(1, chat_h - 1)
        if self.follow:
            self.scroll = 0
        max_scroll = max(0, total - visible)
        self.scroll = max(0, min(self.scroll, max_scroll))
        start = max(0, total - visible - self.scroll)

        for i in range(visible):
            row_idx = start + i
            if row_idx >= total:
                break
            kind, text, key = rows[row_idx]
            y = chat_y + i
            attr = pairs.get(key, pairs["text"])
            if kind == "label":
                attr |= curses.A_BOLD
            elif kind == "meta":
                attr = pairs["dim"]
            elif kind == "gap":
                continue
            _safe_addstr(stdscr, y, 2, text, attr)

        _hline(stdscr, status_y, 0, w, "─", pairs["border"])
        spin = ""
        if self.pending and not self.pending.done:
            frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
            spin = frames[self.spinner_i % len(frames)] + " "
            self.spinner_i += 1
        status_text = f" {spin}{self.status} "
        _safe_addstr(stdscr, status_y, 1, status_text, pairs["accent"])
        hint = "PgUp/PgDn scroll · /help"
        _safe_addstr(stdscr, status_y, max(2, w - len(hint) - 2), hint, pairs["dim"])

        prompt_y = status_y + 1
        _safe_addstr(stdscr, prompt_y, 0, "│", pairs["border"])
        prompt = "› "
        if self.login_step == "password":
            shown = "•" * len(self.input_buf)
        else:
            shown = self.input_buf
        line = prompt + shown
        _safe_addstr(stdscr, prompt_y, 2, line[: max(1, w - 4)], pairs["input"] | curses.A_BOLD)
        if self.login_step != "password":
            cx = min(w - 3, 2 + len(line))
            try:
                stdscr.move(prompt_y, cx)
            except curses.error:
                pass
        _safe_addstr(stdscr, prompt_y, w - 2, "│", pairs["border"])

        foot = " Ask cs.AI anything — /help · Ctrl+D exit "
        _safe_addstr(stdscr, h - 1, 0, "└", pairs["border"])
        _safe_addstr(stdscr, h - 1, 1, foot[: max(0, w - 4)], pairs["dim"])
        _safe_addstr(stdscr, h - 1, w - 2, "┘", pairs["border"])

        stdscr.refresh()

    def handle_key(self, ch: int) -> None:
        if ch == curses.KEY_RESIZE:
            return
        if ch in (4, 26):  # Ctrl+D, Ctrl+Z-ish quit
            self.quit = True
            return
        if ch == 12:  # Ctrl+L
            self.messages.clear()
            self.blocks.clear()
            self.push_system("Conversation cleared.")
            return
        if ch in (curses.KEY_PPAGE,):
            self.follow = False
            self.scroll = min(self.scroll + 5, 99999)
            return
        if ch in (curses.KEY_NPAGE,):
            self.follow = False
            self.scroll = max(0, self.scroll - 5)
            if self.scroll == 0:
                self.follow = True
            return
        if ch in (10, 13, curses.KEY_ENTER):
            self.submit()
            return
        if ch in (curses.KEY_BACKSPACE, 127, 8):
            self.input_buf = self.input_buf[:-1]
            return
        if ch == 27:
            if self.login_step:
                self.login_step = None
                self.status = "Ready"
                self.input_buf = ""
            else:
                self.quit = True
            return
        if 32 <= ch <= 126:
            if self.login_step == "password" and len(self.input_buf) > 128:
                return
            if len(self.input_buf) < 4000:
                self.input_buf += chr(ch)


def run_tui(client: CsAIClient, tier: str | None = None) -> int:
    app = CsAITui(client, tier)
    app.push_system(
        "cs.AI agent ready — full-screen terminal UI.\n"
        "Same live model as the macOS app. Type a question or /help."
    )

    def _main(stdscr: curses.window) -> int:
        curses.curs_set(1)
        stdscr.keypad(True)
        if curses.has_colors():
            curses.start_color()
            curses.use_default_colors()
            curses.init_pair(1, curses.COLOR_CYAN, -1)
            curses.init_pair(2, curses.COLOR_GREEN, -1)
            curses.init_pair(3, curses.COLOR_WHITE, -1)
            curses.init_pair(4, curses.COLOR_BLACK, -1)
            curses.init_pair(5, curses.COLOR_YELLOW, -1)
            curses.init_pair(6, curses.COLOR_BLUE, -1)
        pairs = {
            "header": curses.color_pair(1),
            "assistant": curses.color_pair(2),
            "user": curses.color_pair(3),
            "text": curses.color_pair(3),
            "dim": curses.A_DIM,
            "border": curses.A_DIM,
            "accent": curses.color_pair(5),
            "input": curses.color_pair(1),
            "code": curses.color_pair(6),
        }

        stdscr.timeout(120)
        while not app.quit:
            app.draw(stdscr, pairs)
            try:
                ch = stdscr.getch()
            except curses.error:
                ch = -1
            if ch == -1:
                continue
            app.handle_key(ch)
        return 0

    try:
        return curses.wrapper(_main)
    except curses.error:
        return 1
