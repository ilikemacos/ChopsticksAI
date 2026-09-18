"use strict";

/**
 * Read Netlify / Lambda env at request time.
 * Uses a dynamic key so esbuild cannot bake an empty OPENROUTER_API_KEY
 * from a CLI deploy machine that lacks the secret.
 */
function env(name) {
  const want = String(name || "");
  if (!want) return "";
  try {
    const bag = (typeof process !== "undefined" && process.env) ? process.env : {};
    const hit = bag[want];
    if (hit != null && String(hit).trim()) {
      return String(hit).trim().replace(/^['"]|['"]$/g, "");
    }
  } catch (e) {}
  try {
    if (typeof Netlify !== "undefined" && Netlify.env && typeof Netlify.env.get === "function") {
      const v = Netlify.env.get(want);
      if (v != null && String(v).trim()) return String(v).trim();
    }
  } catch (e) {}
  return "";
}

function openRouterApiKey() {
  let k = env("OPENROUTER_API_KEY");
  if (k.startsWith("Sk-or-")) k = "sk-or-" + k.slice(6);
  return k;
}

module.exports = { env, openRouterApiKey };
