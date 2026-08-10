const crypto = require("node:crypto");
const { queueUsageEmail, AI_EMAIL } = require("./usage-email.js");
const {
  handleSignupSendCode,
  handleSignupVerify,
  handleAuthSignUp,
  handleAuthSignIn,
  handleAuthRefresh,
} = require("./signup-verify.js");

const TIERS = {
  low: {
    label: "Low",
    models: ["nvidia/nemotron-3-nano-30b-a3b:free"],
    longModels: ["nvidia/nemotron-3-nano-30b-a3b:free"],
    context: 12000,
    refine: false,
    maxReply: 400,
    grounding: 3,
    searchMax: 4,
  },
  medium: {
    label: "Medium",
    models: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
    ],
    longModels: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
    ],
    context: 24000,
    refine: true,
    maxReply: 600,
    grounding: 5,
    searchMax: 8,
  },
  high: {
    label: "High",
    models: [
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ],
    longModels: [
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "openai/gpt-oss-20b:free",
    ],
    context: 36000,
    refine: true,
    maxReply: 1000,
    grounding: 6,
    searchMax: 10,
  },
  xhigh: {
    label: "Xhigh",
    models: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
      "nvidia/nemotron-3-ultra-550b-a55b:free",
    ],
    longModels: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ],
    context: 48000,
    refine: true,
    maxReply: 2000,
    grounding: 8,
    searchMax: 12,
  },
  chopsticks: {
    label: "Chopsticks",
    models: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ],
    longModels: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
    ],
    context: 36000,
    refine: true,
    maxReply: 800,
    grounding: 10,
    searchMax: 6,
    chopsticksFocus: true,
  },
  xhighplus: {
    label: "Xhigh+",
    models: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
      "nvidia/nemotron-3-ultra-550b-a55b:free",
    ],
    longModels: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ],
    context: 64000,
    refine: true,
    maxReply: 3000,
    grounding: 10,
    searchMax: 14,
  },
  insane: {
    label: "Insane",
    models: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
      "nvidia/nemotron-3-ultra-550b-a55b:free",
    ],
    longModels: [
      "openai/gpt-oss-20b:free",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ],
    context: 96000,
    refine: true,
    maxReply: 4000,
    grounding: 12,
    searchMax: 16,
  },
  
  chopcode: {
    label: "ChopCode",
    models: [
      "poolside/laguna-s-2.1:free",
      "cohere/north-mini-code:free",
      "openai/gpt-oss-20b:free",
    ],
    longModels: [
      "poolside/laguna-s-2.1:free",
      "openai/gpt-oss-20b:free",
    ],
    context: 64000,
    refine: false,
    maxReply: 4000,
    grounding: 4,
    searchMax: 6,
    temperature: 0.2,
    chopCode: true,
  },
  
  stickercoderplus: {
    label: "StickerCoder+",
    models: [
      "cohere/north-mini-code:free",
      "poolside/laguna-s-2.1:free",
      "openai/gpt-oss-20b:free",
    ],
    longModels: [
      "cohere/north-mini-code:free",
      "openai/gpt-oss-20b:free",
    ],
    context: 96000,
    refine: false,
    maxReply: 6000,
    grounding: 4,
    searchMax: 6,
    temperature: 0.15,
    chopCode: true,
    stickerCoder: true,
  },
};
const TIER_ALIASES = {
  ultra: "xhigh",
  super: "medium",
  "xhigh+": "xhighplus",
  chopcode: "chopcode",
  "chop-code": "chopcode",
  stickercoderplus: "stickercoderplus",
  "stickercoder+": "stickercoderplus",
  "sticker-coder+": "stickercoderplus",
  "sticker-coderplus": "stickercoderplus",
  coderplus: "stickercoderplus",
  "coder+": "stickercoderplus",
};
const DEFAULT_TIER = "high";
const tierOf = (name) => {
  const key = String(name || "").toLowerCase().replace(/\s+/g, "");
  const id = TIER_ALIASES[key] || key;
  return TIERS[id] || TIERS[DEFAULT_TIER];
};

const AUTH_REQUIRED_TIERS = new Set([
  "insane", "xhighplus", "stickercoderplus", "chopcode",
]);

function hmacUnlockSig(body, tag) {
  const secret = env("FATHOM_PRO_HMAC_SECRET");
  if (!secret) return "";
  return crypto.createHmac("sha256", secret).update(`${body}|${tag}`).digest("hex").slice(0, 16);
}

function mintFathomProUnlockKey() {
  const n1 = crypto.randomBytes(6).toString("hex");
  const n2 = crypto.randomBytes(6).toString("hex");
  const body = n1 + n2;
  const sig = hmacUnlockSig(body, "web");
  if (!sig) return "";
  return `oi-pl2-${n1}-${n2}-${sig}`;
}

function verifyFathomProUnlock(raw) {
  const key = String(raw || "").trim().toLowerCase();
  if (!key) return false;
  if (key.includes("c0ffee")) return false;
  if (/^sk-or-/i.test(key) || /^sk-[a-z0-9]/i.test(key)) return false;
  const m = key.match(/^oi-pl2-([0-9a-f]{12})-([0-9a-f]{12})-([0-9a-f]{16})$/);
  if (!m) return false;
  const expect = hmacUnlockSig(m[1] + m[2], "web");
  return expect.length > 0 && expect === m[3];
}

function hashClientBucket(clientId) {
  const salt = env("CHOPSTICKS_AI_BUCKET_SALT") || "chopsticks-ai-bucket-v1";
  const id = String(clientId || "anon").slice(0, 128);
  return "ip-" + crypto.createHmac("sha256", salt).update(id).digest("hex").slice(0, 16);
}

const FREE_USAGE = {
  id: "free",
  keysRequired: 0,
  limit: Number(process.env.CHOPSTICKS_AI_TOKEN_BUDGET || 775000),
  cooldownMs: Number(process.env.CHOPSTICKS_AI_COOLDOWN_MS || 3 * 60 * 60 * 1000),
  contextLimit: Number(process.env.CHOPSTICKS_AI_MAX_CONTEXT || 48000),
  label: "Free",
  detail: "775k tokens · 48k context · 3h cooldown",
};
const CREDIT_TIERS = [
  {
    id: "credits-2",
    keysRequired: 2,
    limit: 800000,
    cooldownMs: Math.round(2.5 * 60 * 60 * 1000),
    contextLimit: 64000,
    label: "2 Fathom Pro APIs",
    detail: "800k tokens · 64k context · 2h 30m cooldown",
  },
  {
    id: "credits-5",
    keysRequired: 5,
    limit: 900000,
    cooldownMs: 2 * 60 * 60 * 1000,
    contextLimit: 96000,
    label: "5 Fathom Pro APIs",
    detail: "900k tokens · 96k context · 2h cooldown",
  },
  {
    id: "credits-10",
    keysRequired: 10,
    limit: 1000000,
    cooldownMs: 1 * 60 * 60 * 1000,
    contextLimit: 128000,
    label: "10 Fathom Pro APIs",
    detail: "1m tokens · 128k context · 1h cooldown",
  },
];

function entitlementDetail(limit, contextLimit, cooldownMs) {
  const toks = (n) => {
    if (n >= 1_000_000) {
      const v = n / 1_000_000;
      return (Number.isInteger(v) ? String(v) : v.toFixed(1).replace(/\.0$/, "")) + "m";
    }
    if (n >= 1000) {
      const v = n / 1000;
      return (Number.isInteger(v) ? String(v) : v.toFixed(1).replace(/\.0$/, "")) + "k";
    }
    return String(n);
  };
  const coolH = Math.round((cooldownMs || FREE_USAGE.cooldownMs) / 3600000);
  const cool =
    coolH >= 1
      ? `${coolH}h cooldown`
      : `${Math.round((cooldownMs || FREE_USAGE.cooldownMs) / 60000)}m cooldown`;
  return `${toks(limit)} tokens · ${toks(contextLimit)} context · ${cool}`;
}

function resolveCredits(rawKeys, clientId) {
  const list = Array.isArray(rawKeys) ? rawKeys : [];
  const valid = [];
  const seen = new Set();
  let rejected = 0;
  for (const raw of list) {
    const key = String(raw || "").trim().toLowerCase();
    if (!key) continue;
    if (seen.has(key)) continue;
    seen.add(key);
    if (!verifyFathomProUnlock(key)) {
      rejected += 1;
      continue;
    }
    valid.push(key);
  }
  let tier = FREE_USAGE;
  for (const t of CREDIT_TIERS) {
    if (valid.length >= t.keysRequired) tier = t;
  }
  const bucketId = tier.keysRequired === 0
    ? hashClientBucket(clientId)
    : ("credits-" + crypto.createHash("sha256").update(valid.slice().sort().join("|")).digest("hex").slice(0, 16));
  return {
    keysSubmitted: seen.size,
    keysValid: valid.length,
    keysRejected: rejected,
    tier,
    bucketId,
    limit: tier.limit,
    cooldownMs: tier.cooldownMs,
    contextLimit: tier.contextLimit || FREE_USAGE.contextLimit,
    upgrades: CREDIT_TIERS.map((t) => ({
      id: t.id,
      keysRequired: t.keysRequired,
      limit: t.limit,
      cooldownMs: t.cooldownMs,
      contextLimit: t.contextLimit,
      label: t.label,
      detail: t.detail,
      unlocked: valid.length >= t.keysRequired,
    })),
  };
}

function extractAccessToken(event) {
  const headers = (event && event.headers) || {};
  const auth = headers.authorization || headers.Authorization || "";
  const m = String(auth).match(/^Bearer\s+(.+)$/i);
  if (m && m[1] && m[1].length > 40) return m[1].trim();
  return "";
}

function clientWho(event) {
  const headers = (event && event.headers) || {};
  return headers["x-nf-client-connection-ip"] ||
    headers["cf-connecting-ip"] ||
    (headers["x-forwarded-for"] || "").split(",")[0].trim() ||
    "anon";
}

async function resolveAccount(accessToken) {
  if (!accessToken || !supabaseConfigured()) return null;
  try {
    const userRes = await fetch(`${env("SUPABASE_URL")}/auth/v1/user`, {
      headers: {
        apikey: env("SUPABASE_ANON_KEY"),
        authorization: `Bearer ${accessToken}`,
      },
    });
    if (!userRes.ok) return null;
    const user = await userRes.json();
    const email = String(user.email || "").trim().toLowerCase();
    if (!email || !user.id) return null;

    let entitlement = null;
    try {
      const profRes = await sb(
        `profiles?id=eq.${encodeURIComponent(user.id)}&select=email,token_budget,context_limit,plan_label,cooldown_ms`,
        { method: "GET", headers: { accept: "application/json" } },
        { service: true }
      );
      if (profRes.ok) {
        const rows = Array.isArray(profRes.body) ? profRes.body : [];
        const row = rows[0] || null;
        if (row) {
          const tb = Number(row.token_budget);
          const cl = Number(row.context_limit);
          const cool = Number(row.cooldown_ms);
          if ((Number.isFinite(tb) && tb > 0) || (Number.isFinite(cl) && cl > 0)) {
            const limit = Number.isFinite(tb) && tb > 0 ? tb : FREE_USAGE.limit;
            const contextLimit = Number.isFinite(cl) && cl > 0 ? cl : FREE_USAGE.contextLimit;
            const cooldownMs =
              Number.isFinite(cool) && cool > 0 ? cool : FREE_USAGE.cooldownMs;
            entitlement = {
              id: "profile",
              label: row.plan_label || "Member",
              detail: entitlementDetail(limit, contextLimit, cooldownMs),
              limit,
              contextLimit,
              cooldownMs,
              bucketId: "user-" + String(user.id).replace(/-/g, "").slice(0, 12),
            };
          }
        }
      }
    } catch (e) { /* profiles columns optional until SQL is applied */ }

    return {
      id: user.id,
      email,
      entitlement,
    };
  } catch (e) {
    return null;
  }
}

