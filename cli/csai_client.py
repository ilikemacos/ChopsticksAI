"""HTTP client for chopstickshq.com cs.AI API."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

API_URL = os.environ.get("CS_AI_API", "https://chopstickshq.com/api/chopsticks-ai")
CONFIG_DIR = Path.home() / ".config" / "chopsticks-ai"
SESSION_FILE = CONFIG_DIR / "session.json"
UNLOCK_KEYS_FILE = CONFIG_DIR / "unlock-keys.json"
PREFS_FILE = CONFIG_DIR / "prefs.json"
DEFAULT_TIER = os.environ.get("CS_AI_TIER", "tamago")

PLATE_ALIASES = {
    "code": "chopcode",
    "chop-code": "chopcode",
    "chopcode": "chopcode",
    "low": "rice",
    "fast": "rice",
    "haiku": "rice",
    "medium": "tamago",
    "high": "tamago",
    "sonnet": "tamago",
    "pro": "hibachi",
    "opus": "hibachi",
    "ultra": "hibachi",
    "insane": "wagyua5",
    "fable": "wagyua5",
    "wagyu": "wagyua5",
    "a1": "wagyua1",
    "a2": "wagyua2",
    "a3": "wagyua3",
    "a4": "wagyua4",
    "a5": "wagyua5",
    "wagyua1": "wagyua1",
    "wagyua2": "wagyua2",
    "wagyua3": "wagyua3",
    "wagyua4": "wagyua4",
    "wagyua5": "wagyua5",
}


def normalize_plate(name: str) -> str:
    key = (name or "").strip().lower().replace(" ", "")
    return PLATE_ALIASES.get(key, key or DEFAULT_TIER)

TIER_TOKENS = {
    "rice": 800,
    "tamago": 2000,
    "hibachi": 4000,
    "wagyu": 8000,
    "wagyua1": 2500,
    "wagyua2": 4000,
    "wagyua3": 5500,
    "wagyua4": 7000,
    "wagyua5": 8000,
    "low": 800,
    "medium": 2000,
    "high": 2000,
    "xhigh": 4000,
    "xhighplus": 4000,
    "insane": 8000,
    "chopsticks": 2000,
    "chopcode": 4000,
    "stickercoderplus": 8000,
    "pro": 4000,
}


def _load_unlock_keys() -> list[str]:
    try:
        if UNLOCK_KEYS_FILE.is_file():
            data = json.loads(UNLOCK_KEYS_FILE.read_text(encoding="utf-8"))
            if isinstance(data, list):
                return [str(k).strip() for k in data if str(k).strip()]
    except (OSError, json.JSONDecodeError):
        pass
    return []


def _ensure_config_dir() -> None:
    _ensure_config_dir()
    try:
        CONFIG_DIR.chmod(0o700)
    except OSError:
        pass


def _save_unlock_keys(keys: list[str]) -> None:
    _ensure_config_dir()
    UNLOCK_KEYS_FILE.write_text(json.dumps(keys, indent=2), encoding="utf-8")
    try:
        UNLOCK_KEYS_FILE.chmod(0o600)
    except OSError:
        pass


def _load_prefs() -> dict[str, Any]:
    try:
        if PREFS_FILE.is_file():
            data = json.loads(PREFS_FILE.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return data
    except (OSError, json.JSONDecodeError):
        pass
    return {"webSearch": True, "tier": DEFAULT_TIER}


def _save_prefs(prefs: dict[str, Any]) -> None:
    _ensure_config_dir()
    PREFS_FILE.write_text(json.dumps(prefs, indent=2), encoding="utf-8")
    try:
        PREFS_FILE.chmod(0o600)
    except OSError:
        pass


def _tier_max_tokens(tier: str) -> int:
    return TIER_TOKENS.get(tier.lower(), 1000)


def format_duration(ms: int) -> str:
    if ms <= 0:
        return "now"
    total_s = max(1, ms // 1000)
    h, rem = divmod(total_s, 3600)
    m, s = divmod(rem, 60)
    parts: list[str] = []
    if h:
        parts.append(f"{h}h")
    if m:
        parts.append(f"{m}m")
    if not parts and s:
        parts.append(f"{s}s")
    return " ".join(parts) or "soon"


def progress_bar(used: int, limit: int, width: int = 24) -> str:
    if limit <= 0:
        return ""
    ratio = max(0.0, min(1.0, used / limit))
    filled = int(round(ratio * width))
    return f"[{'█' * filled}{'░' * (width - filled)}]"


def format_usage(body: dict[str, Any]) -> str:
    usage = body.get("usage") or body
    tier = usage.get("tier") or {}
    label = tier.get("label") or tier.get("id") or "Free"
    detail = str(tier.get("detail") or "").strip()
    used = int(usage.get("used", body.get("used", 0)))
    limit = int(usage.get("limit", body.get("limit", 0)))
    lines = [f"Plan: {label}"]
    if detail:
        lines.append(detail)
    if limit:
        pct = (100.0 * used) / limit if limit else 0.0
        bar = progress_bar(used, limit)
        lines.append(f"Tokens: {used:,} / {limit:,} ({pct:.1f}%)")
        if bar:
            lines.append(bar)
    else:
        lines.append(f"Tokens used: {used:,}")
    cooldown = usage.get("cooldown") or body.get("cooldown")
    if isinstance(cooldown, dict) and cooldown.get("blocked"):
        retry = int(cooldown.get("retryInMs") or 0)
        lines.append(f"Cooldown active — retry in {format_duration(retry)}.")
    warning = usage.get("warning")
    if isinstance(warning, dict):
        msg = warning.get("message")
        if msg:
            lines.append(str(msg))
    return "\n".join(lines)


class CsAIClient:
    def __init__(self) -> None:
        self.session: dict[str, Any] | None = None
        self.unlock_keys = _load_unlock_keys()
        self._prefs = _load_prefs()
        self.tier = normalize_plate(str(self._prefs.get("tier") or DEFAULT_TIER))
        self._load_session()

    @property
    def signed_in(self) -> bool:
        return bool(self.session and self.session.get("access_token"))

    @property
    def email(self) -> str:
        if not self.session:
            return ""
        user = self.session.get("user") or {}
        return str(user.get("email") or "")

    @property
    def web_search(self) -> bool:
        return bool(self._prefs.get("webSearch", True))

    def set_tier(self, name: str) -> str:
        self.tier = normalize_plate(name)
        self._prefs["tier"] = self.tier
        _save_prefs(self._prefs)
        return self.tier

    def set_web_search(self, on: bool) -> None:
        self._prefs["webSearch"] = on
        _save_prefs(self._prefs)

    def add_unlock_key(self, key: str) -> bool:
        key = key.strip()
        if not key or key in self.unlock_keys:
            return False
        self.unlock_keys.append(key)
        _save_unlock_keys(self.unlock_keys)
        return True

    def clear_unlock_keys(self) -> None:
        self.unlock_keys = []
        _save_unlock_keys(self.unlock_keys)

    def _load_session(self) -> None:
        try:
            if SESSION_FILE.is_file():
                data = json.loads(SESSION_FILE.read_text(encoding="utf-8"))
                if data and data.get("access_token"):
                    self.session = data
        except (OSError, json.JSONDecodeError):
            self.session = None

    def _save_session(self) -> None:
        _ensure_config_dir()
        if self.session:
            SESSION_FILE.write_text(json.dumps(self.session, indent=2), encoding="utf-8")
            try:
                SESSION_FILE.chmod(0o600)
            except OSError:
                pass
        elif SESSION_FILE.is_file():
            SESSION_FILE.unlink(missing_ok=True)

    def _normalize_session(self, body: dict[str, Any]) -> dict[str, Any] | None:
        token = body.get("access_token")
        if not token:
            return None
        expires_at = body.get("expires_at")
        if not expires_at:
            expires_in = int(body.get("expires_in") or 3600)
            expires_at = int(time.time()) + expires_in
        return {
            "access_token": token,
            "refresh_token": body.get("refresh_token"),
            "expires_at": expires_at,
            "user": body.get("user"),
        }

    def _request(
        self,
        body: dict[str, Any],
        *,
        auth: bool = True,
        timeout: float = 90.0,
    ) -> dict[str, Any]:
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if auth and self.session and self.session.get("access_token"):
            headers["Authorization"] = f"Bearer {self.session['access_token']}"
        data = json.dumps(body).encode("utf-8")
        req = urllib.request.Request(API_URL, data=data, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                raw = resp.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode("utf-8", errors="replace")
            try:
                parsed = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                parsed = {"error": raw or f"HTTP {exc.code}"}
            parsed.setdefault("error", parsed.get("message") or f"HTTP {exc.code}")
            parsed["httpStatus"] = exc.code
            return parsed
        except urllib.error.URLError as exc:
            return {"mode": "error", "error": str(exc.reason or exc)}

        if not raw:
            return {"mode": "empty"}
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return {"mode": "error", "error": raw}

    def refresh_if_needed(self) -> None:
        if not self.session or not self.session.get("refresh_token"):
            return
        exp = int(self.session.get("expires_at") or 0)
        if exp and time.time() < exp - 60:
            return
        body = self._request(
            {"action": "authRefresh", "refresh_token": self.session["refresh_token"]},
            auth=False,
        )
        session = self._normalize_session(body)
        if session:
            self.session = session
            self._save_session()
        else:
            self.session = None
            self._save_session()

    def sign_in(self, email: str, password: str) -> dict[str, Any]:
        body = self._request(
            {"action": "authSignIn", "email": email.strip(), "password": password},
            auth=False,
        )
        if body.get("needsCode") and body.get("loginToken"):
            return body
        session = self._normalize_session(body)
        if not session:
            err = body.get("error") or body.get("message") or "Sign in failed"
            raise RuntimeError(str(err))
        self.session = session
        self._save_session()
        return body

    def verify_login(self, email: str, password: str, code: str, login_token: str) -> dict[str, Any]:
        body = self._request(
            {
                "action": "loginVerify",
                "email": email.strip(),
                "password": password,
                "code": code.strip(),
                "loginToken": login_token,
            },
            auth=False,
        )
        session = self._normalize_session(body)
        if not session:
            err = body.get("error") or body.get("message") or "Sign in failed"
            raise RuntimeError(str(err))
        self.session = session
        self._save_session()
        return body

    def sign_out(self) -> None:
        self.session = None
        self._save_session()

    def usage(self) -> dict[str, Any]:
        self.refresh_if_needed()
        return self._request({"action": "usage", "unlockKeys": self.unlock_keys})

    def search(self, query: str) -> dict[str, Any]:
        self.refresh_if_needed()
        return self._request({"action": "search", "q": query})

    def chat(
        self,
        messages: list[dict[str, str]],
        *,
        tier: str | None = None,
        disable_search: bool | None = None,
        attachments: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:
        self.refresh_if_needed()
        use_tier = normalize_plate(tier or self.tier)
        no_search = not self.web_search if disable_search is None else disable_search
        if use_tier == "chopcode":
            no_search = True if disable_search is None else disable_search
        body: dict[str, Any] = {
            "messages": messages,
            "tier": use_tier,
            "mode": "agent",
            "maxTokens": _tier_max_tokens(use_tier),
            "onlineMode": True,
            "enableTools": True,
            "client": "cli",
            "language": os.environ.get("CS_AI_LANG", "en"),
            "unlockKeys": self.unlock_keys,
        }
        if no_search:
            body["disableSearch"] = True
        if attachments:
            body["attachments"] = attachments
        return self._request(body)
