const crypto = require("node:crypto");
const { isBrazil, brazilJson } = require("./region-block.js");
const { queueUsageEmail, AI_EMAIL } = require("./usage-email.js");
const {
  handleSignupSendCode,
  handleSignupVerify,
  handleAuthSignUp,
  handleAuthSignIn,
  handleLoginVerify,
  handleAuthRefresh,
} = require("./signup-verify.js");
const { runChopCodeEnsemble, CHOPCODE_AGENTS } = require("./chopcode-ensemble.js");
const {
  analyzeRequest,
  computeBudget,
  followUpQueries,
  rankEvidence,
  detectConflicts,
  formatEvidence,
  hybridRetrieve,
  routeModels,
  CRITIC_SYSTEM,
  DECOMPOSE_HINT,
} = require("./chopsticks-intelligence.js");

const TIERS = {
  rice: {
    label: "Rice",
    models: [
      "groq/llama-3.1-8b-instant",
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "nvidia/llama-3.3-nemotron-super-49b-v1:free",
    ],
    longModels: [
      "groq/llama-3.1-8b-instant",
      "nvidia/nemotron-3-nano-30b-a3b:free",
    ],
    context: 16000,
    refine: false,
    maxReply: 700,
    grounding: 3,
    searchMax: 3,
    timeoutMs: 14000,
    temperature: 0.15,
  },
  tamago: {
    label: "Tamago",
    models: [
      "groq/llama-3.3-70b-versatile",
      "nvidia/nemotron-3-super-120b-a12b:free",
      "z-ai/glm-5.2:free",
    ],
    longModels: [
      "groq/openai/gpt-oss-120b",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ],
    context: 48000,
    refine: false,
    maxReply: 1800,
    grounding: 5,
    searchMax: 6,
    timeoutMs: 20000,
    temperature: 0.2,
  },
  hibachi: {
    label: "Hibachi",
    models: [
      "groq/openai/gpt-oss-120b",
      "nvidia/nemotron-3-ultra-550b-a55b:free",
      "google/gemma-4-31b-it:free",
    ],
    longModels: [
      "nvidia/nemotron-3-ultra-550b-a55b:free",
      "groq/openai/gpt-oss-120b",
    ],
    context: 96000,
    refine: true,
    refineModels: ["groq/llama-3.3-70b-versatile"],
    maxReply: 3500,
    grounding: 8,
    searchMax: 8,
    timeoutMs: 24000,
    temperature: 0.22,
  },
  wagyu: {
    label: "Wagyu A5",
    wagyuGrade: 5,
    models: [
      "nvidia/nemotron-3-ultra-550b-a55b:free",
      "groq/openai/gpt-oss-120b",
      "google/gemma-4-26b-a4b-it:free",
    ],
    longModels: [
      "nvidia/nemotron-3-ultra-550b-a55b:free",
      "groq/openai/gpt-oss-120b",
    ],
    refine: true,
    refineModels: [
      "groq/llama-3.3-70b-versatile",
      "google/gemma-4-26b-a4b-it:free",
    ],
    context: 160000,
    maxReply: 8000,
    grounding: 16,
    searchMax: 16,
    timeoutMs: 28000,
    temperature: 0.25,
  },
};
const WAGYU_SHARED = {
  models: TIERS.wagyu.models,
  longModels: TIERS.wagyu.longModels,
  refineModels: TIERS.wagyu.refineModels,
};
TIERS.wagyua1 = {
  label: "Wagyu A1",
  wagyuGrade: 1,
  ...WAGYU_SHARED,
  refine: false,
  context: 80000,
  maxReply: 2500,
  grounding: 8,
  searchMax: 8,
  timeoutMs: 22000,
};
TIERS.wagyua2 = {
  label: "Wagyu A2",
  wagyuGrade: 2,
  ...WAGYU_SHARED,
  refine: false,
  context: 96000,
  maxReply: 4000,
  grounding: 10,
  searchMax: 10,
  timeoutMs: 24000,
};
TIERS.wagyua3 = {
  label: "Wagyu A3",
  wagyuGrade: 3,
  ...WAGYU_SHARED,
  refine: true,
  context: 112000,
  maxReply: 5500,
  grounding: 12,
  searchMax: 12,
  timeoutMs: 26000,
};
TIERS.wagyua4 = {
  label: "Wagyu A4",
  wagyuGrade: 4,
  ...WAGYU_SHARED,
  refine: true,
  context: 128000,
  maxReply: 7000,
  grounding: 14,
  searchMax: 14,
  timeoutMs: 26000,
};
TIERS.wagyua5 = { ...TIERS.wagyu, label: "Wagyu A5", wagyuGrade: 5 };
TIERS.chopcode = {
    label: "ChopCode",
    chopCode: true,
    models: [
      "qwen/qwen3-coder:free",
      "groq/llama-3.3-70b-versatile",
      "z-ai/glm-5.2:free",
      "nvidia/nemotron-3-ultra:free",
      "cohere/north-mini-code:free",
      "openai/gpt-oss-20b:free",
      "poolside/laguna-s-2.1:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
      "google/gemma-4-31b-it:free",
      "google/gemma-4-26b-a4b-it:free",
    ],
    longModels: [
      "qwen/qwen3-coder:free",
      "z-ai/glm-5.2:free",
      "groq/llama-3.3-70b-versatile",
      "nvidia/nemotron-3-ultra:free",
      "openai/gpt-oss-20b:free",
    ],
    context: 128000,
    refine: true,
    refineModels: ["moonshotai/kimi-k2.6:free"],
    maxReply: 4096,
    grounding: 8,
    searchMax: 8,
    timeoutMs: 24000,
    temperature: 0.12,
};
TIERS.kaji = {
  label: "Kaji",
  kaji: true,
    models: [
      "z-ai/glm-5.2:free",
      "cohere/north-mini-code:free",
      "nvidia/nemotron-3-ultra:free",
      "poolside/laguna-s-2.1:free",
    ],
    longModels: [
      "nvidia/nemotron-3-ultra:free",
      "z-ai/glm-5.2:free",
      "poolside/laguna-s-2.1:free",
      "cohere/north-mini-code:free",
    ],
  refine: true,
  refineModels: ["z-ai/glm-5.2:free", "cohere/north-mini-code:free"],
  context: 128000,
  maxReply: 4096,
  grounding: 8,
  searchMax: 6,
  timeoutMs: 24000,
  temperature: 0.18,
};
TIERS.max = {
  label: "Max",
  max: true,
  models: TIERS.hibachi.models,
  longModels: TIERS.hibachi.longModels,
  context: 96000,
  refine: true,
  refineModels: TIERS.hibachi.refineModels || ["groq/llama-3.3-70b-versatile"],
  maxReply: 1000,
  grounding: 10,
  searchMax: 10,
  timeoutMs: 26000,
  temperature: 0.15,
};
const TIER_ALIASES = {
  rice: "rice",
  haiku: "rice",
  low: "rice",
  fast: "rice",
  tamago: "tamago",
  sonnet: "tamago",
  medium: "tamago",
  high: "tamago",
  standard: "tamago",
  chopsticks: "tamago",
  super: "tamago",
  hibachi: "hibachi",
  opus: "hibachi",
  pro: "hibachi",
  ultra: "hibachi",
  xhigh: "hibachi",
  xhighplus: "hibachi",
  "xhigh+": "hibachi",
  chopcode: "chopcode",
  "chop-code": "chopcode",
  code: "chopcode",
  kaji: "kaji",
  grok: "kaji",
  grokbot: "kaji",
  "grok-bot": "kaji",
  max: "max",
  maxmode: "max",
  csmax: "max",
  wagyu: "wagyua5",
  fable: "wagyua5",
  insane: "wagyua5",
  stickercoderplus: "wagyua5",
  "stickercoder+": "wagyua5",
  "sticker-coder+": "wagyua5",
  "sticker-coderplus": "wagyua5",
  coderplus: "wagyua5",
  "coder+": "wagyua5",
  a1: "wagyua1",
  a2: "wagyua2",
  a3: "wagyua3",
  a4: "wagyua4",
  a5: "wagyua5",
  "wagyu-a1": "wagyua1",
  "wagyu-a2": "wagyua2",
  "wagyu-a3": "wagyua3",
  "wagyu-a4": "wagyua4",
  "wagyu-a5": "wagyua5",
  wagyu1: "wagyua1",
  wagyu2: "wagyua2",
  wagyu3: "wagyua3",
  wagyu4: "wagyua4",
  wagyu5: "wagyua5",
  wagyua1: "wagyua1",
  wagyua2: "wagyua2",
  wagyua3: "wagyua3",
  wagyua4: "wagyua4",
  wagyua5: "wagyua5",
  "3.1": "rice",
  "csai3.1": "rice",
  "3.3-fast": "tamago",
  "3.3fast": "tamago",
  "3.3-thinking": "hibachi",
  "3.3thinking": "hibachi",
  "3.5-air": "wagyua5",
  airii: "wagyua1",
  air2: "wagyua1",
  airiii: "wagyua2",
  air3: "wagyua2",
  airvi: "wagyua3",
  air6: "wagyua3",
  airv: "wagyua4",
  air5: "wagyua4",
  "cscode-pro": "chopcode",
  cscodepro: "chopcode",
  cscode: "chopcode",
};
const DEFAULT_TIER = "tamago";
const tierOf = (name) => {
  const key = String(name || "").toLowerCase().replace(/\s+/g, "");
  const id = TIER_ALIASES[key] || key;
  return TIERS[id] || TIERS[DEFAULT_TIER];
};

const AUTH_REQUIRED_TIERS = new Set([
  "wagyu", "wagyua1", "wagyua2", "wagyua3", "wagyua4", "wagyua5", "chopcode", "kaji",
]);

function timingSafeString(a, b) {
  const left = Buffer.from(String(a || ""));
  const right = Buffer.from(String(b || ""));
  if (left.length !== right.length) {
    crypto.timingSafeEqual(left, left);
    return false;
  }
  return crypto.timingSafeEqual(left, right);
}

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
  if (!expect) return false;
  return timingSafeString(expect, m[3]);
}

function hashClientBucket(clientId) {
  const salt = env("CHOPSTICKS_AI_BUCKET_SALT");
  if (!salt) return "ip-unknown";
  const id = String(clientId || "unknown").slice(0, 128);
  return "ip-" + crypto.createHmac("sha256", salt).update(id).digest("hex").slice(0, 16);
}

const FREE_USAGE = {
  id: "free",
  keysRequired: 0,
  limit: Number(process.env.CHOPSTICKS_AI_TOKEN_BUDGET || 775000),
  cooldownMs: Number(process.env.CHOPSTICKS_AI_COOLDOWN_MS || 5 * 60 * 60 * 1000),
  contextLimit: Number(process.env.CHOPSTICKS_AI_MAX_CONTEXT || 128000),
  label: "Free",
  detail: "775k tokens · 128k context · resets every 5h",
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
  if (!cooldownMs) {
    return `${toks(limit)} tokens · ${toks(contextLimit)} context · no cooldown`;
  }
  const coolH = Math.round(cooldownMs / 3600000);
  const cool =
    coolH >= 1
      ? `${coolH}h cooldown`
      : `${Math.round(cooldownMs / 60000)}m cooldown`;
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
  if (m && m[1] && m[1].trim().length > 20) return m[1].trim();
  return "";
}

function accountEmailFromUser(user) {
  const direct = String((user && user.email) || "").trim().toLowerCase();
  if (direct.includes("@")) return direct;
  const meta = (user && user.user_metadata) || {};
  const fromMeta = String(meta.email || "").trim().toLowerCase();
  if (fromMeta.includes("@")) return fromMeta;
  const ids = (user && Array.isArray(user.identities)) ? user.identities : [];
  for (const row of ids) {
    const data = (row && row.identity_data) || {};
    const e = String(data.email || "").trim().toLowerCase();
    if (e.includes("@")) return e;
  }
  return "";
}

function clientWho(event) {
  const headers = (event && event.headers) || {};
  const ip = String(headers["x-nf-client-connection-ip"] || headers["cf-connecting-ip"] || "").trim();
  return ip || "unknown";
}

const FOUNDER_EMAIL = "mzx@lam.ws";
const FOUNDER_PLAN = {
  token_budget: 1_000_000,
  context_limit: 1_000_000,
  plan_label: "Founder",
  cooldown_ms: 0,
};

async function ensureFounderProfile(userId, email) {
  if (!userId || String(email || "").toLowerCase() !== FOUNDER_EMAIL) return;
  try {
    await sb(
      "profiles?on_conflict=id",
      {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify({
          id: userId,
          email: FOUNDER_EMAIL,
          token_budget: FOUNDER_PLAN.token_budget,
          context_limit: FOUNDER_PLAN.context_limit,
          plan_label: FOUNDER_PLAN.plan_label,
          cooldown_ms: FOUNDER_PLAN.cooldown_ms,
        }),
      },
      { service: true }
    );
  } catch (e) {  }
}