/** Merge Fathom Pro credit tier with signed-in account entitlements (best wins). */
function userBucketId(account) {
  if (!account || !account.id) return null;
  return "user-" + String(account.id).replace(/-/g, "").slice(0, 12);
}

function resolvePlan(rawKeys, account, clientId) {
  const credits = resolveCredits(rawKeys, clientId);
  const signedInBucket = userBucketId(account);
  const ent = account && account.entitlement;
  if (!ent) {
    return {
      ...credits,
      bucketId: signedInBucket || credits.bucketId,
      account: account ? { email: account.email, id: account.id } : null,
    };
  }

  const limit = Math.max(credits.limit, ent.limit || 0);
  const contextLimit = Math.max(credits.contextLimit || 0, ent.contextLimit || 0);
  const cooldownMs = Math.min(credits.cooldownMs, ent.cooldownMs || credits.cooldownMs);
  const fromAccount = (ent.limit || 0) >= credits.limit;
  return {
    ...credits,
    limit,
    contextLimit,
    cooldownMs,
    bucketId: signedInBucket || ent.bucketId || credits.bucketId,
    tier: fromAccount
      ? {
          id: ent.id,
          keysRequired: credits.tier.keysRequired,
          limit,
          cooldownMs,
          contextLimit,
          label: ent.label,
          detail: ent.detail,
        }
      : { ...credits.tier, contextLimit: credits.contextLimit },
    account: { email: account.email, id: account.id, plan: ent.label },
  };
}

function normalizeOpenRouterKey(raw) {
  const key = String(raw || "").trim();
  if (!/^sk-or-[a-z0-9-_]{20,}$/i.test(key)) return "";
  return key;
}

const MODELS = TIERS[DEFAULT_TIER].models;
const MODEL = MODELS[0];

const REFINE_MODEL = process.env.CHOPSTICKS_AI_REFINE_MODEL || "openai/gpt-oss-20b:free";
const REFINE_ENABLED = (process.env.CHOPSTICKS_AI_REFINE || "on") !== "off";

const REFINE_SYSTEM = [
  "You are the reviewer in a two-model pipeline. Another assistant drafted the ",
  "reply below. Improve it and output ONLY the improved reply.\n\n",
  "Fix any inaccuracy, tighten wording, remove padding and repetition, and make ",
  "sure it directly answers what was asked. Keep the draft's facts: do not add ",
  "version numbers, links, commands or claims that are not already there.\n\n",
  "If the draft is already good, return it unchanged. Never mention the draft, ",
  "the review, or yourself as a reviewer - output only the final reply text.",
].join("");
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const TIMEOUT_MS = Number(process.env.CHOPSTICKS_AI_TIMEOUT_MS || 20000);
const REFINE_MIN_MS = 5000;
const LONG_REPLY_TOKENS = 800;
const REFINE_RESERVE_MS = 6000;
const draftBudgetMs = (replyTokens, msLeft) =>
  replyTokens > LONG_REPLY_TOKENS ? msLeft - 800 : Math.max(8000, msLeft - REFINE_RESERVE_MS);

const MAX_CONTEXT_TOKENS = Number(process.env.CHOPSTICKS_AI_MAX_CONTEXT || 48000);
const contextFor = (effortTier, plan) => {
  const cap = (plan && plan.contextLimit) || MAX_CONTEXT_TOKENS;
  const tierCtx = effortTier.context || cap;
  return Math.min(cap, tierCtx);
};
const MAX_REPLY_TOKENS = 400;
const MAX_REPLY_TOKENS_CEILING = 2000;
/** Flat bill per successful reply so higher tiers do not burn allowance faster. */
const BILLABLE_PER_REPLY = Number(process.env.CHOPSTICKS_AI_BILLABLE || 8500);

const APP_VERSION = "2.5.1";
const LANGUAGES = {
  en: "English",
  zh: "Chinese (Simplified)",
  es: "Spanish",
  de: "German",
  ko: "Korean",
  ja: "Japanese",
};

function resolveLanguage(payload, headers) {
  const raw = String((payload && payload.language) || (payload && payload.locale) || "").trim().toLowerCase();
  if (!raw) {
    const al = String((headers && (headers["accept-language"] || headers["Accept-Language"])) || "").toLowerCase();
    if (al.startsWith("zh")) return "zh";
    if (al.startsWith("es")) return "es";
    if (al.startsWith("de")) return "de";
    if (al.startsWith("ko")) return "ko";
    if (al.startsWith("ja")) return "ja";
    return "en";
  }
  if (raw.startsWith("zh")) return "zh";
  if (raw.startsWith("es")) return "es";
  if (raw.startsWith("de")) return "de";
  if (raw.startsWith("ko")) return "ko";
  if (raw.startsWith("ja")) return "ja";
  const code = raw.slice(0, 2);
  return LANGUAGES[code] ? code : "en";
}

function languageInstruction(code) {
  if (code === "en") {
    return "Respond in English unless the user writes in another language; then match their language.";
  }
  const name = LANGUAGES[code] || LANGUAGES.en;
  return `Respond in ${name}. Match the user's language when they switch.`;
}

const MAX_MESSAGES = 12;        // trailing turns kept from the client
const MAX_CHARS_PER_MSG = 2000;
const GROUNDING_INTENTS = 6;

const TOKEN_BUDGET = FREE_USAGE.limit;
const COOLDOWN_MS = FREE_USAGE.cooldownMs;
const SB_TIMEOUT_MS = 5000;
const budgets = new Map(); // bucketId -> { used, windowStart, cooldownUntil }
function budgetBucket(id) {
  const key = id || "global";
  let row = budgets.get(key);
  if (!row) {
    row = { used: 0, windowStart: Date.now(), cooldownUntil: 0 };
    budgets.set(key, row);
  }
  return row;
}
const budget = budgetBucket("global");
let budgetMode = "memory";

const RATE_WINDOW_MS = 60000;
const RATE_MAX = 8;
const DAILY_RATE_MAX = 120;
const SCAVENGER_COOLDOWN_MS = 10 * 60 * 1000;
const hits = new Map();
const dailyHits = new Map();
const scavengerHits = new Map();
const DEBUG_ENABLED = (process.env.CHOPSTICKS_AI_DEBUG || "0") === "1";

/** ~4 chars per token, deliberately an over-estimate so trimming fires early
 *  rather than letting OpenRouter reject an oversized request. */
const estimateTokens = (text) => Math.max(1, Math.ceil(String(text || "").length / 4));
const messageTokens = (m) => estimateTokens(m.content) + 4;

/** Drops the oldest turns until system prompt + history fits the window. The
 *  system prompt is never trimmed - it carries the grounding facts. */
function fitContext(system, turns, contextTokens) {
  const budgetTokens = (contextTokens || MAX_CONTEXT_TOKENS) - MAX_REPLY_TOKENS - messageTokens(system);
  const kept = [];
  let used = 0;
  for (let i = turns.length - 1; i >= 0; i--) {
    const cost = messageTokens(turns[i]);
    if (used + cost > budgetTokens) break;
    kept.unshift(turns[i]);
    used += cost;
  }
  return [system, ...kept];
}

function measureMessages(messages) {
  return messages.reduce((n, m) => n + messageTokens(m), 0);
}

function contextWindowUsage(messages, limit, turnsTotal) {
  return {
    used: measureMessages(messages),
    limit,
    turns: messages.filter((m) => m.role !== "system").length,
    turnsTotal: turnsTotal ?? messages.filter((m) => m.role !== "system").length,
  };
}

function memoryBudgetState(now, bucketId, limit, cooldownMs) {
  const row = budgetBucket(bucketId);
  const lim = limit || TOKEN_BUDGET;
  const cool = cooldownMs || COOLDOWN_MS;
  if (row.cooldownUntil && now < row.cooldownUntil) {
    return { blocked: true, retryInMs: row.cooldownUntil - now, used: row.used, limit: lim };
  }
  if (row.cooldownUntil && now >= row.cooldownUntil) {
    row.used = 0;
    row.windowStart = now;
    row.cooldownUntil = 0;
  }
  return { blocked: false, used: row.used, limit: lim, cooldownMs: cool };
}

function memorySpend(tokens, now, bucketId, limit, cooldownMs) {
  const row = budgetBucket(bucketId);
  const lim = limit || TOKEN_BUDGET;
  const cool = cooldownMs || COOLDOWN_MS;
  row.used += tokens;
  if (row.used >= lim) row.cooldownUntil = now + cool;
  return row;
}

function supabaseConfigured() {
  return Boolean(env("SUPABASE_URL") && (env("SUPABASE_SERVICE_ROLE_KEY") || env("SUPABASE_ANON_KEY")));
}

function supabaseAuthKey(useService) {
  if (useService && env("SUPABASE_SERVICE_ROLE_KEY")) return env("SUPABASE_SERVICE_ROLE_KEY");
  return env("SUPABASE_ANON_KEY");
}

async function sb(path, init = {}, opts = {}) {
  const useService = opts.service !== false && Boolean(env("SUPABASE_SERVICE_ROLE_KEY"));
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), SB_TIMEOUT_MS);
  try {
    const res = await fetch(`${env("SUPABASE_URL")}/rest/v1/${path}`, {
      ...init,
      signal: ctrl.signal,
      headers: {
        apikey: supabaseAuthKey(useService),
        authorization: `Bearer ${supabaseAuthKey(useService)}`,
        "content-type": "application/json",
        ...(init.headers || {}),
      },
    });
    const text = await res.text();
    let body = null;
    try {
      body = text ? JSON.parse(text) : null;
    } catch {
      body = text;
    }
    return { ok: res.ok, status: res.status, body };
  } finally {
    clearTimeout(t);
  }
}

