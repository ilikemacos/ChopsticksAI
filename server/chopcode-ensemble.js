/** ChopCode multi-agent ensemble — specialists discuss, then Lead synthesizes. */

const CHOPCODE_AGENTS = [
  { id: "z-ai/glm-5.2:free", label: "Agent 1", role: "general code" },
  { id: "nvidia/nemotron-3-ultra:free", label: "Agent 2", role: "architecture" },
  { id: "cohere/north-mini-code:free", label: "Agent 3", role: "compact patches" },
  { id: "openai/gpt-oss-20b:free", label: "Agent 4", role: "scripts" },
  { id: "qwen/qwen3-coder:free", label: "Agent 5", role: "refactors" },
  { id: "groq/llama-3.3-70b-versatile", label: "Agent 6", role: "fast draft" },
  { id: "poolside/laguna-s-2.1:free", label: "Agent 7", role: "repo edits" },
  { id: "nvidia/nemotron-3-super-120b-a12b:free", label: "Agent 8", role: "deep review" },
  { id: "google/gemma-4-26b-a4b-it:free", label: "Agent 9", role: "instruction follow" },
  { id: "google/gemma-4-31b-it:free", label: "Agent 10", role: "reasoning" },
];

const CHOPCODE_SYNTH_ID = "moonshotai/kimi-k2.6:free";
const CHOPCODE_SYNTH_LABEL = "Lead";

const CHOPCODE_MODEL_RESOLVE = {
  "nvidia/nemotron-3-ultra:free": "nvidia/nemotron-3-ultra-550b-a55b:free",
  "qwen/qwen3-coder:free": "qwen/qwen3-coder-flash",
  "groq/llama-3.3-70b-versatile:free": "groq/llama-3.3-70b-versatile",
  "moonshotai/kimi-k2.6:free": "moonshotai/kimi-k2.6",
};

const DISCUSS_SYSTEM = [
  "You are one specialist in a shared coding room. The user sees you as a numbered Agent.",
  "Other agents already posted drafts. Reply in 2–4 sentences: agree, push back, or add one sharp point.",
  "Do not rewrite full solutions. Speak naturally as a teammate. Never name models or vendors.",
].join(" ");

const SYNTH_SYSTEM = [
  "You are ChopCode Lead — the final voice of the ChopCode coding assistant.",
  "Specialist agents drafted answers and discussed them in the room. Merge the best ideas into ONE reply.",
  "Fix contradictions, keep runnable code, use ```lang filename fences for every file.",
  "Ground answers in today's date and any live research provided.",
  "Never mention agents, drafts, models, vendors, or that multiple AIs ran.",
  "Output only the final answer the user should see.",
].join(" ");

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

function clipMessage(text, max = 12000) {
  const t = String(text || "");
  return t.length <= max ? t : t.slice(0, max - 20) + "\n\n… [truncated]";
}

function buildSynthUserContent(question, drafts, discussion, clockHuman, webSection) {
  const blocks = drafts.map((d, i) => (
    `### Agent ${i + 1} (${d.label})\n${d.text}`
  )).join("\n\n");
  const discussBlock = discussion.length
    ? "\n\nROOM DISCUSSION:\n" + discussion.map((d) => `- ${d.label}: ${d.text}`).join("\n")
    : "";
  return [
    `USER REQUEST:\n${question}`,
    webSection ? `\nLIVE CONTEXT:\n${webSection}` : "",
    `\nTODAY: ${clockHuman}`,
    "\nSPECIALIST DRAFTS:\n",
    blocks || "(No specialist drafts succeeded — answer from your own knowledge.)",
    discussBlock,
    "\nWrite the merged final answer.",
  ].join("");
}

const INSTANT_TALK = [
  "I'll take the first pass.",
  "I'll check structure and naming.",
  "I'll watch the edge cases.",
  "I'll keep it small and runnable.",
  "I'll tighten the types and imports.",
  "I'll go for the fast path.",
  "I'll think about how this lands in a repo.",
  "I'll review it like a PR.",
  "I'll follow the request literally.",
  "I'll stress-test the reasoning.",
];

function instantConversation(question) {
  const q = String(question || "").trim().slice(0, 80);
  const out = [];
  CHOPCODE_AGENTS.forEach((a, i) => {
    out.push({
      id: `talk-${a.id}`,
      speaker: a.label,
      label: a.label,
      type: "discuss",
      text: INSTANT_TALK[i] + (q ? ` On: “${q}${String(question || "").length > 80 ? "…" : ""}”.` : ""),
      status: "done",
      ms: 0,
    });
  });
  return out;
}

