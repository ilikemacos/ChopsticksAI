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
DEFAULT_TIER = os.environ.get("CS_AI_TIER", "high")

TIER_TOKENS = {
    "low": 400,
    "medium": 600,
    "high": 1000,
    "xhigh": 2000,
    "xhighplus": 3000,
    "insane": 4000,
    "chopsticks": 800,
    "chopcode": 4000,
    "stickercoderplus": 6000,
}


def _tier_max_tokens(tier: str) -> int:
    return TIER_TOKENS.get(tier.lower(), 1000)


class CsAIClient:
    def __init__(self) -> None:
        self.session: dict[str, Any] | None = None
        self.tier = DEFAULT_TIER
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

    def _load_session(self) -> None:
        try:
            if SESSION_FILE.is_file():
                data = json.loads(SESSION_FILE.read_text(encoding="utf-8"))
                if data and data.get("access_token"):
                    self.session = data
        except (OSError, json.JSONDecodeError):
            self.session = None

    def _save_session(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
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
        return self._request({"action": "usage", "unlockKeys": []})

    def search(self, query: str) -> dict[str, Any]:
        self.refresh_if_needed()
        return self._request({"action": "search", "q": query})

    def chat(
        self,
        messages: list[dict[str, str]],
        *,
        tier: str | None = None,
        disable_search: bool = False,
    ) -> dict[str, Any]:
        self.refresh_if_needed()
        use_tier = (tier or self.tier).lower()
        body: dict[str, Any] = {
            "messages": messages,
            "tier": use_tier,
            "mode": "agent",
            "maxTokens": _tier_max_tokens(use_tier),
            "onlineMode": True,
            "enableTools": True,
            "client": "cli",
            "language": os.environ.get("CS_AI_LANG", "en"),
            "unlockKeys": [],
        }
        if disable_search:
            body["disableSearch"] = True
        return self._request(body)