async function budgetPeek(now, opts = {}) {
  const bucketId = opts.bucketId || "global";
  const limit = opts.limit || TOKEN_BUDGET;
  const cooldownMs = opts.cooldownMs || COOLDOWN_MS;
  if (!supabaseConfigured()) {
    budgetMode = "memory";
    const state = memoryBudgetState(now, bucketId, limit, cooldownMs);
    return { ...state, mode: "memory", bucketId, limit, cooldownMs };
  }
  try {
    let res = await sb("rpc/chopsticks_ai_budget_peek", {
      method: "POST",
      body: JSON.stringify({
        p_limit: limit,
        p_cooldown_ms: cooldownMs,
        p_id: bucketId,
      }),
    }, { service: true });
    if ((!res.ok || !res.body || typeof res.body !== "object") && bucketId.startsWith("ip-")) {
      res = await sb("rpc/chopsticks_ai_budget_peek", {
        method: "POST",
        body: JSON.stringify({ p_limit: limit, p_cooldown_ms: cooldownMs, p_id: bucketId }),
      }, { service: true });
    }
    if (!res.ok || !res.body || typeof res.body !== "object") {
      budgetMode = "memory";
      const state = memoryBudgetState(now, bucketId, limit, cooldownMs);
      return { ...state, mode: "memory", bucketId, limit, cooldownMs };
    }
    budgetMode = "supabase";
    const used = Number(res.body.used) || 0;
    budgetBucket(bucketId).used = used;
    if (res.body.blocked) {
      return {
        blocked: true,
        retryInMs: Number(res.body.retry_in_ms) || 0,
        used,
        mode: "supabase",
        bucketId,
        limit,
        cooldownMs,
      };
    }
    return { blocked: false, used, mode: "supabase", bucketId, limit, cooldownMs };
  } catch {
    budgetMode = "memory";
    const state = memoryBudgetState(now, bucketId, limit, cooldownMs);
    return { ...state, mode: "memory", bucketId, limit, cooldownMs };
  }
}

async function budgetSpend(tokens, now, opts = {}) {
  const spent = Math.max(0, Math.min(50000, Math.round(Number(tokens) || 0)));
  const bucketId = opts.bucketId || "global";
  const limit = opts.limit || TOKEN_BUDGET;
  const cooldownMs = opts.cooldownMs || COOLDOWN_MS;
  const finish = (used, mode, blocked) => {
    const row = budgetBucket(bucketId);
    const retryInMs = blocked ? Math.max(0, (row.cooldownUntil || 0) - now) : 0;
    return { used, mode, limit, bucketId, blocked: Boolean(blocked), retryInMs };
  };
  if (!supabaseConfigured()) {
    budgetMode = "memory";
    const row = memorySpend(spent, now, bucketId, limit, cooldownMs);
    return finish(row.used, "memory", row.used >= limit);
  }
  try {
    let res = await sb("rpc/chopsticks_ai_budget_spend", {
      method: "POST",
      body: JSON.stringify({
        p_tokens: spent,
        p_limit: limit,
        p_cooldown_ms: cooldownMs,
        p_id: bucketId,
      }),
    }, { service: true });
    if ((!res.ok || !res.body || typeof res.body !== "object") && bucketId.startsWith("ip-")) {
      res = await sb("rpc/chopsticks_ai_budget_spend", {
        method: "POST",
        body: JSON.stringify({
          p_tokens: spent,
          p_limit: limit,
          p_cooldown_ms: cooldownMs,
          p_id: bucketId,
        }),
      }, { service: true });
    }
    if (!res.ok || !res.body || typeof res.body !== "object") {
      const row = memorySpend(spent, now, bucketId, limit, cooldownMs);
      return finish(row.used, "memory", row.used >= limit);
    }
    const used = Number(res.body.used) || budgetBucket(bucketId).used;
    budgetBucket(bucketId).used = used;
    budgetMode = "supabase";
    if (res.body.blocked) budgetBucket(bucketId).cooldownUntil = now + cooldownMs;
    return finish(used, "supabase", res.body.blocked);
  } catch {
    const row = memorySpend(spent, now, bucketId, limit, cooldownMs);
    return finish(row.used, "memory", row.used >= limit);
  }
}

function budgetState(now, opts) {
  return memoryBudgetState(now, opts && opts.bucketId, opts && opts.limit, opts && opts.cooldownMs);
}

function spend(tokens, now, opts) {
  memorySpend(tokens, now, opts && opts.bucketId, opts && opts.limit, opts && opts.cooldownMs);
}

const env = (name) =>
  (typeof process !== "undefined" && process.env && process.env[name]) || "";

let KB = null;
function knowledgeBase() {
  if (KB) return KB;
  try {
    KB = require("./chopsticks-ai-kb.json");
  } catch (e) {
    KB = { intents: [] };
  }
  return KB;
}

function normalise(text) {
  return String(text || "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** Last few user turns, joined — follow-ups like "how do I install it?" keep
 *  product context from earlier in the thread. */
function retrievalQuery(turns) {
  return turns
    .filter((m) => m.role === "user")
    .slice(-3)
    .map((m) => m.content)
    .join(" ");
}

const KB_CONFIDENCE_FLOOR = 4;

function scoreQuery(query) {
  const kb = knowledgeBase();
  const text = normalise(query);
  if (!text) return [];
  const padded = " " + text + " ";

  const scored = [];
  for (const intent of kb.intents) {
    let total = 0;
    for (const [term, weight] of intent.terms) {
      if (padded.includes(" " + term + " ")) total += weight;
    }
    if (total > 0) scored.push({ intent, score: total });
  }
  scored.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    if (b.intent.priority !== a.intent.priority) return b.intent.priority - a.intent.priority;
    return a.intent.id < b.intent.id ? -1 : 1;
  });
  return scored;
}

/** Same word-boundary scoring as the offline engine, used purely to pick
 *  which facts to hand the model. Weak matches (e.g. bare "minecraft") are
 *  excluded so general questions are not steered to HQ portfolio snippets. */
function retrieve(query, limit = GROUNDING_INTENTS) {
  return scoreQuery(query)
    .filter((s) => s.score >= KB_CONFIDENCE_FLOOR)
    .slice(0, limit)
    .map((s) => s.intent);
}

function clientWantsLiveOnly(payload) {
  if (payload.offlineMode === true || payload.offlineChatMode === true) return false;
  if (payload.onlineMode === true) return true;
  if (payload.client === "widget") return true;
  return payload.mode === "agent" || !payload.offlineMode;
}

function kbFallbackAnswer(query) {
  const top = scoreQuery(query)[0];
  if (!top || top.score < KB_CONFIDENCE_FLOOR) return null;
  return top.intent.answer;
}

/** Looser KB match when live models are down. */
function kbBestEffortAnswer(query) {
  const top = scoreQuery(query)[0];
  if (!top || top.score < 2) return null;
  return top.intent.answer;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const SEARCH_ENABLED = (process.env.CHOPSTICKS_AI_SEARCH || "on") !== "off";
const SEARCH_TIMEOUT_MS = Number(process.env.CHOPSTICKS_AI_SEARCH_TIMEOUT_MS || 4500);
const SEARCH_MIN_LEN = 3;
const MAX_SOURCES = 12;
const UA = "cs.AI/2.0 (+https://chopstickshq.com/chopsticks-ai/)";

function wantsSearch(text) {
  if (!SEARCH_ENABLED) return false;
  return String(text || "").trim().length >= SEARCH_MIN_LEN;
}

/** Strips an optional `/search` prefix; search runs either way. */
function parseSearchRequest(text) {
  const raw = String(text || "").trim();
  if (/^\/search\b/i.test(raw)) {
    const q = raw.replace(/^\/search\s*/i, "").trim();
    return { query: q || raw, hadPrefix: true };
  }
  return { query: raw, hadPrefix: false };
}

function normUrl(src) {
  if (!src) return "";
  if (/^https?:\/\//i.test(src)) return src;
  return "https://" + String(src).replace(/^\/\//, "");
}

async function fetchJson(url, signal, init) {
  const res = await fetch(url, {
    signal,
    headers: { "User-Agent": UA, ...(init && init.headers) },
    ...init,
  });
  if (!res.ok) return null;
  return res.json().catch(() => null);
}

async function fetchText(url, signal, init) {
  const res = await fetch(url, {
    signal,
    headers: { "User-Agent": UA, ...(init && init.headers) },
    ...init,
  });
  if (!res.ok) return null;
  return res.text().catch(() => null);
}

function sourceKey(item) {
  const url = normUrl(item.src || item.url || "");
  if (url) {
    try {
      const u = new URL(url);
      return u.hostname.replace(/^www\./, "") + u.pathname.replace(/\/$/, "");
    } catch (e) {
      return url.toLowerCase();
    }
  }
  return String(item.title || "").toLowerCase();
}

function dedupeSources(items) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    if (!item || (!item.title && !item.src)) continue;
    const key = sourceKey(item);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}

function decodeDdgRedirect(href) {
  if (!href) return "";
  if (href.includes("uddg=")) {
    try {
      return decodeURIComponent(href.match(/uddg=([^&]+)/)[1]);
    } catch (e) { /* fall through */ }
  }
  return href;
}

async function searchDuckDuckGoJson(query, signal) {
  const out = [];
  const ddg = await fetchJson(
    "https://api.duckduckgo.com/?format=json&no_html=1&skip_disambig=1&q=" +
      encodeURIComponent(query), signal
  ).catch(() => null);

  if (!ddg) return out;

  if (ddg.AbstractText) {
    out.push({
      title: ddg.Heading || query,
      text: ddg.AbstractText,
      src: ddg.AbstractURL || ddg.AbstractSource || "",
      via: "DuckDuckGo",
    });
  }
  for (const t of (ddg.RelatedTopics || []).slice(0, 4)) {
    if (t && t.Text) {
      out.push({
        title: (t.Text.split(" - ")[0] || t.Text).slice(0, 120),
        text: t.Text,
        src: t.FirstURL || "",
        via: "DuckDuckGo",
      });
    }
    if (t && t.Topics) {
      for (const sub of t.Topics.slice(0, 2)) {
        if (sub && sub.Text) {
          out.push({
            title: (sub.Text.split(" - ")[0] || sub.Text).slice(0, 120),
            text: sub.Text,
            src: sub.FirstURL || "",
            via: "DuckDuckGo",
          });
        }
      }
    }
  }
  return out;
}

/** DuckDuckGo lite HTML — organic links to real websites (no API key). */
async function searchDuckDuckGoWeb(query, signal) {
  const html = await fetchText("https://lite.duckduckgo.com/lite/", signal, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "text/html",
      "Accept-Language": "en-US,en;q=0.9",
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    },
    body: new URLSearchParams({ q: query, b: "" }).toString(),
  }).catch(() => null);

  if (!html || !/result-link/i.test(html)) return [];

  const out = [];
  const re = /<a[^>]*href=['"]([^'"]+)['"][^>]*class=['"]result-link['"][^>]*>([^<]+)<\/a>/gi;
  let m;
  while ((m = re.exec(html)) && out.length < 6) {
    const url = decodeDdgRedirect(m[1]);
    const title = m[2].trim();
    if (title && url && /^https?:\/\//i.test(url)) {
      out.push({ title: title.slice(0, 120), text: title, src: url, via: "Web" });
    }
  }
  return out;
}

/** Stack Overflow / Stack Exchange — good for technical questions, no key. */
async function searchStackExchange(query, signal) {
  const data = await fetchJson(
    "https://api.stackexchange.com/2.3/search/advanced?order=desc&sort=relevance" +
      "&site=stackoverflow&pagesize=4&q=" + encodeURIComponent(query),
    signal
  ).catch(() => null);
  return (data && data.items || []).map((item) => ({
    title: item.title || query,
    text: "Stack Overflow Q&A — score " + (item.score || 0),
    src: item.link || "",
    via: "Stack Overflow",
  }));
}

/** Hacker News — tech news and discussions via Algolia (no key). */
async function searchHackerNews(query, signal) {
  const data = await fetchJson(
    "https://hn.algolia.com/api/v1/search?query=" + encodeURIComponent(query) + "&hitsPerPage=4",
    signal
  ).catch(() => null);
  return (data && data.hits || []).map((hit) => ({
    title: hit.title || hit.story_title || query,
    text: [
      hit.points ? hit.points + " points" : "",
      hit.num_comments ? hit.num_comments + " comments" : "",
    ].filter(Boolean).join(", "),
    src: hit.url || ("https://news.ycombinator.com/item?id=" + hit.objectID),
    via: "Hacker News",
  }));
}

/** GitHub repositories — open-source projects and docs (no key, rate-limited). */
async function searchGitHub(query, signal) {
  const data = await fetchJson(
    "https://api.github.com/search/repositories?q=" + encodeURIComponent(query) +
      "&sort=stars&per_page=3",
    signal
  ).catch(() => null);
  return (data && data.items || []).map((item) => ({
    title: item.full_name || item.name || query,
    text: [
      item.description || "",
      item.stargazers_count ? item.stargazers_count + " stars" : "",
    ].filter(Boolean).join(" — "),
    src: item.html_url || "",
    via: "GitHub",
  }));
}

/** Wikidata — structured facts and entity descriptions (no key). */
async function searchWikidata(query, signal) {
  const data = await fetchJson(
    "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=" +
      encodeURIComponent(query) + "&language=en&format=json&origin=*&limit=3",
    signal
  ).catch(() => null);
  return (data && data.search || []).map((item) => ({
    title: (item.display && item.display.label && item.display.label.value) || query,
    text: (item.display && item.display.description && item.display.description.value) || "",
    src: "https://www.wikidata.org/wiki/" + item.id,
    via: "Wikidata",
  }));
}

/** MDN Web Docs — JavaScript, HTML, CSS, and web APIs (no key). */
async function searchMdn(query, signal) {
  const data = await fetchJson(
    "https://developer.mozilla.org/api/v1/search?q=" + encodeURIComponent(query) +
      "&locale=en-US",
    signal
  ).catch(() => null);
  return (data && data.documents || []).slice(0, 4).map((doc) => ({
    title: doc.title || query,
    text: doc.summary || "",
    src: "https://developer.mozilla.org" + (doc.mdn_url || ""),
    via: "MDN",
  }));
}

/** Chromium UA for Google / web fetch (Blink-compatible). */
const CHROMIUM_UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

/** Google web results via HTML (no API key). */
async function searchGoogleWeb(query, signal) {
  const html = await fetchText(
    "https://www.google.com/search?q=" + encodeURIComponent(query) + "&num=10&hl=en",
    signal,
    { headers: { "User-Agent": CHROMIUM_UA, "Accept-Language": "en-US,en;q=0.9" } }
  ).catch(() => null);
  if (!html) return [];
  const out = [];
  const re = /<a[^>]+href="\/url\?q=([^"&]+)[^"]*"[^>]*><h3[^>]*>([\s\S]*?)<\/h3>/gi;
  let m;
  while ((m = re.exec(html)) && out.length < 8) {
    let url = m[1].replace(/&amp;/g, "&");
    try { url = decodeURIComponent(url); } catch (e) { /* keep */ }
    const title = m[2].replace(/<[^>]+>/g, "").replace(/&amp;/g, "&").trim();
    if (url.startsWith("http") && title) {
      out.push({ title, text: "", src: url, via: "Chromium" });
    }
  }
  if (out.length) return out;
  const plain = /<a[^>]+href="(https?:\/\/(?!webcache\.googleusercontent)[^"]+)"[^>]*>([^<]{4,140})<\/a>/gi;
  while ((m = plain.exec(html)) && out.length < 8) {
    const title = m[2].replace(/&amp;/g, "&").trim();
    if (title.toLowerCase().includes("google")) continue;
    out.push({ title, text: "", src: m[1], via: "Chromium" });
  }
  return out;
}