function pushTurn(conversation, turn) {
  conversation.push({
    id: turn.id || `${turn.type}-${conversation.length}`,
    speaker: turn.speaker || turn.label || "Agent",
    label: turn.label || turn.speaker || "Agent",
    type: turn.type || "message",
    text: turn.text || "",
    status: turn.status || "done",
    ms: turn.ms || 0,
  });
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
      maxTokens: Math.min(maxTokens, 768),
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

async function runAgentDiscussion({
  successful,
  callChatModel,
  openRouterKey,
  groqKey,
  timeoutMs,
}) {
  if (successful.length < 2) return [];
  const perAgentMs = Math.max(2500, Math.min(7000, timeoutMs));

  const out = await Promise.all(successful.map(async (self) => {
    const others = successful
      .filter((o) => o.agent.id !== self.agent.id)
      .slice(0, 5)
      .map((o) => `- ${o.agent.label}: ${agentPreview(o.text, 200)}`)
      .join("\n");
    const resolved = resolveChopCodeModelId(self.agent.id);
    if (isGroqModelId(resolved) && !groqKey) return null;
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), perAgentMs);
    try {
      const r = await callChatModel({
        model: resolved,
        messages: [
          { role: "system", content: DISCUSS_SYSTEM },
          {
            role: "user",
            content: [
              `Your draft:\n${agentPreview(self.text, 500)}`,
              `\nOther specialists in the room:\n${others}`,
              "\nReply to the room (2–4 sentences):",
            ].join("\n"),
          },
        ],
        openRouterKey,
        groqKey,
        signal: ctrl.signal,
        maxTokens: 220,
        temperature: 0.65,
      });
      if (r.ok && r.text) {
        return {
          id: self.agent.id,
          label: self.agent.label,
          text: r.text.trim(),
        };
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      clearTimeout(timer);
    }
  }));
  return out.filter(Boolean);
}

/**
 * Run specialists in parallel, room discussion, then Lead synthesis.
 * Returns { reply, agents, conversation, leadModel, drafts, tokens }.
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
  const conversation = instantConversation(question);
  const active = CHOPCODE_AGENTS.slice(0, 3);

  const trace = CHOPCODE_AGENTS.map((a, i) => ({
    id: a.id,
    label: a.label,
    role: a.role,
    status: i < active.length ? "running" : "skipped",
    preview: INSTANT_TALK[i] || "",
    message: "",
    ms: 0,
  }));

  const left = Math.max(0, deadlineMs - Date.now());
  const synthReserve = Math.min(2200, Math.max(1200, Math.floor(left * 0.35)));
  const perAgentMs = Math.max(900, Math.min(2200, left - synthReserve - 100));

  const results = await Promise.all(
    active.map((agent, idx) =>
      runOneAgent({
        agent,
        messages,
        callChatModel,
        openRouterKey,
        groqKey,
        maxTokens: Math.min(maxTokens, 512),
        timeoutMs: perAgentMs,
      }).then((r) => {
        trace[idx].status = r.ok ? "done" : "skipped";
        trace[idx].preview = r.preview || trace[idx].preview || "";
        trace[idx].message = r.ok ? clipMessage(r.text) : "";
        trace[idx].ms = r.ms || 0;
        trace[idx].resolved = r.resolved || resolveChopCodeModelId(agent.id);
        if (r.ok && r.text) {
          pushTurn(conversation, {
            id: `draft-${agent.id}`,
            speaker: agent.label,
            label: agent.label,
            type: "draft",
            text: agentPreview(r.text, 280),
            status: "done",
            ms: r.ms || 0,
          });
        }
        return r;
      })
    )
  );

  const successful = results.filter((r) => r.ok && r.text);
  const drafts = successful.map((r) => ({ id: r.agent.id, label: r.agent.label, text: r.text }));

  const discussion = [];

  const leadTrace = {
    id: CHOPCODE_SYNTH_ID,
    label: CHOPCODE_SYNTH_LABEL,
    role: "synthesizer",
    status: "running",
    preview: "",
    message: "",
    ms: 0,
  };
  trace.push(leadTrace);

  const synthResolved = resolveChopCodeModelId(CHOPCODE_SYNTH_ID);
  let reply = "";
  let tokens = 0;
  const synthStart = Date.now();
  const synthCtrl = new AbortController();
  const synthTimer = setTimeout(
    () => synthCtrl.abort(),
    Math.max(900, Math.min(2200, deadlineMs - Date.now() - 200))
  );
  try {
    const synth = await callChatModel({
      model: synthResolved,
      messages: [
        { role: "system", content: SYNTH_SYSTEM },
        {
          role: "user",
          content: buildSynthUserContent(question, drafts, discussion, clockHuman, webSection),
        },
      ],
      openRouterKey,
      groqKey,
      signal: synthCtrl.signal,
      maxTokens: Math.min(maxTokens, 1800),
      temperature: 0.35,
    });
    leadTrace.ms = Date.now() - synthStart;
    if (synth.ok && synth.text) {
      reply = synth.text;
      tokens = synth.tokens || 0;
      leadTrace.status = "done";
      leadTrace.preview = agentPreview(reply);
      leadTrace.message = clipMessage(reply);
      pushTurn(conversation, {
        id: "synthesis",
        speaker: CHOPCODE_SYNTH_LABEL,
        label: CHOPCODE_SYNTH_LABEL,
        type: "synthesis",
        text: agentPreview(reply, 480),
        status: "done",
        ms: leadTrace.ms,
      });
    } else if (drafts.length) {
      reply = drafts[0].text;
      leadTrace.status = "skipped";
      leadTrace.preview = "Lead unavailable — showing top specialist draft";
      leadTrace.message = clipMessage(reply);
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
    conversation,
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
  instantConversation,
  runChopCodeEnsemble,
};
