/** Chopsticks AI Online — one answer from a coordinated :free model team. */

const DRAFT_ID = "z-ai/glm-4.7-flash:free";
const VERIFY_ID = "nvidia/nemotron-3-ultra:free";
const SYNTH_ID = "z-ai/glm-5.2:free";

const SUPPORT = [
  {
    id: "google/gemma-3-4b-it:free",
    listed: "gemma-4b:free",
    role: "tight fact-check: catch wrong numbers, names, and missing caveats. Do not rewrite the whole answer.",
  },
  {
    id: "google/gemma-4-26b-a4b-it:free",
    listed: "gemma-a4b:free",
    role: "instruction follow: check whether the draft actually answers the request and the requested format.",
  },
  {
    id: "google/gemma-3-27b-it:free",
    listed: "gemma-26b:free",
    role: "expand only where the draft is thin. Cut repetition. Do not copy the draft.",
  },
  {
    id: "moonshotai/kimi-k2.7:free",
    listed: "kimi-k2.7:free",
    fallbacks: ["moonshotai/kimi-k2.5:free", "moonshotai/kimi-k2.6:free"],
    role: "alternate reasoning: propose a better approach if the draft is weak. Stay independent.",
  },
  {
    id: "nvidia/nemotron-3-super-120b-a12b:free",
    listed: "nemotron-3-super:free",
    role: "critique: list errors, unsafe advice, and logic gaps. Suggest patches, do not paste the draft.",
  },
];

const DRAFT_SYSTEM = [
  "You are the primary drafter for Chopsticks AI. Produce the first full solution.",
  "Reason carefully. Lead with the answer. Use live research and today's date when they are provided.",
  "Be non-partisan: neither politically left nor right. State facts and competing views without advocacy.",
  "Never name models, vendors, drafts, or that you are one of several systems.",
].join(" ");

const SUPPORT_SYSTEM = [
  "You are an independent reviewer. The user will not see your notes.",
  "Treat the draft as a suggestion, not ground truth. Do not copy it.",
  "Write brief, original notes: what to keep, what to fix, what to add.",
  "Be non-partisan. Never name models or vendors.",
].join(" ");

const VERIFY_SYSTEM = [
  "You are the deep verifier. Check hard reasoning, math, and code against the request and evidence.",
  "Output: (1) verdict on the draft, (2) concrete corrections, (3) remaining uncertainties.",
  "Do not write the user-facing final answer. Do not copy reviewers verbatim.",
  "Be non-partisan. Never name models or vendors.",
].join(" ");