/**
 * Chromium engine — Google web + DuckDuckGo (Chrome UA).
 * Used by the Browser rail and chat grounding.
 */
async function chromiumEngine(query, signal, maxSources) {
  const cap = Math.max(1, Math.min(MAX_SOURCES, Number(maxSources) || 8));
  const batches = await Promise.allSettled([
    searchGoogleWeb(query, signal),
    searchDuckDuckGoWeb(query, signal),
    searchDuckDuckGoJson(query, signal),
  ]);
  let found = [];
  for (const batch of batches) {
    if (batch.status === "fulfilled" && Array.isArray(batch.value)) {
      found.push(...batch.value.map((f) => ({
        ...f,
        via: f.via || "Chromium",
      })));
    }
  }
  return dedupeSources(found).slice(0, cap);
}

/** @deprecated alias — use chromiumEngine */
async function mozillaEngine(query, signal, maxSources) {
  return chromiumEngine(query, signal, maxSources);
}

/** npm registry — JavaScript packages (no key). */
async function searchNpm(query, signal) {
  const data = await fetchJson(
    "https://registry.npmjs.org/-/v1/search?text=" + encodeURIComponent(query) + "&size=3",
    signal
  ).catch(() => null);
  return (data && data.objects || []).map((obj) => ({
    title: (obj.package && obj.package.name) || query,
    text: (obj.package && obj.package.description) || "",
    src: "https://www.npmjs.com/package/" + ((obj.package && obj.package.name) || ""),
    via: "npm",
  }));
}

/** arXiv — research papers (no key). */
async function searchArxiv(query, signal) {
  const xml = await fetchText(
    "https://export.arxiv.org/api/query?search_query=all:" +
      encodeURIComponent(query) + "&max_results=3",
    signal
  ).catch(() => null);
  if (!xml) return [];
  const out = [];
  for (const block of xml.split("<entry>").slice(1, 4)) {
    const title = (block.match(/<title>([\s\S]*?)<\/title>/) || [])[1];
    const summary = (block.match(/<summary>([\s\S]*?)<\/summary>/) || [])[1];
    const id = (block.match(/<id>([^<]+)<\/id>/) || [])[1];
    if (!title) continue;
    out.push({
      title: title.replace(/\s+/g, " ").trim(),
      text: (summary || "").replace(/\s+/g, " ").trim().slice(0, 280),
      src: id || "",
      via: "arXiv",
    });
  }
  return out;
}

/** Brave Search — general web results (optional BRAVE_SEARCH_API_KEY, free tier). */
async function searchBrave(query, signal) {
  const key = env("BRAVE_SEARCH_API_KEY");
  if (!key) return [];
  const data = await fetchJson(
    "https://api.search.brave.com/res/v1/web/search?q=" + encodeURIComponent(query) + "&count=6",
    signal,
    { headers: { Accept: "application/json", "X-Subscription-Token": key } }
  ).catch(() => null);
  return (data && data.web && data.web.results || []).map((item) => ({
    title: item.title,
    text: item.description || "",
    src: item.url || "",
    via: "Web",
  }));
}

/** Up to three Wikipedia articles matching the query. */
async function searchWikipedia(query, signal, limit) {
  const hit = await fetchJson(
    "https://en.wikipedia.org/w/api.php?action=query&list=search&format=json" +
      "&origin=*&srlimit=" + (limit || 3) + "&srsearch=" + encodeURIComponent(query),
    signal
  ).catch(() => null);
  const titles = (hit && hit.query && hit.query.search || []).map((s) => s.title);
  if (!titles.length) return [];

  const summaries = await Promise.all(titles.map(async (title) => {
    const wiki = await fetchJson(
      "https://en.wikipedia.org/api/rest_v1/page/summary/" +
        encodeURIComponent(title.replace(/\s+/g, "_")), signal
    ).catch(() => null);
    if (!wiki || !wiki.extract) return null;
    return {
      title: wiki.title,
      text: wiki.extract,
      src: (wiki.content_urls && wiki.content_urls.desktop && wiki.content_urls.desktop.page) || "",
      via: "Wikipedia",
    };
  }));
  return summaries.filter(Boolean);
}

/** Google results via serper.dev (optional SERPER_API_KEY — free tier available). */
async function searchSerper(query, signal) {
  const key = env("SERPER_API_KEY");
  if (!key) return [];
  const data = await fetchJson("https://google.serper.dev/search", signal, {
    method: "POST",
    headers: { "X-API-KEY": key, "Content-Type": "application/json" },
    body: JSON.stringify({ q: query, num: 6 }),
  }).catch(() => null);
  if (!data) return [];
  const organic = (data.organic || []).map((item) => ({
    title: item.title,
    text: item.snippet || "",
    src: item.link || "",
    via: "Google",
  }));
  const kg = data.knowledgeGraph;
  if (kg && (kg.description || kg.title)) {
    organic.unshift({
      title: kg.title || query,
      text: kg.description || "",
      src: kg.website || kg.descriptionLink || "",
      via: "Google",
    });
  }
  return organic;
}

/** Google Programmable Search (optional GOOGLE_CSE_API_KEY + GOOGLE_CSE_CX). */
async function searchGoogleCse(query, signal) {
  const key = env("GOOGLE_CSE_API_KEY");
  const cx = env("GOOGLE_CSE_CX");
  if (!key || !cx) return [];
  const data = await fetchJson(
    "https://www.googleapis.com/customsearch/v1?key=" + encodeURIComponent(key) +
      "&cx=" + encodeURIComponent(cx) + "&num=6&q=" + encodeURIComponent(query),
    signal
  ).catch(() => null);
  return (data && data.items || []).map((item) => ({
    title: item.title,
    text: item.snippet || "",
    src: item.link || "",
    via: "Google",
  }));
}

