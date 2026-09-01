
const {
  resolveAccount,
  resolvePlan,
  extractAccessToken,
  clientWho,
  canUseChopCode,
  CHOPCODE_PRO_KEYS,
  webSearch,
  clockNow,
  retrieve,
  retrievalQuery,
  callChatModel,
} = require("./chopsticks-ai.js");
const {
  runChopCodeEnsemble,
  CHOPCODE_AGENTS,
  CHOPCODE_SYNTH_ID,
} = require("./chopcode-ensemble.js");
const { isBrazil, brazilJson } = require("./region-block.js");

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const INPUT_TOKEN_LIMIT = 128_000;
const TOTAL_TOKEN_LIMIT = 1_000_000;
const MAX_COMPLETION_TOKENS = 4096;
const MIN_COMPLETION_TOKENS = 256;
const SYSTEM_OVERHEAD_TOKENS = 900;

const SYSTEM_PROMPT = [
  "You are ChopCode, the coding assistant for ChopsticksAI.",
  "Write and edit code, explain bugs, and propose concrete patches.",
  "Prefer working code over commentary. Use markdown fences with a language tag.",
  "If the user pastes code, treat it as the working set unless they say otherwise.",
  "Never name the model you run on, the inference vendor, or any API brand.",
  "If you are unsure, say so and list what you would check next.",
].join(" ");

const env = (name) =>
  String((typeof process !== "undefined" && process.env && process.env[name]) || "").trim();

const json = (status, body, extraHeaders) => ({
  statusCode: status,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    ...(extraHeaders || {}),
  },
  body: JSON.stringify(body),
});

function estimateTokens(text) {
  return Math.max(0, Math.ceil(String(text || "").length / 4));
}

function corsHeaders(event) {
  const origin = String((event.headers && (event.headers.origin || event.headers.Origin)) || "");
  const allow =
    !origin ||
    /^https:\/\/chopstickshq\.com$/i.test(origin) ||
    /^https:\/\/([a-z0-9-]+\.)?netlify\.app$/i.test(origin) ||
    /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);
  return {
    "Access-Control-Allow-Origin": allow ? origin || "https://chopstickshq.com" : "https://chopstickshq.com",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    Vary: "Origin",
  };
}

