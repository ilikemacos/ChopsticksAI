const crypto = require("node:crypto");
const { sendViaResend, AI_EMAIL } = require("./usage-email.js");

const SIGNUP_CODE_TTL_MS = 10 * 60 * 1000;
const SIGNUP_RESEND_MS = 60 * 1000;
const signupSendTimes = new Map();

function env(name) {
  return String(process.env[name] || "").trim();
}

function signupSecret() {
  const s = env("FATHOM_PRO_HMAC_SECRET") || env("CHOPSTICKS_AI_BUCKET_SALT");
  if (!s) return null;
  return s;
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function validEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function generateSignupCode() {
  return String(crypto.randomInt(100000, 1000000));
}

function hashSignupCode(code) {
  return crypto
    .createHmac("sha256", signupSecret())
    .update(String(code).trim())
    .digest("hex")
    .slice(0, 32);
}

function mintSignupToken(email, code) {
  const payload = {
    v: 1,
    email: normalizeEmail(email),
    ch: hashSignupCode(code),
    exp: Date.now() + SIGNUP_CODE_TTL_MS,
  };
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const sig = crypto.createHmac("sha256", signupSecret()).update(body).digest("base64url");
  return `${body}.${sig}`;
}

function parseSignupToken(token) {
  if (!signupSecret()) return null;
  const parts = String(token || "").split(".");
  if (parts.length !== 2) return null;
  const [body, sig] = parts;
  const expect = crypto.createHmac("sha256", signupSecret()).update(body).digest("base64url");
  try {
    const a = Buffer.from(sig);
    const b = Buffer.from(expect);
    if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  } catch {
    return null;
  }
  try {
    const payload = JSON.parse(Buffer.from(body, "base64url").toString("utf8"));
    if (!payload || payload.v !== 1 || !payload.email || !payload.ch || !payload.exp) return null;
    if (Date.now() > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

function verifySignupCode(token, email, code) {
  const payload = parseSignupToken(token);
  if (!payload) return false;
  if (payload.email !== normalizeEmail(email)) return false;
  const ch = hashSignupCode(String(code).trim());
  try {
    const a = Buffer.from(ch);
    const b = Buffer.from(payload.ch);
    if (a.length !== b.length) return false;
    return crypto.timingSafeEqual(a, b);
  } catch {
    return ch === payload.ch;
  }
}

function signupSendRateLimited(email) {
  const key = normalizeEmail(email);
  const now = Date.now();
  const last = signupSendTimes.get(key) || 0;
  if (now - last < SIGNUP_RESEND_MS) return true;
  signupSendTimes.set(key, now);
  if (signupSendTimes.size > 5000) {
    for (const [k, t] of signupSendTimes) {
      if (now - t > SIGNUP_RESEND_MS) signupSendTimes.delete(k);
    }
  }
  return false;
}

async function sendSignupCodeEmail(email, code) {
  const subject = "Your cs.AI verification code";
  const text = [
    "Hi,",
    "",
    "Your verification code for a new cs.AI account is:",
    "",
    `  ${code}`,
    "",
    "Enter this 6-digit code in the app to finish creating your account.",
    "The code expires in 10 minutes.",
    "",
    "If you didn't request this, you can ignore this email.",
    "",
    "— cs.AI · Chopsticks HQ",
    AI_EMAIL,
  ].join("\n");
  const ok = await sendViaResend(email, subject, text);
  if (!ok) throw new Error("Could not send verification email. Try again in a minute.");
}

async function adminCreateUser(email, password) {
  const url = env("SUPABASE_URL");
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new Error("Account signup is not configured on this host.");
  const res = await fetch(`${url}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      apikey: key,
      authorization: `Bearer ${key}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      email: normalizeEmail(email),
      password,
      email_confirm: true,
    }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const raw = body.msg || body.message || body.error_description || body.error || "Could not create account";
    const msg = typeof raw === "string" ? raw : JSON.stringify(raw);
    if (/already|exists|registered/i.test(msg)) {
      throw new Error("An account with this email already exists. Sign in instead.");
    }
    throw new Error(msg);
  }
  return body;
}

async function passwordSignIn(email, password) {
  const url = env("SUPABASE_URL");
  const anon = env("SUPABASE_ANON_KEY");
  if (!url || !anon) throw new Error("Account signup is not configured on this host.");
  const res = await fetch(`${url}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: {
      apikey: anon,
      authorization: `Bearer ${anon}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ email: normalizeEmail(email), password }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const raw = body.error_description || body.msg || body.message || "Sign in failed";
    throw new Error(typeof raw === "string" ? raw : JSON.stringify(raw));
  }
  return body;
}

function json(status, body) {
  return {
    statusCode: status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    body: JSON.stringify(body),
  };
}

async function handleSignupSendCode(event, payload, rateLimited) {
  const who = (event && event.headers && (
    event.headers["x-nf-client-connection-ip"] ||
    event.headers["cf-connecting-ip"] ||
    (event.headers["x-forwarded-for"] || "").split(",")[0].trim()
  )) || "anon";

  if (rateLimited && rateLimited(who)) {
    return json(429, { error: "rate limited", retryInMs: 60000 });
  }
  if (!signupSecret()) {
    return json(503, { error: "signup verification not configured" });
  }
  if (!env("RESEND_API_KEY")) {
    return json(503, { error: "email delivery not configured" });
  }
  if (!env("SUPABASE_URL") || !env("SUPABASE_SERVICE_ROLE_KEY")) {
    return json(503, { error: "account backend not configured" });
  }

  const email = normalizeEmail(payload.email);
  if (!validEmail(email)) {
    return json(400, { error: "Enter a valid email address." });
  }
  if (signupSendRateLimited(email)) {
    return json(429, { error: "Wait a minute before requesting another code.", retryInMs: SIGNUP_RESEND_MS });
  }

  const code = generateSignupCode();
  try {
    await sendSignupCodeEmail(email, code);
  } catch (e) {
    return json(502, { error: e.message || "Could not send verification email." });
  }

  const signupToken = mintSignupToken(email, code);
  return json(200, {
    mode: "signupSendCode",
    ok: true,
    needsCode: true,
    signupToken,
    email,
    expiresInSec: Math.round(SIGNUP_CODE_TTL_MS / 1000),
    from: env("CHOPSTICKS_AI_FROM_EMAIL") || `cs.AI <${AI_EMAIL}>`,
  });
}

async function handleSignupVerify(event, payload, rateLimited) {
  const who = (event && event.headers && (
    event.headers["x-nf-client-connection-ip"] ||
    event.headers["cf-connecting-ip"] ||
    (event.headers["x-forwarded-for"] || "").split(",")[0].trim()
  )) || "anon";

  if (rateLimited && rateLimited(who)) {
    return json(429, { error: "rate limited", retryInMs: 60000 });
  }
  if (!signupSecret()) {
    return json(503, { error: "signup verification not configured" });
  }

  const email = normalizeEmail(payload.email);
  const password = String(payload.password || "");
  const code = String(payload.code || "").trim().replace(/\s/g, "");
  const signupToken = String(payload.signupToken || "");

  if (!validEmail(email)) {
    return json(400, { error: "Enter a valid email address." });
  }
  if (password.length < 6) {
    return json(400, { error: "Password must be at least 6 characters." });
  }
  if (!/^\d{6}$/.test(code)) {
    return json(400, { error: "Enter the 6-digit verification code from your email." });
  }
  if (!verifySignupCode(signupToken, email, code)) {
    return json(403, { error: "Invalid or expired verification code." });
  }

  try {
    await adminCreateUser(email, password);
  } catch (e) {
    return json(400, { error: e.message || "Could not create account." });
  }

  try {
    const session = await passwordSignIn(email, password);
    return json(200, {
      mode: "signupVerify",
      ok: true,
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      expires_at: session.expires_at,
      token_type: session.token_type,
      user: session.user,
    });
  } catch (e) {
    return json(200, {
      mode: "signupVerify",
      ok: true,
      needsSignIn: true,
      message: "Account created. Sign in with your email and password.",
    });
  }
}

async function handleAuthSignUp(event, payload, rateLimited) {
  const who = (event && event.headers && (
    event.headers["x-nf-client-connection-ip"] ||
    event.headers["cf-connecting-ip"] ||
    (event.headers["x-forwarded-for"] || "").split(",")[0].trim()
  )) || "anon";

  if (rateLimited && rateLimited(who)) {
    return json(429, { error: "rate limited", retryInMs: 60000 });
  }
  if (!env("SUPABASE_URL") || !env("SUPABASE_SERVICE_ROLE_KEY")) {
    return json(503, { error: "account backend not configured" });
  }

  const email = normalizeEmail(payload.email);
  const password = String(payload.password || "");
  if (!validEmail(email)) {
    return json(400, { error: "Enter a valid email address." });
  }
  if (password.length < 6) {
    return json(400, { error: "Password must be at least 6 characters." });
  }

  try {
    await adminCreateUser(email, password);
  } catch (e) {
    return json(400, { error: e.message || "Could not create account." });
  }

  try {
    const session = await passwordSignIn(email, password);
    return json(200, {
      mode: "authSignUp",
      ok: true,
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      expires_at: session.expires_at,
      token_type: session.token_type,
      user: session.user,
    });
  } catch (e) {
    return json(200, {
      mode: "authSignUp",
      ok: true,
      needsSignIn: true,
      message: "Account created. Sign in with your email and password.",
    });
  }
}

async function handleAuthSignIn(event, payload, rateLimited) {
  const who = (event && event.headers && (
    event.headers["x-nf-client-connection-ip"] ||
    event.headers["cf-connecting-ip"] ||
    (event.headers["x-forwarded-for"] || "").split(",")[0].trim()
  )) || "anon";

  if (rateLimited && rateLimited(who)) {
    return json(429, { error: "rate limited", retryInMs: 60000 });
  }

  const email = normalizeEmail(payload.email);
  const password = String(payload.password || "");
  if (!validEmail(email)) {
    return json(400, { error: "Enter a valid email address." });
  }
  if (password.length < 6) {
    return json(400, { error: "Password must be at least 6 characters." });
  }

  try {
    const session = await passwordSignIn(email, password);
    return json(200, {
      mode: "authSignIn",
      ok: true,
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      expires_at: session.expires_at,
      token_type: session.token_type,
      user: session.user,
    });
  } catch (e) {
    return json(401, { error: e.message || "Sign in failed." });
  }
}

async function handleAuthRefresh(event, payload) {
  const refresh = String(payload.refresh_token || payload.refreshToken || "").trim();
  if (!refresh) return json(400, { error: "Missing refresh token." });

  const url = env("SUPABASE_URL");
  const anon = env("SUPABASE_ANON_KEY");
  if (!url || !anon) return json(503, { error: "Account backend not configured." });

  const res = await fetch(`${url}/auth/v1/token?grant_type=refresh_token`, {
    method: "POST",
    headers: {
      apikey: anon,
      authorization: `Bearer ${anon}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ refresh_token: refresh }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const raw = body.error_description || body.msg || body.message || "Session expired";
    return json(401, { error: typeof raw === "string" ? raw : JSON.stringify(raw) });
  }
  return json(200, {
    mode: "authRefresh",
    ok: true,
    access_token: body.access_token,
    refresh_token: body.refresh_token,
    expires_in: body.expires_in,
    expires_at: body.expires_at,
    token_type: body.token_type,
    user: body.user,
  });
}

module.exports = {
  handleSignupSendCode,
  handleSignupVerify,
  handleAuthSignUp,
  handleAuthSignIn,
  handleAuthRefresh,
};