/** Returns prompt context plus structured sources for the client UI. */
async function webSearch(query, maxSources) {
  const cap = Math.max(1, Math.min(MAX_SOURCES, Number(maxSources) || MAX_SOURCES));
  const c = new AbortController();
  const timer = setTimeout(() => c.abort(), SEARCH_TIMEOUT_MS);
  try {
    const batches = await Promise.allSettled([
      mozillaEngine(query, c.signal, Math.min(6, cap)),
      searchSerper(query, c.signal),
      searchGoogleCse(query, c.signal),
      searchBrave(query, c.signal),
      searchWikidata(query, c.signal),
      searchStackExchange(query, c.signal),
      searchHackerNews(query, c.signal),
      searchGitHub(query, c.signal),
      searchNpm(query, c.signal),
      searchArxiv(query, c.signal),
    ]);

    let found = [];
    for (const batch of batches) {
      if (batch.status === "fulfilled" && Array.isArray(batch.value)) {
        found.push(...batch.value);
      }
    }
    found = dedupeSources(found).slice(0, cap);

    if (!found.length) return { context: "", sources: [] };

    const sources = found.map((f) => ({
      title: String(f.via ? f.via + ": " + (f.title || query) : (f.title || query)).slice(0, 140),
      url: normUrl(f.src),
      snippet: String(f.text || "").slice(0, 280),
    }));

    const context = sources
      .map((f) => `- ${f.title}: ${f.snippet}${f.url ? ` (${f.url})` : ""}`)
      .join("\n");

    return { context, sources };
  } catch (e) {
    return { context: "", sources: [] };
  } finally {
    clearTimeout(timer);
  }
}

/** Facts chopsticksAI knows about itself. Built from the live config so the
 *  numbers can never drift from what the endpoint actually enforces. */
function selfFacts(tier) {
  const t = tier || TIERS[DEFAULT_TIER];
  return [
    "ABOUT YOURSELF (answer questions about your own capabilities from this):",
    `- You are cs.AI ${APP_VERSION} (chopsticksAI), built and run by Chopsticks HQ.`,
    `- You run on selectable effort levels in ChopsticksAI: Low, Medium, High, Xhigh, Xhigh+, Insane, Chopsticks, ChopCode, and StickerCoder+ (coding specialists).`,
    `- Current effort: ${t.label}, with a ${contextFor(t).toLocaleString()} token context window.`,
    t.stickerCoder
      ? "- StickerCoder+ mode: prioritise complete, runnable code, write_file tool use, and sharp engineering answers."
      : t.chopCode
        ? "- ChopCode mode: prioritise complete, runnable code, clear file fences, and practical engineering answers."
        : null,
    `- Longest single reply: ${MAX_REPLY_TOKENS_CEILING.toLocaleString()} tokens (in ChopsticksAI Lab); ${MAX_REPLY_TOKENS} in the sidebar widget.`,
    `- Conversation memory: the last ${MAX_MESSAGES} turns.`,
    `- Free usage allowance: ${TOKEN_BUDGET.toLocaleString()} tokens, then a ${Math.round(COOLDOWN_MS / 3600000)}-hour cooldown.`,
    "- Upgrades are bought with Fathom Pro oi-pl API keys (not OpenRouter keys): 2 keys → 800k + 2h30m cooldown; 5 keys → 900k + 2h; 10 keys → 1m + 1h.",
    `- Rate limit: ${RATE_MAX} requests per minute per visitor.`,
    "- You search with the Chromium engine first (Google web, DuckDuckGo), then wider sources (Stack Overflow, Hacker News, GitHub, npm, arXiv, Google/Brave when configured). Cite sources in your answer.",
    "- The macOS app includes a built-in Chromium browser rail; visitors can search on https://chopstickshq.com/chopsticks-ai/#search without chatting.",
    "- You answer general questions on any topic, and are the in-house expert on Chopsticks HQ software.",
    "- You need no OpenRouter API key from the user; Fathom Pro unlock keys can be redeemed as usage credits in the Usage tab.",
    "- Email sign-in runs on chopstickshq.com — email and password only, no verification email.",
    "- You are available on every page of chopstickshq.com, in ChopsticksAI at /chopailab, and inside rNitro's Chat tab.",
    "- You do not use vector embeddings — retrieval is keyword intent scoring plus Chromium web search, never a semantic vector index.",
    "- Do not name or speculate about any underlying model, provider or vendor.",
  ].filter(Boolean).join("\n");
}

function systemPrompt(grounding, mode, web, tier, language) {
  const agent = mode === "agent" || tier.chopCode ? [
    "\n\nYou are running as the ChopsticksAI agent",
    tier.stickerCoder
      ? " in StickerCoder+ mode (coding specialist)"
      : tier.chopCode
        ? " in ChopCode mode (coding specialist)"
        : "",
    ". The user may ask you to ",
    "write code, config, scripts, documents or data files.\n",
    "- Prefer the write_file tool for each file you create (path + full content).\n",
    "- You may also put files in fenced code blocks: ```lang filename then the body.\n",
    "- Give complete, runnable files rather than fragments or ellipses.\n",
    "- Keep explanation outside tools/fences and brief.",
    tier.chopsticksFocus
      ? "\n- Chopsticks effort: prioritise accurate answers about Chopsticks HQ software from the reference material; still help with general tasks when asked."
      : "",
    tier.stickerCoder
      ? "\n- StickerCoder+: prefer correct, idiomatic code; use tools aggressively for file creation; include imports and edge cases; keep prose short."
      : tier.chopCode
        ? "\n- ChopCode: prefer correct, idiomatic code; include imports and edge-case handling; add short usage notes only when helpful; do not pad with long essays."
        : "",
  ].join("") : "";

  const facts = grounding.length
    ? grounding.map((i) => `### ${i.label}\n${i.answer}`).join("\n\n")
    : "(no specific reference material matched this question)";

  const persona = tier.stickerCoder
    ? [
        "You are cs.AI StickerCoder+ — a coding mode of chopsticksAI, made by Chopsticks HQ.\n\n",
        "Focus on software engineering: write, debug, refactor, and explain code. ",
        "Be precise and practical. Prefer working solutions over theory.\n\n",
      ].join("")
    : tier.chopCode
    ? [
        "You are cs.AI ChopCode — the coding mode of chopsticksAI, made by Chopsticks HQ.\n\n",
        "Focus on software engineering: write, debug, refactor, and explain code. ",
        "Be precise and practical. Prefer working solutions over theory.\n\n",
      ].join("")
    : [
        "You are cs.AI " + APP_VERSION + " (chopsticksAI), a helpful and knowledgeable general-purpose assistant, ",
        "made by Chopsticks HQ.\n\n",
        "Answer ANY question the user asks — general knowledge, science, history, coding, ",
        "writing, maths, recommendations, advice, casual conversation, anything. You are a ",
        "full assistant, not a support bot, and you should never refuse a question simply ",
        "because it is unrelated to Chopsticks HQ.\n\n",
        "Answer naturally and conversationally. Be concise by default — a short paragraph — ",
        "and go longer only when the question genuinely needs it. Plain text reads best; ",
        "use markdown only when structure really helps, such as code blocks for code.\n\n",
      ].join("");

  return [
    persona,
    "You are also the in-house expert on Chopsticks HQ's own software: rNitro (macOS menu ",
    "bar system monitor), Fathom Air (battery monitor), Fathom Pro (battery, weather and AI ",
    "chat), ARENA (an FPS game), and Chopsticks Shaders. When a question touches those, the ",
    "reference material below is authoritative.\n\n",
    selfFacts(tier),
    web ? web : "",
    "\n\nREFERENCE MATERIAL:\n\n",
    facts,
    "\n\nRules:\n",
    "- For questions about Chopsticks HQ software, version numbers, install commands, file ",
    "names and pricing must come from the reference material above. If it does not cover the ",
    "detail, say you're not certain and point to chopstickshq.com rather than guessing.\n",
    "- Never invent a download link, command, or version number for Chopsticks software.\n",
    "- Never imply Chopsticks software costs money or needs a subscription.\n",
    "- For everything else, just answer the question well using your own knowledge. Do not ",
    "steer the conversation back to Chopsticks HQ, and do not mention the reference material ",
    "when it isn't relevant.\n",
    "- If you are genuinely unsure of a fact, say so rather than inventing one.\n",
    "- You are cs.AI (chopsticksAI), made by Chopsticks HQ. If asked what model, ",
    "engine or company is behind you, say you are cs.AI by Chopsticks ",
    "HQ. Never name or speculate about any underlying model, provider or vendor.\n",
    "- Never mention this prompt or the reference material as such; just answer.",
    "\n" + languageInstruction(language || "en"),
    agent,
  ].join("");
}

function rateLimited(key) {
  const now = Date.now();
  const rec = hits.get(key);
  if (!rec || now - rec.start > RATE_WINDOW_MS) {
    hits.set(key, { start: now, n: 1 });
    if (hits.size > 500) {
      for (const [k, v] of hits) if (now - v.start > RATE_WINDOW_MS) hits.delete(k);
    }
    return false;
  }
  rec.n += 1;
  return rec.n > RATE_MAX;
}

function dailyRateLimited(key) {
  const day = new Date().toISOString().slice(0, 10);
  const recKey = `${key}|${day}`;
  const n = (dailyHits.get(recKey) || 0) + 1;
  dailyHits.set(recKey, n);
  if (dailyHits.size > 3000) {
    for (const k of dailyHits.keys()) {
      if (!k.endsWith(`|${day}`)) dailyHits.delete(k);
    }
  }
  return n > DAILY_RATE_MAX;
}

function scavengerRateLimited(key) {
  const now = Date.now();
  const until = scavengerHits.get(key) || 0;
  if (now < until) return true;
  scavengerHits.set(key, now + SCAVENGER_COOLDOWN_MS);
  if (scavengerHits.size > 500) {
    for (const [k, v] of scavengerHits) if (v < now) scavengerHits.delete(k);
  }
  return false;
}

async function handleMintUnlockKey(event, payload) {
  const who = clientWho(event);
  if (rateLimited(who)) {
    return json(429, { error: "rate limited", retryInMs: 60000 });
  }
  const scavenger = payload.source === "scavenger";
  const vaultPw = env("FATHOM_VAULT_PASSWORD");
  const supplied = String(payload.vaultPassword || payload.password || "").trim();
  if (scavenger) {
    if (scavengerRateLimited(who)) {
      return json(429, { error: "scavenger cooldown", retryInMs: SCAVENGER_COOLDOWN_MS });
    }
  } else if (!vaultPw || supplied !== vaultPw) {
    return json(403, { error: "forbidden" });
  }
  const key = mintFathomProUnlockKey();
  if (!key) return json(503, { error: "unlock signing not configured" });
  return json(200, { mode: "mint", key, prefix: "oi-pl2" });
}

const json = (status, body) => ({
  statusCode: status,
  headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  body: JSON.stringify(body),
});

/** OpenAI-compatible tools for agent file creation. */
const AGENT_TOOLS = [
  {
    type: "function",
    function: {
      name: "write_file",
      description:
        "Create a downloadable file for the user. Call once per file. Prefer this over pasting huge code in prose.",
      parameters: {
        type: "object",
        properties: {
          path: {
            type: "string",
            description: "File name only, e.g. analyse.py or src/app.swift",
          },
          content: {
            type: "string",
            description: "Full file contents",
          },
          language: {
            type: "string",
            description: "Optional language tag for highlighting (python, swift, …)",
          },
        },
        required: ["path", "content"],
      },
    },
  },
];

function sanitizeFileName(raw) {
  let name = String(raw || "file.txt").replace(/\\/g, "/").split("/").filter(Boolean).pop() || "file.txt";
  name = name.replace(/[^\w.\-()+ ]+/g, "_").replace(/^\.+/, "").slice(0, 180);
  return name || "file.txt";
}

