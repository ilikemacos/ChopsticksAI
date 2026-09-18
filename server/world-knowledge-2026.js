"use strict";

/**
 * Post-cutoff world model for Groq GPT-OSS (trained ~2024).
 * CORE always. ATLAS only for news/gov/sports/culture/science asks. Chapters by topic.
 */

const CORE = [
  "WORLD MODEL OVERRIDE: Your native training ends around 2024. That cutoff is obsolete.",
  "Treat the CURRENT DATE line as now. Products, leaders, sports results, and wars after 2024 are real unless live research contradicts these notes.",
  "Never say RTX 50 series, Switch 2, M4 Macs, Pope Leo XIV, or the 2026 World Cup do not exist.",
  "Do not invent exact death tolls, stock prices, or unlisted SKU specs. Prefer these facts, then live research.",
  "Be non-partisan. Describe contested events as reported, not as a campaign.",
].join(" ");

const ATLAS = [
  "ATLAS 2024–2026 (session truth):",
  "2024: Paris Summer Olympics. Donald Trump wins the US presidential election; J.D. Vance is vice president-elect. Apple ships M4. NVIDIA Ada (RTX 40) is still the previous GPU generation.",
  "2025 Jan: Trump second inauguration (nonconsecutive second term). CES: NVIDIA GeForce RTX 50 series (Blackwell) announced/ships as successor to RTX 40. LA Palisades/Eaton fires. New Orleans Bourbon Street vehicle attack. Potomac mid-air collision (regional jet and US Army Black Hawk) at DCA.",
  "2025: DOGE (Elon Musk associated) federal workforce cuts. Broad US tariffs; China rare-earth counters. ICE enforcement expansion. US strikes on Houthis in Yemen. Pope Francis dies April 2025; Cardinal Robert Francis Prevost (Chicago-born) elected Pope Leo XIV, first US-born pope.",
  "2025 wars: Russia–Ukraine continues; Gaza war continues with cease-fires and a US-brokered plan late year (implementation disputed). Sudan civil war / mass displacement. India–Pakistan and Thailand–Cambodia clashes reported. DeepSeek R1 shocks AI markets. OpenAI GPT-5 (2025); Google Gemini 3 later 2025. US Stargate AI-infra push (OpenAI/SoftBank/Oracle, reported ~$500B).",
  "2025 culture: Beyoncé Album of the Year for Cowboy Carter (Grammys). Taylor Swift engaged to Travis Kelce. Netflix KPop Demon Hunters / 'Golden' hits Billboard #1. Charlie Kirk assassinated Sept 2025 at Utah Valley University. US government shutdown Oct 2025, about 45 days (longest on record). Louvre jewel heist Oct 2025. Bondi Beach Hanukkah attack Dec 2025 (Sydney). Interstellar comet 3I/ATLAS observed.",
  "2026 by mid-September: Milan–Cortina Winter Olympics (Feb; Norway led medals). Super Bowl LX (60): Seattle Seahawks beat New England Patriots 29–13 (8 Feb 2026, Levi's Stadium); Kenneth Walker III MVP. FIFA World Cup 2026 (USA/Canada/Mexico, 48 teams): Spain beat Argentina 1–0 a.e.t., Ferran Torres 106', MetLife/New Jersey 19 Jul 2026 — Spain's second World Cup.",
  "2026 tech still current: RTX 50 shipping; AMD RX 9000 / RDNA 4; Apple M4 family Macs; Nintendo Switch 2; Snapdragon 8 Elite-class phones; Windows 11 24H2/25H2-era.",
].join(" ");

