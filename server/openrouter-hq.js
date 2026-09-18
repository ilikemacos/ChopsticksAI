"use strict";

const https = require("node:https");
const { env, openRouterApiKey } = require("./netlify-env.js");

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

function nodeHttps({ method, url, headers, body, signal }) {
  const u = new URL(url);
  const payload = body != null ? Buffer.from(String(body), "utf8") : null;
  const hdrs = { ...(headers || {}) };
  if (payload) hdrs["Content-Length"] = String(payload.length);
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: u.hostname,
        port: 443,
        path: u.pathname + u.search,
        method,
        headers: hdrs,
      },
      (res) => {
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () =>
          resolve({ status: res.statusCode || 0, text: Buffer.concat(chunks).toString("utf8") })
        );
      }
    );
    req.on("error", reject);
    if (signal) {
      const onAbort = () => {
        req.destroy();
        reject(new Error("AbortError"));
      };
      if (signal.aborted) {
        onAbort();
        return;
      }
      signal.addEventListener("abort", onAbort, { once: true });
    }
    if (payload) req.write(payload);
    req.end();
  });
}

function openRouterHeaders() {
  const auth = openRouterApiKey();
  if (!auth) return null;
  return {
    Authorization: "Bearer " + auth,
    "Content-Type": "application/json",
    Accept: "application/json",
    "HTTP-Referer": "https://chopstickshq.com",
    "X-Title": "chopsticksAI",
  };
}

function postHttpsJson(url, headers, bodyText, signal) {
  return nodeHttps({
    method: "POST",
    url,
    headers,
    body: bodyText,
    signal,
  });
}

function getHttps(url, headers, signal) {
  return nodeHttps({
    method: "GET",
    url,
    headers,
    signal,
  });
}

async function probeOpenRouterKey() {
  const headers = openRouterHeaders();
  if (!headers) return { status: 0, configured: false };
  try {
    const res = await getHttps("https://openrouter.ai/api/v1/key", headers);
    return { status: res.status, configured: true };
  } catch (e) {
    return { status: 0, configured: true, error: String((e && e.name) || e) };
  }
}

module.exports = {
  env,
  openRouterApiKey,
  OPENROUTER_URL,
  postHttpsJson,
  getHttps,
  openRouterHeaders,
  probeOpenRouterKey,
};