function parseBody(event) {
  if (!event) return {};
  if (event.body && typeof event.body === "object") return event.body;
  const raw = event.body || "";
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function friendlyError(status, fallback) {
  if (status === 429) {
    return "ChopCode is busy right now. Wait a few seconds and try again.";
  }
  if (status === 401) return "Sign in to use ChopCode.";
  if (status === 403) {
    return `ChopCode is included with Pro. Redeem ${CHOPCODE_PRO_KEYS} Fathom Pro API keys in Usage, then try again.`;
  }
  if (status === 413) {
    return "This request is too large for ChopCode. Shorten the prompt or the code context.";
  }
  if (status === 503) return "ChopCode is temporarily unavailable. Try again later.";
  return fallback || "ChopCode could not complete that request. Try again shortly.";
}

function stripVendorNames(text) {
  return String(text || "")
    .replace(/\bopen\s*router\b/gi, "the coding service")
    .replace(/\bqwen(?:3)?(?:-coder)?\b/gi, "ChopCode")
    .replace(/\bglm(?:[\d.-]+)?\b/gi, "ChopCode")
    .replace(/\bz[\s-]?ai\b/gi, "ChopCode")
    .replace(/\bnemotron\b/gi, "ChopCode")
    .replace(/\bkimi(?:\s*k2(?:\.\d+)?)?\b/gi, "ChopCode")
    .replace(/\bmoonshot(?:ai)?\b/gi, "ChopCode")
    .replace(/\bpoolside\b/gi, "ChopCode")
    .replace(/\blaguna\b/gi, "ChopCode")
    .replace(/\bcohere\b/gi, "ChopCode")
    .replace(/\bllama\b/gi, "ChopCode");
}

function fitChopCodeInput(prompt, code) {
  const p = String(prompt || "").trim();
  if (!p) {
    return { error: json(400, { ok: false, error: "Enter a prompt for ChopCode." }) };
  }
  let c = String(code || "");
  const pTok = estimateTokens(p);
  if (pTok + SYSTEM_OVERHEAD_TOKENS > INPUT_TOKEN_LIMIT) {
    return { error: json(413, { ok: false, error: friendlyError(413) }) };
  }
  let truncated = false;
  let cTok = estimateTokens(c);
  while (c && pTok + cTok + SYSTEM_OVERHEAD_TOKENS > INPUT_TOKEN_LIMIT) {
    truncated = true;
    c = c.slice(0, Math.max(0, Math.floor(c.length * 0.82)));
    cTok = estimateTokens(c);
  }
  const inputTokens = pTok + cTok + SYSTEM_OVERHEAD_TOKENS;
  if (inputTokens > INPUT_TOKEN_LIMIT) {
    return { error: json(413, { ok: false, error: friendlyError(413) }) };
  }
  const room = TOTAL_TOKEN_LIMIT - inputTokens;
  if (room < MIN_COMPLETION_TOKENS) {
    return { error: json(413, { ok: false, error: friendlyError(413) }) };
  }
  const maxTokens = Math.min(MAX_COMPLETION_TOKENS, room);
  return { prompt: p, code: c, truncated, inputTokens, maxTokens };
}

async function buildEducatedMessages(prompt, code) {
  const clock = clockNow();
  const webBundle = await webSearch(prompt, 8);
  const webClip = String(webBundle.context || "").slice(0, 3200);
  const webSection = webClip
    ? `\n\nLIVE RESEARCH as of ${clock.human}:\n${webClip}`
    : `\n\nToday's date: ${clock.human}. No live snippets returned — answer from current stable knowledge and say if unsure.`;
  const kb = retrieve(prompt, 6)
    .map((i) => `### ${i.label}\n${i.answer}`)
    .join("\n\n");
  const userParts = [prompt];
  if (code && code.trim()) {
    userParts.push("", "Code context:", "```", code, "```");
  }
  const system = [
    SYSTEM_PROMPT,
    `\nSession date: ${clock.human} (${clock.isoDay} UTC).`,
    webSection,
    kb ? `\n\nPRODUCT FACTS:\n${kb}` : "",
  ].join("");
  return {
    messages: [
      { role: "system", content: system },
      { role: "user", content: userParts.join("\n") },
    ],
    clock,
    webSection: webClip,
    sources: webBundle.sources || [],
  };
}

async function handleChopCode(event) {
  const cors = corsHeaders(event);
  const method = String((event && event.httpMethod) || (event && event.method) || "GET").toUpperCase();
  if (method === "OPTIONS") {
    return { statusCode: 204, headers: cors, body: "" };
  }
  if (method === "GET") {
    return json(200, {
      ok: true,
      product: "ChopCode",
      stream: false,
      ensemble: true,
      agents: CHOPCODE_AGENTS.map((a) => ({ id: a.id, label: a.label, role: a.role })),
      lead: CHOPCODE_SYNTH_ID,
      inputTokenLimit: INPUT_TOKEN_LIMIT,
      totalTokenLimit: TOTAL_TOKEN_LIMIT,
    }, cors);
  }
  if (method !== "POST") {
    return json(405, { ok: false, error: "Use POST." }, cors);
  }

  const payload = parseBody(event);
  const prompt = payload.prompt || payload.message || payload.q || "";
  const code = payload.code || payload.context || payload.codeContext || "";
  const unlockKeys = Array.isArray(payload.unlockKeys) ? payload.unlockKeys : [];

  const accessToken = extractAccessToken(event);
  const account = await resolveAccount(accessToken);
  if (!account) {
    return json(401, { ok: false, error: friendlyError(401) }, cors);
  }
  const plan = resolvePlan(unlockKeys, account, clientWho(event));
  if (!canUseChopCode(account, plan)) {
    return json(403, { ok: false, error: friendlyError(403), requiresKeys: CHOPCODE_PRO_KEYS }, cors);
  }

  const fitted = fitChopCodeInput(prompt, code);
  if (fitted.error) {
    fitted.error.headers = { ...fitted.error.headers, ...cors };
    return fitted.error;
  }

  const apiKey = env("OPENROUTER_API_KEY");
  const groqKey = env("GROQ_API_KEY");
  if (!apiKey) {
    return json(503, { ok: false, error: friendlyError(503) }, cors);
  }

  let educated;
  try {
    educated = await buildEducatedMessages(fitted.prompt, fitted.code);
  } catch (e) {
    return json(502, { ok: false, error: friendlyError(502) }, cors);
  }

  const deadline = Date.now() + 52000;
  let ensemble;
  try {
    ensemble = await runChopCodeEnsemble({
      callChatModel,
      messages: educated.messages,
      openRouterKey: apiKey,
      groqKey,
      maxTokens: fitted.maxTokens,
      deadlineMs: deadline,
      question: fitted.prompt,
      clockHuman: educated.clock.human,
      webSection: educated.webSection,
    });
  } catch (e) {
    return json(502, { ok: false, error: friendlyError(502) }, cors);
  }

  const finalText = stripVendorNames(ensemble.reply || "");
  if (!finalText) {
    return json(502, { ok: false, error: friendlyError(502) }, cors);
  }

  return json(200, {
    ok: true,
    product: "ChopCode",
    text: finalText,
    truncated: fitted.truncated,
    inputTokens: fitted.inputTokens,
    agents: ensemble.agents,
    chopCodeEnsemble: true,
    sources: educated.sources,
    searched: Boolean(educated.webSection),
  }, cors);
}

async function handler(event, context) {
  if (event && event.httpMethod !== "OPTIONS" && isBrazil(event, context)) {
    return brazilJson("csai");
  }
  return handleChopCode(event);
}

module.exports = {
  handler,
  handleChopCode,
  INPUT_TOKEN_LIMIT,
  TOTAL_TOKEN_LIMIT,
  CHOPCODE_AGENTS,
};