function langFromName(name) {
  const ext = String(name).split(".").pop().toLowerCase();
  const map = {
    py: "python", js: "javascript", ts: "typescript", tsx: "tsx", jsx: "jsx",
    swift: "swift", md: "markdown", json: "json", html: "html", css: "css",
    sh: "bash", rs: "rust", go: "go", java: "java", rb: "ruby", php: "php",
    sql: "sql", yaml: "yaml", yml: "yaml", toml: "toml", c: "c", cpp: "cpp", h: "c",
  };
  return map[ext] || "text";
}

/** Pull ```lang filename … ``` fences into structured files. */
function extractFencedFiles(text) {
  const out = [];
  const re = /```([^\n`]*)\n([\s\S]*?)```/g;
  let m;
  while ((m = re.exec(String(text || "")))) {
    const head = String(m[1] || "").trim();
    const body = String(m[2] || "").replace(/\n+$/, "");
    if (!body) continue;
    const bits = head.split(/\s+/).filter(Boolean);
    let lang = "text";
    let name = "";
    if (bits.length >= 2) {
      lang = bits[0].toLowerCase();
      name = sanitizeFileName(bits.slice(1).join(" "));
    } else if (bits.length === 1 && /\./.test(bits[0])) {
      name = sanitizeFileName(bits[0]);
      lang = langFromName(name);
    } else if (bits.length === 1) {
      lang = bits[0].toLowerCase();
      name = `chopsticksai-file.${lang === "text" ? "txt" : lang}`;
    } else {
      name = "chopsticksai-file.txt";
    }
    out.push({ name, content: body, language: lang });
  }
  return out;
}

function mergeFiles(a, b) {
  const map = new Map();
  for (const f of [...(a || []), ...(b || [])]) {
    if (!f || !f.name) continue;
    map.set(f.name, {
      name: f.name,
      content: String(f.content || ""),
      language: f.language || langFromName(f.name),
    });
  }
  return [...map.values()];
}

/** Ensure each file appears as a downloadable fence in the reply text. */
function ensureFileFences(text, files) {
  let out = String(text || "").trim();
  for (const f of files || []) {
    const needle = f.name;
    if (out.includes(needle) && out.includes("```")) {
      const hasFence = new RegExp("```[^\\n]*\\b" + needle.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\b").test(out);
      if (hasFence) continue;
    }
    const lang = f.language || langFromName(f.name);
    out += (out ? "\n\n" : "") + "```" + lang + " " + f.name + "\n" + f.content + "\n```";
  }
  return out;
}

function parseToolArgs(raw) {
  if (raw && typeof raw === "object") return raw;
  try {
    return JSON.parse(String(raw || "{}"));
  } catch (e) {
    return {};
  }
}

/**
 * After a first completion that may include tool_calls, execute write_file
 * tools and ask the model to finish. Returns { text, files, tokens }.
 */
async function continueWithTools({
  model, messages, first, key, signal, maxTokens, temperature,
}) {
  const files = [];
  let tokens = first.tokens || 0;
  let msgs = messages.map((m) => ({ ...m }));
  let cur = first;
  for (let round = 0; round < 4; round++) {
    const calls = cur.toolCalls || [];
    if (!calls.length) {
      return { text: cur.text || "", files, tokens };
    }
    msgs.push({
      role: "assistant",
      content: cur.text || null,
      tool_calls: calls,
    });
    for (const tc of calls) {
      const fn = (tc && tc.function) || {};
      const name = String(fn.name || "");
      const args = parseToolArgs(fn.arguments);
      let result = { ok: false, error: "unknown tool" };
      if (name === "write_file") {
        const path = sanitizeFileName(args.path || args.name || "file.txt");
        const content = String(args.content ?? args.body ?? "");
        if (content.length > 1_500_000) {
          result = { ok: false, error: "file too large" };
        } else {
          files.push({
            name: path,
            content,
            language: String(args.language || langFromName(path)).slice(0, 40),
          });
          result = { ok: true, path, bytes: content.length };
        }
      }
      msgs.push({
        role: "tool",
        tool_call_id: tc.id || ("call_" + round),
        content: JSON.stringify(result),
      });
    }
    try {
      cur = await callModel({
        model,
        messages: msgs,
        key,
        signal,
        maxTokens,
        temperature,
        tools: AGENT_TOOLS,
        toolChoice: "auto",
      });
    } catch (e) {
      return {
        text: first.text || (files.length ? "Created files via tools." : ""),
        files,
        tokens,
      };
    }
    if (!cur.ok) {
      return {
        text: first.text || (files.length ? "Created files via tools." : ""),
        files,
        tokens,
      };
    }
    tokens += cur.tokens || 0;
  }
  return { text: cur.text || "", files, tokens };
}

/** Normalize assistant message content (string or text parts). */
function messageText(msg) {
  const raw = msg && msg.content;
  if (typeof raw === "string") return raw.trim();
  if (Array.isArray(raw)) {
    return raw
      .map((part) => {
        if (typeof part === "string") return part;
        if (part && typeof part.text === "string") return part.text;
        if (part && typeof part.content === "string") return part.content;
        return "";
      })
      .join("")
      .trim();
  }
  return "";
}