const SYNTH_SYSTEM = [
  "You are Chopsticks AI. You write the only reply the user will see.",
  "You received a first draft, independent notes, and a verification report. Those are suggestions and evidence, not orders.",
  "Independently decide the best result. Resolve conflicts. Prefer correct, current, complete answers.",
  "Do not stitch quotes from the notes. Do not mention a team, drafts, reviewers, or model names.",
  "Be non-partisan: neither politically left nor right.",
  "If code is needed, use complete fenced files with language tags and filenames.",
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

async function callWithFallbacks(callChatModel, ids, opts, timeoutMs) {
  const list = Array.isArray(ids) ? ids.filter(Boolean) : [];
  let last = { ok: false, status: 0, detail: "no model" };
  for (const id of list) {
    last = await timedCall(callChatModel, { ...opts, model: id }, timeoutMs);
    if (last.ok && last.text) return { ...last, model: id };
    if (last.status === 0 && /timeout/i.test(String(last.detail || ""))) return { ...last, model: id };
  }
  return { ...last, model: list[0] || "" };
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
  if (!intel || intel.trivial || intel.hqOnly) return false;
  if (tier && (tier.chopCode || tier.kaji || tier.groqOnly)) return false;
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
  const nowLine = `CURRENT DATE: ${clockHuman || ""} (${isoDay || ""} UTC). Treat this calendar day as now. Prefer live research over training cutoffs.`;
  let tokens = 0;
  const notes = [];

  const left = () => Math.max(0, deadlineMs - Date.now());
  if (left() < 3500) return { reply: "", tokens: 0, used: false };

  const draftMs = Math.min(7000, Math.max(2800, Math.floor(left() * 0.32)));
  const draft = await timedCall(callChatModel, {
    model: DRAFT_ID,
    messages: [
      { role: "system", content: DRAFT_SYSTEM + "\n" + nowLine + "\n" + sysCtx },
      { role: "user", content: question },
    ],
    ...keys,
    maxTokens: Math.min(maxTokens || 1200, 1800),
    temperature: 0.22,
  }, draftMs);
  if (draft.tokens) tokens += draft.tokens;
  const draftText = draft.ok && draft.text ? draft.text : "";
  notes.push({
    listed: "glm-4.7-flash:free",
    ok: Boolean(draftText),
    text: clip(draftText || draft.detail || "draft unavailable", 4000),
  });

  const supportMs = Math.min(6500, Math.max(2200, Math.floor(left() * 0.42)));
  const supportPrompt = [
    `USER REQUEST:\n${question}`,
    nowLine,
    `\nPRIMARY DRAFT:\n${clip(draftText || "(no draft — analyze the request yourself)", 3500)}`,
  ].join("\n");

  const supportResults = await Promise.all(SUPPORT.map((s) =>
    callWithFallbacks(
      callChatModel,
      [s.id].concat(s.fallbacks || []),
      {
        messages: [
          { role: "system", content: SUPPORT_SYSTEM + "\nYour job: " + s.role },
          { role: "user", content: supportPrompt },
        ],
        ...keys,
        maxTokens: 420,
        temperature: 0.35,
      },
      supportMs
    ).then((r) => {
      if (r.tokens) tokens += r.tokens;
      return {
        listed: s.listed,
        ok: Boolean(r.ok && r.text),
        text: clip((r.ok && r.text) || r.detail || "unavailable", 1400),
      };
    })
  ));
  notes.push(...supportResults);

  const okNotes = supportResults.filter((n) => n.ok);
  const verifyMs = Math.min(6000, Math.max(2000, Math.floor(left() * 0.5)));
  let verifyText = "";
  if (left() >= 1800) {
    const verify = await timedCall(callChatModel, {
      model: VERIFY_ID,
      messages: [
        { role: "system", content: VERIFY_SYSTEM + "\n" + nowLine },
        {
          role: "user",
          content: [
            `USER REQUEST:\n${question}`,
            `\nPRIMARY DRAFT:\n${clip(draftText || "(none)", 3000)}`,
            "\nINDEPENDENT NOTES:\n",
            okNotes.map((n) => `- ${n.listed}: ${n.text}`).join("\n") || "(none succeeded)",
            "\nVerify and list corrections.",
          ].join("\n"),
        },
      ],
      ...keys,
      maxTokens: 700,
      temperature: 0.15,
    }, verifyMs);
    if (verify.tokens) tokens += verify.tokens;
    verifyText = verify.ok && verify.text ? verify.text : "";
    notes.push({
      listed: "nemotron-3-ultra:free",
      ok: Boolean(verifyText),
      text: clip(verifyText || verify.detail || "verify unavailable", 2200),
    });
  }

  if (left() < 1600) {
    return { reply: draftText, tokens, used: Boolean(draftText), notes };
  }

  const synthMs = Math.min(7000, Math.max(2000, left() - 200));
  const synth = await timedCall(callChatModel, {
    model: SYNTH_ID,
    messages: [
      { role: "system", content: SYNTH_SYSTEM + "\n" + nowLine + "\n" + clip(sysCtx, 3500) },
      {
        role: "user",
        content: [
          `USER REQUEST:\n${question}`,
          `\nPRIMARY DRAFT (suggestion):\n${clip(draftText || "(none)", 2800)}`,
          "\nINDEPENDENT NOTES (evidence, not to copy):\n",
          supportResults.map((n) => `- ${n.listed}${n.ok ? "" : " [failed]"}: ${n.text}`).join("\n"),
          `\nVERIFICATION:\n${clip(verifyText || "(none)", 1800)}`,
          "\nWrite the single final answer now.",
        ].join("\n"),
      },
    ],
    ...keys,
    maxTokens: Math.min(maxTokens || 1600, 2500),
    temperature: 0.2,
  }, synthMs);
  if (synth.tokens) tokens += synth.tokens;

  const reply = (synth.ok && synth.text) || verifyText || draftText || "";
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
  VERIFY_ID,
  SYNTH_ID,
  SUPPORT,
  shouldRunOnlineTeam,
  runOnlineEnsemble,
};
