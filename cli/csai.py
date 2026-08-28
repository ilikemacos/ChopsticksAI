#!/usr/bin/python3
"""cs.AI terminal CLI — interactive agent chat from your shell.

Usage:
  csai                     Full-screen terminal UI (default)
  csai --plain             Simple line-by-line prompt
  csai ask "question"      One-shot question
  csai login               Sign in (chopstickshq.com account)
  csai logout              Clear saved session
  csai usage               Show allowance / plan
  csai search "query"      Mozilla search via cs.AI
  csai ask "question"      One-shot (--json / --quiet for scripts)
  csai update              Update CLI from chopstickshq.com
  csai version             Show version and update status

Install:
  ./cli/install.sh
  curl -fsSL https://chopstickshq.com/chopsticks-ai/install-csai-cli.sh | bash
  irm https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.ps1 | iex
"""

from __future__ import annotations

import argparse
import getpass
import json
import os
try:
    import readline
except ImportError:
    readline = None  # type: ignore[assignment]
import sys
import textwrap
from pathlib import Path

CLI_DIR = Path(__file__).resolve().parent
if str(CLI_DIR) not in sys.path:
    sys.path.insert(0, str(CLI_DIR))

from csai_client import CsAIClient, format_usage, progress_bar  # noqa: E402
from csai_update import VERSION, cmd_update, cmd_version  # noqa: E402

try:
    from csai_tui import run_tui  # noqa: E402
except ImportError:
    run_tui = None  # type: ignore[misc, assignment]

# VERSION imported from csai_update
BANNER = f"""\
┌ cs.AI {VERSION} ─ chopsticksAI CLI ─────────────────────────
│ chopstickshq.com · allowance resets every 5h
└ type /help for commands · /exit to quit
"""

DIM = "\033[2m"
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
RESET = "\033[0m"


def supports_color() -> bool:
    if os.environ.get("NO_COLOR"):
        return False
    return sys.stdout.isatty()


def c(text: str, code: str) -> str:
    if not supports_color():
        return text
    return f"{code}{text}{RESET}"


def print_banner(client: CsAIClient) -> None:
    print(c(BANNER, CYAN), end="")
    if client.signed_in:
        print(c(f"Signed in as {client.email}", GREEN))
    else:
        print(c("Guest mode · /login for synced account & higher tiers", DIM))
    print(c(f"Tier: {client.tier}", DIM))
    search_state = "on" if client.web_search else "off"
    keys_note = f" · {len(client.unlock_keys)} unlock key(s)" if client.unlock_keys else ""
    print(c(f"Auto search: {search_state}{keys_note}", DIM))
    print()


def wrap_print(text: str, indent: str = "") -> None:
    width = max(40, min(100, (os.get_terminal_size().columns if sys.stdout.isatty() else 80) - len(indent)))
    for para in text.split("\n"):
        if not para.strip():
            print()
            continue
        print(textwrap.fill(para, width=width, initial_indent=indent, subsequent_indent=indent))


def print_reply(body: dict, indent: str = "") -> None:
    mode = body.get("mode") or "live"
    reply = body.get("reply") or body.get("error") or body.get("message")
    if mode in ("cooldown", "limited", "auth_required", "error", "unconfigured"):
        msg = reply or f"Request blocked ({mode})"
        print(c(str(msg), YELLOW if mode != "error" else RED))
        return
    if not reply:
        print(c("(empty reply)", DIM))
        return
    wrap_print(str(reply), indent=indent)

    files = body.get("files") or []
    for item in files:
        if not isinstance(item, dict):
            continue
        name = item.get("name") or "file"
        content = item.get("content") or ""
        lang = item.get("language") or "text"
        print()
        print(c(f"── {name} ({lang}) ──", DIM))
        print(content.rstrip())
        print(c("── end ──", DIM))

    sources = body.get("sources") or []
    if sources:
        print()
        print(c("Sources:", DIM))
        for src in sources[:5]:
            if not isinstance(src, dict):
                continue
            title = src.get("title") or src.get("url") or "link"
            url = src.get("url") or ""
            line = f"  · {title}"
            if url:
                line += f"  {url}"
            print(c(line, DIM))

    budget = body.get("budget") or body.get("usage")
    if isinstance(budget, dict) and budget.get("limit"):
        used = int(budget.get("used", 0))
        limit = int(budget.get("limit", 0))
        bar = progress_bar(used, limit, width=20)
        print()
        print(c(f"Usage: {used:,} / {limit:,} tokens", DIM))
        if bar:
            print(c(f"        {bar}", DIM))


