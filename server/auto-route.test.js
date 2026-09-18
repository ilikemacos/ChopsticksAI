"use strict";

const assert = require("node:assert/strict");
const { analyzeRequest, classifyAutoRoute } = require("./chopsticks-intelligence.js");

function intelFor(text, opts) {
  return analyzeRequest(text, opts || {});
}

const cases = [
  { name: "trivial chat → Fast", text: "hi there", expect: "csaifast" },
  { name: "coding → Core", text: "fix this python traceback in my flask app", expect: "csai46core", opts: { coding: true } },
  { name: "long writing → Flash", text: "write a detailed essay ".repeat(40), expect: "csai47flash" },
  { name: "research → Flash", text: "compare the latest arxiv papers on diffusion models", expect: "csai47flash" },
  { name: "vision → Core", text: "what is in this photo?", expect: "csai46core", opts: { hasImage: true } },
  { name: "medium chat → Flash", text: "explain how rainbows form in simple terms for a curious friend who asked after school today", expect: "csai47flash" },
  { name: "everyday chat → Lite", text: "what do you think about weekend hiking trips with friends near the city when the weather is nice", expect: "csai46lite" },
];

let failed = 0;
for (const c of cases) {
  const intel = intelFor(c.text, c.opts);
  const route = classifyAutoRoute(intel, {
    hasImage: Boolean(c.opts && c.opts.hasImage),
    coding: Boolean(c.opts && c.opts.coding),
    textLen: c.text.length,
  });
  try {
    assert.equal(route, c.expect, c.name);
    console.log("ok:", c.name, "→", route);
  } catch (e) {
    failed += 1;
    console.error("FAIL:", c.name, "got", route, "expected", c.expect);
  }
}

if (failed) {
  process.exit(1);
}
console.log("auto-route tests passed");
