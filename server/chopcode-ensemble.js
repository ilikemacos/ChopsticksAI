/** ChopCode multi-agent ensemble — eight specialists + Kimi K2.6 lead synthesizer. */

const CHOPCODE_AGENTS = [
  { id: "z-ai/glm-5.2:free", label: "ChopCode · GLM", role: "general code" },
  { id: "nvidia/nemotron-3-ultra:free", label: "ChopCode · Nemotron Ultra", role: "architecture" },
  { id: "cohere/north-mini-code:free", label: "ChopCode · North", role: "compact patches" },
  { id: "openai/gpt-oss-20b:free", label: "ChopCode · OSS 20B", role: "scripts" },
  { id: "qwen/qwen3-coder:free", label: "ChopCode · Qwen Coder", role: "refactors" },
  { id: "groq/llama-3.3-70b-versatile:free", label: "ChopCode · Llama 70B", role: "fast draft" },
  { id: "poolside/laguna-s-2.1:free", label: "ChopCode · Laguna", role: "repo edits" },
  { id: "nvidia/nemotron-3-super-120b-a12b:free", label: "ChopCode · Nemotron Super", role: "deep review" },
];

const CHOPCODE_SYNTH_ID = "moonshotai/kimi-k2.6:free";
const CHOPCODE_SYNTH_LABEL = "ChopCode · Lead";

/** Map public ChopCode ids → live OpenRouter / Groq routes when suffix differs. */
const CHOPCODE_MODEL_RESOLVE = {
  "nvidia/nemotron-3-ultra:free": "nvidia/nemotron-3-ultra-550b-a55b:free",
  "qwen/qwen3-coder:free": "qwen/qwen3-coder-flash",
  "groq/llama-3.3-70b-versatile:free": "groq/llama-3.3-70b-versatile",
  "moonshotai/kimi-k2.6:free": "moonshotai/kimi-k2.6",
};

function resolveChopCodeModelId(id) {
  const raw = String(id || "").trim();
  return CHOPCODE_MODEL_RESOLVE[raw] || raw;
}

function isGroqModelId(id) {
  return String(id || "").toLowerCase().startsWith("groq/");
}

function agentPreview(text, max = 220) {
  const t = String(text || "").replace(/\s+/g, " ").trim();
  if (!t) return "";
  return t.length <= max ? t : t.slice(0, max - 1) + "…";
}

const SYNTH_SYSTEM = [
  "You are ChopCode Lead — the final voice of the ChopCode coding assistant.",
  "Eight specialist agents already answered the user. Merge their best ideas into ONE reply.",
  "Fix contradictions, keep runnable code, use ```lang filename fences for every file.",
  "Ground answers in today's date and any live research provided.",
  "Never mention agents, drafts, models, vendors, or that multiple AIs ran.",
  "Output only the final answer the user should see.",
].join(" ");

function buildSynthUserContent(question, drafts, clockHuman, webSection) {
  const blocks = drafts.map((d, i) => (
    `### Agent ${i + 1} (${d.label})\n${d.text}`
  )).join("\n\n");
  return [
    `USER REQUEST:\n${question}`,
    webSection ? `\nLIVE CONTEXT:\n${webSection}` : "",
    `\nTODAY: ${clockHuman}`,
    "\nSPECIALIST DRAFTS:\n",
    blocks || "(No specialist drafts succeeded — answer from your own knowledge.)",
    "\nWrite the merged final answer.",
  ].join("");
}