def cmd_login(client: CsAIClient, email: str | None) -> int:
    if not email:
        email = input("Email: ").strip()
    if not email:
        print(c("Email required.", RED), file=sys.stderr)
        return 1
    try:
        password = getpass.getpass("Password: ")
        body = client.sign_in(email, password)
        if body.get("needsCode"):
            code = input("Email code: ").strip()
            client.verify_login(email, password, code, str(body.get("loginToken") or ""))
    except RuntimeError as exc:
        print(c(str(exc), RED), file=sys.stderr)
        return 1
    print(c(f"Signed in as {client.email}", GREEN))
    return 0


def body_to_json(body: dict) -> str:
    payload = {
        "mode": body.get("mode"),
        "reply": body.get("reply"),
        "error": body.get("error") or body.get("message"),
        "sources": body.get("sources"),
        "files": body.get("files"),
        "usage": body.get("usage") or body.get("budget"),
    }
    return json.dumps(payload, ensure_ascii=False)


def cmd_usage(client: CsAIClient, *, as_json: bool = False) -> int:
    body = client.usage()
    if as_json:
        print(json.dumps(body, ensure_ascii=False))
        return 0
    text = format_usage(body)
    for line in text.splitlines():
        if line.startswith("Cooldown") or "almost full" in line or "used " in line.lower():
            print(c(line, YELLOW))
        elif line.startswith("Plan:"):
            print(c(line, BOLD))
        elif line.startswith("["):
            print(c(line, CYAN))
        else:
            print(line)
    return 0


def cmd_search(client: CsAIClient, query: str) -> int:
    body = client.search(query)
    results = body.get("results") or body.get("sources") or []
    if not results:
        print_reply(body)
        return 0 if body.get("reply") else 1
    for idx, item in enumerate(results[:8], 1):
        if not isinstance(item, dict):
            continue
        title = item.get("title") or "Result"
        url = item.get("url") or ""
        snippet = (item.get("snippet") or "").strip()
        print(c(f"{idx}. {title}", BOLD))
        if url:
            print(c(f"   {url}", CYAN))
        if snippet:
            wrap_print(snippet, indent="   ")
        print()
    return 0


def load_file_attachments(paths: list[str]) -> list[dict]:
    out = []
    for raw in paths or []:
        p = Path(raw).expanduser()
        if not p.is_file():
            print(c(f"Not a file: {raw}", YELLOW), file=sys.stderr)
            continue
        size = p.stat().st_size
        item = {
            "name": p.name,
            "mime": "text/plain",
            "size": size,
            "path": str(p),
        }
        if size <= 512 * 1024:
            try:
                item["text"] = p.read_text(encoding="utf-8", errors="replace")[:200000]
            except OSError:
                pass
        out.append(item)
    return out


def cmd_ask(
    client: CsAIClient,
    question: str,
    tier: str | None,
    *,
    as_json: bool = False,
    quiet: bool = False,
    no_search: bool = False,
    files: list[str] | None = None,
) -> int:
    messages = [{"role": "user", "content": question}]
    attachments = load_file_attachments(files or [])
    if not quiet and not as_json:
        print(c("Thinking…", DIM))
    body = client.chat(
        messages,
        tier=tier,
        disable_search=no_search or None,
        attachments=attachments or None,
    )
    if as_json:
        print(body_to_json(body))
        return 0 if body.get("reply") and body.get("mode") not in ("error",) else 1
    if quiet:
        reply = body.get("reply") or body.get("error") or body.get("message") or ""
        if reply:
            print(str(reply).strip())
        return 0 if body.get("reply") and body.get("mode") not in ("error",) else 1
    print()
    print_reply(body)
    return 0 if body.get("reply") and body.get("mode") not in ("error",) else 1