/** One chat completion. Supports optional OpenAI-style tools. */
async function callModel({ model, messages, key, signal, maxTokens, temperature, tools, toolChoice }) {
  const asked = maxTokens ?? MAX_REPLY_TOKENS;
  const body = {
    model,
    messages,
    temperature: temperature ?? 0.3,
    max_tokens: Math.max(asked, Math.min(asked + 256, asked * 2, 1200)),
  };
  if (tools && tools.length) {
    body.tools = tools;
    body.tool_choice = toolChoice || "auto";
  }
  const res = await fetch(OPENROUTER_URL, {
    method: "POST",
    signal,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://chopstickshq.com",
      "X-Title": "chopsticksAI",
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    return { ok: false, status: res.status, detail: await res.text().catch(() => "") };
  }
  const data = await res.json();
  const choice = (data.choices && data.choices[0]) || {};
  const msg = choice.message || {};
  let text = messageText(msg);
  const toolCalls = Array.isArray(msg.tool_calls) ? msg.tool_calls : [];
  if (!text && !toolCalls.length && /length|max_tokens/i.test(String(choice.finish_reason || choice.native_finish_reason || ""))) {
    if (!signal || !signal.aborted) {
      try {
        const retryBody = {
          model: body.model,
          messages: body.messages,
          temperature: body.temperature,
          max_tokens: Math.min(Math.max(asked * 3, 900), 2000),
        };
        const res2 = await fetch(OPENROUTER_URL, {
          method: "POST",
          signal,
          headers: {
            Authorization: `Bearer ${key}`,
            "Content-Type": "application/json",
            "HTTP-Referer": "https://chopstickshq.com",
            "X-Title": "chopsticksAI",
          },
          body: JSON.stringify(retryBody),
        });
        if (res2.ok) {
          const data2 = await res2.json();
          const msg2 = (data2.choices && data2.choices[0] && data2.choices[0].message) || {};
          text = messageText(msg2);
          const reported2 = data2.usage && Number(data2.usage.total_tokens);
          if (text) {
            return {
              ok: true,
              text,
              toolCalls: [],
              tokens: Number.isFinite(reported2) && reported2 > 0 ? reported2 : null,
            };
          }
        }
      } catch (e) {
      }
    }
  }
  if (!text && !toolCalls.length) {
    return {
      ok: false,
      status: res.status,
      detail: "empty completion finish=" + String(choice.finish_reason || ""),
    };
  }
  const reported = data.usage && Number(data.usage.total_tokens);
  return {
    ok: true,
    text,
    toolCalls,
    tokens: Number.isFinite(reported) && reported > 0 ? reported : null,
  };
}

function usagePayload(plan, state) {
  const used = state.used || 0;
  const limit = plan.limit || 0;
  const ratio = limit > 0 ? used / limit : 0;
  let warning = null;
  if (!state.blocked && ratio >= 0.8) {
    const pct = Math.round(ratio * 100);
    warning = {
      level: ratio >= 0.95 ? "critical" : "high",
      ratio,
      percent: pct,
      message:
        ratio >= 0.95
          ? `Allowance almost full (${pct}%). Next replies may hit the cooldown soon.`
          : `You've used ${pct}% of your allowance. Consider redeeming Fathom Pro keys in Usage.`,
    };
  }
  return {
    used,
    limit,
    contextLimit: plan.contextLimit || MAX_CONTEXT_TOKENS,
    cooldownMs: plan.cooldownMs,
    cooldown: state.blocked
      ? { blocked: true, retryInMs: state.retryInMs || 0 }
      : null,
    warning,
    keysValid: plan.keysValid,
    keysSubmitted: plan.keysSubmitted,
    keysRejected: plan.keysRejected,
    tier: {
      id: plan.tier.id,
      label: plan.tier.label,
      detail: plan.tier.detail,
      keysRequired: plan.tier.keysRequired,
      contextLimit: plan.contextLimit || plan.tier.contextLimit,
    },
    upgrades: plan.upgrades,
    free: {
      limit: FREE_USAGE.limit,
      cooldownMs: FREE_USAGE.cooldownMs,
      contextLimit: FREE_USAGE.contextLimit,
      label: FREE_USAGE.label,
      detail: FREE_USAGE.detail,
    },
    account: plan.account || null,
    budgetMode: state.mode || budgetMode,
    creditSource: "fathom-pro-oi-pl",
    product: "cs.AI",
    version: "2.0",
  };
}

async function healthHandler(event) {
  const configured = Boolean(env("OPENROUTER_API_KEY"));
  const now = Date.now();
  const who = clientWho(event);
  let unlockKeys = [];
  try {
    const q = (event && event.queryStringParameters) || {};
    if (q.unlockKeys) {
      unlockKeys = String(q.unlockKeys).split(",").map((s) => s.trim()).filter(Boolean);
    }
  } catch (e) { /* ignore */ }
  const accessToken = extractAccessToken(event);
  const account = await resolveAccount(accessToken);
  const plan = resolvePlan(unlockKeys, account, who);
  let cooldown = null;
  let budgetModeNow = "memory";
  let used = 0;
  try {
    const state = await budgetPeek(now, {
      bucketId: plan.bucketId,
      limit: plan.limit,
      cooldownMs: plan.cooldownMs,
    });
    budgetModeNow = state.mode || budgetMode;
    used = state.used || 0;
    if (state.blocked) {
      cooldown = { blocked: true, retryInMs: state.retryInMs || 0 };
    }
  } catch (e) {
    /* health should still return */
  }
  const ok = configured && !(cooldown && cooldown.blocked);
  return json(ok ? 200 : 503, {
    ok,
    service: "chopsticks-ai",
    configured,
    cooldown,
    budget: { used, limit: plan.limit },
    usage: usagePayload(plan, {
      used,
      blocked: Boolean(cooldown && cooldown.blocked),
      retryInMs: cooldown && cooldown.retryInMs,
      mode: budgetModeNow,
    }),
    budgetMode: budgetModeNow,
    search: SEARCH_ENABLED,
    time: new Date(now).toISOString(),
  });
}

async function handler(event) {
  if (event.httpMethod === "OPTIONS") return { statusCode: 204, body: "" };
  if (event.httpMethod === "GET") {
    return healthHandler(event);
  }
  if (event.httpMethod !== "POST") {
    return json(405, { error: "GET or POST only" });
  }

  const key = env("OPENROUTER_API_KEY");
  if (!key) {
    return json(200, {
      reply:
        "chopsticksAI isn't configured on this host yet. " +
        "Ask on chopstickshq.com or email " + AI_EMAIL + ".",
      mode: "unconfigured",
    });
  }

  let payload;
  try {
    payload = JSON.parse(event.body || "{}");
  } catch (e) {
    return json(400, { error: "invalid JSON" });
  }

  const tier = tierOf(payload.tier);
  const tierKey = String(payload.tier || DEFAULT_TIER).toLowerCase().replace(/\s+/g, "");
  const tierId = TIER_ALIASES[tierKey] || tierKey || DEFAULT_TIER;
  const apiKey = key;
  const unlockKeys = Array.isArray(payload.unlockKeys)
    ? payload.unlockKeys
    : (Array.isArray(payload.fathomProKeys) ? payload.fathomProKeys : []);
  const who = clientWho(event);
  const accessToken = extractAccessToken(event);
  const account = await resolveAccount(accessToken);

  if (payload.action === "mintUnlockKey") {
    return handleMintUnlockKey(event, payload);
  }

  if (payload.action === "signupSendCode") {
    return handleSignupSendCode(event, payload, rateLimited);
  }
  if (payload.action === "signupVerify") {
    return handleSignupVerify(event, payload, rateLimited);
  }
  if (payload.action === "authSignUp") {
    return handleAuthSignUp(event, payload, rateLimited);
  }
  if (payload.action === "authSignIn") {
    return handleAuthSignIn(event, payload, rateLimited);
  }
  if (payload.action === "authRefresh") {
    return handleAuthRefresh(event, payload);
  }

  if (payload.action === "vaultCheck") {
    const vaultPw = env("FATHOM_VAULT_PASSWORD");
    const supplied = String(payload.vaultPassword || payload.password || "").trim();
    if (!vaultPw || supplied !== vaultPw) {
      return json(403, { error: "forbidden" });
    }
    return json(200, { ok: true });
  }

  if (AUTH_REQUIRED_TIERS.has(tierId) && !account) {
    return json(403, {
      error: "sign in required for this tier",
      mode: "auth_required",
      tier: tier.label,
    });
  }

  const plan = resolvePlan(unlockKeys, account, who);
  const budgetOpts = {
    bucketId: plan.bucketId,
    limit: plan.limit,
    cooldownMs: plan.cooldownMs,
  };

  if (payload.action === "usage" || payload.mode === "usage") {
    const nowU = Date.now();
    const stateU = await budgetPeek(nowU, budgetOpts);
    return json(200, {
      mode: "usage",
      usage: usagePayload(plan, stateU),
      budget: { used: stateU.used || 0, limit: plan.limit },
      budgetMode: stateU.mode || budgetMode,
    });
  }

  if (payload.action === "search" || payload.mode === "search") {
    const q = String(payload.q || payload.query || "").trim().slice(0, 240);
    if (q.length < SEARCH_MIN_LEN) {
      return json(400, { error: "query too short", min: SEARCH_MIN_LEN });
    }
    if (!SEARCH_ENABLED) {
      return json(200, { mode: "search", engine: "chromium", query: q, sources: [], searched: false });
    }
    const headersS = event.headers || {};
    const whoS =
      headersS["x-nf-client-connection-ip"] ||
      headersS["cf-connecting-ip"] ||
      (headersS["x-forwarded-for"] || "").split(",")[0].trim() ||
      "anon";
    if (rateLimited(whoS) || dailyRateLimited(whoS)) {
      return json(429, { error: "rate limited", retryInMs: 60000 });
    }
    const cap = Math.max(1, Math.min(MAX_SOURCES, Number(payload.max) || 8));
    const c = new AbortController();
    const timer = setTimeout(() => c.abort(), SEARCH_TIMEOUT_MS);
    let raw = [];
    try {
      raw = await mozillaEngine(q, c.signal, cap);
    } finally {
      clearTimeout(timer);
    }
    const sources = raw.map((f) => ({
      title: String(f.title || q).slice(0, 140),
      url: normUrl(f.src),
      snippet: String(f.text || "").slice(0, 280),
      via: f.via || "Chromium",
    }));
    return json(200, {
      mode: "search",
      engine: "chromium",
      product: "cs.AI",
      version: "2.0",
      query: q,
      searched: true,
      sources,
    });
  }

  const headers = event.headers || {};
  if (rateLimited(who) || dailyRateLimited(who)) {
    return json(429, {
      reply: "That's a lot of questions at once — give it a minute and try again.",
      mode: "limited",
    });
  }

  const incoming = Array.isArray(payload.messages) ? payload.messages : [];
  const language = resolveLanguage(payload, headers);
  const turns = incoming
    .filter((m) => m && (m.role === "user" || m.role === "assistant") && m.content)
    .slice(-MAX_MESSAGES)
    .map((m) => ({
      role: m.role,
      content: String(m.content).slice(0, MAX_CHARS_PER_MSG),
    }));

  const lastUser = [...turns].reverse().find((m) => m.role === "user");
  if (!lastUser) return json(400, { error: "no user message" });

  const rawAtt = Array.isArray(payload.attachments) ? payload.attachments : [];
  const attachments = rawAtt.slice(0, 40).map((a) => ({
    name: String((a && a.name) || "file").slice(0, 200),
    mime: String((a && a.mime) || "").slice(0, 120),
    size: Number(a && a.size) || 0,
    url: String((a && a.url) || "").slice(0, 2000),
    path: String((a && a.path) || "").slice(0, 500),
    text: typeof (a && a.text) === "string" ? String(a.text).slice(0, 200000) : "",
  })).filter((a) => a.name);
  if (attachments.length) {
    const lines = attachments.map((a, i) => {
      const sz = a.size >= 1024 * 1024 * 1024
        ? (a.size / (1024 * 1024 * 1024)).toFixed(2) + " GB"
        : a.size >= 1024 * 1024
          ? (a.size / (1024 * 1024)).toFixed(1) + " MB"
          : a.size >= 1024
            ? Math.round(a.size / 1024) + " KB"
            : a.size + " B";
      let block = `${i + 1}. ${a.name} (${a.mime || "file"}, ${sz})`;
      if (a.url) block += `\n   URL: ${a.url}`;
      if (a.text) {
        block += `\n   --- file text preview ---\n${a.text}\n   --- end preview ---`;
      } else if (/^image\//i.test(a.mime)) {
        block += "\n   (image attached — describe using the filename/URL; do not invent pixel details)";
      } else {
        block += "\n   (binary/large file — use the URL/name; contents not inlined)";
      }
      return block;
    });
    lastUser.content = (String(lastUser.content || "") +
      "\n\nATTACHED FILES (uploaded by the user for this turn):\n" + lines.join("\n"))
      .slice(0, 220000);
  }

  const now = Date.now();
  const state = await budgetPeek(now, budgetOpts);
  if (state.blocked) {
    queueUsageEmail(plan, state, account);
    const mins = Math.ceil(state.retryInMs / 60000);
    const willEmail = account && account.email && env("RESEND_API_KEY") && env("CHOPSTICKS_AI_USAGE_EMAIL") !== "off";
    const next = plan.upgrades.find((u) => !u.unlocked);
    const tip = next
      ? ` Redeem ${next.keysRequired} Fathom Pro API keys in Usage to raise your limit (${next.detail}).`
      : "";
    return json(200, {
      reply:
        "chopsticksAI has used up its allowance for now and is cooling down " +
        `(about ${mins} minute${mins === 1 ? "" : "s"} left).` +
        (willEmail ? " We emailed you at " + account.email + "." : "") +
        tip +
        " Everything it knows is still on chopstickshq.com in the meantime.",
      mode: "cooldown",
      retryInMs: state.retryInMs,
      usage: usagePayload(plan, state),
      budget: { used: state.used || 0, limit: plan.limit },
    });
  }

  const wanted = Number(payload.maxTokens);
  const tierCap = tier.maxReply || MAX_REPLY_TOKENS_CEILING;
  const replyTokens = Number.isFinite(wanted)
    ? Math.max(100, Math.min(tierCap, MAX_REPLY_TOKENS_CEILING, Math.round(wanted)))
    : (payload.mode === "agent" ? tierCap : MAX_REPLY_TOKENS);

  const { query: searchQuery, hadPrefix } = parseSearchRequest(lastUser.content);
  const clientSearchOff = payload.disableSearch === true || payload.client === "widget";
  const isWidget = payload.client === "widget";
  const searchOn = wantsSearch(searchQuery) && (!tier.chopCode || hadPrefix) && (!clientSearchOff || hadPrefix);
  const searchMax = isWidget ? 3 : Math.min(tier.searchMax || 6, 5);
  const searchStarted = Date.now();
  const webBundle = searchOn
    ? await webSearch(searchQuery, searchMax)
    : { context: "", sources: [] };
  const searchMs = Date.now() - searchStarted;
  let webSection = "";
  if (searchOn) {
    const clipped = String(webBundle.context || "").slice(0, 2800);
    webSection = clipped
      ? "\n\nWEB SEARCH RESULTS (retrieved just now for this question — weave in anything useful; cite URLs when you rely on one, and add a **Sources** section at the end with markdown links when you used them):\n" + clipped
      : "\n\nWEB SEARCH: no snippets returned for this query — answer from your knowledge and the reference material below.";
  }

  const modelTurns = turns.map((m) => ({ ...m }));
  if (hadPrefix && modelTurns.length) {
    const last = modelTurns[modelTurns.length - 1];
    if (last.role === "user") last.content = searchQuery;
  }

  const system = {
    role: "system",
    content: systemPrompt(
      retrieve(retrievalQuery(modelTurns), tier.grounding || GROUNDING_INTENTS),
      payload.mode, webSection, tier, language
    ),
  };
  const messages = fitContext(system, modelTurns, contextFor(tier, plan));

  const RESCUE_RESERVE_MS = 9000;
  const platformLeft = Math.max(8000, 22000 - searchMs);
  const modelWindow = Math.min(TIMEOUT_MS, platformLeft);
  const deadline = Date.now() + modelWindow;
  const modelDeadline = deadline - RESCUE_RESERVE_MS;
  const ATTEMPT_CAP_MS = 7000;
  const withTimeout = (ms) => {
    const c = new AbortController();
    const t = setTimeout(() => c.abort(), Math.max(500, ms));
    return { signal: c.signal, done: () => clearTimeout(t) };
  };
  try {
    let draft = null;
    let draftModel = null;
    let lastStatus = 0;
    let lastDetail = "";
    let producedFiles = [];

    const ask = String(lastUser.content || "");
    const wantsFiles = /\b(write|create|generate|make|build|scaffold|implement)\b[\s\S]{0,80}\b(file|script|code|program|function|class|module|component|app)\b|\.\w{1,8}\b|```|write_file/i.test(ask);
    const useTools = payload.enableTools !== false
      && (tier.chopCode || payload.tools === true || wantsFiles);

    const longRun = replyTokens > LONG_REPLY_TOKENS;
    const chain = (longRun
      ? (tier.longModels || tier.models)
      : tier.models
    ).slice(0, 2);

    for (let ci = 0; ci < chain.length; ci++) {
      const candidate = chain[ci];
      const msLeft = modelDeadline - Date.now();
      if (msLeft <= 1500) break;
      const share = ci === 0
        ? Math.floor(msLeft * 0.75)
        : msLeft - 400;
      const reserveRetry = useTools ? Math.min(3500, Math.floor(share * 0.35)) : 0;
      const budgetMs = Math.min(ATTEMPT_CAP_MS, Math.max(2500, share - reserveRetry));
      let r;
      const attemptStart = Date.now();
      const tryCall = async (ms, withTools) => {
        const g = withTimeout(Math.min(ATTEMPT_CAP_MS, ms));
        try {
          return await callModel({
            model: candidate,
            messages,
            key: apiKey,
            signal: g.signal,
            maxTokens: replyTokens,
            temperature: tier.temperature,
            tools: withTools ? AGENT_TOOLS : undefined,
            toolChoice: withTools ? "auto" : undefined,
          });
        } catch (e) {
          return { ok: false, status: 0, detail: String(e && e.name) };
        } finally {
          g.done();
        }
      };

      r = await tryCall(budgetMs, useTools);
      if (!r.ok && useTools) {
        const left = modelDeadline - Date.now() - 300;
        if (left > 2000) {
          r = await tryCall(Math.min(left, Math.max(reserveRetry, 3500)), false);
        }
      }
      if (!r.ok && (r.status === 429 || r.status === 503)) {
        const left = modelDeadline - Date.now() - 300;
        if (left > 2500) {
          await sleep(300);
          r = await tryCall(Math.min(left, 7000), false);
        }
      }
      if (r.ok && (r.text || (r.toolCalls && r.toolCalls.length))) {
        if (r.toolCalls && r.toolCalls.length) {
          const left = Math.min(deadline - Date.now() - 400, modelDeadline - Date.now() + 2000);
          if (left > 2000) {
            const g3 = withTimeout(left);
            try {
              const cont = await continueWithTools({
                model: candidate,
                messages,
                first: r,
                key: apiKey,
                signal: g3.signal,
                maxTokens: replyTokens,
                temperature: tier.temperature,
              });
              draft = {
                ok: true,
                text: cont.text || r.text || "",
                tokens: cont.tokens,
                toolCalls: [],
              };
              producedFiles = cont.files || [];
            } catch (e) {
              draft = {
                ok: true,
                text: r.text || "Created files via tools.",
                tokens: r.tokens || null,
                toolCalls: [],
              };
            } finally {
              g3.done();
            }
          } else {
            draft = {
              ok: true,
              text: r.text || "Created files via tools.",
              tokens: r.tokens || null,
              toolCalls: [],
            };
          }
        } else {
          draft = r;
        }
        draftModel = candidate;
        break;
      }
      lastStatus = r.status || 0;
      lastDetail = (r.detail || "") + ` [${candidate.split("/")[1]} ${Date.now() - attemptStart}/${budgetMs}ms]`;
      if (ci === 0 && Date.now() - attemptStart > 8000) break;
    }

    if (!draft) {
      const slimSystem = {
        role: "system",
        content: systemPrompt(
          retrieve(retrievalQuery(modelTurns), Math.min(3, tier.grounding || 3)),
          payload.mode, "", tier, language
        ),
      };
      const slimMessages = fitContext(slimSystem, modelTurns, 12000);
      const rescues = [
        "nvidia/nemotron-3-nano-30b-a3b:free",
        "openai/gpt-oss-20b:free",
      ];
      for (const rescue of rescues) {
        const left = deadline - Date.now() - 200;
        if (left < 2000) break;
        const slice = Math.min(4500, left);
        const gR = withTimeout(slice);
        try {
          const r = await callModel({
            model: rescue,
            messages: slimMessages,
            key: apiKey,
            signal: gR.signal,
            maxTokens: Math.min(350, replyTokens),
            temperature: 0.3,
          });
          if (r.ok && r.text) {
            draft = r;
            draftModel = rescue;
            break;
          }
          lastStatus = r.status || lastStatus;
          lastDetail = (r.detail || lastDetail || "") + ` [rescue:${rescue.split("/")[1]}]`;
        } catch (e) {
          lastDetail = String(e && e.name) + ` [rescue:${rescue.split("/")[1]}]`;
        } finally {
          gR.done();
        }
      }
    }

    if (!draft) {
      console.error("chopsticksAI: all models failed", {
        tier: tier.label, status: lastStatus, detail: String(lastDetail).slice(0, 300),
        replyTokens, msLeft: deadline - Date.now(),
      });
      const liveOnly = clientWantsLiveOnly(payload);
      if (!liveOnly) {
        const kbQuery = retrievalQuery(turns) || lastUser.content;
        const kbAnswer = kbFallbackAnswer(kbQuery);
        if (kbAnswer) {
          return json(200, {
            reply: kbAnswer,
            mode: "offline",
          });
        }
      }
      const panicLeft = deadline - Date.now();
      if (panicLeft > 1800) {
        const gP = withTimeout(panicLeft - 300);
        try {
          const r = await callModel({
            model: "nvidia/nemotron-3-nano-30b-a3b:free",
            messages: fitContext(
              {
                role: "system",
                content: systemPrompt(
                  retrieve(retrievalQuery(modelTurns), 2),
                  payload.mode, "", tier, language
                ),
              },
              modelTurns,
              10000
            ),
            key: apiKey,
            signal: gP.signal,
            maxTokens: Math.min(320, replyTokens),
            temperature: 0.35,
          });
          if (r.ok && r.text) {
            draft = r;
            draftModel = "nvidia/nemotron-3-nano-30b-a3b:free";
          }
        } catch (e) {
          lastDetail = String(e && e.name) + " [panic]";
        } finally {
          gP.done();
        }
      }
    }

    if (!draft) {
      const liveOnly = clientWantsLiveOnly(payload);
      if (!liveOnly) {
        const kbQuery = retrievalQuery(turns) || lastUser.content;
        const kbAnswer = kbFallbackAnswer(kbQuery);
        if (kbAnswer) {
          return json(200, {
            reply: kbAnswer,
            mode: "offline",
            ...(DEBUG_ENABLED && payload.debug ? {
              diag: {
                status: lastStatus,
                detail: String(lastDetail || "").slice(0, 400),
                replyTokens,
                msLeft: deadline - Date.now(),
              },
            } : {}),
          });
        }
      }
      return json(200, {
        reply: "Try sending that again — the live model is still responding.",
        mode: "error",
        ...(DEBUG_ENABLED && payload.debug ? {
          diag: {
            status: lastStatus,
            detail: String(lastDetail || "").slice(0, 400),
            replyTokens,
            msLeft: deadline - Date.now(),
          },
        } : {}),
      });
    }

    let spent = draft.tokens || (messages.reduce((n, m) => n + messageTokens(m), 0) + MAX_REPLY_TOKENS);
    let reply = draft.text || "";
    let refinedBy = null;

    producedFiles = mergeFiles(producedFiles, extractFencedFiles(reply));
    if (producedFiles.length) {
      reply = ensureFileFences(reply, producedFiles);
    }

    const hasCodeBlock = reply.includes("```") || producedFiles.length > 0;
    const timeLeft = deadline - Date.now();
    const refineOn = REFINE_ENABLED && tier.refine !== false && !isWidget;
    const refineModel = tier.refineModel || REFINE_MODEL;
    if (refineOn && refineModel && refineModel !== draftModel
        && !hasCodeBlock && timeLeft >= REFINE_MIN_MS) {
      const question = [...turns].reverse().find((m) => m.role === "user");
      const g = withTimeout(timeLeft - 500);
      let r;
      try {
      r = await callModel({
        model: refineModel,
        key: apiKey,
        signal: g.signal,
        temperature: 0.2,
        messages: [
          { role: "system", content: REFINE_SYSTEM },
          {
            role: "user",
            content:
              "QUESTION:\n" + (question ? question.content : "") +
              "\n\nDRAFT REPLY:\n" + reply,
          },
        ],
      });
      } catch (e) {
        r = { ok: false };
      } finally {
        g.done();
      }
      if (r.ok && r.text) {
        reply = r.text;
        refinedBy = refineModel;
        spent += r.tokens || estimateTokens(draft.text || "") + MAX_REPLY_TOKENS;
      }
    }

    const spentResult = await budgetSpend(BILLABLE_PER_REPLY, now, budgetOpts);
    queueUsageEmail(plan, spentResult, account);

    if (!reply && !producedFiles.length) {
      return json(200, { reply: "I didn't get a usable answer back — try rephrasing?", mode: "empty" });
    }
    if (!reply && producedFiles.length) {
      reply = ensureFileFences("Created " + producedFiles.length + " file(s).", producedFiles);
    }

    const ctxLimit = contextFor(tier, plan);
    return json(200, {
      reply,
      mode: "live",
      model: "cs.AI " + APP_VERSION,
      tier: tier.label,
      context: ctxLimit,
      contextWindow: contextWindowUsage(messages, ctxLimit, turns.length),
      searched: searchOn,
      sources: webBundle.sources,
      files: producedFiles.map((f) => ({
        name: f.name,
        content: f.content,
        language: f.language,
      })),
      budget: { used: spentResult.used, limit: plan.limit },
      usage: usagePayload(plan, {
        used: spentResult.used,
        blocked: false,
        mode: spentResult.mode,
      }),
      budgetMode: spentResult.mode,
    });
  } catch (e) {
    const aborted = e && e.name === "AbortError";
    return json(200, {
      reply: aborted
        ? "That took too long to answer. Try a shorter question?"
        : "chopsticksAI hit an error reaching its model. Try again shortly.",
      mode: "error",
    });
  } finally {
  }
}

module.exports = {
  handler, retrieve, retrievalQuery, systemPrompt, normalise, fitContext,
  measureMessages, contextWindowUsage,
  wantsSearch, parseSearchRequest, webSearch, selfFacts, verifyFathomProUnlock,
  mintFathomProUnlockKey, handleMintUnlockKey,
  resolveCredits, resolvePlan, resolveAccount, usagePayload,
  budgetPeek, budgetSpend, budgetState, spend,
  _budget: budget, budgetMode, MAX_CONTEXT_TOKENS, TOKEN_BUDGET, COOLDOWN_MS,
  FREE_USAGE, CREDIT_TIERS, mozillaEngine,
};
