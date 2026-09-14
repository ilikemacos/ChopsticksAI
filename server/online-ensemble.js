/** cs.AI-4.0-Air — GLM 4.7 Flash Free drafts, GLM 5.2 Free writes the final reply. */

const DRAFT_ID = "z-ai/glm-4.7-flash:free";
const SYNTH_ID = "z-ai/glm-5.2:free";

const DRAFT_SYSTEM = [
  "You are the drafter. Write a complete first solution.",
  "Lead with the answer. Use live research and today's date when they are provided.",
  "Be non-partisan. Never name models, vendors, or that a later pass will rewrite you.",
].join(" ");

const SYNTH_SYSTEM = [
  "You write the only reply the user will see.",
  "You received a first draft. Treat it as notes, not the final answer.",
  "Write a better, complete answer. Do not mention a draft, a team, or model names.",
  "Be non-partisan: neither politically left nor right.",
  "If code is needed, use complete fenced files with language tags and filenames.",
  "Never add a Sources section or list URLs.",
].join(" ");

function clip(text, max) {
  const t = String(text || "");
  if (t.length <= max) return t;
  return t.slice(0, max - 16) + "\n\n… [truncated]";
}

function questionFromMessages(messages) {
  const turns = Array.isArray(messages) ? messages : [];
  for (let i = turns.length - 1; i >= 0; i--) {
    if (turns[i] && turns[i].role === "user") return String(turns[i].content || "");
  }
  return "";
}

function systemFromMessages(messages) {
  const sys = (Array.isArray(messages) ? messages : []).find((m) => m && m.role === "system");
  return sys ? String(sys.content || "") : "";
}

async function timedCall(callChatModel, opts, timeoutMs) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), Math.max(400, timeoutMs));
  const t0 = Date.now();
  try {
    const r = await callChatModel({ ...opts, signal: ctrl.signal });
    return { ...r, ms: Date.now() - t0 };
  } catch (e) {
    return {
      ok: false,
      status: 0,
      detail: e && e.name === "AbortError" ? "timeout" : String((e && e.name) || e),
      ms: Date.now() - t0,
    };
  } finally {
    clearTimeout(timer);
  }
}

async function callTwice(callChatModel, model, opts, timeoutMs) {
  const slice = Math.max(900, Math.floor(timeoutMs / 2));
  let last = await timedCall(callChatModel, { ...opts, model }, slice);
  if (last.ok && last.text) return { ...last, model };
  last = await timedCall(callChatModel, { ...opts, model }, Math.max(900, timeoutMs - slice));
  if (last.ok && last.text) return { ...last, model };
  return { ...last, model };
}

function shouldRunOnlineTeam({
  customModel,
  kajiResume,
  isWidget,
  intel,
  tier,
  maxMode,
}) {
  if (customModel || kajiResume || isWidget) return false;
  if (!(tier && (tier.air4 || tier.team))) return false;
  if (tier && (tier.chopCode || tier.kaji || tier.groqOnly || tier.flash4)) return false;
  return true;
}

async function runOnlineEnsemble({
  callChatModel,
  messages,
  openRouterKey,
  groqKey,
  anthropicKey,
  maxTokens,
  deadlineMs,
  clockHuman,
  isoDay,
}) {
  const keys = { openRouterKey, groqKey, anthropicKey };
  const question = clip(questionFromMessages(messages), 6000);
  const sysCtx = clip(systemFromMessages(messages), 7000);
  const nowLine = `CURRENT DATE: ${clockHuman || ""} (${isoDay || ""} UTC). Knowledge is current as of 13 September 2026. Treat this calendar day as now. Prefer live research over training cutoffs.`;
  let tokens = 0;
  const notes = [];
  const left = () => Math.max(0, deadlineMs - Date.now());
  if (left() < 2000) return { reply: "", tokens: 0, used: false };

  const draft = await callTwice(callChatModel, DRAFT_ID, {
    messages: [
      { role: "system", content: DRAFT_SYSTEM + "\n" + nowLine + "\n" + sysCtx },
      { role: "user", content: question },
    ],
    ...keys,
    maxTokens: Math.min(maxTokens || 1200, 1800),
    temperature: 0.22,
  }, Math.min(8000, Math.max(2800, Math.floor(left() * 0.42))));
  if (draft.tokens) tokens += draft.tokens;
  const draftText = draft.ok && draft.text ? draft.text : "";
  notes.push({
    listed: "glm-4.7-flash:free",
    ok: Boolean(draftText),
    text: clip(draftText || draft.detail || "draft unavailable", 4000),
  });

  if (left() < 1800) {
    return { reply: draftText, tokens, used: Boolean(draftText), leadModel: DRAFT_ID, notes };
  }

  const synth = await callTwice(callChatModel, SYNTH_ID, {
    messages: [
      { role: "system", content: SYNTH_SYSTEM + "\n" + nowLine + "\n" + clip(sysCtx, 3500) },
      {
        role: "user",
        content: [
          `USER REQUEST:\n${question}`,
          `\nDRAFT (notes only — write the real answer):\n${clip(draftText || "(none — answer the request yourself)", 3500)}`,
          "\nWrite the single final answer now.",
        ].join("\n"),
      },
    ],
    ...keys,
    maxTokens: Math.min(maxTokens || 1600, 2500),
    temperature: 0.2,
  }, Math.min(10000, Math.max(2200, left() - 150)));
  if (synth.tokens) tokens += synth.tokens;

  const reply = (synth.ok && synth.text) || draftText || "";
  return {
    reply,
    tokens,
    used: Boolean(reply),
    leadModel: (synth.ok && synth.text) ? SYNTH_ID : (draftText ? DRAFT_ID : ""),
    notes,
  };
}

module.exports = {
  DRAFT_ID,
  SYNTH_ID,
  SUPPORT: [],
  shouldRunOnlineTeam,
  runOnlineEnsemble,
};