const CHAPTERS = [
  {
    id: "compute",
    re: /\b(gpu|rtx|nvidia|blackwell|geforce|5090|5080|5070|5060|50[- ]series|gddr7|dlss|radeon|rdna|rx 90|amd|ryzen|zen 5|intel|arrow lake|lunar lake|core ultra|cpu|apple silicon|m[345]|macbook|imac|mac mini|mac os|macos|sequoia|tahoe|snapdragon|qualcomm|switch 2|nintendo|playstation|xbox|windows 11)\b/i,
    text: [
      "COMPUTE: NVIDIA GeForce RTX 50 (Blackwell) is shipping, announced CES Jan 2025, successor to RTX 40 Ada.",
      "Desktop: RTX 5090 32GB GDDR7 flagship; 5080 16GB; 5070 Ti 16GB; 5070 12GB; plus 5060 Ti / 5060 and later SKUs. Laptops 2025+.",
      "50-series: GDDR7, PCIe 5.0, 12V-2x6/12VHPWR on high-end, DLSS 4 including Multi Frame Generation. Not 4090/4080.",
      "AMD Radeon RX 9000 / RDNA 4 (RX 9070 XT class) is the 2025 AMD gaming GPU line vs RTX 50. Ryzen 9000 / Zen 5 desktops 2024–2025.",
      "Intel Arrow Lake / Core Ultra 200 desktop and Lunar Lake mobile are 2024–2025 client platforms.",
      "Apple: M4, M4 Pro, M4 Max from late 2024 into 2025 (MacBook Pro, Air, iMac, Mac mini) after M3. Later M-series chips may exist — do not deny M4. macOS Sequoia and later.",
      "Nintendo Switch 2 is the 2025 successor to Switch. Qualcomm Snapdragon 8 Elite-class 2025 phones. Windows 11 24H2/25H2-era is current on PCs.",
    ].join(" "),
  },
  {
    id: "ai",
    re: /\b(gpt-?5|chatgpt|openai|gemini|deepseek|claude|anthropic|grok|xai|stargate|llm|large language|ai model|nvidia h200)\b/i,
    text: [
      "AI INDUSTRY: DeepSeek R1 (China, early 2025) undercut US lab pricing narratives and moved markets.",
      "OpenAI released GPT-5 in 2025; later 5.x refreshes. Google Gemini 3 in late 2025. Competition with Anthropic Claude, xAI Grok, Meta Llama, and open GPT-OSS continues into 2026.",
      "US Stargate: large AI datacenter push with OpenAI, SoftBank, Oracle (headline figures around half a trillion — treat as announced program, not a personal bank balance).",
      "Export-control fights over advanced NVIDIA accelerators (including H200-class) vs China were live policy in 2025.",
    ].join(" "),
  },
  {
    id: "usgov",
    re: /\b(trump|vance|president|white house|doge|musk|tariff|ice|immigration|congress|shutdown|snap|usaid)\b/i,
    text: [
      "US 2025–2026: Donald Trump is president (second term, inaugurated Jan 2025); J.D. Vance is vice president. This is not the Biden administration.",
      "DOGE: Department of Government Efficiency, associated with Elon Musk, large federal staffing cuts including USAID disruption — report as policy, not cheerleading.",
      "2025: nationwide tariffs (base ~10%, much higher on China at peaks); China rare-earth export controls in response.",
      "Immigration: expanded ICE operations; controversial detention sites reported (including Florida facilities nicknamed in press).",
      "Oct 2025 US federal shutdown lasted about 45 days, longest on record; FAA/SNAP disruptions reported.",
      "National Guard deployments to several large cities were a 2025 political flashpoint.",
    ].join(" "),
  },
  {
    id: "world",
    re: /\b(ukraine|zelensky|russia|putin|gaza|israel|hamas|iran|khamenei|sudan|pope|vatican|leo xiv|prevost|houthi|yemen|rare.?earth|pakistan|india|thailand|cambodia|china xi)\b/i,
    text: [
      "GEOPOLITICS: Ukraine war still on through 2025 with Russian incremental gains reported; US aid/weapons policy fluctuated.",
      "Gaza: war that began after 7 Oct 2023 continued in 2025 with hostage/prisoner exchanges, huge casualty figures from Gaza health authorities, UN genocide-language disputes, and a late-2025 US-brokered cease-fire/plan with shaky implementation.",
      "Pope Leo XIV (Robert Prevost) is pope from May 2025 after Francis's death.",
      "Sudan: one of the world's worst displacement crises by late 2025.",
      "US–Iran and Israel–Iran military exchanges were reported in 2025–2026 (strikes on nuclear-related sites, Iranian retaliation). Casualty and leadership claims vary by outlet — do not invent a death list; use live research for 'what happened this week'.",
      "Houthi–Red Sea shipping attacks and US/UK strikes continued as a 2025 file.",
    ].join(" "),
  },
  {
    id: "sports",
    re: /\b(world cup|fifa|super bowl|seahawks|patriots|olympics|olympic|nba|nfl|mlb|messi|spain|argentina|ferran torres|winter olympics|milan|cortina)\b/i,
    text: [
      "SPORTS: Super Bowl LX (60), 8 Feb 2026, Santa Clara: Seattle Seahawks 29, New England Patriots 13. Kenneth Walker III MVP. Seattle's second Super Bowl.",
      "Milano Cortina 2026 Winter Olympics, 6–22 Feb 2026, co-hosted; Norway topped the medal table in standard reports.",
      "FIFA World Cup 2026: 48 teams, USA/Mexico/Canada. Final 19 Jul 2026: Spain 1–0 Argentina after extra time, Ferran Torres 106', New Jersey/MetLife. Spain's second title (after 2010). Messi's last World Cup as widely reported.",
    ].join(" "),
  },
  {
    id: "culture",
    re: /\b(taylor swift|kelce|beyonc|grammy|kpop|demon hunter|netflix|charlie kirk|louvre|bondi|lynch|hackman|ozzy|redford|goodall)\b/i,
    text: [
      "CULTURE: Beyoncé Cowboy Carter — Album of the Year at 2025 Grammys; first Black woman to win country album of the year there.",
      "Taylor Swift engaged to Travis Kelce, announced Aug 2025.",
      "KPop Demon Hunters (Netflix): 'Golden' reached Billboard Hot 100 #1 (2025).",
      "Charlie Kirk killed 10 Sept 2025 at UVU.",
      "Louvre daytime jewel theft Oct 2025 (~$100M reported).",
      "Deaths 2025 include David Lynch, Gene Hackman, Ozzy Osbourne, Robert Redford, Jane Goodall, among others widely reported.",
    ].join(" "),
  },
  {
    id: "science",
    re: /\b(artemis|nasa|moon|3i|atlas comet|ozempic|wegovy|glp-?1|ebola|who)\b/i,
    text: [
      "SCIENCE: Interstellar comet 3I/ATLAS discovered/observed 2025 (third known interstellar visitor).",
      "GLP-1 drugs (Ozempic/Wegovy class) remained mainstream in 2025; Breakthrough Prize recognition for related science.",
      "Artemis II was planned/flown as the next crewed NASA lunar flyby era mission in 2026 reporting — confirm flight status with live research if asked 'did it launch'.",
      "New START expired in 2026 reporting as the last US–Russia strategic arms treaty clock ran out — treat as a live arms-control story.",
    ].join(" "),
  },
];

