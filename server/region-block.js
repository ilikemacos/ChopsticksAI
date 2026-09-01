const CSAI_BR =
  "cs.AI is currently unavailable in Brazil while we complete regional privacy, data-processing, and compliance requirements.";
const MACBAR_BR =
  "MacBar downloads and in-app chat are currently paused in Brazil while we complete regional privacy, data-processing, and compliance requirements. A copy already on your Mac still runs locally.";

function geoCountry(_event, context) {
  const geo = (context && context.geo) || {};
  const nested = geo.country && (geo.country.code || geo.country);
  return String(nested || geo.countryCode || "")
    .trim()
    .toUpperCase();
}

function isBrazil(event, context) {
  return geoCountry(event, context) === "BR";
}

function brazilJson(product) {
  const error = product === "macbar" ? MACBAR_BR : CSAI_BR;
  return {
    statusCode: 451,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify({
      error,
      code: "region_unavailable",
      region: "BR",
    }),
  };
}

module.exports = {
  CSAI_BR,
  MACBAR_BR,
  geoCountry,
  isBrazil,
  brazilJson,
};
