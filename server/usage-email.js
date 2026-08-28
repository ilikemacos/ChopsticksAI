const AI_EMAIL = "chopstickshq@lam.ws";
const AI_FROM = `cs.AI <${AI_EMAIL}>`;
const EMAIL_DEDUPE_MS = 6 * 60 * 60 * 1000;
const sentAlerts = new Map();

function env(name) {
  return String(process.env[name] || "").trim();
}

function fmtTokens(n) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1).replace(/\.0$/, "")}m`;
  if (n >= 1000) return `${Math.round(n / 1000)}k`;
  return String(Math.round(n));
}

function shouldSendAlert(bucketId, kind) {
  const key = `${bucketId || "anon"}:${kind}`;
  const now = Date.now();
  const last = sentAlerts.get(key) || 0;
  if (now - last < EMAIL_DEDUPE_MS) return false;
  sentAlerts.set(key, now);
  if (sentAlerts.size > 2000) {
    for (const [k, t] of sentAlerts) {
      if (now - t > EMAIL_DEDUPE_MS) sentAlerts.delete(k);
    }
  }
  return true;
}

function buildMessage(kind, opts) {
  const used = fmtTokens(opts.used || 0);
  const limit = fmtTokens(opts.limit || 0);
  const pct = Math.round((opts.ratio || 0) * 100);
  const tier = opts.tierLabel || "Free";
  const lab = "https://chopstickshq.com/chopailab/";
  const usage = "https://chopstickshq.com/chopsticks-ai/";

  if (kind === "blocked") {
    const mins = Math.max(1, Math.ceil((opts.retryInMs || 0) / 60000));
    return {
      subject: "cs.AI allowance used — cooldown active",
      text: [
        "Hi,",
        "",
        `Your cs.AI allowance (${tier}) is used up for now.`,
        `Usage: ${used} / ${limit} tokens (${pct}%).`,
        `Cooldown: about ${mins} minute${mins === 1 ? "" : "s"}.`,
        "",
        "Redeem Fathom Pro oi-pl2 keys in Usage for a higher allowance, or wait for the cooldown to reset.",
        "",
        `Lab: ${lab}`,
        `Product page: ${usage}`,
        "",
        "— cs.AI · Chopsticks HQ",
        AI_EMAIL,
      ].join("\n"),
    };
  }

  if (kind === "warn95") {
    return {
      subject: "cs.AI allowance almost full",
      text: [
        "Hi,",
        "",
        `You're at ${pct}% of your cs.AI allowance (${tier}).`,
        `Usage: ${used} / ${limit} tokens.`,
        "",
        "The next few replies may trigger a cooldown. Consider redeeming Fathom Pro keys in Usage for a higher limit.",
        "",
        `Lab: ${lab}`,
        "",
        "— cs.AI · Chopsticks HQ",
        AI_EMAIL,
      ].join("\n"),
    };
  }

  return {
    subject: "cs.AI allowance running low",
    text: [
      "Hi,",
      "",
      `You've used ${pct}% of your cs.AI allowance (${tier}).`,
      `Usage: ${used} / ${limit} tokens.`,
      "",
      "Redeem Fathom Pro oi-pl2 keys in Usage if you need more headroom this window.",
      "",
      `Lab: ${lab}`,
      "",
      "— cs.AI · Chopsticks HQ",
      AI_EMAIL,
    ].join("\n"),
  };
}

async function sendViaResend(to, subject, text) {
  const apiKey = env("RESEND_API_KEY");
  if (!apiKey) return false;
  const from = env("CHOPSTICKS_AI_FROM_EMAIL") || AI_FROM;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from, to: [to], subject, text }),
  });
  return res.ok;
}

function queueUsageEmail(plan, state, account) {
  const to = account && account.email;
  if (!to || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to)) return;
  if (env("CHOPSTICKS_AI_USAGE_EMAIL") === "off") return;

  const used = Number(state.used) || 0;
  const limit = Number(plan.limit) || 0;
  if (limit <= 0) return;

  const ratio = used / limit;
  let kind = null;
  if (state.blocked) kind = "blocked";
  else if (ratio >= 0.95) kind = "warn95";
  else if (ratio >= 0.8) kind = "warn80";
  if (!kind) return;
  if (!shouldSendAlert(plan.bucketId, kind)) return;

  const msg = buildMessage(kind, {
    used,
    limit,
    ratio,
    retryInMs: state.retryInMs || 0,
    tierLabel: (plan.tier && plan.tier.label) || "Free",
  });

  sendViaResend(to, msg.subject, msg.text).catch(() => {});
}

module.exports = {
  AI_EMAIL,
  AI_FROM,
  queueUsageEmail,
  sendViaResend,
};
