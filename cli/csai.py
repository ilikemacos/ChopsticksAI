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
  csai update              Update CLI from chopstickshq.com
  csai version             Show version and update status

Install:
  ./cli/install.sh
  curl -fsSL https://chopstickshq.com/chopsticks-ai/install-csai-cli.sh | bash
"""

from __future__ import annotations

import argparse
import getpass
import os
import readline
import sys
import textwrap
from pathlib import Path

CLI_DIR = Path(__file__).resolve().parent
if str(CLI_DIR) not in sys.path:
    sys.path.insert(0, str(CLI_DIR))

from csai_client import CsAIClient  # noqa: E402
from csai_update import VERSION, cmd_update, cmd_version  # noqa: E402

try:
    from csai_tui import run_tui  # noqa: E402
except ImportError:
    run_tui = None  # type: ignore[misc, assignment]

# VERSION imported from csai_update
BANNER = f"""\
cs.AI {VERSION} · chopsticksAI CLI
chopstickshq.com · type /help for commands · /exit to quit
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
        used = budget.get("used", 0)
        limit = budget.get("limit", 0)
        print()
        print(c(f"Usage: {used:,} / {limit:,} tokens", DIM))


def cmd_login(client: CsAIClient, email: str | None) -> int:
    if not email:
        email = input("Email: ").strip()
    if not email:
        print(c("Email required.", RED), file=sys.stderr)
        return 1
    password = getpass.getpass("Password: ")
    try:
        client.sign_in(email, password)
    except RuntimeError as exc:
        print(c(str(exc), RED), file=sys.stderr)
        return 1
    print(c(f"Signed in as {client.email}", GREEN))
    return 0


def cmd_usage(client: CsAIClient) -> int:
    body = client.usage()
    usage = body.get("usage") or body
    tier = usage.get("tier") or {}
    label = tier.get("label") or tier.get("id") or "Free"
    used = usage.get("used", body.get("used", 0))
    limit = usage.get("limit", body.get("limit", 0))
    print(f"Plan: {label}")
    if limit:
        pct = (100.0 * float(used)) / float(limit) if limit else 0
        print(f"Tokens: {int(used):,} / {int(limit):,} ({pct:.1f}%)")
    else:
        print(f"Tokens used: {int(used):,}")
    if body.get("cooldown"):
        print(c("Cooldown active — wait before more requests.", YELLOW))
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


def cmd_ask(client: CsAIClient, question: str, tier: str | None) -> int:
    messages = [{"role": "user", "content": question}]
    print(c("Thinking…", DIM))
    body = client.chat(messages, tier=tier)
    print()
    print_reply(body)
    return 0 if body.get("reply") and body.get("mode") not in ("error",) else 1


def run_repl(client: CsAIClient, tier: str | None) -> int:
    history = Path.home() / ".local" / "share" / "chopsticks-ai" / "history"
    history.parent.mkdir(parents=True, exist_ok=True)
    try:
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
                /help              This help
                /clear             Clear conversation
                /login             Sign in
                /logout            Sign out
                /usage             Token allowance
                /tier [name]       Show or set tier (high, medium, chopcode, …)
                /search <query>    Web search
                /update            Update CLI
                /exit              Quit
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
            if cmd == "tier":
                if arg:
                    client.tier = arg.lower()
                    print(c(f"Tier set to {client.tier}", GREEN))
                else:
                    print(f"Current tier: {client.tier}")
                continue
            if cmd == "search":
                if not arg:
                    print(c("Usage: /search your query", YELLOW))
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
    parser.add_argument("--tier", default=None, help="Effort tier (default: high or CS_AI_TIER)")
    parser.add_argument(
        "--plain",
        action="store_true",
        help="Simple line prompt instead of full-screen TUI",
    )

    sub = parser.add_subparsers(dest="command")

    sub.add_parser("login", help="Sign in to chopstickshq.com")
    sub.add_parser("logout", help="Sign out")
    sub.add_parser("usage", help="Show token allowance")

    ask_p = sub.add_parser("ask", help="Ask one question and exit")
    ask_p.add_argument("question", nargs="+", help="Your question")

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
        client.tier = args.tier.lower()

    cmd = args.command
    if cmd == "login":
        return cmd_login(client, None)
    if cmd == "logout":
        client.sign_out()
        print("Signed out.")
        return 0
    if cmd == "usage":
        return cmd_usage(client)
    if cmd == "ask":
        question = " ".join(args.question).strip()
        return cmd_ask(client, question, args.tier)
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

    use_plain = args.plain or os.environ.get("CS_AI_PLAIN") == "1" or not sys.stdout.isatty()
    if not use_plain and run_tui is not None:
        return run_tui(client, args.tier)
    return run_repl(client, args.tier)


if __name__ == "__main__":
    raise SystemExit(main())
