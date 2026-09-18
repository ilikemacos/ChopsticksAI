"use strict";

const { env } = require("./netlify-env.js");
const { applyDonation, DONOR_DAYS } = require("./kofi-webhook.js");

function adminPassword() {
  return String(env("CHQ_ADMIN_PASSWORD") || "150415");
}

function checkAdmin(payload, timingSafeString) {
  const supplied = String(payload.adminPassword || payload.password || "");
  const expect = adminPassword();
  return timingSafeString(supplied, expect);
}

async function supabaseAdmin(method, path, body) {
  const url = env("SUPABASE_URL");
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return { status: 503, body: { error: "supabase unconfigured" } };
  const res = await fetch(url + path, {
    method,
    headers: {
      apikey: key,
      authorization: "Bearer " + key,
      "content-type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let parsed = null;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = text; }
  return { status: res.status, body: parsed };
}

async function handleChqAdmin(event, payload, deps) {
  const { json, sb, mintFathomProUnlockKey, timingSafeString, rateLimited } = deps;
  const who = "admin-" + String((event.headers && (event.headers["x-nf-client-connection-ip"] || event.headers["x-forwarded-for"] || "")) || "x").slice(0, 40);
  if (rateLimited(who, 30)) return json(429, { error: "rate limited" });
  if (!checkAdmin(payload, timingSafeString)) return json(401, { error: "wrong password" });

  const act = String(payload.action || "").toLowerCase();

  if (act === "adminping" || act === "adminlogin") {
    return json(200, { ok: true, mode: "admin" });
  }

  if (act === "adminfakedonation") {
    const email = String(payload.email || "").trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return json(400, { error: "email required" });
    }
    const days = Number(payload.days) > 0 ? Number(payload.days) : DONOR_DAYS;
    const shopKeys = Number(payload.shopKeys) || 0;
    const kind = shopKeys > 0 ? "Shop Order" : "Donation";
    const tx = "admin-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 10);
    const result = await applyDonation({
      sb,
      mintFathomProUnlockKey,
      email,
      kind,
      tx,
      shopKeys,
      days,
      notify: payload.notify === true,
    });
    if (!result.ok) return json(502, { error: result.error || "failed", detail: result.detail || undefined });
    return json(200, {
      ok: true,
      mode: "adminFakeDonation",
      email,
      donor_until: result.donor_until,
      keys: result.keys || [],
      tx,
    });
  }

  if (act === "adminlistusers") {
    const prof = await sb(
      "profiles?select=id,email,display_name,plan_label,token_budget,context_limit,cooldown_ms,created_at,updated_at&order=updated_at.desc&limit=200",
      { method: "GET", headers: { accept: "application/json" } },
      { service: true }
    );
    const donors = await sb(
      "kofi_donors?select=email,donor_until,updated_at&order=updated_at.desc&limit=500",
      { method: "GET", headers: { accept: "application/json" } },
      { service: true }
    );
    const donorMap = {};
    if (donors.ok && Array.isArray(donors.body)) {
      for (const d of donors.body) donorMap[String(d.email || "").toLowerCase()] = d.donor_until;
    }
    const users = (prof.ok && Array.isArray(prof.body) ? prof.body : []).map((u) => ({
      ...u,
      donor_until: donorMap[String(u.email || "").toLowerCase()] || null,
    }));
    const orphanDonors = Object.keys(donorMap)
      .filter((em) => !users.some((u) => String(u.email || "").toLowerCase() === em))
      .map((email) => ({ id: null, email, donor_until: donorMap[email], plan_label: "(donor only)" }));
    return json(200, { ok: true, mode: "adminListUsers", users: users.concat(orphanDonors) });
  }

  if (act === "adminpatchuser") {
    const id = String(payload.id || "").trim();
    const email = String(payload.email || "").trim().toLowerCase();
    if (!id && !email) return json(400, { error: "id or email required" });

    if (id) {
      const patch = {};
      if (payload.email) patch.email = email;
      if (payload.display_name != null) patch.display_name = String(payload.display_name);
      if (payload.plan_label != null) patch.plan_label = String(payload.plan_label);
      if (payload.token_budget != null && payload.token_budget !== "") patch.token_budget = Number(payload.token_budget);
      if (payload.context_limit != null && payload.context_limit !== "") patch.context_limit = Number(payload.context_limit);
      if (payload.cooldown_ms != null && payload.cooldown_ms !== "") patch.cooldown_ms = Number(payload.cooldown_ms);
      patch.updated_at = new Date().toISOString();
      if (Object.keys(patch).length > 1) {
        const res = await sb(
          `profiles?id=eq.${encodeURIComponent(id)}`,
          { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify(patch) },
          { service: true }
        );
        if (!res.ok) return json(502, { error: "profile update failed", detail: res.body });
      }
      if (payload.newPassword) {
        const auth = await supabaseAdmin("PUT", "/auth/v1/admin/users/" + id, {
          password: String(payload.newPassword),
          email_confirm: true,
          ...(payload.email ? { email } : {}),
        });
        if (auth.status >= 400) return json(502, { error: "auth update failed", detail: auth.body });
      } else if (payload.email) {
        await supabaseAdmin("PUT", "/auth/v1/admin/users/" + id, { email, email_confirm: true });
      }
    }

    const donorEmail = email || String(payload.donorEmail || "").trim().toLowerCase();
    if (payload.donor_until === "" || payload.donor_until === null) {
      if (donorEmail) {
        await sb(`kofi_donors?email=eq.${encodeURIComponent(donorEmail)}`, { method: "DELETE" }, { service: true });
      }
    } else if (payload.donor_until) {
      if (!donorEmail) return json(400, { error: "email required for donor_until" });
      await sb("kofi_donors", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify({
          email: donorEmail,
          donor_until: new Date(payload.donor_until).toISOString(),
          updated_at: new Date().toISOString(),
        }),
      }, { service: true });
    }

    return json(200, { ok: true, mode: "adminPatchUser" });
  }

  return json(400, { error: "unknown admin action" });
}

module.exports = { handleChqAdmin };
