"use strict";

const { env } = require("./netlify-env.js");
const { sendViaResend, AI_EMAIL } = require("./usage-email.js");

const DONOR_DAYS = 30;
const REDEEM_URL = "https://chopstickshq.com/chopsticks-ai/web/upgrades/";
const CHAT_URL = "https://chopstickshq.com/chopsticks-ai/web/";

function json(status, body) {
  return {
    statusCode: status,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}

function isKofiWebhookEvent(event) {
  if (!event || String(event.httpMethod || "").toUpperCase() !== "POST") return false;
  const headers = event.headers || {};
  const ct = String(headers["content-type"] || headers["Content-Type"] || "").toLowerCase();
  if (ct.includes("application/x-www-form-urlencoded")) return true;
  const raw = String(event.body || "");
  return /verification_token/.test(raw) && /kofi_transaction_id/.test(raw);
}

function parseKofiData(body) {
  const params = new URLSearchParams(String(body || ""));
  const dataRaw = params.get("data");
  if (!dataRaw) return null;
  try {
    const parsed = JSON.parse(dataRaw);
    return parsed && typeof parsed === "object" ? parsed : null;
  } catch {
    return null;
  }
}

function keysForShop(data) {
  const items = Array.isArray(data.shop_items) ? data.shop_items : [];
  let n = 0;
  for (const it of items) {
    const code = String((it && (it.direct_link_code || it.code || it.variation_name)) || "").toLowerCase();
    const qty = Math.max(1, Number(it && it.quantity) || 1);
    if (code === "csai-keys-10" || /keys-10|key-10|10key/.test(code)) n += 10 * qty;
    else if (code === "csai-keys-5" || /keys-5|key-5|5key/.test(code)) n += 5 * qty;
    else if (code === "csai-keys-2" || /keys-2|key-2|2key/.test(code)) n += 2 * qty;
  }
  return n;
}

async function applyDonation(opts) {
  const {
    sb,
    mintFathomProUnlockKey,
    email,
    kind,
    tx,
    shopKeys,
    days,
    notify,
  } = opts;
  const until = new Date(Date.now() + (Number(days) > 0 ? Number(days) : DONOR_DAYS) * 864e5).toISOString();
  const existing = await sb(
    `kofi_orders?kofi_transaction_id=eq.${encodeURIComponent(tx)}&select=kofi_transaction_id`,
    { method: "GET" },
    { service: true }
  );
  if (existing.ok && Array.isArray(existing.body) && existing.body.length) {
    return { ok: true, duplicate: true, donor_until: until, keys: [] };
  }

  const keys = [];
  const n = Math.max(0, Math.min(20, Number(shopKeys) || 0));
  for (let i = 0; i < n; i++) {
    const k = mintFathomProUnlockKey();
    if (k) keys.push(k);
  }

  const ins = await sb(`kofi_orders?on_conflict=kofi_transaction_id`, {
    method: "POST",
    headers: { Prefer: "return=minimal,resolution=ignore-duplicates" },
    body: JSON.stringify({
      kofi_transaction_id: tx,
      email,
      kind,
      keys_minted: keys.length,
      donor_until: until,
    }),
  }, { service: true });
  if (!ins.ok && ins.status !== 409) {
    const detail = typeof ins.body === "string" ? ins.body : JSON.stringify(ins.body || {});
    return { ok: false, error: "order store failed", detail: String(detail).slice(0, 400) };
  }

  await sb(`kofi_donors?on_conflict=email`, {
    method: "POST",
    headers: { Prefer: "return=minimal,resolution=merge-duplicates" },
    body: JSON.stringify({
      email,
      donor_until: until,
      updated_at: new Date().toISOString(),
    }),
  }, { service: true });

  if (notify !== false) {
    const keyBlock = keys.length
      ? `\n\nFathom Pro keys (${keys.length}):\n${keys.join("\n")}\n\nRedeem at ${REDEEM_URL}`
      : "";
    const text = [
      "Thanks for supporting Chopsticks HQ.",
      "",
      `You're a cs.AI donor until ${until.slice(0, 10)}. Sign in at ${CHAT_URL} with this email (${email}) for cs.AI-4.7-Pro and priority rate limits.`,
      keyBlock,
      "",
      "— cs.AI · Chopsticks HQ",
      AI_EMAIL,
    ].join("\n");
    await sendViaResend(email, "cs.AI donor — 4.7-Pro unlocked", text);
  }
  return { ok: true, donor_until: until, keys, duplicate: false };
}

async function handleKofiWebhook(event, deps) {
  const { sb, mintFathomProUnlockKey, timingSafeString } = deps;
  const token = env("KOFI_WEBHOOK_TOKEN");
  if (!token) return json(503, { error: "kofi unconfigured" });
  const data = parseKofiData(event.body);
  if (!data) return json(400, { error: "invalid kofi payload" });
  if (!timingSafeString(String(data.verification_token || ""), token)) {
    return json(401, { error: "forbidden" });
  }
  const type = String(data.type || "");
  if (!/^(Donation|Shop Order|Subscription)$/i.test(type)) {
    return json(200, { ok: true, ignored: type });
  }
  const tx = String(data.kofi_transaction_id || "").trim();
  const email = String(data.email || "").trim().toLowerCase();
  if (!tx || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return json(400, { error: "missing email or transaction" });
  }
  const shopKeys = /shop/i.test(type) ? keysForShop(data) : 0;
  const result = await applyDonation({
    sb,
    mintFathomProUnlockKey,
    email,
    kind: type,
    tx,
    shopKeys,
    days: DONOR_DAYS,
    notify: true,
  });
  if (!result.ok) return json(502, { error: result.error || "failed" });
  return json(200, {
    ok: true,
    duplicate: Boolean(result.duplicate),
    donor_until: result.donor_until,
    keys: (result.keys && result.keys.length) || 0,
  });
}

module.exports = { isKofiWebhookEvent, handleKofiWebhook, applyDonation, DONOR_DAYS };