async function ensureFounderAuthUser() {
  const password = env("CHOPSTICKS_AI_FOUNDER_PASSWORD");
  const url = env("SUPABASE_URL");
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!password || !url || !key) return { ok: false, reason: "not configured" };
  const headers = {
    apikey: key,
    authorization: "Bearer " + key,
    "content-type": "application/json",
  };
  const admin = async (method, path, body) => {
    const res = await fetch(url + path, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    let parsed = null;
    try { parsed = text ? JSON.parse(text) : null; } catch { parsed = text; }
    return { status: res.status, body: parsed };
  };
  let uid = "";
  const listed = await admin("GET", "/auth/v1/admin/users?page=1&per_page=200");
  const users = (listed.body && listed.body.users) || [];
  for (const u of users) {
    if (String(u.email || "").toLowerCase() === FOUNDER_EMAIL) {
      uid = u.id;
      break;
    }
  }
  if (uid) {
    await admin("PUT", "/auth/v1/admin/users/" + uid, {
      password,
      email_confirm: true,
    });
  } else {
    const created = await admin("POST", "/auth/v1/admin/users", {
      email: FOUNDER_EMAIL,
      password,
      email_confirm: true,
    });
    uid = (created.body && (created.body.id || (created.body.user && created.body.user.id))) || "";
  }
  if (uid) await ensureFounderProfile(uid, FOUNDER_EMAIL);
  return { ok: Boolean(uid) };
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
    if (!user || !user.id) return null;
    const email = accountEmailFromUser(user);

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
              Number.isFinite(cool) && cool >= 0 ? cool : FREE_USAGE.cooldownMs;
            entitlement = {
              id: "profile",
              label: row.plan_label || (canPickOpenRouterModel({ email }) ? "Founder" : "Member"),
              detail: entitlementDetail(limit, contextLimit, cooldownMs),
              limit,
              contextLimit,
              cooldownMs,
              bucketId: "user-" + String(user.id).replace(/-/g, "").slice(0, 12),
            };
          }
        }
      }
    } catch (e) {  }

    if (email === FOUNDER_EMAIL) {
      await ensureFounderProfile(user.id, email);
      entitlement = {
        id: "profile",
        label: "Founder",
        detail: entitlementDetail(FOUNDER_PLAN.token_budget, FOUNDER_PLAN.context_limit, FOUNDER_PLAN.cooldown_ms),
        limit: FOUNDER_PLAN.token_budget,
        contextLimit: FOUNDER_PLAN.context_limit,
        cooldownMs: FOUNDER_PLAN.cooldown_ms,
        bucketId: "user-" + String(user.id).replace(/-/g, "").slice(0, 12),
      };
    }

    return {
      id: user.id,
      email,
      entitlement,
    };
  } catch (e) {
    return null;
  }
}

function userBucketId(account) {
  if (!account || !account.id) return null;
  return "user-" + String(account.id).replace(/-/g, "").slice(0, 12);
}

const CHOPCODE_PRO_KEYS = 5;

function canUseChopCode(account, plan) {
  if (!account || !account.id) return false;
  if (account.email === FOUNDER_EMAIL) return true;
  const label = String((account.entitlement && account.entitlement.label) || (plan && plan.account && plan.account.plan) || "").toLowerCase();
  if (label === "founder") return true;
  return Number((plan && plan.keysValid) || 0) >= CHOPCODE_PRO_KEYS;
}

function canUseKaji(account, plan) {
  return canUseChopCode(account, plan);
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
  const cooldownMs = Number.isFinite(ent.cooldownMs)
    ? Math.min(credits.cooldownMs, Math.max(0, ent.cooldownMs))
    : credits.cooldownMs;
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

const MODEL_PICKER_EMAILS = new Set(
  String(process.env.CHOPSTICKS_AI_MODEL_PICKER_EMAILS || "mzx@lam.ws")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean)
);

function canPickOpenRouterModel(account) {
  return !!(account && account.email && MODEL_PICKER_EMAILS.has(account.email));
}

function normalizeOpenRouterModelId(raw) {
  const id = String(raw || "").trim();
  if (!id || id.length > 160) return "";
  if (isClaudeModelId(id)) return id;
  if (/^groq\/.+/i.test(id)) return id;
  if (!/^[a-z0-9][a-z0-9._-]*\/[a-z0-9][a-z0-9._:+\/-]*$/i.test(id)) return "";
  if (id === "nvidia/nemotron-3-ultra:free") return "nvidia/nemotron-3-ultra-550b-a55b:free";
  return id;
}

function isClaudeModelId(id) {
  const s = String(id || "").toLowerCase();
  return s.startsWith("claude-") || s.startsWith("claude/") || s.startsWith("anthropic/claude");
}