function lastAsk(messagesOrText) {
  if (typeof messagesOrText === "string") return messagesOrText;
  if (!Array.isArray(messagesOrText)) return "";
  for (let i = messagesOrText.length - 1; i >= 0; i--) {
    const m = messagesOrText[i];
    if (m && m.role === "user" && m.content) {
      if (typeof m.content === "string") return m.content;
      if (Array.isArray(m.content)) {
        return m.content.map((p) => (p && p.text) || "").join(" ");
      }
    }
  }
  return "";
}

function isCodeLike(ask) {
  return /```|function\s+\w+\s*\(|def\s+\w+|traceback|TypeError|npm install|cargo build/i.test(ask)
    && !/\b(rtx|gpu|world cup|president|pope)\b/i.test(ask);
}

const ATLAS_WHEN = new Set(["usgov", "world", "sports", "culture", "science"]);

function worldKnowledgeForAsk(ask) {
  const q = String(ask || "");
  const parts = [CORE];
  const hits = CHAPTERS.filter((ch) => ch.re.test(q));
  const atlasHint = /\b(news|today|this week|who won|election|war|president|pope|olympics|world cup)\b/i.test(q);
  const wantAtlas = !isCodeLike(q) && q.length > 0 && (
    atlasHint || hits.some((h) => ATLAS_WHEN.has(h.id))
  );
  if (wantAtlas) parts.push(ATLAS);
  if (hits.length) {
    for (const ch of hits.slice(0, 4)) parts.push(ch.text);
  }
  return parts.join("\n");
}

function packCoversAsk(ask) {
  const q = String(ask || "");
  if (!q.trim() || isCodeLike(q)) return false;
  if (/\b(price|today|tonight|this week|latest|news|stock|who won)\b/i.test(q)) return false;
  const hits = CHAPTERS.filter((ch) => ch.re.test(q));
  if (!hits.length) return false;
  return hits.every((h) => h.id === "compute" || h.id === "ai");
}

function worldKnowledgePack() {
  return worldKnowledgeForAsk("");
}

module.exports = {
  worldKnowledgePack,
  worldKnowledgeForAsk,
  lastAsk,
  packCoversAsk,
};
