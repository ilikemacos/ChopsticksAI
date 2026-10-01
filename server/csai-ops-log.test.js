"use strict";

/**
 * Documents cs.AI free-tier ops log event names (suggestion #6).
 *
 * csai.auto_fallback_fast — effective plate collapsed to Fast (csaifast) backend
 *   reason codes: auto_route_trivial | live_miss | durable_rescue | unsigned_donor | upstream_unavailable
 *
 * csai.flash_upstream_miss — Flash (csai47flash) upstream model attempt failed
 */

const assert = require("node:assert/strict");
const {
  logCsAiOps,
  logAutoFallbackFast,
  isFastBackendModel,
  tierIdFromTier,
  flashMissReason,
  FAST_TIER_IDS,
  DEFAULT_TIER,
} = require("./chopsticks-ai.js");

const GROK41 = "x-ai/grok-4.1-fast:free";

assert.equal(isFastBackendModel(GROK41), true);
assert.equal(isFastBackendModel("openai/gpt-oss-120b:free"), false);
assert.equal(FAST_TIER_IDS.has(DEFAULT_TIER), true);
assert.equal(flashMissReason({ status: 429 }), "http_429");
assert.equal(flashMissReason({ detail: "timeout" }), "timeout");
assert.equal(flashMissReason({}), "empty_completion");

const lines = [];
const origLog = console.log;
console.log = (line) => lines.push(line);

try {
  logAutoFallbackFast({
    reason: "auto_route_trivial",
    fromTier: "csaiauto",
    toTier: DEFAULT_TIER,
    turnId: "test-turn",
    intentClass: "GENERAL",
  });
  logCsAiOps("csai.flash_upstream_miss", {
    turnId: "test-turn",
    attempt: 0,
    model: "nemotron-3-ultra",
    reason: "http_503",
    status: 503,
    laterFallbackSucceeded: true,
  });
} finally {
  console.log = origLog;
}

assert.equal(lines.length, 2);
const autoLine = JSON.parse(lines[0]);
assert.equal(autoLine.event, "csai.auto_fallback_fast");
assert.equal(autoLine.reason, "auto_route_trivial");
assert.equal(autoLine.fromTier, "csaiauto");
assert.equal(autoLine.toTier, "csaifast");
assert.equal(autoLine.product, "cs.AI");
assert.ok(autoLine.ts);

const flashLine = JSON.parse(lines[1]);
assert.equal(flashLine.event, "csai.flash_upstream_miss");
assert.equal(flashLine.laterFallbackSucceeded, true);

console.log("csai-ops-log tests passed");