def cmd_keys(client: CsAIClient, arg: str) -> int:
    parts = arg.split(maxsplit=1)
    sub = parts[0].lower() if parts else ""
    rest = parts[1].strip() if len(parts) > 1 else ""
    if sub in ("", "list"):
        n = len(client.unlock_keys)
        if n:
            print(f"{n} unlock key(s) saved locally (~/.config/chopsticks-ai/unlock-keys.json)")
        else:
            print("No unlock keys saved. Add with: /keys add <key>")
        return 0
    if sub == "add":
        if not rest:
            print(c("Usage: /keys add <unlock-key>", YELLOW))
            return 1
        if client.add_unlock_key(rest):
            print(c("Unlock key saved.", GREEN))
            return 0
        print(c("Key not added (empty or duplicate).", YELLOW))
        return 1
    if sub == "clear":
        client.clear_unlock_keys()
        print(c("Unlock keys cleared.", DIM))
        return 0
    print(c("Usage: /keys [list|add <key>|clear]", YELLOW))
    return 1


def run_repl(client: CsAIClient, tier: str | None) -> int:
    history = Path.home() / ".local" / "share" / "chopsticks-ai" / "history"
    history.parent.mkdir(parents=True, exist_ok=True)
    try:
        if readline is not None:
            readline.read_history_file(str(history))
    except OSError:
        pass

    print_banner(client)
    messages: list[dict[str, str]] = []

    while True:
        try:
            line = input(c("csai › ", BOLD)).strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not line:
            continue

        try:
            if readline is not None:
                readline.write_history_file(str(history))
        except OSError:
            pass

        if line.startswith("/"):
            parts = line[1:].split(maxsplit=1)
            cmd = parts[0].lower()
            arg = parts[1].strip() if len(parts) > 1 else ""

            if cmd in ("exit", "quit", "q"):
                break
            if cmd == "help":
                print(textwrap.dedent("""\
                Commands
                  /help              This help
                  /clear             Clear conversation
                  /login [email]     Sign in to chopstickshq.com
                  /logout            Sign out
                  /usage             Token allowance (resets every 5h)
                  /tier [name]       Show or set plate (rice, tamago, hibachi, wagyu a1–a5, chopcode)
                  /keys [add|clear]  Unlock keys for higher tiers
                  /search on|off     Toggle auto web search in chat
                  /search <query>    Standalone web search
                  /update            Update CLI from chopstickshq.com
                  /version           Show CLI version
                  /exit              Quit

                Headless
                  csai ask "…" --plate chopcode
                  csai ask "…" --file app.py
                  csai ask "…" --json
                  csai --plain
                """))
                continue
            if cmd == "clear":
                messages.clear()
                print(c("Conversation cleared.", DIM))
                continue
            if cmd == "login":
                cmd_login(client, arg or None)
                continue
            if cmd == "logout":
                client.sign_out()
                print(c("Signed out.", DIM))
                continue
            if cmd == "usage":
                cmd_usage(client)
                continue
            if cmd == "keys":
                cmd_keys(client, arg)
                continue
            if cmd == "tier":
                if arg:
                    client.set_tier(arg)
                    print(c(f"Plate set to {client.tier}", GREEN))
                else:
                    print(f"Current plate: {client.tier}")
                continue
            if cmd == "search":
                if arg.lower() in ("on", "off"):
                    client.set_web_search(arg.lower() == "on")
                    state = "on" if client.web_search else "off"
                    print(c(f"Auto web search: {state}", GREEN))
                    continue
                if not arg:
                    state = "on" if client.web_search else "off"
                    print(c(f"Auto web search is {state}. Use /search on|off or /search <query>", YELLOW))
                    continue
                cmd_search(client, arg)
                continue
            if cmd == "update":
                cmd_update()
                continue
            if cmd == "version":
                cmd_version()
                continue
            print(c(f"Unknown command /{cmd}. Try /help", YELLOW))
            continue

        messages.append({"role": "user", "content": line})
        print(c("Thinking…", DIM), flush=True)
        body = client.chat(messages, tier=tier)
        reply = body.get("reply") or body.get("error") or body.get("message") or ""
        if reply and body.get("mode") not in ("error", "auth_required"):
            messages.append({"role": "assistant", "content": str(reply)})
        print()
        print_reply(body)
        print()

    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="csai",
        description="cs.AI terminal CLI — chopsticksAI agent chat",
    )
    parser.add_argument("--version", action="version", version=f"cs.AI {VERSION}")
    parser.add_argument("--tier", "--plate", dest="tier", default=None, help="Plate (rice, tamago, hibachi, wagyua1–wagyua5, chopcode)")
    parser.add_argument(
        "--plain",
        action="store_true",
        help="Simple line prompt instead of full-screen TUI",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="JSON output (ask, usage)",
    )
    parser.add_argument(
        "--quiet",
        "-q",
        action="store_true",
        help="Reply text only (ask)",
    )
    parser.add_argument(
        "--no-search",
        action="store_true",
        help="Disable web search for this request (ask)",
    )

    sub = parser.add_subparsers(dest="command")

    login_p = sub.add_parser("login", help="Sign in with email and password")
    login_p.add_argument("email", nargs="?", default=None, help="Email address")
    sub.add_parser("logout", help="Sign out")
    sub.add_parser("usage", help="Show token allowance")

    ask_p = sub.add_parser("ask", help="Ask one question and exit")
    ask_p.add_argument("question", nargs="+", help="Your question")
    ask_p.add_argument("--json", action="store_true", help="JSON output")
    ask_p.add_argument("--quiet", "-q", action="store_true", help="Reply text only")
    ask_p.add_argument("--no-search", action="store_true", help="Disable web search")
    ask_p.add_argument("--file", "-f", action="append", dest="files", default=[], help="Attach a file (repeatable)")

    search_p = sub.add_parser("search", help="Mozilla search")
    search_p.add_argument("query", nargs="+", help="Search query")

    update_p = sub.add_parser("update", help="Update CLI from chopstickshq.com")
    update_p.add_argument(
        "--check",
        action="store_true",
        help="Only check for updates",
    )
    update_p.add_argument(
        "--force",
        action="store_true",
        help="Re-download even if version matches",
    )

    sub.add_parser("version", help="Show CLI version and update status")
    sub.add_parser("chat", help="Interactive session (default)")

    return parser


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    parser = build_parser()
    args = parser.parse_args(argv)
    client = CsAIClient()
    if args.tier:
        client.set_tier(args.tier)

    cmd = args.command
    if cmd == "login":
        return cmd_login(client, getattr(args, "email", None))
    if cmd == "logout":
        client.sign_out()
        print("Signed out.")
        return 0
    if cmd == "usage":
        return cmd_usage(client, as_json=getattr(args, "json", False))
    if cmd == "ask":
        question = " ".join(args.question).strip()
        return cmd_ask(
            client,
            question,
            args.tier,
            as_json=getattr(args, "json", False),
            quiet=getattr(args, "quiet", False),
            no_search=getattr(args, "no_search", False),
            files=getattr(args, "files", None),
        )
    if cmd == "search":
        query = " ".join(args.query).strip()
        return cmd_search(client, query)
    if cmd == "update":
        return cmd_update(
            check_only=getattr(args, "check", False),
            force=getattr(args, "force", False),
        )
    if cmd == "version":
        return cmd_version()

    use_plain = (
        args.plain
        or os.environ.get("CS_AI_PLAIN") == "1"
        or not sys.stdout.isatty()
        or (sys.platform == "win32" and run_tui is None)
    )
    if not use_plain and run_tui is not None:
        return run_tui(client, args.tier)
    return run_repl(client, args.tier)


if __name__ == "__main__":
    raise SystemExit(main())
