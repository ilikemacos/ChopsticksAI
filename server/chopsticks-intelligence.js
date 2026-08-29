"use strict";

/**
 * cs.AI-3.7 intelligence stack: route, retrieve, rank, verify.
 * No embeddings; BM25 + keyword + entity matching on the HQ KB.
 */

const STOP = new Set((
  "a an the and or of to for in on with from as is are was were be been being " +
  "this that it at by into about than then so if not no yes do does did how " +
  "what whats who whom which when where why can could should would will just"
).split(" "));

function tokens(text) {
  return String(text || "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, " ")
    .split(/\s+/)
    .filter((t) => t.length > 1 && !STOP.has(t));
}

function unique(arr) {
  const out = [];
  const seen = new Set();
  for (const x of arr) {
    if (!x || seen.has(x)) continue;
    seen.add(x);
    out.push(x);
  }
  return out;
}

function analyzeRequest(text, opts) {
  const ask = String(text || "").trim();
  const len = ask.length;
  const coding = Boolean(opts && opts.coding);
  const kaji = Boolean(opts && opts.kaji);
  const chopCode = Boolean(opts && opts.chopCode);

  let category = "GENERAL";
  if (coding || chopCode) category = /debug|error|fix|traceback|stack/i.test(ask) ? "DEBUGGING" : "CODING";
  else if (/\b(compare|vs\.?|versus|difference between)\b/i.test(ask)) category = "COMPARISON";
  else if (/\b(summarize|summarise|tldr|tl;dr)\b/i.test(ask)) category = "SUMMARIZATION";
  else if (/\b(plan|roadmap|steps to|how should i)\b/i.test(ask)) category = "PLANNING";
  else if (/\b(prove|integral|derivative|equation|probability|theorem)\b/i.test(ask)) category = "MATHEMATICS";
  else if (/\b(paper|arxiv|study|research|cite)\b/i.test(ask)) category = "RESEARCH";
  else if (/\b(news|today|current|latest|price|release|version)\b/i.test(ask)) category = "CURRENT_INFORMATION";
  else if (/\b(write|poem|story|joke|lyrics)\b/i.test(ask)) category = "CREATIVE";
  else if (/\b(analyze|analyse|why does|explain)\b/i.test(ask)) category = "ANALYSIS";

  const freshness = /\b(today|tonight|this week|this year|latest|current|now|2026|news|price|release|version|who won)\b/i.test(ask);
  const webHint = freshness
    || category === "RESEARCH"
    || category === "CURRENT_INFORMATION"
    || category === "COMPARISON"
    || /\b(gpu|gpu|rtx|nvidia|cpu|sdk|api docs?)\b/i.test(ask);
  const mathEasy = /^\s*\d[\d\s+\-*/().^]+\s*=?\s*$/.test(ask) || /^\s*what is \d+\s*[+\-*/]\s*\d+\s*\??\s*$/i.test(ask);
  const trivial = mathEasy || (len < 24 && /^(hi|hello|hey|thanks|ok|yes|no)\b/i.test(ask));

  let complexity = 0.2;
  if (trivial) complexity = 0.05;
  else if (mathEasy) complexity = 0.08;
  else {
    complexity = Math.min(1, 0.18 + len / 900);
    if (coding) complexity += 0.2;
    if (category === "RESEARCH" || category === "COMPARISON") complexity += 0.2;
    if (/\b(design|architecture|best|trade-?off|workstation)\b/i.test(ask)) complexity += 0.15;
    if ((ask.match(/\?/g) || []).length > 1) complexity += 0.12;
    complexity = Math.min(1, complexity);
  }

  const namedUrl = /https:\/\//i.test(ask);
  const kajiFileWork = kaji && /\b(list|read|write|desktop|documents|downloads|folder|open_page|open https|open this url)\b/i.test(ask);
  const webRequired = namedUrl
    || (!trivial && (webHint || (!kaji && len > 80)));
  const toolsRequired = coding || chopCode || kajiFileWork || (kaji && namedUrl);
  const verificationRequired = complexity >= 0.5 || category === "MATHEMATICS" || category === "CODING" || category === "RESEARCH";
  const decompose = complexity >= 0.65 && !trivial;

  return {
    category,
    complexity: Math.round(complexity * 100) / 100,
    freshnessRequired: freshness,
    webRequired,
    toolsRequired,
    verificationRequired,
    decompose,
    trivial,
  };
}

function computeBudget(intel, tier) {
  const c = intel.complexity;
  if (intel.trivial || intel.hqOnly) {
    return {
      band: "minimal",
      searchCycles: 0,
      searchMax: 0,
      critics: 0,
      evidenceCap: 2,
      skipFastRace: false,
      useLongModels: false,
      skipHqDump: false,
      skipTools: true,
    };
  }
  let band = "minimal";
  if (c >= 0.8) band = "maximum";
  else if (c >= 0.5) band = "deep";
  else if (c >= 0.2) band = "normal";

  const searchCycles = intel.trivial
    ? 0
    : intel.webRequired
      ? (band === "maximum" ? 3 : band === "deep" ? 2 : 1)
      : 0;
  const searchMax = intel.trivial
    ? 0
    : Math.min(
      tier.searchMax || 8,
      band === "maximum" ? 8 : band === "deep" ? 6 : band === "normal" ? 4 : 2
    );
  const critics = intel.verificationRequired && band !== "minimal" ? (band === "maximum" ? 2 : 1) : 0;
  const evidenceCap = band === "maximum" ? 6 : band === "deep" ? 5 : 4;

  return {
    band,
    searchCycles,
    searchMax,
    critics,
    evidenceCap,
    skipFastRace: c >= 0.55,
    useLongModels: c >= 0.55 || intel.category === "CODING" || intel.category === "DEBUGGING",
    skipHqDump: intel.category === "CODING" || intel.category === "DEBUGGING" || intel.category === "MATHEMATICS",
    skipTools: false,
  };
}

function followUpQueries(query, intel) {
  const q = String(query || "").replace(/\nATTACHED FILES[\s\S]*$/, "").trim().slice(0, 160);
  if (!q) return [];
  const extra = [];
  if (intel.category === "COMPARISON") {
    extra.push(q + " specifications comparison 2026");
  }
  if (intel.freshnessRequired) {
    extra.push(q + " official source");
  }
  if (intel.category === "CODING" || intel.category === "DEBUGGING") {
    extra.push(q + " documentation");
  }
  if (intel.category === "RESEARCH") {
    extra.push(q + " site:arxiv.org OR review");
  }
  extra.push(q + " vs alternatives");
  return unique(extra).filter((x) => x !== q).slice(0, 3);
}

const AUTHORITY_HOST = [
  [/\.edu$/i, 0.95],
  [/\.gov$/i, 0.95],
  [/arxiv\.org/i, 0.92],
  [/wikipedia\.org/i, 0.78],
  [/developer\.mozilla\.org/i, 0.9],
  [/github\.com/i, 0.82],
  [/stackoverflow\.com|stackexchange\.com/i, 0.8],
  [/nvidia\.com|intel\.com|amd\.com|apple\.com/i, 0.88],
  [/chopstickshq\.com/i, 0.99],
  [/nytimes\.com|bbc\.|reuters\.|apnews\./i, 0.8],
];

function hostAuthority(url) {
  try {
    const host = new URL(url).hostname.replace(/^www\./, "");
    for (const [re, score] of AUTHORITY_HOST) {
      if (re.test(host)) return score;
    }
    return 0.55;
  } catch {
    return 0.4;
  }
}

function overlapScore(query, text) {
  const q = unique(tokens(query));
  if (!q.length) return 0;
  const hay = " " + tokens(text).join(" ") + " ";
  let hit = 0;
  for (const t of q) {
    if (hay.includes(" " + t + " ")) hit += 1;
  }
  return hit / q.length;
}

function rankEvidence(query, items) {
  const list = Array.isArray(items) ? items : [];
  const scored = list.map((item) => {
    const title = String(item.title || "");
    const snippet = String(item.snippet || item.text || "");
    const url = String(item.url || item.src || "");
    const blob = title + " " + snippet;
    const relevance = overlapScore(query, blob);
    const authority = hostAuthority(url);
    const freshness = /\b(202[5-9]|today|latest|current)\b/i.test(blob) ? 0.85 : 0.55;
    const specificity = Math.min(1, snippet.length / 220) * (/\d/.test(snippet) ? 1 : 0.7);
    return {
      ...item,
      title,
      url,
      snippet: snippet.slice(0, 320),
      _rel: relevance,
      _auth: authority,
      evidenceScore:
        0.35 * relevance +
        0.2 * authority +
        0.15 * freshness +
        0.15 * specificity +
        0.15 * Math.min(1, relevance + authority * 0.3),
    };
  });

  const claimKey = (s) => {
    const nums = String(s.snippet || "").match(/\b\d+(?:\.\d+)?\s?(?:GB|TB|GHz|W|GB\/s)?\b/gi) || [];
    return nums.sort().join("|");
  };
  const byClaim = new Map();
  for (const s of scored) {
    const k = claimKey(s);
    if (!k) continue;
    byClaim.set(k, (byClaim.get(k) || 0) + 1);
  }
  for (const s of scored) {
    const k = claimKey(s);
    const n = k ? byClaim.get(k) || 1 : 1;
    s.evidenceScore += 0.1 * Math.min(1, (n - 1) / 3);
  }

  scored.sort((a, b) => b.evidenceScore - a.evidenceScore);
  return scored;
}

function detectConflicts(ranked) {
  const nums = [];
  for (const s of ranked.slice(0, 8)) {
    const m = String(s.snippet || "").match(/\b(\d+(?:\.\d+)?)\s?(GB|TB)\b/gi);
    if (!m) continue;
    for (const hit of m) {
      nums.push({ hit: hit.toUpperCase(), url: s.url, title: s.title });
    }
  }
  const uniq = unique(nums.map((n) => n.hit));
  if (uniq.length < 2) return [];
  return [{
    kind: "numeric",
    values: uniq,
    note: "Sources disagree on quantities (" + uniq.join(" vs ") + "). Check product/revision/date before stating one number.",
  }];
}

function formatEvidence(ranked, conflicts, cap) {
  const top = (ranked || []).slice(0, cap || 5);
  if (!top.length) return "";
  const lines = top.map((s, i) => {
    const url = s.url ? ` (${s.url})` : "";
    return `${i + 1}. ${s.title}: ${s.snippet}${url}`;
  });
  let block =
    "\n\nVERIFIED EVIDENCE (ranked; prefer these over training memory; cite URLs; add a **Sources** section when you used them):\n" +
    lines.join("\n");
  if (conflicts && conflicts.length) {
    block += "\n\nSOURCE CONFLICTS — do not silently merge:\n" +
      conflicts.map((c) => "- " + c.note).join("\n");
  }
  block += "\n\nIf evidence is missing or confidence is low, say what is unknown. Do not invent numbers, APIs, or citations.";
  return block;
}

function bm25IntentScore(query, intent) {
  const q = unique(tokens(query));
  if (!q.length) return 0;
  const doc = tokens((intent.label || "") + " " + (intent.answer || "") + " " + (intent.id || ""));
  if (!doc.length) return 0;
  const tf = new Map();
  for (const t of doc) tf.set(t, (tf.get(t) || 0) + 1);
  let score = 0;
  for (const t of q) {
    const f = tf.get(t) || 0;
    if (!f) continue;
    score += (f * 2.2) / (f + 1.2);
  }
  const entities = String(query).match(/\b[A-Z][a-zA-Z0-9+]{2,}\b/g) || [];
  const hay = String(intent.label || "") + " " + String(intent.answer || "");
  for (const e of entities) {
    if (hay.toLowerCase().includes(e.toLowerCase())) score += 1.5;
  }
  return score;
}

function hybridRetrieve(query, scoredRows, limit) {
  const rows = Array.isArray(scoredRows) ? scoredRows : [];
  const mixed = rows.map((s) => {
    const bm = bm25IntentScore(query, s.intent);
    return { intent: s.intent, score: (s.score || 0) + bm * 2 };
  });
  mixed.sort((a, b) => b.score - a.score);
  return mixed.slice(0, limit).map((s) => s.intent);
}

function routeModels({ intel, tier, groqKey, customModel, pickedModel, longRun }) {
  if (customModel && pickedModel) return [pickedModel];
  if (tier.kaji) {
    const pool = (longRun || intel.decompose ? (tier.longModels || tier.models) : tier.models) || [];
    const seen = new Set();
    const out = [];
    for (const m of pool) {
      if (!m || seen.has(m)) continue;
      seen.add(m);
      out.push(m);
    }
    return out;
  }
  const coding = intel.category === "CODING" || intel.category === "DEBUGGING" || tier.chopCode;
  const useLong = longRun || intel.decompose || (intel.complexity >= 0.55);
  let pool = useLong ? (tier.longModels || tier.models) : tier.models;
  if (coding && !tier.chopCode) {
    const specialists = [
      ...(groqKey ? ["groq/llama-3.3-70b-versatile", "groq/openai/gpt-oss-120b"] : []),
      "qwen/qwen3-coder:free",
      "nvidia/nemotron-3-super-120b-a12b:free",
    ];
    pool = specialists.concat(pool);
  }
  if (intel.trivial) {
    const fast = [
      ...(groqKey ? ["groq/llama-3.1-8b-instant"] : []),
      "nvidia/nemotron-3-nano-30b-a3b:free",
    ];
    pool = fast.concat(pool);
  }
  const seen = new Set();
  const out = [];
  for (const m of pool) {
    if (!m || seen.has(m)) continue;
    seen.add(m);
    out.push(m);
  }
  return out;
}

const CRITIC_SYSTEM = [
  "You are an adversarial critic. Assume the draft may be wrong.\n",
  "You are given VERIFIED EVIDENCE and optional SOURCE CONFLICTS. Use only that block for numbers, dates, versions, and prices.\n",
  "If a number or date is not in the evidence, cut it or mark it unknown. Do not invent citations.\n",
  "Then output ONLY the corrected final reply the user should see. ",
  "Never mention that you are a critic or that a draft existed.",
].join("");

const DECOMPOSE_HINT = [
  "\n\nREASONING PROTOCOL for this request:\n",
  "State known facts vs assumptions. Do not treat assumptions as facts.\n",
  "If the problem is multi-part, solve each subproblem then combine and verify.\n",
  "Lead with the answer. Keep uncertainties explicit.\n",
].join("");

module.exports = {
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
};