function claudeNativeModelId(id) {
  return String(id || "")
    .trim()
    .replace(/^anthropic\//i, "")
    .replace(/^claude\//i, "claude-");
}

function isGroqModelId(id) {
  return String(id || "").toLowerCase().startsWith("groq/");
}

/** HQ OpenRouter key: only :free. Groq/Claude use their own keys. */
function isHqOpenRouterAllowed(id) {
  if (isGroqModelId(id) || isClaudeModelId(id)) return true;
  return String(id || "").toLowerCase().endsWith(":free");
}

function groqNativeModelId(id) {
  if (!isGroqModelId(id)) return "";
  return String(id).slice(5);
}

function normalizeGroqApiKey(raw) {
  const key = String(raw || "").trim();
  if (!/^gsk_[a-zA-Z0-9]+/.test(key)) return "";
  return key;
}

function normalizeUserOpenRouterKey(raw) {
  const key = String(raw || "").trim();
  if (!/^sk-or-v1-[a-zA-Z0-9]+$/.test(key)) return "";
  return key;
}

function normalizeAnthropicKey(raw) {
  const key = String(raw || "").trim();
  if (!/^sk-ant-[a-zA-Z0-9\-_]+$/.test(key)) return "";
  return key;
}

function resolveGroqKey(payload, account, tier) {
  const server = env("GROQ_API_KEY");
  if (tier && tier.groqOnly) return server || "";
  const user = normalizeGroqApiKey(payload && payload.groqKey);
  return user || server || "";
}

function resolveOpenRouterKey(payload) {
  return normalizeUserOpenRouterKey(payload && payload.openRouterKey) || env("OPENROUTER_API_KEY") || "";
}

function resolveAnthropicKey(payload) {
  return normalizeAnthropicKey(payload && payload.anthropicKey);
}

function canUseCustomModel(modelId, payload, account) {
  if (!modelId) return false;
  if (canPickOpenRouterModel(account)) return true;
  if (isClaudeModelId(modelId)) return Boolean(resolveAnthropicKey(payload));
  if (isGroqModelId(modelId)) return Boolean(resolveGroqKey(payload, account));
  return Boolean(normalizeUserOpenRouterKey(payload && payload.openRouterKey));
}

const CLAUDE_MODEL_CATALOG = [
  { id: "claude-opus-4-6", name: "Claude Opus 4.6", context: 200000, provider: "claude" },
  { id: "claude-sonnet-4-6", name: "Claude Sonnet 4.6", context: 200000, provider: "claude" },
  { id: "claude-opus-4-5", name: "Claude Opus 4.5", context: 200000, provider: "claude" },
  { id: "claude-sonnet-4-5", name: "Claude Sonnet 4.5", context: 200000, provider: "claude" },
  { id: "claude-haiku-4-5", name: "Claude Haiku 4.5", context: 200000, provider: "claude" },
  { id: "claude-opus-4-1", name: "Claude Opus 4.1", context: 200000, provider: "claude" },
  { id: "claude-opus-4", name: "Claude Opus 4", context: 200000, provider: "claude" },
  { id: "claude-sonnet-4", name: "Claude Sonnet 4", context: 200000, provider: "claude" },
  { id: "claude-3-7-sonnet-latest", name: "Claude Sonnet 3.7", context: 200000, provider: "claude" },
  { id: "claude-3-5-sonnet-latest", name: "Claude Sonnet 3.5", context: 200000, provider: "claude" },
  { id: "claude-3-5-haiku-latest", name: "Claude Haiku 3.5", context: 200000, provider: "claude" },
  { id: "claude-3-opus-latest", name: "Claude Opus 3", context: 200000, provider: "claude" },
  { id: "claude-3-haiku-20240307", name: "Claude Haiku 3", context: 200000, provider: "claude" },
];

async function fetchAnthropicModels(apiKey) {
  const catalog = CLAUDE_MODEL_CATALOG.slice();
  if (!apiKey) return catalog;
  try {
    const res = await fetch("https://api.anthropic.com/v1/models?limit=1000", {
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
    });
    if (!res.ok) return catalog;
    const body = await res.json();
    const live = (Array.isArray(body.data) ? body.data : [])
      .map((m) => ({
        id: String(m.id || "").trim(),
        name: String(m.display_name || m.id || "").trim(),
        context: Number(m.max_tokens || m.context_window) || 200000,
        provider: "claude",
      }))
      .filter((m) => m.id);
    const seen = new Set(live.map((m) => m.id));
    for (const m of catalog) {
      if (!seen.has(m.id)) live.push(m);
    }
    live.sort((a, b) => a.id.localeCompare(b.id));
    return live;
  } catch (e) {
    return catalog;
  }
}

const GROQ_MODEL_CATALOG = [
  { id: "groq/llama-3.1-8b-instant", name: "Groq · Llama 3.1 8B Instant", context: 131072 },
  { id: "groq/llama-3.3-70b-versatile", name: "Groq · Llama 3.3 70B Versatile", context: 131072 },
  { id: "groq/openai/gpt-oss-20b", name: "Groq · GPT-OSS 20B", context: 131072 },
  { id: "groq/openai/gpt-oss-120b", name: "Groq · GPT-OSS 120B", context: 131072 },
  { id: "groq/qwen/qwen3.6-27b", name: "Groq · Qwen3.6 27B (preview)", context: 131072 },
  { id: "groq/openai/gpt-oss-safeguard-20b", name: "Groq · GPT-OSS Safeguard 20B", context: 131072 },
  { id: "groq/compound-mini", name: "Groq · Compound Mini", context: 131072 },
  { id: "groq/compound", name: "Groq · Compound", context: 131072 },
];

let groqModelsCache = { at: 0, models: [] };
const GROQ_MODELS_CACHE_MS = 10 * 60 * 1000;

async function fetchGroqModelsLive(groqKey) {
  const now = Date.now();
  if (
    groqModelsCache.models.length &&
    now - groqModelsCache.at < GROQ_MODELS_CACHE_MS
  ) {
    return groqModelsCache.models;
  }
  const res = await fetch("https://api.groq.com/openai/v1/models", {
    headers: { Authorization: `Bearer ${groqKey}` },
  });
  if (!res.ok) return GROQ_MODEL_CATALOG.slice();
  const body = await res.json();
  const names = new Map(GROQ_MODEL_CATALOG.map((m) => [groqNativeModelId(m.id), m.name]));
  const models = (Array.isArray(body.data) ? body.data : [])
    .map((m) => {
      const native = String(m.id || "").trim();
      if (!native) return null;
      const id = `groq/${native}`;
      return {
        id,
        name: names.get(native) || `Groq · ${native}`,
        context: Number(m.context_window) || null,
        provider: "groq",
      };
    })
    .filter(Boolean);
  const merged = [...GROQ_MODEL_CATALOG.map((m) => ({ ...m, provider: "groq" }))];
  const seen = new Set(merged.map((m) => m.id));
  for (const m of models) {
    if (!seen.has(m.id)) {
      merged.push(m);
      seen.add(m.id);
    }
  }
  merged.sort((a, b) => a.id.localeCompare(b.id));
  groqModelsCache = { at: now, models: merged };
  return merged;
}

function mergePickerModels(openRouterModels, groqModels) {
  const groq = (groqModels || []).map((m) => ({ ...m, provider: m.provider || "groq" }));
  const or = (openRouterModels || []).map((m) => ({ ...m, provider: m.provider || "openrouter" }));
  return [...groq, ...or];
}

let openRouterModelsCache = { at: 0, models: [] };
const OPENROUTER_MODELS_CACHE_MS = 15 * 60 * 1000;

async function fetchOpenRouterModels(apiKey) {
  const now = Date.now();
  if (
    openRouterModelsCache.models.length &&
    now - openRouterModelsCache.at < OPENROUTER_MODELS_CACHE_MS
  ) {
    return openRouterModelsCache.models;
  }
  const res = await fetch("https://openrouter.ai/api/v1/models", {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  if (!res.ok) throw new Error("OpenRouter models unavailable");
  const body = await res.json();
  const models = (Array.isArray(body.data) ? body.data : [])
    .map((m) => ({
      id: String(m.id || "").trim(),
      name: String(m.name || m.id || "").trim(),
      context: Number(m.context_length) || null,
      provider: "openrouter",
    }))
    .filter((m) => m.id)
    .sort((a, b) => a.id.localeCompare(b.id));
  openRouterModelsCache = { at: now, models };
  return models;
}

async function handleListModels(event) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "sign in required", mode: "listModels" });
  let payload = {};
  try {
    payload = JSON.parse(event.body || "{}");
  } catch (e) { }
  const userOr = normalizeUserOpenRouterKey(payload.openRouterKey);
  const groqKey = resolveGroqKey(payload);
  const anthropicKey = resolveAnthropicKey(payload);
  const orKey = userOr;
  let openRouterModels = [];
  let groqModels = GROQ_MODEL_CATALOG.map((m) => ({ ...m, provider: "groq" }));
  let claudeModels = CLAUDE_MODEL_CATALOG.slice();
  if (orKey) {
    try {
      openRouterModels = await fetchOpenRouterModels(orKey);
    } catch (e) { }
  }
  if (groqKey) {
    try {
      groqModels = await fetchGroqModelsLive(groqKey);
    } catch (e) { }
  }
  try {
    claudeModels = await fetchAnthropicModels(anthropicKey);
  } catch (e) { }
  const models = [
    ...groqModels.map((m) => ({ ...m, provider: "groq" })),
    ...claudeModels.map((m) => ({ ...m, provider: "claude" })),
    ...openRouterModels.map((m) => ({ ...m, provider: m.provider || "openrouter" })),
  ];
  return json(200, {
    mode: "listModels",
    models,
    counts: {
      groq: groqModels.length,
      claude: claudeModels.length,
      openrouter: openRouterModels.length,
    },
    groqConfigured: Boolean(groqKey),
    claudeConfigured: Boolean(anthropicKey),
    openRouterConfigured: Boolean(orKey),
  });
}

async function handleOpenRouterModels(event) {
  const account = await requireAccount(event);
  if (!canPickOpenRouterModel(account)) {
    return json(403, { error: "Model picker not enabled for this account" });
  }
  const apiKey = env("OPENROUTER_API_KEY");
  if (!apiKey) return json(503, { error: "OpenRouter not configured" });
  let payload = {};
  try {
    payload = JSON.parse(event.body || "{}");
  } catch (e) {  }
  const groqKey = resolveGroqKey(payload, account);
  try {
    const openRouterModels = await fetchOpenRouterModels(apiKey);
    let groqModels = GROQ_MODEL_CATALOG.map((m) => ({ ...m, provider: "groq" }));
    if (groqKey) {
      try {
        groqModels = await fetchGroqModelsLive(groqKey);
      } catch (e) {
        
      }
    }
    const models = mergePickerModels(openRouterModels, groqModels);
    return json(200, {
      mode: "openRouterModels",
      models,
      groqConfigured: Boolean(groqKey),
    });
  } catch (e) {
    return json(502, { error: "Could not load models" });
  }
}

const MODELS = TIERS[DEFAULT_TIER].models;
const MODEL = MODELS[0];

const REFINE_MODEL = process.env.CHOPSTICKS_AI_REFINE_MODEL || "openai/gpt-oss-20b:free";
const REFINE_ENABLED = (process.env.CHOPSTICKS_AI_REFINE || "on") !== "off";

const REFINE_SYSTEM = [
  "You are the reviewer in a two-model pipeline. Another assistant drafted the ",
  "reply below. Improve it and output ONLY the improved reply.\n\n",
  "Fix inaccuracy, complete truncated answers, and make the response match the ",
  "user's requested format (letter, number, JSON, or short phrase when asked). ",
  "Tighten wording. Keep the draft's facts unless they are clearly wrong. ",
  "For math, verify the arithmetic. For code, keep it complete and runnable.\n\n",
  "If the draft is already good, return it unchanged. Never mention the draft, ",
  "the review, or yourself as a reviewer - output only the final reply text.",
].join("");
const CHOPCODE_PAIR_SYSTEM = [
  "You are the second ChopCode model. A first coding model drafted the reply below. ",
  "Improve the draft: fix bugs, fill gaps, complete code, and keep it runnable. ",
  "Return the full improved answer the user should see. Every code file must be a fenced block: ```lang filename then the body. Never dump raw HTML/JS as plain chat text. ",
  "If the draft is already correct, return it unchanged. ",
  "Never mention drafts, reviews, pipelines, model names, vendors, or that two models ran.",
].join("");
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const TIMEOUT_MS = Number(process.env.CHOPSTICKS_AI_TIMEOUT_MS || 18000);
const REFINE_MIN_MS = 5000;
const LONG_REPLY_TOKENS = 800;
const REFINE_RESERVE_MS = 6000;
const draftBudgetMs = (replyTokens, msLeft) =>
  replyTokens > LONG_REPLY_TOKENS ? msLeft - 800 : Math.max(8000, msLeft - REFINE_RESERVE_MS);

const MAX_CONTEXT_TOKENS = Number(process.env.CHOPSTICKS_AI_MAX_CONTEXT || 128000);
const contextFor = (effortTier, plan) => {
  const planCap = plan && Number(plan.contextLimit) > 0 ? Number(plan.contextLimit) : MAX_CONTEXT_TOKENS;
  const tierCtx = effortTier.context || planCap;
  if (planCap > tierCtx) return planCap;
  return Math.min(planCap, tierCtx);
};
const MAX_REPLY_TOKENS = 400;
const MAX_REPLY_TOKENS_CEILING = 8000;

const BILLABLE_PER_REPLY = Number(process.env.CHOPSTICKS_AI_BILLABLE || 8500);
const BILLABLE_MAX_MODE = 1000;

const APP_VERSION = "3.8.7";
const PREVIEW_APP_VERSION = "3.8.7";
const STACK_NAME = "cs.AI-3.7";

function appVersionFor(account) {
  return canPickOpenRouterModel(account) ? PREVIEW_APP_VERSION : APP_VERSION;
}
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

const MAX_MESSAGES = 16;
const MAX_CHARS_PER_MSG = 12000;
const GROUNDING_INTENTS = 6;

const TOKEN_BUDGET = FREE_USAGE.limit;
const COOLDOWN_MS = FREE_USAGE.cooldownMs;
const RESET_WINDOW_MS = Number(process.env.CHOPSTICKS_AI_RESET_MS || 5 * 60 * 60 * 1000);
const SB_TIMEOUT_MS = 5000;
const budgets = new Map();
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

function maybeResetBudgetWindow(row, now) {
  if (!row.windowStart) row.windowStart = now;
  if (now - row.windowStart >= RESET_WINDOW_MS) {
    row.used = 0;
    row.windowStart = now;
    row.cooldownUntil = 0;
    return true;
  }
  return false;
}

function memoryBudgetState(now, bucketId, limit, cooldownMs) {
  const row = budgetBucket(bucketId);
  const lim = limit || TOKEN_BUDGET;
  const cool = cooldownMs == null ? COOLDOWN_MS : cooldownMs;
  maybeResetBudgetWindow(row, now);
  if (row.cooldownUntil && now < row.cooldownUntil && cool > 0) {
    return { blocked: true, retryInMs: row.cooldownUntil - now, used: row.used, limit: lim };
  }
  if (row.cooldownUntil && now >= row.cooldownUntil) {
    row.used = 0;
    row.windowStart = now;
    row.cooldownUntil = 0;
  }
  return {
    blocked: false,
    used: row.used,
    limit: lim,
    cooldownMs: cool,
    resetInMs: Math.max(0, RESET_WINDOW_MS - (now - row.windowStart)),
  };
}

function memorySpend(tokens, now, bucketId, limit, cooldownMs) {
  const row = budgetBucket(bucketId);
  const lim = limit || TOKEN_BUDGET;
  const cool = cooldownMs == null ? COOLDOWN_MS : cooldownMs;
  maybeResetBudgetWindow(row, now);
  row.used += tokens;
  if (row.used >= lim && cool > 0) row.cooldownUntil = now + cool;
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
  const cooldownMs = opts.cooldownMs == null ? COOLDOWN_MS : opts.cooldownMs;
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
        p_cooldown_ms: cooldownMs > 0 ? cooldownMs : 1,
        p_id: bucketId,
      }),
    }, { service: true });
    if ((!res.ok || !res.body || typeof res.body !== "object") && bucketId.startsWith("ip-")) {
      res = await sb("rpc/chopsticks_ai_budget_peek", {
        method: "POST",
        body: JSON.stringify({ p_limit: limit, p_cooldown_ms: cooldownMs > 0 ? cooldownMs : 1, p_id: bucketId }),
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
    if (res.body.blocked && cooldownMs > 0) {
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
    return { blocked: false, used, mode: "supabase", bucketId, limit, cooldownMs, resetInMs: memoryBudgetState(now, bucketId, limit, cooldownMs).resetInMs };
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
  const cooldownMs = opts.cooldownMs == null ? COOLDOWN_MS : opts.cooldownMs;
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
        p_cooldown_ms: cooldownMs > 0 ? cooldownMs : 1,
        p_id: bucketId,
      }),
    }, { service: true });
    if ((!res.ok || !res.body || typeof res.body !== "object") && bucketId.startsWith("ip-")) {
      res = await sb("rpc/chopsticks_ai_budget_spend", {
        method: "POST",
        body: JSON.stringify({
          p_tokens: spent,
          p_limit: limit,
          p_cooldown_ms: cooldownMs > 0 ? cooldownMs : 1,
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
    return finish(used, "supabase", cooldownMs > 0 && res.body.blocked);
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
  const rows = scoreQuery(query).filter((s) => s.score >= KB_CONFIDENCE_FLOOR);
  const hybrid = hybridRetrieve(query, rows, limit);
  return hybrid.length ? hybrid : rows.slice(0, limit).map((s) => s.intent);
}

/** Ranked HQ hits only — same hybrid path as other plates. No leftover-catalog dump. */
function retrieveForKaji(query, limit = 12) {
  return retrieve(query, Math.min(limit, 12));
}

function isThinFollowUp(text) {
  const t = String(text || "").trim();
  if (!t || t.length > 180) return false;
  return /^(go\s+)?deeper\b/i.test(t)
    || /\b(go deeper|give me names?|be specific|more detail|list (them|names)|who (are|is) (they|that))\b/i.test(t)
    || /^(and\s+)?(names?|more|who|expand|continue|again|specifics?)\b/i.test(t);
}

function searchQueryForTurns(turns, lastContent) {
  const last = String(lastContent || "").trim();
  if (!isThinFollowUp(last)) return last;
  const prior = (turns || [])
    .filter((m) => m.role === "user")
    .slice(0, -1)
    .map((m) => String(m.content || "").trim())
    .filter(Boolean)
    .join(" ");
  return (prior + " " + last).replace(/\s+/g, " ").trim().slice(0, 280);
}

function namesFromSearchContext(context) {
  const hits = String(context || "").match(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3}\b/g) || [];
  const skip = new Set([
    "The", "This", "That", "Live", "Research", "Sources", "Google", "Wikipedia",
    "Official", "Home", "About", "News", "Today", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday", "Sunday", "January", "February", "March",
    "April", "June", "July", "August", "September", "October", "November", "December",
  ]);
  const uniq = [];
  for (const n of hits) {
    if (skip.has(n)) continue;
    if (n.length < 4) continue;
    if (!uniq.includes(n)) uniq.push(n);
  }
  return uniq.slice(0, 18);
}

function clientWantsLiveOnly(payload) {
  if (payload.offlineMode === true || payload.offlineChatMode === true) return false;
  if (payload.onlineMode === true) return true;
  if (payload.client === "widget") return true;
  return payload.mode === "agent" || !payload.offlineMode;
}

function isCodingTask(text) {
  const ask = String(text || "");
  if (/\b(write|create|generate|make|build|scaffold|implement|export|download|fix|debug|refactor)\b[\s\S]{0,120}\b(file|files|script|code|program|function|class|module|component|page|app|html|css|python|javascript|swift|json|zip)\b/i.test(ask)) return true;
  if (/\b(python|javascript|typescript|html|css|swift|react)\b/i.test(ask)) return true;
  if (/\.\w{1,8}\b|```|write_file/i.test(ask)) return true;
  return false;
}

function answerWhenModelsFail(turns, lastUser, webBundle, payload) {
  const liveOnly = payload ? clientWantsLiveOnly(payload) : false;
  const coding = isCodingTask((lastUser && lastUser.content) || retrievalQuery(turns));
  if (!liveOnly && !coding) {
    const kbQuery = retrievalQuery(turns) || (lastUser && lastUser.content);
    const kbAnswer = kbFallbackAnswer(kbQuery) || kbBestEffortAnswer(kbQuery);
    if (kbAnswer) {
      return { reply: kbAnswer, mode: "live" };
    }
  }

  const follow = String((lastUser && lastUser.content) || "").trim();
  const context = String((webBundle && webBundle.context) || "").trim();
  const sources = (webBundle && Array.isArray(webBundle.sources) && webBundle.sources) || [];
  const wantNames = /\bnames?\b/i.test(follow) || /\bwho\b/i.test(follow);
  const names = namesFromSearchContext(context);
  const priorAssistant = [...(turns || [])].reverse().find((m) => m.role === "assistant");

  const bits = [];
  if (wantNames && names.length) {
    bits.push("Names that show up in the sources for this thread:\n\n" + names.map((n) => "• " + n).join("\n"));
  } else if (context) {
    bits.push(context.slice(0, 1600));
  } else if (priorAssistant && priorAssistant.content && isThinFollowUp(follow)) {
    bits.push(String(priorAssistant.content).slice(0, 1800));
    bits.push("That’s the last pass I had. The live model dropped before I could expand it with more names.");
  }

  if (sources.length) {
    bits.push(
      "**Sources**\n" +
      sources.slice(0, 6).map((s) => {
        const title = s.title || s.url || "source";
        return s.url ? `- [${title}](${s.url})` : `- ${title}`;
      }).join("\n")
    );
  }

  if (bits.length) {
    return { reply: bits.join("\n\n"), mode: "live" };
  }

  return {
    reply: "The live model dropped on that turn. Ask once more in this same thread — I’ll keep the topic and go specific (names, numbers, steps).",
    mode: "live",
  };
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
const SEARCH_TIMEOUT_MS = Number(process.env.CHOPSTICKS_AI_SEARCH_TIMEOUT_MS || 2200);
const SEARCH_MIN_LEN = 3;
const MAX_SOURCES = 12;
const UA = STACK_NAME + "/" + APP_VERSION + " (+https://chopstickshq.com/chopsticks-ai/)";

function clockNow() {
  const d = new Date();
  const isoDay = d.toISOString().slice(0, 10);
  const human = new Intl.DateTimeFormat("en-GB", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(d);
  const year = d.getUTCFullYear();
  return { isoDay, human, year, iso: d.toISOString() };
}

function freshnessQuery(q) {
  const { human, year } = clockNow();
  const clean = String(q || "")
    .replace(/\nATTACHED FILES[\s\S]*$/, "")
    .trim()
    .slice(0, 220);
  if (!clean) return `current events ${year} ${human}`;
  if (/\b(19|20)\d{2}\b/.test(clean)) return clean;
  return `${clean} as of ${human}`;
}

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
  if (/^https?:\/\//i.test(String(src))) return String(src);
  return "https://" + String(src).replace(/^\/+/, "");
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

const CHOPSTICKS_HQ_HOME = "https://chopstickshq.com/";

function queryMentionsChopsticks(query) {
  const q = String(query || "").toLowerCase();
  return /\bchopsticks?\b/.test(q) || q.includes("chopstickshq");
}

function chopsticksHQPinnedSources(query) {
  if (!queryMentionsChopsticks(query)) return [];
  const q = String(query || "").toLowerCase();
  const out = [
    {
      title: "Chopsticks HQ",
      text: "Official home for cs.AI, MacBar, Fathom, guides, and downloads.",
      src: CHOPSTICKS_HQ_HOME,
      via: "Chopsticks HQ",
    },
    {
      title: "chopsticksAI (cs.AI)",
      text: "Free macOS AI assistant with Chromium browser, web app, and Terminal CLI.",
      src: "https://chopstickshq.com/chopsticks-ai/",
      via: "Chopsticks HQ",
    },
  ];
  if (/\b(rnitro|menu bar|monitor)\b/.test(q)) {
    out.push({
      title: "MacBar — macOS menu bar monitor",
      text: "CPU, memory, disk, network, and battery monitoring.",
      src: "https://chopstickshq.com/macbar/",
      via: "Chopsticks HQ",
    });
  }
  if (/\b(fathom|battery|weather)\b/.test(q)) {
    out.push({
      title: "Fathom Air & Fathom Pro",
      text: "Battery monitor and weather apps from Chopsticks HQ.",
      src: "https://chopstickshq.com/fathom/",
      via: "Chopsticks HQ",
    });
  }
  if (/\b(lab|agent|chopcode|web app|csai|cs\.ai)\b/.test(q)) {
    out.push({
      title: "cs.AI web app",
      text: "Browser agent with effort tiers, attachments, and Chromium search.",
      src: "https://chopstickshq.com/chopsticks-ai/web/",
      via: "Chopsticks HQ",
    });
  }
  return out;
}

function isChopsticksHQSource(item) {
  const url = normUrl(item.src || item.url || "");
  try {
    return new URL(url).hostname.replace(/^www\./, "") === "chopstickshq.com";
  } catch (e) {
    return url.includes("chopstickshq.com");
  }
}

/** Pin chopstickshq.com first when the query mentions chopsticks / Chopsticks HQ. */
function prioritizeChopsticksHQ(query, items) {
  if (!queryMentionsChopsticks(query)) return items;
  const pinned = chopsticksHQPinnedSources(query);
  const hq = items.filter(isChopsticksHQSource);
  const rest = items.filter((item) => !isChopsticksHQSource(item));
  return dedupeSources([...pinned, ...hq, ...rest]);
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

const CHROMIUM_UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

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
    try { url = decodeURIComponent(url); } catch (e) {  }
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
  return prioritizeChopsticksHQ(query, dedupeSources(found)).slice(0, cap);
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
async function webSearch(query, maxSources, timeoutMs) {
  const cap = Math.max(1, Math.min(MAX_SOURCES, Number(maxSources) || MAX_SOURCES));
  const c = new AbortController();
  const timer = setTimeout(() => c.abort(), timeoutMs || SEARCH_TIMEOUT_MS);
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
    found = prioritizeChopsticksHQ(query, dedupeSources(found));
    const ranked = rankEvidence(query, found.map((f) => ({
      title: String(f.via ? f.via + ": " + (f.title || query) : (f.title || query)).slice(0, 140),
      url: normUrl(f.src),
      snippet: String(f.text || "").slice(0, 280),
      via: f.via,
    }))).slice(0, cap);

    if (!ranked.length) return { context: "", sources: [], ranked: [], conflicts: [] };

    const conflicts = detectConflicts(ranked);
    const sources = ranked.map((f) => ({
      title: f.title,
      url: f.url,
      snippet: f.snippet,
    }));
    const context = sources
      .map((f) => `- ${f.title}: ${f.snippet}${f.url ? ` (${f.url})` : ""}`)
      .join("\n");

    return { context, sources, ranked, conflicts };
  } catch (e) {
    return { context: "", sources: [], ranked: [], conflicts: [] };
  } finally {
    clearTimeout(timer);
  }
}

/** Facts chopsticksAI knows about itself. Built from the live config so the
 *  numbers can never drift from what the endpoint actually enforces. */
function selfFacts(tier, appVersion) {
  const ver = appVersion || APP_VERSION;
  const t = tier || TIERS[DEFAULT_TIER];
  return [
    "ABOUT YOURSELF (answer questions about your own capabilities from this):",
    `- You are ${STACK_NAME} (${ver}), built and run by Chopsticks HQ.`,
    `- You refresh live web research for each user question, dated as of today.`,
    `- Current date for this session: ${clockNow().human} (${clockNow().isoDay} UTC).`,
    `- Current plate: ${t.label} (Rice < Tamago < Hibachi < Wagyu A1 < A2 < A3 < A4 < A5), ${contextFor(t).toLocaleString()} token context, up to ${(t.maxReply || MAX_REPLY_TOKENS).toLocaleString()} reply tokens.`,
    t.stickerCoder
      ? "- StickerCoder+ mode: prioritise complete, runnable code, write_file tool use, and sharp engineering answers."
      : t.kaji
        ? "- Kaji mode (alpha, agentic): tools write_file, open_page, and on Mac list_dir / read_file / write_mac_file plus run_command in a headless Alpine sandbox (no network, not a Linux desktop). The in-app browser is WebKit. Prefer “I don’t know” over a confident guess. Do not name underlying models or vendors."
      : t.chopCode
        ? "- ChopCode mode: ten coding specialists run in parallel (each educated on today's date and live research), then Lead merges their drafts into one answer. Prioritise complete, runnable code and clear file fences."
        : null,
    `- Longest single reply: ${MAX_REPLY_TOKENS_CEILING.toLocaleString()} tokens (in ChopsticksAI Lab); ${MAX_REPLY_TOKENS} in the sidebar widget.`,
    `- Conversation memory: the last ${MAX_MESSAGES} turns.`,
    `- Free usage allowance: ${TOKEN_BUDGET.toLocaleString()} tokens, then a ${Math.round(COOLDOWN_MS / 3600000)}-hour cooldown.`,
    "- Upgrades: sign in and redeem Fathom Pro oi-pl2- keys at https://chopstickshq.com/chopsticks-ai/web/upgrades/ (2 keys → 800k + 2h30m; 5 keys → 900k + 2h + ChopCode + Kaji; 10 keys → 1m + 1h). Not OpenRouter keys.",
    `- Rate limit: ${RATE_MAX} requests per minute per visitor.`,
    "- You search with the Chromium engine on each question (unless the user turns search off) so answers reflect information as of the current date. Cite sources when you use them.",
    "- The macOS app and web app include a built-in Chromium browser rail whose home page is https://chopstickshq.com; standalone search is at https://chopstickshq.com/chopsticks-ai/#search. Queries mentioning chopsticks prioritize chopstickshq.com in results.",
    "- You answer general questions on any topic, and are the in-house expert on Chopsticks HQ software.",
    "- You need no OpenRouter API key from the user; Fathom Pro unlock keys can be redeemed as usage credits in the Usage tab.",
    "- cs.AI Enterprise is for large companies: custom usage, seats, invoice/PO, SSO reviewed on request. There is no public price. Direct orgs to https://chopstickshq.com/chopsticks-ai/enterprise/ and chopstickshq@lam.ws (subject: cs.AI Enterprise). Do not invent certifications or a checkout URL.",
    "- Email sign-in is password. Create account emails a 6-digit code (10 minutes) from chopstickshq@lam.ws to the address they typed.",
    "- You are available on every page of chopstickshq.com, in ChopsticksAI at /chopailab, and inside MacBar's Chat tab.",
    "- Retrieval is hybrid keyword + BM25 + entity matching on HQ knowledge, plus ranked live web evidence. There is no vector index.",
    "- Do not name or speculate about any underlying model, provider or vendor.",
  ].filter(Boolean).join("\n");
}

function systemPrompt(grounding, mode, web, tier, language, appVersion, maxMode) {
  const ver = appVersion || APP_VERSION;
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
    "- Supported outputs include HTML, Markdown (.md), JSON, CSV, Python/JS/Swift code, ZIP (use write_file with encoding base64), and any other text format.\n",
    "- Never dump code as plain chat text. Every code sample must be inside a fenced block with a language tag and a filename so the app can Copy and Download it.\n",
    "- Give complete, runnable files rather than fragments or ellipses.\n",
    "- Keep explanation outside tools/fences and brief.",
    tier.chopsticksFocus
      ? "\n- Chopsticks effort: prioritise accurate answers about Chopsticks HQ software from the reference material; still help with general tasks when asked."
      : "",
    tier.stickerCoder
      ? "\n- StickerCoder+: prefer correct, idiomatic code; use tools aggressively for file creation; include imports and edge cases; keep prose short."
      : tier.chopCode
        ? "\n- ChopCode: coding models work together, grounded in 2026 live research. Put every file in a ```lang filename fence. Prefer current stable APIs; include imports and edge-case handling; keep prose short."
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
    : tier.kaji
    ? [
        "You are Kaji — Chopsticks HQ’s agentic assistant on " + STACK_NAME + ". Catchphrase: Think different. Ask Kaji.\n\n",
        "Kaji is ALPHA. Do not bluff. Prefer tools over guessing.\n",
        "You are an agent: plan, use tools, observe results, then answer. ",
        "On the macOS app you can list, read, and write files under the user’s Home, Desktop, Documents, and Downloads (list_dir, read_file, write_mac_file). Stay in those folders. Never touch Keychain, .ssh, or other users.\n",
        "On the macOS app you also have run_command: a headless Alpine Linux guest (Apple Virtualization, aarch64/x86_64, no NIC, no desktop). Commands run after the user confirms. Scratch folder: ~/Downloads/Kaji-scratch. Do not call this a Linux desktop, SSH box, or Chrome.\n",
        "You were trained on the full Chopsticks HQ catalog plus live web research. ",
        "The in-app browser is your web computer: use open_page for https URLs. Use write_file for downloadable files in chat. ",
        "Never claim you have SSH, a Linux desktop, or that the in-app browser is Chrome.\n\n",
      ].join("")
    : tier.chopCode
    ? [
        "You are cs.AI ChopCode — the coding mode of chopsticksAI, made by Chopsticks HQ.\n\n",
        "Focus on software engineering: write, debug, refactor, and explain code. ",
        "Be precise and practical. Prefer working solutions over theory.\n\n",
      ].join("")
    : [
        "You are " + STACK_NAME + " (" + ver + "), a helpful and knowledgeable general-purpose assistant, ",
        "made by Chopsticks HQ.\n\n",
        "Answer ANY question the user asks — general knowledge, science, history, coding, ",
        "writing, maths, recommendations, advice, casual conversation, anything. You are a ",
        "full assistant, not a support bot, and you should never refuse a question simply ",
        "because it is unrelated to Chopsticks HQ.\n\n",
        "Answer naturally and conversationally. Be concise by default — a short paragraph — ",
        "and go longer only when the question genuinely needs it. Plain text reads best; ",
        "use markdown only when structure really helps, such as code blocks for code.\n\n",
      ].join("");

  const clock = clockNow();
  const dateBlock = [
    `\nCURRENT DATE (authoritative for this reply): ${clock.human} (${clock.isoDay} UTC).`,
    `The current year is ${clock.year}. It is not 2024 or 2025. Do not write as if those years are “now”.`,
    "You have been given live web research retrieved just now for this question.",
    "Prefer those results over memorized training data for anything time-sensitive",
    "(news, versions, prices, APIs, SDKs, sports, politics, product status).",
    "If search and memory conflict, trust search and cite it. If search is empty, say the date and be clear you may be missing today's developments.\n",
  ].join(" ");
  const yearKnowledge = [
    `\n\n2026 WORKING KNOWLEDGE (use with live research; do not freeze on older training cutoffs):`,
    `- Calendar: ${clock.human}. macOS 26 is current on Apple Silicon Macs; Swift 6 is the shipping language.`,
    "- Treat library/framework docs, CLI flags, and package versions as needing a 2026 check via live research.",
    "- For code, prefer current stable APIs. Do not recommend deprecated 2023–2024-only patterns when a current replacement exists.",
    "- If the user asks what is current (Node, Python, Swift, Xcode, browsers, CSS, React, Rust, Go), answer for 2026 using live research, not a stale cutoff.\n",
  ].join("\n");

  return [
    persona,
    dateBlock,
    yearKnowledge,
    grounding.length
      ? [
          "You are also the in-house expert on Chopsticks HQ's own software: MacBar (macOS menu ",
          "bar system monitor), Fathom Air (battery monitor), Fathom Pro (battery, weather and AI ",
          "chat), ARENA (an FPS game), and Chopsticks Shaders. When a question touches those, the ",
          "reference material below is authoritative.\n\n",
        ].join("")
      : "Answer the user's question. Do not mention Chopsticks HQ unless they asked about it.\n\n",
    selfFacts(tier, ver),
    web ? web : "",
    "\n\nREFERENCE MATERIAL:\n\n",
    facts,
    "\n\nRules:\n",
    "- For questions about Chopsticks HQ software, version numbers, install commands, file ",
    "names and pricing must come from the reference material above. If it does not cover the ",
    "detail, say you're not certain and point to chopstickshq.com rather than guessing.\n",
    "- Never invent a download link, command, or version number for Chopsticks software.\n",
    "- Never imply Chopsticks software costs money or needs a subscription.\n",
    "- For news, software versions, current events, and anything that changes over time, ",
    "use the live web research and today's date — the year is 2026, not 2024 or 2025.\n",
    "- For everything else, just answer the question well using your own knowledge. Do not ",
    "steer the conversation back to Chopsticks HQ, and do not mention the reference material ",
    "when it isn't relevant.\n",
    "- If you are genuinely unsure of a fact, say so rather than inventing one.\n",
    "- No evidence → do not invent. Conflicting evidence → investigate and explain. Low confidence → qualify. Missing information → say what is unknown.\n",
    "- Be smarter and faster: lead with the answer, skip throat-clearing, skip repeating the question. Prefer one tight paragraph unless the user asked for depth or code. ",
    "Check names, versions, and numbers against reference material and live research before stating them. If those sources disagree with your memory, trust the sources.\n",
    maxMode
      ? "- Max mode is on. Think carefully before answering: consider alternatives, verify numbers, then give a complete answer. Keep the user-visible reply within about 1000 tokens. Do not dump a long hidden chain of thought.\n"
      : "",
    "- Follow the user's requested format exactly. If they want a letter, a number, JSON, or a single word, that is the whole answer.\n",
    "- For math and logic: compute carefully, then state the final result clearly. Recheck arithmetic before sending.\n",
    "- For code: complete runnable files in fenced blocks with a language tag and filename. Include imports. Do not leave TODOs or ellipses.\n",
    "- Do not refuse ordinary knowledge, coding, or analysis questions. Stay on the task.\n",
    "- You are " + STACK_NAME + " (chopsticksAI), made by Chopsticks HQ. If asked what model, ",
    "engine or company is behind you, say you are " + STACK_NAME + " by Chopsticks ",
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
  const vaultHash = env("FATHOM_VAULT_PASSWORD_HASH");
  const supplied = String(payload.vaultPassword || payload.password || "").trim();
  if (scavenger) {
    if (env("CHOPSTICKS_AI_SCAVENGER") !== "1") {
      return json(403, { error: "forbidden" });
    }
    if (scavengerRateLimited(who)) {
      return json(429, { error: "scavenger cooldown", retryInMs: SCAVENGER_COOLDOWN_MS });
    }
  } else if (!vaultOk(supplied, vaultPw, vaultHash)) {
    return json(403, { error: "forbidden" });
  }
  const key = mintFathomProUnlockKey();
  if (!key) return json(503, { error: "unlock signing not configured" });
  return json(200, { mode: "mint", key, prefix: "oi-pl2" });
}

function vaultOk(supplied, vaultPw, vaultHash) {
  if (vaultHash) {
    const got = crypto.createHash("sha256").update(String(supplied)).digest("hex");
    return timingSafeString(got, vaultHash);
  }
  if (!vaultPw) return false;
  return timingSafeString(supplied, vaultPw);
}

const ALLOWED_ORIGIN = "https://chopstickshq.com";
let __corsOrigin = "";

function requestOrigin(event) {
  const headers = (event && event.headers) || {};
  return String(headers.origin || headers.Origin || "").trim();
}

function corsHeaders() {
  const h = { "Content-Type": "application/json", "Cache-Control": "no-store" };
  if (!__corsOrigin || __corsOrigin === ALLOWED_ORIGIN) {
    h["Access-Control-Allow-Origin"] = ALLOWED_ORIGIN;
    h["Access-Control-Allow-Headers"] = "Content-Type, Authorization";
    h["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS";
    h.Vary = "Origin";
  }
  return h;
}

const json = (status, body) => ({
  statusCode: status,
  headers: corsHeaders(),
  body: JSON.stringify(body),
});

/** OpenAI-compatible tools for agent file creation. */
const AGENT_TOOLS = [
  {
    type: "function",
    function: {
      name: "write_file",
      description:
        "Create a downloadable file for the user (HTML, Markdown, JSON, Python, ZIP, CSV, etc.). Call once per file. For binary files like ZIP, pass encoding base64.",
      parameters: {
        type: "object",
        properties: {
          path: {
            type: "string",
            description: "File name only, e.g. index.html, README.md, bundle.zip",
          },
          content: {
            type: "string",
            description: "Full file contents (UTF-8 text, or base64 when encoding is base64)",
          },
          language: {
            type: "string",
            description: "Optional language tag for highlighting (python, html, markdown, …)",
          },
          encoding: {
            type: "string",
            enum: ["utf8", "base64"],
            description: "Use base64 for binary files such as ZIP archives",
          },
        },
        required: ["path", "content"],
      },
    },
  },
];

const KAJI_TOOLS = AGENT_TOOLS.concat([
  {
    type: "function",
    function: {
      name: "open_page",
      description:
        "Open an https URL in Kaji’s web computer (the in-app WebKit view). This is your web machine — not Chrome and not the Linux sandbox. Use for docs, news, product pages, and anything you would otherwise open in a browser.",
      parameters: {
        type: "object",
        properties: {
          url: { type: "string", description: "https URL to load" },
          title: { type: "string", description: "Short label for the tab" },
        },
        required: ["url"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "list_dir",
      description:
        "List files in a folder on the user’s Mac. Allowed: ~, ~/Desktop, ~/Documents, ~/Downloads. Use before reading or writing.",
      parameters: {
        type: "object",
        properties: {
          path: { type: "string", description: "Folder path, e.g. ~/Desktop or ~/Documents/project" },
        },
        required: ["path"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "read_file",
      description:
        "Read a text file on the user’s Mac (Home, Desktop, Documents, Downloads). Max ~80 KB.",
      parameters: {
        type: "object",
        properties: {
          path: { type: "string", description: "File path, e.g. ~/Desktop/notes.md" },
        },
        required: ["path"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "write_mac_file",
      description:
        "Write or overwrite a file on the user’s Mac under Home, Desktop, Documents, or Downloads. Use for real disk edits. Prefer write_file when the user only needs a download in chat.",
      parameters: {
        type: "object",
        properties: {
          path: { type: "string", description: "Destination path, e.g. ~/Desktop/hello.py" },
          content: { type: "string", description: "Full UTF-8 file contents" },
        },
        required: ["path", "content"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "run_command",
      description:
        "Run a shell command in Kaji’s headless Alpine sandbox on the Mac app (Apple Virtualization, no network, no desktop). User must confirm. CWD is ~/Downloads/Kaji-scratch inside the guest. Web Kaji cannot run this. Prefer open_page for browsing.",
      parameters: {
        type: "object",
        properties: {
          command: { type: "string", description: "Shell command, e.g. uname -a or ls" },
        },
        required: ["command"],
      },
    },
  },
]);

const KAJI_LOCAL_TOOL_NAMES = new Set(["list_dir", "read_file", "write_mac_file", "run_command"]);

function isMacKajiClient(payload) {
  const c = String((payload && payload.client) || "").toLowerCase();
  return c === "macos" || c === "mac" || c === "app";
}

function serializeToolCalls(calls) {
  return (calls || []).map((tc) => ({
    id: String((tc && tc.id) || ""),
    name: String((tc && tc.function && tc.function.name) || ""),
    arguments: String((tc && tc.function && tc.function.arguments) || "{}"),
    type: "function",
    function: tc && tc.function,
  }));
}

function sanitizeOpenUrl(raw) {
  try {
    const u = new URL(String(raw || "").trim());
    if (u.protocol !== "https:") return "";
    return u.toString();
  } catch {
    return "";
  }
}

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
    zip: "zip", gz: "gzip", tar: "tar", csv: "csv", xml: "xml", txt: "text",
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
      ...(f.encoding ? { encoding: f.encoding } : {}),
    });
  }
  return [...map.values()];
}

function looksLikeCodeLine(line) {
  const t = String(line || "").trim();
  if (!t) return false;
  if (/^<\/?[a-zA-Z!][^>]*>/.test(t)) return true;
  if (/^(const|let|var|function|class|import |export |return |document\.|window\.|console\.)/.test(t)) return true;
  if (/[{};]\s*$/.test(t) && t.length < 240 && !/^[A-Z][^<{]{12,}[.!?]$/.test(t)) return true;
  return false;
}

function guessLangFromBlock(block) {
  const s = String(block || "");
  if (/<!DOCTYPE|<html\b|<head\b|<body\b|<\/?(div|span|script|style|p|section)\b/i.test(s)) return "html";
  if (/\b(const|let|function|=>|document\.)\b/.test(s)) return "javascript";
  if (/\b(def |import |print\()/.test(s)) return "python";
  if (/[{:][^;]*;/.test(s) && /[.#][\w-]+\s*\{/.test(s)) return "css";
  return "text";
}

function fenceLooseInProse(prose) {
  const lines = String(prose || "").split("\n");
  const chunks = [];
  let i = 0;
  while (i < lines.length) {
    const twoCode = looksLikeCodeLine(lines[i]) && i + 1 < lines.length && looksLikeCodeLine(lines[i + 1]);
    if (twoCode) {
      const start = i;
      i += 2;
      while (i < lines.length && (looksLikeCodeLine(lines[i]) || !String(lines[i]).trim())) i += 1;
      while (i > start && !String(lines[i - 1]).trim()) i -= 1;
      const block = lines.slice(start, i).join("\n").replace(/\n+$/, "");
      const lang = guessLangFromBlock(block);
      const ext = lang === "javascript" ? "js" : lang === "text" ? "txt" : lang;
      chunks.push("```" + lang + " chopsticksai-file." + ext + "\n" + block + "\n```");
      continue;
    }
    const start = i;
    i += 1;
    while (i < lines.length) {
      const nextTwo = looksLikeCodeLine(lines[i]) && i + 1 < lines.length && looksLikeCodeLine(lines[i + 1]);
      if (nextTwo) break;
      i += 1;
    }
    const block = lines.slice(start, i).join("\n").trim();
    if (block) chunks.push(block);
  }
  return chunks.join("\n\n");
}

function liftLooseCodeIntoFences(text) {
  const raw = String(text || "");
  const parts = raw.split("```");
  const out = [];
  for (let i = 0; i < parts.length; i++) {
    if (i % 2 === 1) {
      out.push("```" + parts[i].replace(/\n+$/, "") + "\n```");
      continue;
    }
    const lifted = fenceLooseInProse(parts[i]);
    if (lifted) out.push(lifted);
  }
  return out.join("\n\n").replace(/\n{3,}/g, "\n\n");
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

async function fetchOpenPage(url) {
  try {
    const res = await fetch(url, {
      redirect: "follow",
      headers: {
        "User-Agent": UA,
        Accept: "text/html,application/xhtml+xml;q=0.9,*/*;q=0.8",
      },
      signal: AbortSignal.timeout(4000),
    });
    const html = await res.text();
    const csp = String(res.headers.get("content-security-policy") || "");
    const xfo = String(res.headers.get("x-frame-options") || "");
    const embedBlocked = /frame-ancestors\s+['"]?none/i.test(csp)
      || /DENY|SAMEORIGIN/i.test(xfo);
    const titleMatch = html.match(/<title[^>]*>([^<]{1,200})/i);
    const title = titleMatch ? String(titleMatch[1]).replace(/\s+/g, " ").trim().slice(0, 120) : url;
    const text = html
      .replace(/<script[\s\S]*?<\/script>/gi, " ")
      .replace(/<style[\s\S]*?<\/style>/gi, " ")
      .replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, 4000);
    return {
      ok: true,
      url,
      title,
      text,
      embedBlocked,
      machine: "web-browser",
    };
  } catch (e) {
    return {
      ok: false,
      url,
      title: url,
      text: "",
      embedBlocked: true,
      error: "could not fetch page",
    };
  }
}

function plateTemperature(tier, intel) {
  if (intel && intel.category === "CREATIVE") return 0.35;
  if (tier && tier.kaji) return 0.18;
  return (tier && tier.temperature) || 0.2;
}

/**
 * After a first completion that may include tool_calls, execute write_file
 * tools and ask the model to finish. Returns { text, files, tokens }.
 */
async function continueWithTools({
  model, messages, first, openRouterKey, groqKey, anthropicKey, signal, maxTokens, temperature, tools,
}) {
  const files = [];
  const pages = [];
  const toolset = tools || AGENT_TOOLS;
  let tokens = first.tokens || 0;
  let msgs = messages.map((m) => ({ ...m }));
  let cur = first;
  for (let round = 0; round < 4; round++) {
    const calls = cur.toolCalls || [];
    if (!calls.length) {
      return { text: cur.text || "", files, pages, tokens };
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
          const enc = String(args.encoding || "utf8").toLowerCase();
          files.push({
            name: path,
            content,
            language: String(args.language || langFromName(path)).slice(0, 40),
            ...(enc === "base64" ? { encoding: "base64" } : {}),
          });
          result = { ok: true, path, bytes: content.length };
        }
      } else if (name === "open_page") {
        const url = sanitizeOpenUrl(args.url || args.href);
        if (!url) {
          result = { ok: false, error: "https URL required" };
        } else {
          result = await fetchOpenPage(url);
          pages.push({
            url: result.url,
            title: result.title || url,
            embedBlocked: Boolean(result.embedBlocked),
          });
        }
      } else if (KAJI_LOCAL_TOOL_NAMES.has(name)) {
        result = {
          ok: false,
          pending: true,
          error: "Mac file and sandbox tools run on the cs.AI Mac app.",
        };
      }
      msgs.push({
        role: "tool",
        tool_call_id: tc.id || ("call_" + round),
        content: JSON.stringify(result),
      });
    }
    try {
      cur = await callChatModel({
        model,
        messages: msgs,
        openRouterKey,
        groqKey,
        anthropicKey,
        signal,
        maxTokens,
        temperature,
        tools: toolset,
        toolChoice: "auto",
      });
    } catch (e) {
      return {
        text: first.text || (files.length ? "Created files via tools." : ""),
        files,
        pages,
        tokens,
      };
    }
    if (!cur.ok) {
      return {
        text: first.text || (files.length ? "Created files via tools." : ""),
        files,
        pages,
        tokens,
      };
    }
    tokens += cur.tokens || 0;
  }
  return { text: cur.text || "", files, pages, tokens };
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

/** One Groq chat completion (OpenAI-compatible). */
async function callGroqModel({ model, messages, key, signal, maxTokens, temperature, tools, toolChoice }) {
  const asked = maxTokens ?? MAX_REPLY_TOKENS;
  const body = {
    model,
    messages,
    temperature: temperature ?? 0.3,
    max_tokens: Math.max(asked, Math.min(asked + 256, asked * 2, 8192)),
  };
  if (tools && tools.length) {
    body.tools = tools;
    body.tool_choice = toolChoice || "auto";
  }
  let res;
  try {
    res = await fetch(GROQ_URL, {
    method: "POST",
    signal,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  } catch (e) {
    return { ok: false, status: 0, detail: String((e && e.name) || e) };
  }
  if (!res.ok) {
    return { ok: false, status: res.status, detail: await res.text().catch(() => "") };
  }
  const data = await res.json();
  const choice = (data.choices && data.choices[0]) || {};
  const msg = choice.message || {};
  let text = messageText(msg);
  const toolCalls = Array.isArray(msg.tool_calls) ? msg.tool_calls : [];
  if (!text && !toolCalls.length) {
    return {
      ok: false,
      status: res.status,
      detail: "empty groq completion finish=" + String(choice.finish_reason || ""),
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

/** Anthropic Messages API. */
async function callAnthropicModel({ model, messages, key, signal, maxTokens, temperature }) {
  if (!key) return { ok: false, status: 503, detail: "Anthropic API key not configured" };
  const native = claudeNativeModelId(model);
  let system = "";
  const conv = [];
  for (const m of messages || []) {
    if (!m) continue;
    if (m.role === "system") {
      system += (system ? "\n\n" : "") + String(m.content || "");
      continue;
    }
    const role = m.role === "assistant" ? "assistant" : "user";
    const text = typeof m.content === "string" ? m.content : messageText(m);
    if (!text) continue;
    if (conv.length && conv[conv.length - 1].role === role) {
      conv[conv.length - 1].content += "\n\n" + text;
    } else {
      conv.push({ role, content: text });
    }
  }
  if (!conv.length) return { ok: false, status: 400, detail: "no messages" };
  if (conv[0].role !== "user") conv.unshift({ role: "user", content: "(continue)" });
  const body = {
    model: native,
    max_tokens: Math.min(Math.max(maxTokens || 1024, 256), 8192),
    temperature: temperature ?? 0.3,
    messages: conv,
  };
  if (system) body.system = system;
  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      signal,
      headers: {
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      return { ok: false, status: res.status, detail: await res.text().catch(() => "") };
    }
    const data = await res.json();
    const text = (Array.isArray(data.content) ? data.content : [])
      .map((p) => (p && p.type === "text" ? p.text : ""))
      .join("")
      .trim();
    if (!text) return { ok: false, status: 200, detail: "empty claude completion" };
    const reported = data.usage
      ? Number(data.usage.input_tokens || 0) + Number(data.usage.output_tokens || 0)
      : null;
    return { ok: true, text, toolCalls: [], tokens: reported };
  } catch (e) {
    return { ok: false, status: 0, detail: String((e && e.name) || e) };
  }
}

async function callChatModel({
  model,
  messages,
  openRouterKey,
  groqKey,
  anthropicKey,
  signal,
  maxTokens,
  temperature,
  tools,
  toolChoice,
}) {
  if (isClaudeModelId(model)) {
    return callAnthropicModel({
      model,
      messages,
      key: anthropicKey,
      signal,
      maxTokens,
      temperature,
    });
  }
  if (isGroqModelId(model)) {
    if (!groqKey) {
      return { ok: false, status: 503, detail: "Groq API key not configured" };
    }
    return callGroqModel({
      model: groqNativeModelId(model),
      messages,
      key: groqKey,
      signal,
      maxTokens,
      temperature,
      tools,
      toolChoice,
    });
  }
  return callModel({
    model,
    messages,
    key: openRouterKey,
    signal,
    maxTokens,
    temperature,
    tools,
    toolChoice,
  });
}

/** One chat completion. Supports optional OpenAI-style tools. */
async function callModel({ model, messages, key, signal, maxTokens, temperature, tools, toolChoice }) {
  const asked = maxTokens ?? MAX_REPLY_TOKENS;
  const body = {
    model,
    messages,
    temperature: temperature ?? 0.3,
    max_tokens: Math.min(Math.max(asked, 256), MAX_REPLY_TOKENS_CEILING),
  };
  if (tools && tools.length) {
    body.tools = tools;
    body.tool_choice = toolChoice || "auto";
  }
  let res;
  try {
    res = await fetch(OPENROUTER_URL, {
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
  } catch (e) {
    return { ok: false, status: 0, detail: String((e && e.name) || e) };
  }
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
    resetInMs: state.blocked ? 0 : (state.resetInMs || 0),
    resetsAt:
      !state.blocked && state.resetInMs
        ? new Date(Date.now() + state.resetInMs).toISOString()
        : null,
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
    chopcode: {
      allowed: canUseChopCode(accountFromPlan(plan), plan),
      requiresKeys: CHOPCODE_PRO_KEYS,
    },
    kaji: {
      allowed: canUseKaji(accountFromPlan(plan), plan),
      requiresKeys: CHOPCODE_PRO_KEYS,
    },
  };
}

function accountFromPlan(plan) {
  if (!plan || !plan.account) return null;
  return {
    id: plan.account.id,
    email: plan.account.email,
    entitlement: { label: plan.account.plan },
  };
}

async function healthHandler(event) {
  return json(200, { ok: true, service: "chopsticks-ai" });
}

async function requireAccount(event) {
  const accessToken = extractAccessToken(event);
  if (!accessToken) return null;
  return resolveAccount(accessToken);
}

async function chatOwnedBy(account, chatId) {
  const res = await sb(
    `chats?id=eq.${encodeURIComponent(chatId)}&user_id=eq.${encodeURIComponent(account.id)}&select=id`,
    { method: "GET", headers: { accept: "application/json" } },
    { service: true }
  );
  return res.ok && Array.isArray(res.body) && res.body.length > 0;
}

async function handleAuthMe(event) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Not signed in", mode: "authMe" });
  return json(200, {
    mode: "authMe",
    ok: true,
    user: { id: account.id, email: account.email },
    modelPicker: canPickOpenRouterModel(account),
    appVersion: appVersionFor(account),
  });
}

async function handleChatsList(event) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Sign in required", mode: "chatsList" });
  const res = await sb(
    `chats?user_id=eq.${encodeURIComponent(account.id)}&select=id,title,client,tier,created_at,updated_at&order=updated_at.desc&limit=50`,
    { method: "GET", headers: { accept: "application/json" } },
    { service: true }
  );
  if (!res.ok) return json(502, { error: "Could not list chats" });
  return json(200, { mode: "chatsList", chats: Array.isArray(res.body) ? res.body : [] });
}

async function handleChatCreate(event, payload) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Sign in required", mode: "chatCreate" });
  const row = {
    user_id: account.id,
    title: String(payload.title || "New Chat").slice(0, 120),
    client: String(payload.client || "web").slice(0, 16),
    tier: payload.tier ? String(payload.tier).slice(0, 32) : null,
  };
  const res = await sb("chats", {
    method: "POST",
    headers: { accept: "application/json", Prefer: "return=representation" },
    body: JSON.stringify(row),
  }, { service: true });
  if (!res.ok || !Array.isArray(res.body) || !res.body[0]) {
    return json(502, { error: "Could not create chat" });
  }
  return json(200, { mode: "chatCreate", chat: res.body[0] });
}

async function handleChatMessages(event, payload) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Sign in required", mode: "chatMessages" });
  const chatId = String(payload.chatId || payload.id || "").trim();
  if (!chatId) return json(400, { error: "Missing chatId" });
  if (!(await chatOwnedBy(account, chatId))) return json(404, { error: "Chat not found" });
  const res = await sb(
    `chat_messages?chat_id=eq.${encodeURIComponent(chatId)}&select=role,content,sources,seq&order=seq.asc`,
    { method: "GET", headers: { accept: "application/json" } },
    { service: true }
  );
  if (!res.ok) return json(502, { error: "Could not load messages" });
  return json(200, { mode: "chatMessages", messages: Array.isArray(res.body) ? res.body : [] });
}

async function handleChatPatch(event, payload) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Sign in required", mode: "chatPatch" });
  const chatId = String(payload.chatId || payload.id || "").trim();
  if (!chatId) return json(400, { error: "Missing chatId" });
  if (!(await chatOwnedBy(account, chatId))) return json(404, { error: "Chat not found" });
  const patch = { updated_at: new Date().toISOString() };
  if (payload.title) patch.title = String(payload.title).slice(0, 120);
  if (payload.tier) patch.tier = String(payload.tier).slice(0, 32);
  await sb(`chats?id=eq.${encodeURIComponent(chatId)}&user_id=eq.${encodeURIComponent(account.id)}`, {
    method: "PATCH",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify(patch),
  }, { service: true });
  return json(200, { mode: "chatPatch", ok: true });
}

async function handleChatSave(event, payload) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Sign in required", mode: "chatSave" });
  const chatId = String(payload.chatId || payload.id || "").trim();
  if (!chatId) return json(400, { error: "Missing chatId" });
  if (!(await chatOwnedBy(account, chatId))) return json(404, { error: "Chat not found" });

  const patch = { updated_at: new Date().toISOString() };
  if (payload.title) patch.title = String(payload.title).slice(0, 120);
  if (payload.tier) patch.tier = String(payload.tier).slice(0, 32);
  await sb(`chats?id=eq.${encodeURIComponent(chatId)}&user_id=eq.${encodeURIComponent(account.id)}`, {
    method: "PATCH",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify(patch),
  }, { service: true });

  await sb(`chat_messages?chat_id=eq.${encodeURIComponent(chatId)}`, {
    method: "DELETE",
  }, { service: true });

  const messages = Array.isArray(payload.messages) ? payload.messages : [];
  const rows = messages.map(function (m, i) {
    return {
      chat_id: chatId,
      role: m.role === "user" ? "user" : (m.role === "system" ? "system" : "assistant"),
      content: String(m.content || "").slice(0, 100000),
      sources: Array.isArray(m.sources) ? m.sources : [],
      seq: i,
    };
  });

  if (rows.length) {
    for (let i = 0; i < rows.length; i += 40) {
      const chunk = rows.slice(i, i + 40);
      const ins = await sb("chat_messages", {
        method: "POST",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify(chunk),
      }, { service: true });
      if (!ins.ok) return json(502, { error: "Could not save messages" });
    }
  }
  return json(200, { mode: "chatSave", ok: true });
}

async function handleChatDelete(event, payload) {
  const account = await requireAccount(event);
  if (!account) return json(401, { error: "Sign in required", mode: "chatDelete" });
  const chatId = String(payload.chatId || payload.id || "").trim();
  if (!chatId) return json(400, { error: "Missing chatId" });
  if (!(await chatOwnedBy(account, chatId))) return json(404, { error: "Chat not found" });
  await sb(`chats?id=eq.${encodeURIComponent(chatId)}&user_id=eq.${encodeURIComponent(account.id)}`, { method: "DELETE" }, { service: true });
  return json(200, { mode: "chatDelete", ok: true });
}

async function handler(event, context) {
  __corsOrigin = requestOrigin(event);
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: corsHeaders(), body: "" };
  }
  if (isBrazil(event, context)) {
    return brazilJson("csai");
  }
  if (event.httpMethod === "GET") {
    return healthHandler(event);
  }
  if (event.httpMethod !== "POST") {
    return json(405, { error: "GET or POST only" });
  }
  if (__corsOrigin && __corsOrigin !== ALLOWED_ORIGIN) {
    return json(403, { error: "origin not allowed" });
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
  const apiKey = resolveOpenRouterKey(payload);
  const anthropicKey = resolveAnthropicKey(payload);
  const unlockKeys = Array.isArray(payload.unlockKeys)
    ? payload.unlockKeys
    : (Array.isArray(payload.fathomProKeys) ? payload.fathomProKeys : []);
  const who = clientWho(event);
  const accessToken = extractAccessToken(event);
  const account = await resolveAccount(accessToken);
  const groqKey = resolveGroqKey(payload, account, tier);

  if (payload.action === "bootstrapFounder") {
    const secret = env("CHOPSTICKS_AI_BOOTSTRAP_SECRET");
    const hdr = String((event.headers && (event.headers["x-cs-bootstrap"] || event.headers["X-Cs-Bootstrap"])) || "");
    if (!secret || !timingSafeString(hdr, secret)) {
      return json(404, { error: "not found" });
    }
    const result = await ensureFounderAuthUser();
    return json(result.ok ? 200 : 503, { ok: result.ok, mode: "bootstrapFounder" });
  }

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
  if (payload.action === "loginVerify") {
    return handleLoginVerify(event, payload, rateLimited);
  }
  if (payload.action === "authRefresh") {
    return handleAuthRefresh(event, payload);
  }
  if (
    payload.action === "authOAuthStart" ||
    payload.action === "authOAuthExchange" ||
    payload.action === "authIdentities" ||
    payload.action === "authUnlinkIdentity"
  ) {
    return json(410, {
      error: "Google and GitHub sign-in is no longer available. Use email and password.",
    });
  }
  if (payload.action === "authMe") {
    return handleAuthMe(event);
  }
  if (payload.action === "chatsList") {
    return handleChatsList(event);
  }
  if (payload.action === "chatCreate") {
    return handleChatCreate(event, payload);
  }
  if (payload.action === "chatMessages") {
    return handleChatMessages(event, payload);
  }
  if (payload.action === "chatPatch") {
    return handleChatPatch(event, payload);
  }
  if (payload.action === "chatSave") {
    return handleChatSave(event, payload);
  }
  if (payload.action === "chatDelete") {
    return handleChatDelete(event, payload);
  }
  if (payload.action === "listModels") {
    return handleListModels(event);
  }
  if (payload.action === "openRouterModels") {
    return handleOpenRouterModels(event);
  }

  if (payload.action === "vaultCheck") {
    const vaultPw = env("FATHOM_VAULT_PASSWORD");
    const vaultHash = env("FATHOM_VAULT_PASSWORD_HASH");
    const supplied = String(payload.vaultPassword || payload.password || "").trim();
    if (!vaultOk(supplied, vaultPw, vaultHash)) {
      return json(403, { error: "forbidden" });
    }
    return json(200, { ok: true });
  }

  if (!account) {
    return json(401, {
      error: "sign in required",
      mode: "auth_required",
      tier: tier.label,
    });
  }

  if (AUTH_REQUIRED_TIERS.has(tierId) && !account) {
    return json(403, {
      error: "sign in required for this tier",
      mode: "auth_required",
      tier: tier.label,
    });
  }

  const plan = resolvePlan(unlockKeys, account, who);
  if (tier.chopCode && !canUseChopCode(account, plan)) {
    return json(403, {
      error: "ChopCode is included with Pro. Redeem 5 Fathom Pro API keys in Usage, then try again.",
      mode: "chopcode_pro",
      tier: tier.label,
    });
  }
  if (tier.kaji && !canUseKaji(account, plan)) {
    return json(403, {
      error: "Kaji is Pro. Redeem 5 Fathom Pro keys in Usage, then Ask Kaji.",
      mode: "kaji_pro",
      tier: tier.label,
    });
  }
  if (tier.groqOnly && !env("GROQ_API_KEY")) {
    return json(503, {
      error: "This plate is not available — Groq is not configured on the server.",
      mode: "groq_unconfigured",
      tier: tier.label,
    });
  }
  const appVer = appVersionFor(account);
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
      appVersion: appVer,
      usage: usagePayload(plan, stateU),
      budget: { used: stateU.used || 0, limit: plan.limit },
      budgetMode: stateU.mode || budgetMode,
    });
  }

  if (payload.action === "educate" || payload.mode === "educate") {
    const clock = clockNow();
    if (!SEARCH_ENABLED) {
      return json(200, { mode: "educate", date: clock.human, isoDay: clock.isoDay, sources: [], searched: false });
    }
    const q = String(payload.q || "").trim().slice(0, 180) || `technology and world news as of ${clock.human}`;
    const bundle = await webSearch(freshnessQuery(q), 6);
    return json(200, {
      mode: "educate",
      appVersion: appVer,
      date: clock.human,
      isoDay: clock.isoDay,
      query: q,
      searched: true,
      sources: bundle.sources || [],
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
      } else if (/^image\//.test(String(a.mime || ""))) {
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

  const maxModeOn = payload.maxMode === true || Boolean(tier.max);
  const wanted = Number(payload.maxTokens);
  const tierCap = maxModeOn
    ? BILLABLE_MAX_MODE
    : (tier.maxReply || MAX_REPLY_TOKENS_CEILING);
  const replyTokens = Number.isFinite(wanted)
    ? Math.max(100, Math.min(tierCap, MAX_REPLY_TOKENS_CEILING, Math.round(wanted)))
    : (payload.mode === "agent" ? tierCap : MAX_REPLY_TOKENS);

  const { query: parsedSearch, hadPrefix } = parseSearchRequest(lastUser.content);
  const searchQuery = searchQueryForTurns(turns, parsedSearch) || parsedSearch;
  const clientSearchOff = payload.disableSearch === true || payload.client === "widget";
  const isWidget = payload.client === "widget";
  const intel = analyzeRequest(lastUser.content, {
    coding: isCodingTask(lastUser.content),
    kaji: Boolean(tier.kaji),
    chopCode: Boolean(tier.chopCode),
  });
  const kbTop = scoreQuery(searchQuery || lastUser.content)[0];
  intel.hqOnly = Boolean(
    kbTop
    && kbTop.score >= 8
    && !intel.freshnessRequired
    && intel.category !== "CURRENT_INFORMATION"
    && intel.category !== "RESEARCH"
    && intel.category !== "CODING"
    && intel.category !== "DEBUGGING"
    && !intel.toolsRequired
  );
  if (maxModeOn) {
    intel.complexity = 1;
    intel.trivial = false;
    intel.hqOnly = false;
    intel.verificationRequired = true;
    intel.decompose = true;
    if (!clientSearchOff) intel.webRequired = true;
  }
  const budget = computeBudget(intel, tier, { maxMode: maxModeOn });
  const kajiResume = payload.kajiResume && typeof payload.kajiResume === "object" ? payload.kajiResume : null;
  const searchOn = !kajiResume && !intel.trivial && !intel.hqOnly && intel.webRequired && (
    wantsSearch(searchQuery) && (!clientSearchOff || hadPrefix)
  );
  const searchMax = isWidget ? 3 : Math.min(budget.searchMax || 4, MAX_SOURCES);
  const searchStarted = Date.now();
  const liveQuery = freshnessQuery(searchQuery);
  let webBundle = searchOn
    ? await webSearch(liveQuery, searchMax)
    : { context: "", sources: [], ranked: [], conflicts: [] };
  if (searchOn && budget.searchCycles > 1 && (webBundle.sources || []).length < 3) {
    const extra = followUpQueries(searchQuery, intel);
    for (const q of extra.slice(0, budget.searchCycles - 1)) {
      if (Date.now() - searchStarted > 1800) break;
      const more = await webSearch(freshnessQuery(q), Math.min(4, searchMax), 900);
      const merged = rankEvidence(searchQuery, [
        ...(webBundle.ranked || webBundle.sources || []),
        ...(more.ranked || more.sources || []),
      ]).slice(0, searchMax);
      webBundle = {
        ranked: merged,
        conflicts: detectConflicts(merged),
        sources: merged.map((f) => ({ title: f.title, url: f.url, snippet: f.snippet })),
        context: merged.map((f) => `- ${f.title}: ${f.snippet}${f.url ? ` (${f.url})` : ""}`).join("\n"),
      };
    }
  }
  const searchMs = Date.now() - searchStarted;
  const clock = clockNow();
  let webSection = "";
  if (searchOn) {
    const evidence = formatEvidence(
      webBundle.ranked || webBundle.sources,
      webBundle.conflicts,
      budget.evidenceCap
    );
    const clipped = String(webBundle.context || "").slice(0, 2400);
    webSection = evidence
      ? evidence
      : (clipped
        ? `\n\nLIVE RESEARCH as of ${clock.human} (retrieved just now — prefer this over training memory for anything current; cite URLs):\n` + clipped
        : `\n\nLIVE RESEARCH as of ${clock.human}: no snippets returned — answer from your knowledge, and say if the topic may have changed since your training data.`);
    if (intel.decompose) webSection += DECOMPOSE_HINT;
  } else {
    webSection = `\n\nLIVE RESEARCH skipped (${intel.trivial ? "trivial request" : "search off"}). Today's date is still ${clock.human}. Do not invent today's headlines.`;
  }

  const modelTurns = turns.map((m) => ({ ...m }));
  if (hadPrefix && modelTurns.length) {
    const last = modelTurns[modelTurns.length - 1];
    if (last.role === "user") last.content = searchQuery;
  }

  const skipHqGrounding = Boolean((tier.chopCode && !tier.kaji) || (budget.skipHqDump && !tier.kaji));
  const kbFacts = (n) => {
    if (skipHqGrounding) return [];
    if (tier.kaji) return retrieveForKaji(retrievalQuery(modelTurns), n);
    return retrieve(retrievalQuery(modelTurns), n);
  };

  const system = {
    role: "system",
    content: systemPrompt(
      kbFacts(tier.grounding || GROUNDING_INTENTS),
      payload.mode, webSection, tier, language, appVer, maxModeOn
    ),
  };
  const messages = fitContext(system, modelTurns, contextFor(tier, plan));
  if (kajiResume && Array.isArray(kajiResume.toolCalls) && Array.isArray(kajiResume.results)) {
    messages.push({
      role: "assistant",
      content: kajiResume.text || null,
      tool_calls: (kajiResume.toolCalls || []).map((tc) => {
        if (tc && tc.function) return tc;
        return {
          id: String((tc && tc.id) || ""),
          type: "function",
          function: {
            name: String((tc && tc.name) || ""),
            arguments: String((tc && tc.arguments) || "{}"),
          },
        };
      }),
    });
    for (const tr of kajiResume.results) {
      messages.push({
        role: "tool",
        tool_call_id: String((tr && (tr.id || tr.tool_call_id)) || ""),
        content: typeof (tr && tr.content) === "string" ? tr.content : JSON.stringify((tr && tr.content) || {}),
      });
    }
  }

  const RESCUE_RESERVE_MS = 7000;
  const PAIR_RESERVE_MS = 0;
  const platformLeft = Math.max(8000, (tier.timeoutMs || TIMEOUT_MS) - searchMs);
  const modelWindow = Math.min(tier.timeoutMs || TIMEOUT_MS, platformLeft, 22000);
  const deadline = Date.now() + modelWindow;
  const modelDeadline = deadline - RESCUE_RESERVE_MS - PAIR_RESERVE_MS;
  const ATTEMPT_CAP_MS = Math.min(12000, Math.max(6500, tier.timeoutMs || TIMEOUT_MS));
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
    let producedPages = [];

    const ask = String(lastUser.content || "");
    const wantsFiles = /\b(write|create|generate|make|build|scaffold|implement|export|download)\b[\s\S]{0,80}\b(file|files|script|code|program|function|class|module|component|app|html|markdown|md|zip|archive|pdf|csv|json)\b|\.\w{1,8}\b|```|write_file/i.test(ask);
    const useTools = budget.skipTools
      ? false
      : (
        (tier.kaji && (intel.toolsRequired || wantsFiles))
        || (!tier.kaji && payload.enableTools !== false && (payload.tools === true || wantsFiles))
      );
    const activeTools = tier.kaji
      ? (isMacKajiClient(payload)
        ? KAJI_TOOLS
        : KAJI_TOOLS.filter((t) => t.function && t.function.name !== "run_command"))
      : AGENT_TOOLS;

    const longRun = replyTokens > LONG_REPLY_TOKENS;
    const pickedModel = normalizeOpenRouterModelId(payload.model);
    const customModel = pickedModel && canUseCustomModel(pickedModel, payload, account);
    if (pickedModel && !customModel) {
      return json(403, {
        error: isClaudeModelId(pickedModel)
          ? "Add a Claude API key in More models to use that model."
          : isGroqModelId(pickedModel)
            ? "Add a Groq API key in More models to use that model."
            : "Add an OpenRouter API key in More models to use that model.",
        mode: "model_forbidden",
      });
    }
    const chain = (kajiResume && kajiResume.model && isHqOpenRouterAllowed(kajiResume.model)
      ? [kajiResume.model]
      : routeModels({
      intel,
      tier,
      groqKey,
      customModel,
      pickedModel,
      longRun,
    }))
      .filter((m) => !isGroqModelId(m) || groqKey)
      .filter((m) => customModel || isHqOpenRouterAllowed(m))
      .slice(0, customModel || kajiResume ? 1 : (intel.trivial ? 1 : (tier.chopCode || tier.kaji ? 4 : 3)));

    const slimFast = fitContext(
      {
        role: "system",
        content: systemPrompt(
          kbFacts(2),
          payload.mode, "", tier, language, appVer, maxModeOn
        ),
      },
      modelTurns,
      10000
    );
    const fastModels = [
      ...(groqKey ? ["groq/llama-3.1-8b-instant"] : []),
      "nvidia/nemotron-3-nano-30b-a3b:free",
      "openai/gpt-oss-20b:free",
    ];
    const fastPromise = (async () => {
      if (budget.skipFastRace || tier.kaji) return null;
      for (const m of fastModels) {
        if (deadline - Date.now() < 1400) return null;
        const g = withTimeout(Math.min(4200, deadline - Date.now() - 200));
        try {
          const r = await callChatModel({
            model: m,
            messages: slimFast,
            openRouterKey: apiKey,
            groqKey,
            anthropicKey,
            signal: g.signal,
            maxTokens: Math.min(500, replyTokens),
            temperature: 0.35,
          });
          if (r.ok && r.text) return { ...r, model: m };
        } catch (e) {
          lastDetail = String(e && e.name) + " [fast]";
        } finally {
          g.done();
        }
      }
      return null;
    })();

    let agentsTrace = null;
    let conversationTrace = null;
    if (tier.chopCode && !customModel) {
      const ensDeadline = Date.now() + Math.min(4500, Math.max(2500, modelDeadline - Date.now()));
      const ens = await runChopCodeEnsemble({
        callChatModel,
        messages,
        openRouterKey: apiKey,
        groqKey,
        maxTokens: Math.min(replyTokens, 1200),
        deadlineMs: ensDeadline,
        question: String(lastUser.content || ask || ""),
        clockHuman: clock.human,
        webSection: searchOn ? String(webBundle.context || "").slice(0, 2800) : "",
      });
      agentsTrace = ens.agents;
      conversationTrace = ens.conversation;
      if (ens.reply) {
        draft = { text: ens.reply, tokens: ens.tokens || 0 };
        draftModel = ens.leadModel;
      }
    }

    if (!draft) {
    for (let ci = 0; ci < chain.length; ci++) {
      const candidate = chain[ci];
      const modelTag = isGroqModelId(candidate)
        ? groqNativeModelId(candidate)
        : candidate.split("/").slice(1).join("/");
      const msLeft = modelDeadline - Date.now();
      if (msLeft <= (tier.chopCode ? 400 : 1500)) break;
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
          return await callChatModel({
            model: candidate,
            messages,
            openRouterKey: apiKey,
            groqKey,
            anthropicKey,
            signal: g.signal,
            maxTokens: replyTokens,
            temperature: plateTemperature(tier, intel),
            tools: withTools ? activeTools : undefined,
            toolChoice: withTools ? "auto" : undefined,
          });
        } catch (e) {
          return { ok: false, status: 0, detail: String(e && e.name) };
        } finally {
          g.done();
        }
      };

      r = await tryCall(budgetMs, useTools);
      if (!r.ok && useTools && r.status !== 404 && r.status !== 402 && r.status !== 400) {
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
          const localCalls = r.toolCalls.filter((tc) =>
            KAJI_LOCAL_TOOL_NAMES.has(String((tc && tc.function && tc.function.name) || ""))
          );
          if (localCalls.length && isMacKajiClient(payload)) {
            draft = {
              ok: true,
              text: r.text || "",
              tokens: r.tokens || null,
              pendingLocal: true,
              toolCalls: r.toolCalls,
            };
            draftModel = candidate;
            break;
          }
          const left = Math.min(deadline - Date.now() - 400, modelDeadline - Date.now() + 2000);
          if (left > 2000) {
            const g3 = withTimeout(left);
            try {
              const cont = await continueWithTools({
                model: candidate,
                messages,
                first: r,
                openRouterKey: apiKey,
                groqKey,
                anthropicKey,
                signal: g3.signal,
                maxTokens: replyTokens,
                temperature: plateTemperature(tier, intel),
                tools: activeTools,
              });
              draft = {
                ok: true,
                text: cont.text || r.text || "",
                tokens: cont.tokens,
                toolCalls: [],
              };
              producedFiles = cont.files || [];
              producedPages = cont.pages || [];
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
      lastDetail = (r.detail || "") + ` [${modelTag} ${Date.now() - attemptStart}/${budgetMs}ms]`;
      if (ci === 0 && Date.now() - attemptStart > 8000 && lastStatus !== 404 && lastStatus !== 402) continue;
    }

    if (!draft && !tier.groqOnly) {
      const slimSystem = {
        role: "system",
        content: systemPrompt(
          kbFacts(Math.min(3, tier.grounding || 3)),
          payload.mode, "", tier, language, appVer, maxModeOn
        ),
      };
      const slimMessages = fitContext(slimSystem, modelTurns, 12000);
      const rescues = customModel
        ? []
        : [
          ...(groqKey ? ["groq/llama-3.1-8b-instant"] : []),
          "nvidia/nemotron-3-nano-30b-a3b:free",
          "openai/gpt-oss-20b:free",
        ];
      for (const rescue of rescues) {
        const left = deadline - Date.now() - 200;
        if (left < 2000) break;
        const slice = Math.min(4500, left);
        const gR = withTimeout(slice);
        try {
          const r = await callChatModel({
            model: rescue,
            messages: slimMessages,
            openRouterKey: apiKey,
            groqKey,
            anthropicKey,
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
    }

    if (!draft) {
      console.error("chopsticksAI: all models failed", {
        tier: tier.label, status: lastStatus, detail: String(lastDetail).slice(0, 300),
        replyTokens, msLeft: deadline - Date.now(),
      });
      const panicLeft = deadline - Date.now();
      if (!customModel && panicLeft > 1800 && !tier.groqOnly) {
        const gP = withTimeout(panicLeft - 300);
        try {
          const r = await callChatModel({
            model: groqKey ? "groq/llama-3.1-8b-instant" : "nvidia/nemotron-3-nano-30b-a3b:free",
            messages: fitContext(
              {
                role: "system",
                content: systemPrompt(
                  kbFacts(2),
                  payload.mode, "", tier, language, appVer, maxModeOn
                ),
              },
              modelTurns,
              10000
            ),
            openRouterKey: apiKey,
            groqKey,
            anthropicKey,
            signal: gP.signal,
            maxTokens: Math.min(320, replyTokens),
            temperature: 0.35,
          });
          if (r.ok && r.text) {
            draft = r;
            draftModel = groqKey ? "groq/llama-3.1-8b-instant" : "nvidia/nemotron-3-nano-30b-a3b:free";
          }
        } catch (e) {
          lastDetail = String(e && e.name) + " [panic]";
        } finally {
          gP.done();
        }
      }
    }

    if (!draft) {
      const fast = await fastPromise;
      if (fast && fast.text) {
        draft = fast;
        draftModel = fast.model;
      }
    }

    if (!draft) {
      return json(200, {
        ...answerWhenModelsFail(turns, lastUser, webBundle, payload),
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

    if (draft.pendingLocal && isMacKajiClient(payload)) {
      return json(200, {
        reply: draft.text || "",
        mode: "kaji_local_tools",
        localTools: serializeToolCalls(draft.toolCalls),
        appVersion: appVer,
        model: draftModel,
        tier: tier.label,
        searched: searchOn,
        sources: webBundle.sources || [],
        files: [],
        browser: producedPages,
      });
    }

    producedFiles = mergeFiles(producedFiles, extractFencedFiles(reply));
    reply = liftLooseCodeIntoFences(reply);
    producedFiles = mergeFiles(producedFiles, extractFencedFiles(reply));
    if (producedFiles.length) {
      reply = ensureFileFences(reply, producedFiles);
    }

    const refineOn = REFINE_ENABLED && !isWidget && !agentsTrace && !draft.pendingLocal
      && !intel.trivial && !intel.hqOnly
      && (budget.critics > 0 || (tier.refine !== false && intel.complexity >= 0.45));
    const refineQueue = (Array.isArray(tier.refineModels) && tier.refineModels.length
      ? tier.refineModels
      : (tier.refineModel ? [tier.refineModel] : (tier.refine ? [REFINE_MODEL] : [])))
      .filter((m) => !isGroqModelId(m) || groqKey)
      .filter((m) => isHqOpenRouterAllowed(m));
    const question = [...turns].reverse().find((m) => m.role === "user");
      const pairPass = Boolean(tier.chopCode);
      const maxCritics = pairPass
        ? 1
        : (intel.hqOnly || intel.trivial ? 0 : Math.max(budget.critics, intel.complexity >= 0.45 ? 1 : 0));
    let criticUsed = 0;
    for (const refineModel of refineQueue) {
      const timeLeft = deadline - Date.now();
      if (!refineOn || !refineModel) break;
      if (refineModel === draftModel || refineModel === refinedBy) continue;
      if (!pairPass && timeLeft < REFINE_MIN_MS) break;
      if (!pairPass && criticUsed >= maxCritics) break;
      if (pairPass && timeLeft < 1800) break;
      const g = withTimeout(Math.min(timeLeft - 400, pairPass ? 7500 : timeLeft - 500));
      let r;
      try {
        r = await callChatModel({
          model: refineModel,
          openRouterKey: apiKey,
          groqKey,
          anthropicKey,
          signal: g.signal,
          temperature: pairPass ? 0.4 : 0.2,
          maxTokens: pairPass ? Math.min(replyTokens, 4096) : undefined,
          messages: [
            { role: "system", content: pairPass ? CHOPCODE_PAIR_SYSTEM : (budget.critics ? CRITIC_SYSTEM : REFINE_SYSTEM) },
            {
              role: "user",
              content:
                "QUESTION:\n" + (question ? question.content : "") +
                "\n\nVERIFIED EVIDENCE (only source for numbers, dates, versions, prices):\n" +
                (formatEvidence(
                  webBundle.ranked || webBundle.sources,
                  webBundle.conflicts,
                  budget.evidenceCap
                ) || "(none — do not invent numbers, dates, or citations)") +
                "\n\nDRAFT REPLY:\n" + reply,
            },
          ],
        });
      } catch (e) {
        r = { ok: false };
      } finally {
        g.done();
      }
      criticUsed += 1;
      if (r.ok && r.text) {
        reply = r.text;
        refinedBy = refineModel;
        spent += r.tokens || estimateTokens(draft.text || "") + MAX_REPLY_TOKENS;
        if (pairPass) {
          reply = liftLooseCodeIntoFences(reply);
          producedFiles = mergeFiles(producedFiles, extractFencedFiles(reply));
        }
        if (pairPass) break;
      }
    }

    const spentResult = await budgetSpend(maxModeOn ? BILLABLE_MAX_MODE : BILLABLE_PER_REPLY, now, budgetOpts);
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
      appVersion: appVer,
      model: customModel && draftModel ? draftModel : ("cs.AI " + appVer),
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
      browser: producedPages,
      budget: { used: spentResult.used, limit: plan.limit },
      usage: usagePayload(plan, {
        used: spentResult.used,
        blocked: false,
        mode: spentResult.mode,
      }),
      budgetMode: spentResult.mode,
      ...(agentsTrace ? {
        agents: agentsTrace,
        conversation: conversationTrace || [],
        chopCodeEnsemble: true,
      } : {}),
    });
  } catch (e) {
    return json(200, {
      ...answerWhenModelsFail(turns, lastUser, typeof webBundle !== "undefined" ? webBundle : null, payload),
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
  canUseChopCode, CHOPCODE_PRO_KEYS, extractAccessToken, clientWho,
  budgetPeek, budgetSpend, budgetState, spend,
  callChatModel, clockNow,
  _budget: budget, budgetMode, MAX_CONTEXT_TOKENS, TOKEN_BUDGET, COOLDOWN_MS,
  FREE_USAGE, CREDIT_TIERS, mozillaEngine,
};