async function runOneAgent({
  agent,
  messages,
  callChatModel,
  openRouterKey,
  groqKey,
  maxTokens,
  timeoutMs,
}) {
  const resolved = resolveChopCodeModelId(agent.id);
  if (isGroqModelId(resolved) && !groqKey) {
    return { agent, ok: false, status: 503, preview: "Groq route unavailable", ms: 0 };
  }
  const t0 = Date.now();
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const r = await callChatModel({
      model: resolved,
      messages,
      openRouterKey,
      groqKey,
      signal: ctrl.signal,
      maxTokens: Math.min(maxTokens, 2048),
      temperature: 0.55,
    });
    const ms = Date.now() - t0;
    if (r.ok && r.text) {
      return {
        agent,
        ok: true,
        text: r.text,
        preview: agentPreview(r.text),
        ms,
        resolved,
      };
    }
    return {
      agent,
      ok: false,
      status: r.status || 0,
      preview: agentPreview(r.detail || "No response", 120),
      ms,
      resolved,
    };
  } catch (e) {
    return {
      agent,
      ok: false,
      status: 0,
      preview: e && e.name === "AbortError" ? "Timed out" : "Error",
      ms: Date.now() - t0,
      resolved,
    };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Run all ChopCode specialists in parallel, then synthesize with Kimi K2.6 (free).
 * Returns { reply, agents, leadModel, drafts, tokens }.
 */
async function runChopCodeEnsemble({
  callChatModel,
  messages,
  openRouterKey,
  groqKey,
  maxTokens,
  deadlineMs,
  question,
  clockHuman,
  webSection,
}) {
  const trace = CHOPCODE_AGENTS.map((a) => ({
    id: a.id,
    label: a.label,
    role: a.role,
    status: "running",
    preview: "",
    ms: 0,
  }));

  const budget = Math.max(3500, Math.min(11000, deadlineMs - Date.now() - 6000));
  const perAgentMs = Math.max(3500, Math.min(9000, budget));

  const results = await Promise.all(
    CHOPCODE_AGENTS.map((agent, idx) =>
      runOneAgent({
        agent,
        messages,
        callChatModel,
        openRouterKey,
        groqKey,
        maxTokens,
        timeoutMs: perAgentMs,
      }).then((r) => {
        trace[idx].status = r.ok ? "done" : "skipped";
        trace[idx].preview = r.preview || "";
        trace[idx].ms = r.ms || 0;
        trace[idx].resolved = r.resolved || resolveChopCodeModelId(agent.id);
        return r;
      })
    )
  );

  const drafts = results
    .filter((r) => r.ok && r.text)
    .map((r) => ({ id: r.agent.id, label: r.agent.label, text: r.text }));

  const leadTrace = {
    id: CHOPCODE_SYNTH_ID,
    label: CHOPCODE_SYNTH_LABEL,
    role: "synthesizer",
    status: "running",
    preview: "",
    ms: 0,
  };
  trace.push(leadTrace);

  const synthResolved = resolveChopCodeModelId(CHOPCODE_SYNTH_ID);
  let reply = "";
  let tokens = 0;
  const synthStart = Date.now();
  const synthCtrl = new AbortController();
  const synthTimer = setTimeout(() => synthCtrl.abort(), Math.max(2500, deadlineMs - Date.now() - 400));
  try {
    const synth = await callChatModel({
      model: synthResolved,
      messages: [
        { role: "system", content: SYNTH_SYSTEM },
        {
          role: "user",
          content: buildSynthUserContent(question, drafts, clockHuman, webSection),
        },
      ],
      openRouterKey,
      groqKey,
      signal: synthCtrl.signal,
      maxTokens: Math.min(maxTokens, 4096),
      temperature: 0.35,
    });
    leadTrace.ms = Date.now() - synthStart;
    if (synth.ok && synth.text) {
      reply = synth.text;
      tokens = synth.tokens || 0;
      leadTrace.status = "done";
      leadTrace.preview = agentPreview(reply);
    } else if (drafts.length) {
      reply = drafts[0].text;
      leadTrace.status = "skipped";
      leadTrace.preview = "Lead unavailable — showing top specialist draft";
    } else {
      leadTrace.status = "error";
      leadTrace.preview = synth.detail ? agentPreview(synth.detail, 120) : "Lead unavailable";
    }
  } catch (e) {
    leadTrace.status = "error";
    leadTrace.preview = e && e.name === "AbortError" ? "Lead timed out" : "Lead error";
    leadTrace.ms = Date.now() - synthStart;
    if (drafts.length) reply = drafts[0].text;
  } finally {
    clearTimeout(synthTimer);
  }

  return {
    reply,
    agents: trace,
    leadModel: synthResolved,
    draftCount: drafts.length,
    tokens,
  };
}

module.exports = {
  CHOPCODE_AGENTS,
  CHOPCODE_SYNTH_ID,
  CHOPCODE_SYNTH_LABEL,
  resolveChopCodeModelId,
  runChopCodeEnsemble,
};
