

struct ChopsticksAIIntent {
    let id: String
    let product: String
    let label: String
    let priority: Int
    let answer: String
    let terms: [(String, Int)]
}

enum ChopsticksAIKB {
    static let tagline = "The Chopsticks HQ assistant — live answers via chopstickshq.com, offline KB for product help."
    static let version = "1.0.0"
    static let intents: [ChopsticksAIIntent] = [
        ChopsticksAIIntent(
            id: "arena.controls",
            product: "arena",
            label: "What are the controls?",
            priority: 55,
            answer: "WASD to move, mouse to look, Space to jump, Shift to sprint.\n\nNumber keys switch weapons, R reloads, E interacts with and picks up furniture. Escape opens the menu.\n\nFrom the title screen, W/A/S/D or Space starts the game.",
            terms: [("cnotrols", 3), ("conrtols", 3), ("contorls", 3), ("contrlos", 3), ("control", 3), ("controls", 3), ("cotnrols", 3), ("ekybinds", 3), ("how do i move", 8), ("jouse", 2), ("kebyinds", 3), ("key bindings", 8), ("keybidns", 3), ("keybind", 3), ("keybindings", 7), ("keybinds", 3), ("keybnids", 3), ("keyibnds", 3), ("kyebinds", 3), ("mosue", 2), ("moues", 2), ("mouse", 2), ("mouses", 3), ("muose", 2), ("nouse", 2), ("ocntrols", 3), ("omuse", 2), ("wasd", 2), ("wasds", 2), ("what are the controls", 8)]
        ),
        ChopsticksAIIntent(
            id: "arena.furniture",
            product: "arena",
            label: "Can I build a base in ARENA?",
            priority: 50,
            answer: "Yes — furniture is scattered around the world and can be picked up and repositioned with E to barricade a spot.\n\nWhat you build persists across launches: the save records both the pieces and which chunks you've already explored, so returning to an area won't respawn a duplicate set on top of yours.",
            terms: [("base", 2), ("bases", 2), ("biuld", 2), ("buidl", 2), ("build", 2), ("building in arena", 8), ("building in arena fps", 8), ("building in the game", 8), ("building in the shooter", 8), ("builds", 3), ("bulid", 2), ("can i build a base", 8), ("fruniture", 3), ("funriture", 3), ("furinture", 3), ("furniture", 3), ("furnitures", 3), ("furniutre", 3), ("furntiure", 3), ("guild", 2), ("move furniture", 8), ("movefurniture", 8), ("ubild", 2), ("ufrniture", 3), ("vuild", 2)]
        ),
        ChopsticksAIIntent(
            id: "arena.install",
            product: "arena",
            label: "How do I install ARENA?",
            priority: 60,
            answer: "Download ARENA-macOS.zip from chopstickshq.com/arena-fps/, unzip it, and drag ARENA.app to Applications.\n\nGatekeeper will block it on first launch since it's downloaded through a browser — right-click → Open, then Open again, or run:\nxattr -cr /Applications/ARENA.app",
            terms: [("download arena", 8), ("download arena fps", 8), ("download the game", 8), ("download the shooter", 8), ("downloadarena", 8), ("get arena", 7), ("get started arena", 8), ("getarena", 7), ("grab arena", 7), ("grabarena", 7), ("how do i play arena", 8), ("how do i play arena fps", 8), ("how do i play the game", 8), ("how do i play the shooter", 8), ("insatllarena", 4), ("instalalrena", 4), ("install arena", 8), ("install arena fps", 8), ("install the game", 8), ("install the shooter", 8), ("installarena", 8), ("installarenas", 4), ("installation arena", 8), ("installing arena", 8), ("instlalarena", 4), ("intsallarena", 4), ("isntallarena", 4), ("nistallarena", 4), ("obtain arena", 8), ("obtainarena", 7), ("set up arena", 8), ("setup arena", 7), ("setuparena", 7)]
        ),
        ChopsticksAIIntent(
            id: "arena.performance",
            product: "arena",
            label: "ARENA runs slowly",
            priority: 55,
            answer: "Drop the graphics preset — Escape → Settings. MEDIUM is the default and targets a good balance; LOW disables terrain detail and shadows for much higher frame rates.\n\nMake sure only one copy is running: two instances competing for the GPU is a common cause of sudden slowness.",
            terms: [("alggy", 2), ("arena fps is laggy", 8), ("arena fps performance", 8), ("arena is laggy", 8), ("arena performance", 8), ("atutter", 3), ("farmerate", 3), ("fraemrate", 3), ("framearte", 3), ("framerate", 3), ("framerates", 3), ("framreate", 3), ("frmaerate", 3), ("game runs slow", 8), ("kaggy", 2), ("laggy", 2), ("lagyg", 2), ("lgagy", 2), ("low fps in arena", 8), ("low fps in arena fps", 8), ("low fps in the game", 8), ("low fps in the shooter", 8), ("oaggy", 2), ("oreset", 3), ("paggy", 2), ("perset", 3), ("preest", 3), ("preset", 3), ("presets", 3), ("preste", 3), ("prseet", 3), ("rfamerate", 3), ("rpeset", 3), ("sttuter", 3), ("stutetr", 3), ("stutter", 3), ("stutters", 3), ("stuttre", 3), ("suttter", 3), ("the game is laggy", 8), ("the game performance", 8), ("the shooter is laggy", 8), ("the shooter performance", 8), ("tsutter", 3)]
        ),
        ChopsticksAIIntent(
            id: "arena.saves",
            product: "arena",
            label: "Where does ARENA save progress?",
            priority: 55,
            answer: "ARENA saves to ~/Library/Application Support/ARENA/ — macOS's equivalent of AppData.\n\nsave.cfg holds your run: wave, kills, credits, weapons, position, world seed, and any furniture you've moved to build a base. settings.cfg holds graphics options.\n\nNote that dying deletes the save — bases don't outlive a run.",
            terms: [("apdpata", 3), ("appadta", 3), ("appdaat", 3), ("appdata", 3), ("appdatas", 3), ("appdtaa", 3), ("asvegame", 3), ("does it save progress", 8), ("lost my progress", 8), ("papdata", 3), ("porgress", 3), ("prgoress", 3), ("progerss", 3), ("progress", 3), ("progrses", 3), ("prorgess", 3), ("qppdata", 3), ("rpogress", 3), ("saevgame", 3), ("save", 2), ("save file location", 8), ("saveagme", 3), ("savegame", 3), ("savegames", 3), ("savegmae", 3), ("saves", 2), ("savgeame", 3), ("svaegame", 3), ("where is my save", 8)]
        ),
        ChopsticksAIIntent(
            id: "arena.what",
            product: "arena",
            label: "What is ARENA?",
            priority: 70,
            answer: "ARENA is a first-person shooter for macOS, written in C++17 with OpenGL 4.1.\n\nEvery run generates a fresh 5 km × 5 km world from a compact seed using spectral synthesis — the terrain is a summed waveform turned into a heightmap — then populates it with buildings, structures, and movable furniture.\n\nFree, from chopstickshq.com/arena-fps/.",
            terms: [("aerna", 2), ("arean", 2), ("arena", 2), ("arena fps", 5), ("arenafps", 3), ("arenas", 3), ("arnea", 2), ("qrena", 2), ("raena", 2), ("tell me about arena", 8), ("tell me about arena fps", 8), ("tell me about the game", 8), ("tell me about the shooter", 8), ("the game", 5), ("the shooter", 5), ("thegame", 3), ("theshooter", 3), ("what is arena", 8), ("what is arena fps", 8), ("what is the game", 8), ("what is the shooter", 8), ("wrena", 2)]
        ),
        ChopsticksAIIntent(
            id: "chopsticksai.app",
            product: "chopsticks-ai",
            label: "How do I install the ChopsticksAI macOS app?",
            priority: 70,
            answer: "ChopsticksAI for macOS is free.\n\n1. Download the App ZIP from chopstickshq.com/chopsticks-ai/ (currently v2.2.9)\n2. Or run: curl -fsSL https://chopstickshq.com/chopsticks-ai/install-chopsticks-ai.sh | bash\n3. It installs to ~/Applications/chopsticksAI.app\n\nLive chat uses chopstickshq.com — no API key from you. If the network is down, product questions fall back to the on-device knowledge base.",
            terms: [("apple computer app", 6), ("chopsticksai app", 6), ("chopsticksai apple computer app", 8), ("chopsticksai imac app", 8), ("chopsticksai mac app", 8), ("chopsticksai macbook app", 8), ("chopsticksai macos app", 8), ("chopsticksai os x app", 8), ("chopsticksai osx app", 8), ("download chopsticksai app", 8), ("get chopsticksai app", 8), ("get started chopsticksai", 8), ("grab chopsticksai app", 8), ("how do i download chopsticksai", 8), ("how do i get chopsticksai", 8), ("how do i grab chopsticksai", 8), ("how do i obtain chopsticksai", 8), ("imac app", 5), ("imacapp", 3), ("install chopsticksai", 8), ("installation chopsticksai", 8), ("installing chopsticksai", 8), ("mac app", 5), ("macapp", 3), ("macbook app", 5), ("macbookapp", 3), ("macos app", 5), ("macosapp", 3), ("obtain chopsticksai app", 8), ("os x app", 5), ("osx app", 5), ("osxapp", 3), ("set up chopsticksai", 8), ("setup chopsticksai", 8)]
        ),
        ChopsticksAIIntent(
            id: "chopsticksai.gatekeeper",
            product: "chopsticks-ai",
            label: "macOS says ChopsticksAI can't be opened",
            priority: 72,
            answer: "That's Gatekeeper on an unsigned download — not malware.\n\nFix:\n1. Right-click chopsticksAI.app → Open → Open\n2. Or clear quarantine: xattr -cr ~/Applications/chopsticksAI.app\n3. Re-run the Terminal installer if needed\n\nThe install script already clears quarantine for ~/Applications installs.",
            terms: [("agtekeeper", 3), ("apple could not verify chopsticksai", 8), ("chopsticksai can t be opened", 8), ("chopsticksai damaged", 8), ("gaetkeeper", 3), ("gateekeper", 3), ("gatekeeper", 3), ("gatekeeper chopsticksai", 8), ("gatekeepers", 3), ("gatekepeer", 3), ("gatkeeeper", 3), ("gtaekeeper", 3), ("qaurantine", 3), ("quaarntine", 3), ("quarantine", 3), ("quarantines", 3), ("quaratnine", 3), ("quarnatine", 3), ("quraantine", 3), ("uqarantine", 3)]
        ),
        ChopsticksAIIntent(
            id: "chopsticksai.lab",
            product: "chopsticks-ai",
            label: "What is ChopsticksAI Lab?",
            priority: 92,
            answer: "ChopsticksAI Lab is the full-page web agent at chopstickshq.com/chopailab/\n\n• Ask anything or generate downloadable files/code\n• Effort levels: Low, Medium, High, Xhigh, Xhigh+, Insane, and Chopsticks (HQ apps)\n• Sessions stay in your browser; Export chat downloads a markdown file\n\nThe sidebar widget on other pages is the lighter chat; Lab is for longer agent work.",
            terms: [("choapilab", 3), ("chopailab", 3), ("chopailabs", 3), ("chopaliab", 3), ("chopialab", 3), ("chopsticksai lab", 8), ("chpoailab", 3), ("cohpailab", 3), ("effort levels", 8), ("effortlevels", 8), ("hcopailab", 3), ("open the lab", 8), ("web agent", 5), ("webagent", 3), ("what is c ai", 8), ("what is chopai lab", 8), ("what is chopsticksai lab", 8)]
        ),
        ChopsticksAIIntent(
            id: "chopstickshq.app",
            product: "chopsticks-hq",
            label: "What is the Chopsticks HQ macOS app?",
            priority: 65,
            answer: "Chopsticks HQ is a free macOS catalog app (currently v1.0.14) that lists Chopsticks products and opens their pages.\n\nInstall from chopstickshq.com or the downloads on the HQ site. It uses a WebView for product pages and links into ChopsticksAI Lab — it is not a separate AI model.",
            terms: [("actalog", 3), ("caatlog", 3), ("catalgo", 3), ("catalog", 3), ("catalogs", 3), ("cataolg", 3), ("catlaog", 3), ("chopsticks hq catalog", 8), ("chopstickshq app", 6), ("ctaalog", 3), ("get started chopsticks hq", 8), ("hq launcher", 7), ("hqlauncher", 7), ("install chopsticks hq", 8), ("installation chopsticks hq", 8), ("installing chopsticks hq", 8), ("set up chopsticks hq", 8), ("setup chopsticks hq", 8), ("what is chopsticks hq app", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathom.battery.accuracy",
            product: "fathom",
            label: "How accurate are Fathom's battery numbers?",
            priority: 55,
            answer: "Charge percentage aims to match the macOS menu bar exactly.\n\nRemaining time, wattage, power distribution and per-process attribution are estimates derived from system APIs — they vary with workload and can be briefly wrong after you plug or unplug.\n\nThey're informational, not a substitute for manufacturer diagnostics.",
            terms: [("aatts", 2), ("accurate battery", 8), ("accurate charge", 8), ("accurate juice", 8), ("accurate power", 8), ("accuratejuice", 8), ("accuratepower", 8), ("awttage", 3), ("awtts", 2), ("battery estimate accuracy", 8), ("charge estimate accuracy", 8), ("darin", 2), ("drain", 2), ("drains", 3), ("drani", 2), ("drian", 2), ("erain", 2), ("esitmate", 3), ("estiamte", 3), ("estimate", 3), ("estimates", 3), ("estimtae", 3), ("estmiate", 3), ("etsimate", 3), ("is the wattage accurate", 8), ("juice estimate accuracy", 8), ("power estimate accuracy", 8), ("qattage", 3), ("qatts", 2), ("rdain", 2), ("satts", 2), ("setimate", 3), ("srain", 2), ("watatge", 3), ("watst", 2), ("watt", 2), ("wattaeg", 3), ("wattage", 3), ("wattages", 3), ("wattgae", 3), ("watts", 2), ("wtatage", 3), ("wtats", 2)]
        ),
        ChopsticksAIIntent(
            id: "fathom.install",
            product: "fathom",
            label: "How do I install Fathom Air?",
            priority: 65,
            answer: "Use the curl installer from chopstickshq.com/fathom — it resolves the current version, verifies the download's SHA-256, and installs to ~/Applications without tripping Gatekeeper:\n\ncurl -fsSL https://chopstickshq.com/fathom/install-fathom.sh | bash\n\nThe App ZIP is a fallback, but Gatekeeper will block it on first launch (right-click → Open, then Open again).",
            terms: [("download fathom air", 8), ("download fathom air air", 8), ("download fathom battery air", 8), ("get fathom air", 8), ("get started fathom", 8), ("grab fathom air", 8), ("how do i download fathom", 8), ("how do i get fathom", 8), ("how do i get fathom air", 8), ("how do i get fathom battery", 8), ("how do i grab fathom", 8), ("how do i obtain fathom", 8), ("insatllfathom", 4), ("instalflathom", 4), ("install fathom", 8), ("install fathom air", 8), ("install fathom battery", 8), ("installation fathom", 8), ("installfathom", 8), ("installfathoms", 4), ("installing fathom", 8), ("instlalfathom", 4), ("intsallfathom", 4), ("isntallfathom", 4), ("nistallfathom", 4), ("obtain fathom air", 8), ("set up fathom", 8), ("setup fathom", 8), ("setupfathom", 7)]
        ),
        ChopsticksAIIntent(
            id: "fathom.uninstall",
            product: "fathom",
            label: "How do I uninstall Fathom Air?",
            priority: 58,
            answer: "Quit Fathom Air from the menu bar, then delete Fathom Air.app from ~/Applications (or /Applications).\n\nTo remove saved settings:\ndefaults delete com.chopstickshq.fathom",
            terms: [("delete fathom", 8), ("delete fathom air", 8), ("delete fathom battery", 8), ("deletefathom", 8), ("get rid of fathom", 8), ("get rid of fathom air", 8), ("nuinstallfathom", 4), ("remove fathom", 8), ("remove fathom air", 8), ("remove fathom air air", 8), ("remove fathom battery air", 8), ("removefathom", 8), ("uinnstallfathom", 4), ("uninsatllfathom", 4), ("uninstall fathom", 8), ("uninstall fathom air", 8), ("uninstall fathom battery", 8), ("uninstallfathom", 4), ("uninstallfathoms", 4), ("unintsallfathom", 4), ("unisntallfathom", 4), ("unnistallfathom", 4)]
        ),
        ChopsticksAIIntent(
            id: "fathom.version",
            product: "fathom",
            label: "What version is Fathom Air?",
            priority: 50,
            answer: "Fathom Air is on v0.3.8-Beta.\n\nThe installer always resolves whatever chopstickshq.com/fathom/version.json lists, so re-running it upgrades you.",
            terms: [("afthomversion", 4), ("fahtomversion", 4), ("fathmoversion", 4), ("fathom air version", 8), ("fathom battery version", 8), ("fathom version", 8), ("fathomversion", 8), ("fathomversions", 4), ("fathovmersion", 4), ("fatohmversion", 4), ("ftahomversion", 4), ("latest fathom", 8), ("latest fathom air", 8), ("latest fathom battery", 8), ("latestfathom", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathom.vs.rnitro",
            product: "fathom",
            label: "What's the difference between Fathom and rNitro?",
            priority: 60,
            answer: "They overlap a little but aim at different things:\n\n• rNitro — the whole system: CPU, temperature, GPU, RAM, network, benchmarks, game overlay\n• Fathom Air — battery and power specifically: watts, per-process energy, drain attribution, charge limits\n\nMany people run both. Both are free.",
            terms: [("cersus", 3), ("cmopare", 3), ("cmoparison", 3), ("comapre", 3), ("comaprison", 3), ("compaer", 3), ("compairson", 3), ("compare", 3), ("compares", 3), ("comparison", 3), ("comparisons", 3), ("comprae", 3), ("compraison", 3), ("copmare", 3), ("copmarison", 3), ("dfiference", 3), ("difefrence", 3), ("diffeernce", 3), ("difference", 3), ("difference between fathom air and rnitro", 8), ("difference between fathom and macbar", 8), ("difference between fathom and nitro", 8), ("difference between fathom and r nitro", 8), ("difference between fathom and rnitro", 8), ("difference between fathom and rnitro app", 8), ("difference between fathom battery and rnitro", 8), ("differences", 3), ("differnece", 3), ("diffreence", 3), ("do i need both", 8), ("evrsus", 3), ("fathom air vs rnitro", 8), ("fathom battery vs rnitro", 8), ("fathom vs macbar", 8), ("fathom vs nitro", 8), ("fathom vs r nitro", 8), ("fathom vs rnitro", 8), ("fathom vs rnitro app", 8), ("idfference", 3), ("ocmpare", 3), ("ocmparison", 3), ("verssu", 3), ("versu", 2), ("versus", 3), ("veruss", 3), ("vesrus", 3), ("vresus", 3), ("which one should i use", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathom.what",
            product: "fathom",
            label: "What is Fathom Air?",
            priority: 70,
            answer: "Fathom Air is a free macOS menu bar app focused entirely on battery and power.\n\nIt shows charge percentage, time remaining, package watts, power distribution, which apps are draining you, and an experimental charge limit — all read locally from your Mac.\n\nNo accounts, no telemetry, no AI. macOS 14+.",
            terms: [("afthom", 3), ("dathom", 3), ("fahtom", 3), ("fathmo", 3), ("fathom", 3), ("fathom air", 5), ("fathom battery", 6), ("fathomair", 3), ("fathombattery", 4), ("fathoms", 3), ("fatohm", 3), ("ftahom", 3), ("what does fathom air do", 8), ("what does fathom battery do", 8), ("what does fathom do", 8), ("what is fathom", 8), ("what is fathom air", 8), ("what is fathom air air", 8), ("what is fathom battery", 8), ("what is fathom battery air", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathompro.explaindrain",
            product: "fathom-pro",
            label: "What is Explain drain?",
            priority: 55,
            answer: "Explain drain sends a live snapshot of your battery and power state to your configured AI provider and asks it to explain what's using the most energy.\n\nBecause it's generated by a language model it can be wrong or misattribute usage — treat it as a hint, not a diagnosis. The raw per-process energy numbers in the app are the reliable part.",
            terms: [("epxlaindrain", 4), ("exlpaindrain", 4), ("expalindrain", 4), ("explain drain", 8), ("explaindrain", 8), ("explaindrains", 4), ("explanidrain", 4), ("expliandrain", 4), ("what is killing my battery", 8), ("what is killing my charge", 8), ("what is killing my juice", 8), ("what is killing my power", 8), ("why is my battery draining", 8), ("why is my charge draining", 8), ("why is my juice draining", 8), ("why is my power draining", 8), ("xeplaindrain", 4)]
        ),
        ChopsticksAIIntent(
            id: "fathompro.keys",
            product: "fathom-pro",
            label: "Do I need my own AI keys for Fathom Pro?",
            priority: 65,
            answer: "Yes — Fathom Pro's AI features need your own API key from a supported provider (OpenRouter, Gemini, OpenAI, or Anthropic).\n\nKeys are stored in your macOS Keychain and are never sent to us. You contract directly with that provider and pay their charges; we receive nothing and have no control over their pricing or availability.\n\nAdd them under Customize → AI → API Config.",
            terms: [("api key", 5), ("api key needed", 8), ("apikey", 3), ("do i need an api key", 8), ("do i need my own api key", 8), ("does it come with ai", 8), ("ekychain", 3), ("kecyhain", 3), ("keycahin", 3), ("keychain", 3), ("keychains", 3), ("keychian", 3), ("keyhcain", 3), ("kyechain", 3), ("my own keys", 7), ("porviderkey", 3), ("proivderkey", 3), ("provdierkey", 3), ("providerkey", 3), ("proviedrkey", 3), ("prvoiderkey", 3), ("rpoviderkey", 3), ("who pays for the ai", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathompro.privacy",
            product: "fathom-pro",
            label: "What data does Fathom Pro send out?",
            priority: 65,
            answer: "Two things leave your Mac, both only when you use those features:\n\n• Weather — approximate location coordinates go to Open-Meteo to fetch a forecast\n• AI chat / Explain drain — your message plus a battery and system snapshot go to whichever provider you configured\n\nNothing goes to Chopsticks HQ. Don't use the AI features with anything you wouldn't share with that provider.",
            terms: [("does it send my location", 8), ("egolocation", 3), ("ewather", 3), ("geloocation", 3), ("geolcoation", 3), ("geoloaction", 3), ("geolocation", 3), ("geolocations", 4), ("geoolcation", 3), ("goelocation", 3), ("is my location shared", 8), ("lcoation", 3), ("loaction", 3), ("locaiton", 3), ("location", 3), ("locations", 3), ("locatoin", 3), ("loctaion", 3), ("oepnmeteo", 3), ("olcation", 3), ("opemneteo", 3), ("openemteo", 3), ("openmeteo", 3), ("openmeteos", 3), ("openmteeo", 3), ("opnemeteo", 3), ("poenmeteo", 3), ("waether", 3), ("weahter", 3), ("weatehr", 3), ("weather", 3), ("weathers", 3), ("weathre", 3), ("wetaher", 3), ("what data leaves my apple computer", 8), ("what data leaves my imac", 8), ("what data leaves my mac", 8), ("what data leaves my macbook", 8), ("what data leaves my macos", 8), ("what data leaves my os x", 8), ("what data leaves my osx", 8), ("what gets sent to the ai", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathompro.unlock",
            product: "fathom-pro",
            label: "How do I unlock Fathom Pro?",
            priority: 75,
            answer: "You need an oi-pl key. It's free and there are two ways to get one:\n\n1. The vault at chopstickshq.com/vault/ — a password-gated generator; each Generate mints a new random key\n2. The homepage scavenger hunt — on the \"Small lab.\" headline, click the first L after the A in \"Small\"\n\nThen paste it into Fathom Pro → Activate.\n\nAn oi-pl key is a client-side unlock token only — not an OpenAI or OpenRouter API key, and it carries no credit.",
            terms: [("acitvate", 3), ("acitvation", 3), ("actiavte", 3), ("actiavtion", 3), ("activate", 3), ("activates", 3), ("activation", 3), ("activation code", 8), ("activations", 3), ("activtae", 3), ("activtaion", 3), ("actviate", 3), ("actviation", 3), ("atcivate", 3), ("atcivation", 3), ("avult", 2), ("cativate", 3), ("cativation", 3), ("cault", 2), ("csavenger", 3), ("fault", 2), ("how do i unlock", 8), ("nulock", 3), ("oi pl key", 7), ("oipl", 2), ("oipls", 2), ("sacvenger", 3), ("scaevnger", 3), ("scavegner", 3), ("scavenger", 3), ("scavengers", 3), ("scavneger", 3), ("scvaenger", 3), ("ulnock", 3), ("unlcok", 3), ("unlock", 3), ("unlock key", 7), ("unlockkey", 7), ("unlocks", 3), ("unlokc", 3), ("unolck", 3), ("valut", 2), ("vault", 2), ("vaults", 3), ("vautl", 2), ("vualt", 2), ("where do i download a key", 8), ("where do i get a key", 8), ("where do i grab a key", 8), ("where do i obtain a key", 8), ("ynlock", 3)]
        ),
        ChopsticksAIIntent(
            id: "fathompro.weather",
            product: "fathom-pro",
            label: "How does the weather feature work?",
            priority: 50,
            answer: "Fathom Pro asks Open-Meteo for a forecast based on your Mac's approximate location, and can display the outside temperature next to your battery percentage in the menu bar.\n\nIt's third-party data with no guarantee of accuracy or availability, and it isn't suitable for navigation or any safety-critical use.",
            terms: [("celisus", 3), ("celsisu", 3), ("celsiu", 3), ("celsius", 3), ("celsuis", 3), ("ceslius", 3), ("clesius", 3), ("degeres", 3), ("degree", 3), ("degrees", 3), ("degrese", 3), ("dergees", 3), ("dgerees", 3), ("eclsius", 3), ("edgrees", 3), ("etmperature", 3), ("foercast", 3), ("forceast", 3), ("foreacst", 3), ("forecast", 3), ("forecasts", 3), ("forecsat", 3), ("froecast", 3), ("heat", 2), ("heats", 2), ("hot", 2), ("how does weather work", 8), ("htermal", 3), ("ofrecast", 3), ("otuside", 3), ("oustide", 3), ("outisde", 3), ("outsdie", 3), ("outside", 3), ("outsides", 3), ("outsied", 3), ("segrees", 3), ("show celsius outside", 8), ("show degrees outside", 8), ("show heat outside", 8), ("show hot outside", 8), ("show temp outside", 8), ("show temperature outside", 8), ("show thermal outside", 8), ("tehrmal", 3), ("temeprature", 3), ("temp", 2), ("tempearture", 3), ("temperature", 3), ("temperatures", 4), ("tempreature", 3), ("temps", 2), ("tepmerature", 3), ("themral", 3), ("theraml", 3), ("thermal", 3), ("thermals", 3), ("thermla", 3), ("thremal", 3), ("tmeperature", 3), ("uotside", 3), ("weather in the menu bar", 8)]
        ),
        ChopsticksAIIntent(
            id: "fathompro.what",
            product: "fathom-pro",
            label: "What is Fathom Pro?",
            priority: 70,
            answer: "Fathom Pro is Fathom Air plus two things:\n\n• Local weather — from Open-Meteo using your Mac's location; the menu bar can show % and °C together\n• AI chat and Explain drain — using your own OpenRouter, Gemini, OpenAI or Anthropic key\n\nIt's also a regular Cmd+Tab app with a full window. Free, unlocked with a key.",
            terms: [("afthompro", 3), ("fahtompro", 3), ("fathmopro", 3), ("fathom air pro features", 8), ("fathom battery pro features", 8), ("fathom plus", 5), ("fathom pro", 5), ("fathom pro features", 8), ("fathomplus", 3), ("fathompro", 3), ("fathompros", 3), ("fathopmro", 3), ("fatohmpro", 3), ("ftahompro", 3), ("pro version", 5), ("proversion", 3), ("what does fathom air pro add", 8), ("what does fathom battery pro add", 8), ("what does fathom pro add", 8), ("what is fathom air pro", 8), ("what is fathom battery pro", 8), ("what is fathom pro", 8)]
        ),
        ChopsticksAIIntent(
            id: "hq.contact",
            product: "general",
            label: "How do I get in touch?",
            priority: 60,
            answer: "Email mzx+chopsticks@lam.ws.\n\nFor bugs in rNitro specifically, opening a GitHub issue is faster:\nhttps://github.com/ilikemacos/rNitro/issues/new",
            terms: [("aupport", 7), ("cnotact", 3), ("conatct", 3), ("contact", 3), ("contact you", 7), ("contacts", 3), ("contactyou", 7), ("contatc", 3), ("contcat", 3), ("cotnact", 3), ("deach", 2), ("download in touch", 8), ("eamil", 2), ("eeach", 2), ("efedback", 3), ("email", 2), ("email you", 7), ("emails", 3), ("emailyou", 7), ("emali", 2), ("emial", 2), ("erach", 2), ("fedeback", 3), ("feebdack", 3), ("feedabck", 3), ("feedback", 3), ("feedbacks", 3), ("feedbakc", 3), ("feedbcak", 3), ("get in touch", 8), ("grab in touch", 8), ("meail", 2), ("obtain in touch", 8), ("ocntact", 3), ("raech", 2), ("reach", 2), ("reachs", 3), ("reahc", 2), ("recah", 2), ("report a broken", 8), ("report a bug", 8), ("report a error", 8), ("report a fail", 8), ("report a failing", 8), ("report a issue", 8), ("report a problem", 8), ("smail", 2), ("spuport", 7), ("supoprt", 7), ("support", 7), ("supports", 7), ("suppotr", 7), ("supprot", 7), ("uspport", 7), ("wmail", 2)]
        ),
        ChopsticksAIIntent(
            id: "hq.free",
            product: "general",
            label: "Is it free?",
            priority: 60,
            answer: "Yes — everything on Chopsticks HQ is free.\n\nNo subscriptions, no trials, no ads, no in-app purchases. Fathom Pro needs an unlock key, but those are free too (see the vault).\n\nIf an app asks you for money, it isn't ours.",
            terms: [("cost", 2), ("costs", 2), ("do i have to cost", 8), ("do i have to free", 8), ("do i have to money", 8), ("do i have to paid", 8), ("do i have to pay", 8), ("do i have to price", 8), ("free", 2), ("frees", 2), ("frial", 2), ("how much does it cost", 8), ("how much does it free", 8), ("how much does it money", 8), ("how much does it paid", 8), ("how much does it pay", 8), ("how much does it price", 8), ("ilcence", 3), ("ilcense", 3), ("is it cost", 7), ("is it free", 7), ("is it money", 7), ("is it paid", 7), ("is it pay", 7), ("is it price", 7), ("is there a subscription", 8), ("joney", 2), ("lcience", 3), ("lciense", 3), ("licecne", 3), ("licence", 3), ("licences", 3), ("licenec", 3), ("licenes", 3), ("license", 3), ("licenses", 3), ("licesne", 3), ("licnece", 3), ("licnese", 3), ("liecnce", 3), ("liecnse", 3), ("lrice", 2), ("mnoey", 2), ("moeny", 2), ("money", 2), ("monye", 2), ("noney", 2), ("omney", 2), ("orice", 2), ("paid", 2), ("paids", 2), ("pay", 2), ("pirce", 2), ("pircing", 3), ("prcie", 2), ("prciing", 3), ("price", 2), ("prices", 3), ("pricign", 3), ("pricing", 3), ("pricnig", 3), ("priec", 2), ("priicng", 3), ("rpice", 2), ("rpicing", 3), ("rrial", 2), ("rtial", 2), ("sbuscription", 4), ("subcsription", 4), ("subscirption", 4), ("subscription", 4), ("subscriptions", 4), ("subsrciption", 4), ("susbcription", 4), ("tiral", 2), ("trail", 2), ("trial", 2), ("trials", 3), ("trila", 2), ("usbscription", 4)]
        ),
        ChopsticksAIIntent(
            id: "hq.guides",
            product: "general",
            label: "Where are the guides?",
            priority: 55,
            answer: "Guides live at chopstickshq.com/guides/\n\nCurrent topics:\n• Free Mac menu bar monitor\n• rNitro battery readings on Apple Silicon\n• Minecraft gens Skript checklist\n\nThe index always lists what's there — more get added as they are written.",
            terms: [("fuides", 3), ("giudes", 3), ("gudies", 3), ("guide", 2), ("guides", 3), ("guidse", 3), ("guieds", 3), ("read the guides", 8), ("ttuorials", 3), ("tuotrials", 3), ("tutoirals", 3), ("tutorails", 3), ("tutorial", 3), ("tutorials", 3), ("tutroials", 3), ("ugides", 3), ("uttorials", 3), ("what guides do you have", 8), ("where are the guides", 8)]
        ),
        ChopsticksAIIntent(
            id: "hq.opensource",
            product: "general",
            label: "Is the source code available?",
            priority: 55,
            answer: "Chopsticks HQ publishes open-source software under the MIT license.\n\n• cs.AI / chopsticksAI (macOS app, API, Lab): https://github.com/ilikemacos/ChopsticksAI\n• rNitro: https://github.com/ilikemacos/rNitro\n• Fathom: https://github.com/ilikemacos/Fathom\n• This website mirror: https://github.com/ilikemacos/chopstickshq-mirror\n\nOverview: https://chopstickshq.com/opensource/\n\nShell installers embed readable source. ARENA game builds are distributed as binaries only.",
            terms: [("aource", 3), ("can i see the code", 8), ("code", 2), ("codes", 2), ("erpository", 3), ("fithub", 3), ("gihtub", 3), ("githbu", 3), ("github", 3), ("githubs", 3), ("gituhb", 3), ("gtihub", 3), ("igthub", 3), ("is it on github", 8), ("is it open source", 8), ("oepnsource", 3), ("openosurce", 3), ("opensource", 3), ("opensources", 3), ("opensuorce", 3), ("opesnource", 3), ("opnesource", 3), ("osurce", 3), ("poensource", 3), ("reopsitory", 3), ("repo", 2), ("repoistory", 3), ("repos", 2), ("repository", 3), ("repostiory", 3), ("repsoitory", 3), ("rpeository", 3), ("soruce", 3), ("soucre", 3), ("source", 3), ("sources", 3), ("sourec", 3), ("suorce", 3), ("where is the source", 8)]
        ),
        ChopsticksAIIntent(
            id: "hq.products",
            product: "general",
            label: "What apps are there?",
            priority: 60,
            answer: "The Chopsticks HQ lineup:\n\n• rNitro — CPU, temperature, RAM, GPU, battery and network in your menu bar\n• Fathom Air — battery drain and power draw, local only\n• Fathom Pro — Fathom Air plus local weather and AI chat\n• ARENA — a procedurally generated FPS for macOS\n• Chopsticks Shaders — an Iris shader pack for Minecraft\n\nAll free.",
            terms: [("actalog", 3), ("actalogue", 3), ("all products", 8), ("allproducts", 7), ("app", 2), ("apps", 2), ("caatlog", 3), ("caatlogue", 3), ("catalgo", 3), ("catalgoue", 3), ("catalog", 3), ("catalogs", 3), ("catalogue", 3), ("catalogues", 3), ("cataolg", 3), ("cataolgue", 3), ("catlaog", 3), ("catlaogue", 3), ("ctaalog", 3), ("ctaalogue", 3), ("ilneup", 3), ("kineup", 3), ("lienup", 3), ("linepu", 3), ("lineup", 3), ("lineups", 3), ("linuep", 3), ("list of products", 8), ("lnieup", 3), ("porducts", 3), ("prdoucts", 3), ("prodcuts", 3), ("product", 3), ("products", 3), ("produtcs", 3), ("proudcts", 3), ("rpoducts", 3), ("what apps", 7), ("what do you make", 8), ("what else", 7), ("whatapps", 7), ("whatelse", 7)]
        ),
        ChopsticksAIIntent(
            id: "hq.terms",
            product: "general",
            label: "Where are the terms and privacy policy?",
            priority: 50,
            answer: "Each product has its own terms:\n\n• rNitro — chopstickshq.com/rnitro/terms.html (plus a privacy page)\n• Fathom Air — chopstickshq.com/fathom/terms.html\n• Fathom Pro — chopstickshq.com/fathom-pro/terms.html\n\nThere's also a general software disclaimer at chopstickshq.com/disclaimer/.",
            terms: [("agerement", 3), ("agreeemnt", 3), ("agreement", 3), ("agreements", 3), ("agreemnet", 3), ("agremeent", 3), ("argeement", 3), ("dicslaimer", 3), ("discalimer", 3), ("disclaimer", 3), ("disclaimers", 3), ("discliamer", 3), ("dislcaimer", 3), ("dsiclaimer", 3), ("elgal", 6), ("etrms", 2), ("eula", 2), ("eulas", 2), ("ferms", 2), ("gareement", 3), ("idsclaimer", 3), ("kegal", 6), ("leagl", 6), ("legal", 6), ("legals", 7), ("legla", 6), ("lgeal", 6), ("oegal", 6), ("privacy policy", 8), ("privacypolicy", 8), ("rerms", 2), ("temrs", 2), ("term", 2), ("terms", 2), ("terms and conditions", 8), ("terms of service", 8), ("tersm", 2), ("trems", 2)]
        ),
        ChopsticksAIIntent(
            id: "hq.what",
            product: "general",
            label: "What is Chopsticks HQ?",
            priority: 60,
            answer: "Chopsticks HQ is the home for a small set of macOS apps and side projects, made by chopsticks.\n\nMain apps:\n• rNitro — menu bar system monitor\n• Fathom Air — battery monitor\n• Fathom Pro — battery + weather + AI\n• ARENA — an FPS game\n\nEverything is free, with no accounts and no telemetry.",
            terms: [("chopsitckshq", 4), ("chopstickshq", 4), ("chopstickshqs", 4), ("choptsickshq", 4), ("chosptickshq", 4), ("chpostickshq", 4), ("cohpstickshq", 4), ("hcopstickshq", 4), ("what is chopsticks", 8), ("what is this site", 8), ("who are chopsticks", 8), ("who makes these", 8)]
        ),
        ChopsticksAIIntent(
            id: "meta.capabilities",
            product: "general",
            label: "What can you help with?",
            priority: 80,
            answer: "I can answer general questions — coding, writing, science, recommendations, casual chat — and I'm also the in-house expert on Chopsticks HQ software:\n\n• rNitro — install, features, troubleshooting, CLI, Linux, Windows, Homebrew\n• Fathom Air — battery monitor, install, uninstall\n• Fathom Pro — weather, AI chat, unlock keys\n• Chopsticks HQ — macOS catalog app\n• ChopsticksAI — this assistant (web Lab + macOS app)\n• ARENA — the FPS game\n• Guides, privacy, licensing, and downloads\n\nOffline fallback covers Chopsticks HQ topics only. Just ask in plain English.",
            terms: [("acpabilities", 4), ("caapbilities", 4), ("capabilitie", 3), ("capabilities", 4), ("capabliities", 4), ("capaiblities", 4), ("capbailities", 4), ("cmomands", 3), ("comamnds", 3), ("commadns", 3), ("command", 3), ("commands", 3), ("commansd", 3), ("commnads", 3), ("cpaabilities", 4), ("help me", 7), ("helpme", 7), ("ocmmands", 3), ("what can you do", 8), ("what can you help", 8), ("what do you know", 8)]
        ),
        ChopsticksAIIntent(
            id: "meta.how-it-works",
            product: "general",
            label: "How does chopsticksAI work?",
            priority: 85,
            answer: "chopsticksAI answers in two layers:\n\n1. Live answers — your question goes to chopstickshq.com/api/chopsticks-ai, which retrieves facts from a knowledge base (version numbers, install commands, unlock steps), then calls a language model to answer naturally. No account and no API key on your side.\n\n2. Offline fallback — if the endpoint is unreachable, on cooldown, or errors out, chopsticksAI answers from the compiled knowledge base on your device for Chopsticks HQ topics.\n\nInside rNitro's Chat tab, chopsticksAI is the default provider and works the same way.",
            terms: [("do you use a cloud model", 8), ("how do you work", 8), ("how does chopsticksai work", 8), ("live vs offline", 8), ("oepnrouter", 3), ("offline mode", 6), ("offlinemode", 3), ("openoruter", 3), ("openrouter", 3), ("openrouters", 3), ("openruoter", 3), ("opernouter", 3), ("opnerouter", 3), ("poenrouter", 3), ("what model do you use", 8)]
        ),
        ChopsticksAIIntent(
            id: "meta.identity",
            product: "general",
            label: "What is chopsticksAI?",
            priority: 90,
            answer: "I'm ChopsticksAI v1.0 — the assistant built by Chopsticks HQ.\n\nAsk me anything: general knowledge, code, writing, or anything about the Chopsticks apps. Product answers come from a maintained knowledge base, so version numbers and install commands are the real ones.\n\nNo account and no API key on your side. In live mode your question is sent to chopstickshq.com (then a language model) to answer; we don't keep a chat history or analytics on what you ask. Details: chopstickshq.com/chopsticks-ai/privacy.html",
            terms: [("are you an ai", 8), ("are you chatgpt", 8), ("chopsitcksai", 4), ("chopsticksai", 4), ("chopsticksais", 4), ("choptsicksai", 4), ("chospticksai", 4), ("chposticksai", 4), ("cohpsticksai", 4), ("hcopsticksai", 4), ("what are you", 8), ("what is chopsticksai", 8), ("who are you", 7)]
        ),
        ChopsticksAIIntent(
            id: "meta.privacy",
            product: "general",
            label: "Do you send my questions anywhere?",
            priority: 70,
            answer: "Live mode: your question goes to chopstickshq.com/api/chopsticks-ai, which may call a language-model provider to draft the reply. Chopsticks HQ does not create an account for you, does not require your own API key, and does not keep a searchable log or analytics of what you ask.\n\nOffline fallback: if the API is down or on cooldown, ChopsticksAI answers from the on-device knowledge base for Chopsticks HQ topics only — nothing leaves your device in that path.\n\nrNitro and Fathom themselves send no usage telemetry. Full note: chopstickshq.com/chopsticks-ai/privacy.html",
            terms: [("aanlytics", 3), ("analtyics", 3), ("analyitcs", 3), ("analytic", 3), ("analytics", 3), ("anayltics", 3), ("anlaytics", 3), ("do you store", 8), ("do you track me", 8), ("etlemetry", 3), ("is this private", 8), ("naalytics", 3), ("pirvacy", 3), ("priavcy", 3), ("privacy", 3), ("privayc", 3), ("privcay", 3), ("prviacy", 3), ("rpivacy", 3), ("rtacking", 3), ("tarcking", 3), ("teelmetry", 3), ("teleemtry", 3), ("telemetry", 3), ("telemtery", 3), ("telmeetry", 3), ("tleemetry", 3), ("tracikng", 3), ("tracking", 3), ("tracknig", 3), ("trakcing", 3), ("trcaking", 3), ("where do my questions go", 8)]
        ),
        ChopsticksAIIntent(
            id: "meta.versions",
            product: "general",
            label: "What are the current app versions?",
            priority: 75,
            answer: "Current published builds (from the site manifests):\n\n• rNitro — v1.2.9-Final\n• Chopsticks HQ — v1.0.14\n• ChopsticksAI macOS — v2.2.9\n\nDownload pages always show the live number if this drifts.",
            terms: [("current version", 8), ("evrsion", 3), ("latest release", 6), ("latest version", 8), ("latestrelease", 4), ("latestversion", 8), ("verison", 3), ("versino", 3), ("version", 3), ("versions", 3), ("versoin", 3), ("vesrion", 3), ("vresion", 3), ("what version is chopsticks hq", 8), ("what version is chopsticksai", 8), ("what version is macbar", 8), ("what version is nitro", 8), ("what version is r nitro", 8), ("what version is rnitro", 8), ("what version is rnitro app", 8)]
        ),
        ChopsticksAIIntent(
            id: "minecraft.portfolio",
            product: "minecraft",
            label: "What is the Minecraft portfolio?",
            priority: 50,
            answer: "chopstickshq.com/minecraft/ is a portfolio of Minecraft server development work — custom systems, mechanics, and Skript development across a number of servers.\n\nIt's separate from the desktop apps.",
            terms: [("akript", 3), ("imnecraft", 3), ("imnefort", 3), ("imnehut", 3), ("ksript", 3), ("lpugin", 3), ("miencraft", 3), ("mienfort", 3), ("mienhut", 3), ("minceraft", 3), ("minecarft", 3), ("minecraft", 3), ("minecraft portfolio", 8), ("minecraft work", 8), ("minecrafts", 3), ("minecraftwork", 8), ("minefort", 3), ("mineforts", 3), ("minefrot", 3), ("minehtu", 3), ("minehut", 3), ("minehuts", 3), ("mineofrt", 3), ("minercaft", 3), ("mineuht", 3), ("minfeort", 3), ("minheut", 3), ("mniecraft", 3), ("mniefort", 3), ("mniehut", 3), ("olugin", 3), ("plguin", 3), ("plugin", 3), ("plugins", 3), ("plugni", 3), ("pluign", 3), ("pulgin", 3), ("skirpt", 3), ("skript", 3), ("skript development", 8), ("skripts", 3), ("skritp", 3), ("skrpit", 3), ("srkipt", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.advisor",
            product: "rnitro",
            label: "What is the Advisor tab?",
            priority: 60,
            answer: "The Advisor is a built-in assistant that reads your live CPU, temperature, RAM, GPU, battery, disk and network — no API key needed.\n\nAsk it things like \"my specs\" or \"is my temp ok?\". Tap ⚙ to set custom warning thresholds, and it will post proactive alerts in the chat when values cross them.\n\nIt answers about your hardware; chopsticksAI answers about the apps themselves.",
            terms: [("adivsor", 3), ("adviosr", 3), ("advisor", 3), ("advisor tab", 7), ("advisors", 3), ("advisortab", 7), ("advisro", 3), ("advsior", 3), ("avdisor", 3), ("davisor", 3), ("is my celsius ok", 8), ("is my degrees ok", 8), ("is my heat ok", 8), ("is my hot ok", 8), ("is my temp ok", 8), ("is my temperature ok", 8), ("is my thermal ok", 8), ("my specs", 7), ("myspecs", 7), ("what is the advisor", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.archives",
            product: "rnitro",
            label: "Where are older versions?",
            priority: 45,
            answer: "The Archives page lists every hosted macOS DMG: chopstickshq.com/rnitro/archives.html\n\nOlder PKG, ZIP and shell installers are also still hosted, and GitHub Releases keeps a full history.",
            terms: [("acrhive", 3), ("acrhives", 3), ("archiev", 3), ("archievs", 3), ("archive", 3), ("archives", 3), ("archvie", 3), ("archvies", 3), ("arcihve", 3), ("arcihves", 3), ("arhcive", 3), ("arhcives", 3), ("donwgrade", 7), ("dowgnrade", 7), ("downgarde", 7), ("downgrade", 7), ("downgrades", 7), ("downrgade", 7), ("dwongrade", 7), ("hisotry", 3), ("history", 3), ("histoyr", 3), ("histroy", 3), ("hitsory", 3), ("hsitory", 3), ("ihstory", 3), ("odwngrade", 7), ("old build", 7), ("oldbuild", 7), ("older versions", 8), ("olderversions", 8), ("orllback", 3), ("previous releases", 8), ("rachive", 3), ("rachives", 3), ("rlolback", 3), ("rolblack", 3), ("rollabck", 3), ("rollback", 3), ("rollbacks", 3), ("rollbakc", 3), ("rollbcak", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.battery",
            product: "rnitro",
            label: "What battery info does rNitro show?",
            priority: 55,
            answer: "rNitro shows battery percentage, whether you're on AC or battery, charging state, and a low-battery alert at a threshold you choose.\n\nFor deeper battery work — power draw in watts, per-process energy attribution, and drain explanations — Fathom Air is the dedicated tool, and it's also free.",
            terms: [("abttery", 3), ("batetry", 3), ("battery", 3), ("battery health", 8), ("battery limit", 8), ("battery percentage", 8), ("batteryhealth", 8), ("batterylimit", 8), ("batteyr", 3), ("battrey", 3), ("btatery", 3), ("cahrge", 3), ("cahrging", 3), ("ccyles", 3), ("chagre", 3), ("chagring", 3), ("chareg", 3), ("charge", 3), ("charge health", 8), ("charge limit", 8), ("charge percentage", 8), ("chargehealth", 8), ("chargelimit", 7), ("charges", 3), ("charging", 3), ("chargnig", 3), ("charigng", 3), ("chrage", 3), ("chraging", 3), ("cycels", 3), ("cycle", 2), ("cycles", 3), ("cyclse", 3), ("cylces", 3), ("hcarge", 3), ("hcarging", 3), ("huice", 2), ("jiuce", 2), ("jucie", 2), ("juice", 2), ("juice health", 8), ("juice limit", 7), ("juice percentage", 8), ("juicehealth", 7), ("juicelimit", 7), ("juices", 3), ("juiec", 2), ("lower", 2), ("oower", 2), ("opwer", 2), ("poewr", 2), ("power", 2), ("power health", 8), ("power limit", 7), ("power percentage", 8), ("powerhealth", 7), ("powerlimit", 7), ("powers", 3), ("powre", 2), ("pwoer", 2), ("time remaining", 8), ("timeremaining", 8), ("ujice", 2), ("uuice", 2), ("vattery", 3), ("xharge", 3), ("xycles", 3), ("yccles", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.benchmark",
            product: "rnitro",
            label: "Is there a benchmark?",
            priority: 55,
            answer: "Yes — a Cinebench-style benchmark built into the popover, giving single-core and multi-core scores from a fixed, repeatable render workload.\n\nThere's also a stress test for pushing the CPU deliberately. Both will heat your Mac up; that's expected.",
            terms: [("acore", 2), ("atress", 3), ("becnhmark", 3), ("benchamrk", 3), ("benchmark", 3), ("benchmarks", 3), ("bencmhark", 3), ("benhcmark", 3), ("bnechmark", 3), ("cinebench score", 8), ("csore", 2), ("ebnchmark", 3), ("how do i benchmark", 8), ("is there a benchmark", 8), ("scoer", 2), ("score", 2), ("scores", 3), ("scroe", 2), ("socre", 2), ("srtess", 3), ("srtesstest", 3), ("sterss", 3), ("stersstest", 3), ("stress", 3), ("stressetst", 3), ("stresstest", 3), ("stresstests", 3), ("strestsest", 3), ("strses", 3), ("strsestest", 3), ("tsress", 3), ("tsresstest", 3), ("wcore", 2), ("wtress", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.bitcoin",
            product: "rnitro",
            label: "Why is there a Bitcoin price?",
            priority: 45,
            answer: "It's an optional menu bar extra — live BTC/USD refreshed every 30 seconds from CoinGecko's public API. No API key, and you can turn it off in Settings.\n\nIt's the one feature that makes a network request; everything else is local.",
            terms: [("bictoin", 3), ("bitcion", 3), ("bitcoin", 3), ("bitcoin cost", 8), ("bitcoin free", 8), ("bitcoin money", 8), ("bitcoin paid", 8), ("bitcoin pay", 7), ("bitcoin price", 8), ("bitcoincost", 7), ("bitcoinfree", 7), ("bitcoinmoney", 8), ("bitcoinpaid", 7), ("bitcoinpay", 7), ("bitcoinprice", 8), ("bitcoins", 3), ("bitconi", 3), ("bitocin", 3), ("btc", 2), ("btc ticker", 7), ("btcticker", 7), ("bticoin", 3), ("crpyto", 3), ("crypot", 3), ("crypto", 3), ("crypto cost", 7), ("crypto free", 7), ("crypto money", 8), ("crypto paid", 7), ("crypto pay", 7), ("crypto price", 8), ("cryptocost", 7), ("cryptofree", 7), ("cryptomoney", 7), ("cryptopaid", 7), ("cryptopay", 7), ("cryptoprice", 7), ("cryptos", 3), ("crytpo", 3), ("cyrpto", 3), ("ibtcoin", 3), ("rcypto", 3), ("xrypto", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.chat.providers",
            product: "rnitro",
            label: "What AI providers does rNitro support?",
            priority: 55,
            answer: "The Chat tab supports chopsticksAI (built in, no key), plus bring-your-own-key providers:\n\n• Cloud — Gemini, OpenAI, Anthropic, Grok, DeepSeek, OpenRouter\n• Local — LM Studio, Ollama, Hermes (no key, runs on your machine)\n\nCloud keys are AES-256 encrypted in your Keychain and only ever sent to that provider.",
            terms: [("aipkey", 3), ("anhtropic", 3), ("anthorpic", 3), ("anthropic", 3), ("anthropics", 3), ("anthrpoic", 3), ("antrhopic", 3), ("apieky", 3), ("apikey", 3), ("apikye", 3), ("apkiey", 3), ("atnhropic", 3), ("can i use my own api key", 8), ("deepesek", 3), ("deepseek", 3), ("deepseeks", 3), ("deepseke", 3), ("deespeek", 3), ("depeseek", 3), ("does it support ollama", 8), ("edepseek", 3), ("egmini", 3), ("ehrmes", 3), ("femini", 3), ("geimni", 3), ("gemiin", 3), ("gemini", 3), ("geminis", 3), ("gemnii", 3), ("germes", 3), ("gmeini", 3), ("hemres", 3), ("herems", 3), ("herme", 2), ("hermes", 3), ("hermse", 3), ("hremes", 3), ("illama", 3), ("kllama", 3), ("lmstduio", 3), ("lmstudio", 3), ("lmstudios", 3), ("lmstuido", 3), ("lmsutdio", 3), ("lmtsudio", 3), ("local llm", 7), ("localllm", 7), ("lolama", 3), ("lsmtudio", 3), ("mlstudio", 3), ("nathropic", 3), ("oepnrouter", 3), ("olalma", 3), ("ollaam", 3), ("ollama", 3), ("ollamas", 3), ("ollmaa", 3), ("openoruter", 3), ("openrouter", 3), ("openrouters", 3), ("openruoter", 3), ("opernouter", 3), ("opnerouter", 3), ("paikey", 3), ("poenrouter", 3), ("porvider", 3), ("proivder", 3), ("provdier", 3), ("provider", 3), ("providers", 3), ("proviedr", 3), ("prvoider", 3), ("qpikey", 3), ("rpovider", 3), ("seepseek", 3), ("which ai providers", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.cli",
            product: "rnitro",
            label: "Is there a command line version?",
            priority: 60,
            answer: "Yes — rNitro CLI (v0.2-cli), a btop-style terminal dashboard for when you're on SSH or don't want a menu bar app.\n\nIt shows CPU, memory, disk I/O, network, battery, and top processes. Keys: q quits, r refreshes. Use rnitro --once for one-shot JSON output.\n\nRuns on macOS and Linux, Python 3, no GUI required.",
            terms: [("ahell", 2), ("btop", 2), ("btops", 2), ("cli", 2), ("cli version", 7), ("cliversion", 7), ("cnosole", 3), ("command line", 6), ("command line version", 8), ("commandline", 3), ("conosle", 3), ("consloe", 3), ("consoel", 3), ("console", 3), ("console version", 8), ("consoles", 3), ("cosnole", 3), ("ehadless", 3), ("ehell", 2), ("etrminal", 3), ("haedless", 3), ("headelss", 3), ("headless", 3), ("headlses", 3), ("healdess", 3), ("hedaless", 3), ("hsell", 2), ("htop", 2), ("htops", 2), ("is there a cli", 8), ("is there a command line", 8), ("is there a console", 8), ("is there a shell", 8), ("is there a terminal", 8), ("ocnsole", 3), ("sehll", 2), ("shell", 2), ("shell version", 8), ("shells", 3), ("shellversion", 8), ("shlel", 2), ("ssh monitoring", 8), ("sshmonitoring", 8), ("temrinal", 3), ("terimnal", 3), ("termianl", 3), ("terminal", 3), ("terminal version", 8), ("terminals", 3), ("termnial", 3), ("treminal", 3), ("tui", 2), ("whell", 2)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.cpu",
            product: "rnitro",
            label: "What CPU information does it show?",
            priority: 60,
            answer: "rNitro shows total CPU load with a 60-second history graph, colour-coded by intensity, plus:\n\n• Per-core usage bars and clock speeds for every logical core\n• Base and boost clock estimates\n• Package power draw in watts\n• Load average\n\nOpen the Monitor tab and click any stat for a detail view.",
            terms: [("chip", 2), ("chip monitoring", 8), ("chips", 2), ("clcok", 2), ("clock", 2), ("clocks", 3), ("clokc", 2), ("coers", 2), ("colck", 2), ("core", 2), ("cores", 2), ("corse", 2), ("cpu", 2), ("cpu monitoring", 8), ("cpumonitoring", 8), ("croes", 2), ("dlock", 2), ("does it show chip usage", 8), ("does it show cpu usage", 8), ("does it show processor usage", 8), ("does it show silicon usage", 8), ("dores", 2), ("eprcore", 3), ("ghz", 2), ("islicon", 3), ("lcock", 2), ("load", 2), ("loads", 2), ("mhz", 2), ("ocres", 2), ("pecrore", 3), ("per core usage", 8), ("percoer", 3), ("percore", 3), ("percores", 3), ("percroe", 3), ("perocre", 3), ("porcessor", 3), ("prcoessor", 3), ("precore", 3), ("procesosr", 3), ("processor", 3), ("processor monitoring", 8), ("processors", 3), ("procsesor", 3), ("proecssor", 3), ("rpocessor", 3), ("siilcon", 3), ("silcion", 3), ("silicno", 3), ("silicon", 3), ("silicon monitoring", 8), ("silicons", 3), ("siliocn", 3), ("sliicon", 3), ("what chip info", 8), ("what cpu info", 8), ("what processor info", 8), ("what silicon info", 8), ("xlock", 2), ("xores", 2)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.gatekeeper",
            product: "rnitro",
            label: "macOS says the app can't be opened",
            priority: 78,
            answer: "That's macOS quarantining anything downloaded through a browser — normal for indie apps.\n\nDon't click Move to Trash. Either:\n\n1. Right-click the app → Open → Open again, or\n2. System Settings → Privacy & Security → press Open at the bottom, or\n3. In Terminal: xattr -cr ~/Applications/rNitro.app\n\nThe Terminal installer avoids this entirely — it clears the flag for you.",
            terms: [("agtekeeper", 3), ("amlware", 3), ("apple could not verify", 8), ("blcoked", 3), ("blocekd", 3), ("blockde", 3), ("blocked", 3), ("blokced", 3), ("bolcked", 3), ("cannot be opened", 8), ("cant be opened", 8), ("damaged and cant be opened", 8), ("gaetkeeper", 3), ("gateekeper", 3), ("gatekeeper", 3), ("gatekeepers", 3), ("gatekepeer", 3), ("gatkeeeper", 3), ("gtaekeeper", 3), ("lbocked", 3), ("malawre", 3), ("malwaer", 3), ("malware", 3), ("malwares", 3), ("malwrae", 3), ("mawlare", 3), ("mlaware", 3), ("move to trash", 8), ("noatrised", 3), ("noatrized", 3), ("notairsed", 3), ("notairzed", 3), ("notarised", 3), ("notarized", 3), ("notarsied", 3), ("notarzied", 3), ("notraised", 3), ("notraized", 3), ("ntoarised", 3), ("ntoarized", 3), ("nuverified", 3), ("ontarised", 3), ("ontarized", 3), ("qaurantine", 3), ("quaarntine", 3), ("quarantine", 3), ("quarantines", 3), ("quaratnine", 3), ("quarnatine", 3), ("quraantine", 3), ("unevrified", 3), ("unidentified developer", 8), ("unveirfied", 3), ("unverfiied", 3), ("unverified", 3), ("unvreified", 3), ("uqarantine", 3), ("uvnerified", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.gpu",
            product: "rnitro",
            label: "Does it monitor the GPU?",
            priority: 55,
            answer: "Yes — GPU utilisation as a percentage, with its own alert threshold.\n\nHigh GPU usage during games, video export, or Metal work is normal; the Advisor tab flags it only when it crosses the limit you set.",
            terms: [("does it show gpu", 8), ("does it show graphics", 8), ("does it show metal", 8), ("does it show video card", 8), ("emtal", 2), ("garphics", 3), ("gpu", 2), ("gpu monitoring", 8), ("gpu usage", 7), ("gpumonitoring", 8), ("gpuusage", 7), ("grahpics", 3), ("graphcis", 3), ("graphic", 3), ("graphics", 3), ("graphics monitoring", 8), ("graphics usage", 8), ("graphicsusage", 8), ("grapihcs", 3), ("grpahics", 3), ("jetal", 2), ("meatl", 2), ("metal", 2), ("metal monitoring", 8), ("metal usage", 7), ("metals", 3), ("metalusage", 7), ("metla", 2), ("mteal", 2), ("netal", 2), ("rgaphics", 3), ("video card", 5), ("video card monitoring", 8), ("video card usage", 8), ("videocard", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.install.homebrew",
            product: "rnitro",
            label: "Install rNitro with Homebrew",
            priority: 72,
            answer: "If you use Homebrew:\n\nbrew tap ilikemacos/rnitro\nbrew install rnitro\n\nThat installs the stable formula. For the latest experimental build with the full feature set, use the Terminal installer from chopstickshq.com/rnitro instead.\n\nNo Homebrew? The curl one-liner on the rNitro page works without it.",
            terms: [("brew get started rnitro", 8), ("brew install macbar", 8), ("brew install nitro", 8), ("brew install r nitro", 8), ("brew install rnitro", 8), ("brew install rnitro app", 8), ("brew installation rnitro", 8), ("brew installing rnitro", 8), ("brew set up rnitro", 8), ("brew setup rnitro", 8), ("get started with homebrew", 8), ("hmoebrew", 3), ("hoembrew", 3), ("homberew", 3), ("homeberw", 3), ("homebrew", 3), ("homebrew macbar", 8), ("homebrew nitro", 8), ("homebrew r nitro", 8), ("homebrew rnitro", 8), ("homebrew rnitro app", 8), ("homebrewnitro", 8), ("homebrews", 3), ("homerbew", 3), ("install with homebrew", 8), ("installation with homebrew", 8), ("installing with homebrew", 8), ("ohmebrew", 3), ("set up with homebrew", 8), ("setup with homebrew", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.install.macos",
            product: "rnitro",
            label: "How do I install rNitro on macOS?",
            priority: 75,
            answer: "The Terminal install is the recommended path — it installs to ~/Applications and clears the quarantine flag, so Gatekeeper never blocks it.\n\nCopy the Terminal command from chopstickshq.com/rnitro and paste it into Terminal.\n\nThe App ZIP is a fallback. Because browser downloads get macOS's quarantine flag, Gatekeeper will block it on first launch — right-click the app, choose Open, then Open again.",
            terms: [("aetup", 2), ("estup", 2), ("get started", 5), ("get started on mac", 8), ("getstarted", 3), ("how do i download rnitro", 8), ("how do i get macbar", 8), ("how do i get nitro", 8), ("how do i get r nitro", 8), ("how do i get rnitro", 8), ("how do i get rnitro app", 8), ("how do i get started rnitro", 8), ("how do i grab rnitro", 8), ("how do i install macbar", 8), ("how do i install nitro", 8), ("how do i install r nitro", 8), ("how do i install rnitro", 8), ("how do i install rnitro app", 8), ("how do i installation rnitro", 8), ("how do i installing rnitro", 8), ("how do i obtain rnitro", 8), ("how do i set up rnitro", 8), ("how do i setup rnitro", 8), ("insatll", 3), ("insatllation", 4), ("insatlling", 3), ("instalaltion", 4), ("instalilng", 3), ("install", 3), ("install on apple computer", 8), ("install on imac", 8), ("install on mac", 8), ("install on macbook", 8), ("install on macos", 8), ("install on os x", 8), ("install on osx", 8), ("installation", 4), ("installation on mac", 8), ("installations", 4), ("installing", 3), ("installing on mac", 8), ("installs", 3), ("instlal", 3), ("instlalation", 4), ("instlaling", 3), ("intsall", 3), ("intsallation", 4), ("intsalling", 3), ("isntall", 3), ("isntallation", 4), ("isntalling", 3), ("nistall", 3), ("nistallation", 4), ("nistalling", 3), ("set up", 5), ("set up on mac", 8), ("setpu", 2), ("setup", 2), ("setup on mac", 8), ("setups", 3), ("seutp", 2), ("steup", 2), ("unstall", 3), ("wetup", 2), ("which download should i pick", 8), ("which get should i pick", 8), ("which grab should i pick", 8), ("which obtain should i pick", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.intel",
            product: "rnitro",
            label: "Does it work on Intel Macs?",
            priority: 60,
            answer: "Intel Macs are no longer receiving updates. The last Intel build is v1.2.5-Beta, still downloadable from the Intel Mac tab on the rNitro page.\n\nApple Silicon (M1 and newer) gets all current development.",
            terms: [("does it work on intel", 8), ("inetl", 2), ("intel", 2), ("intel apple computer support", 8), ("intel imac support", 8), ("intel mac support", 8), ("intel macbook support", 8), ("intel macos support", 8), ("intel os x support", 8), ("intel osx support", 8), ("intels", 3), ("intle", 2), ("is intel supported", 8), ("itnel", 2), ("jntel", 2), ("nitel", 2), ("untel", 2), ("x86", 2)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.linux",
            product: "rnitro",
            label: "Is there a Linux version?",
            priority: 60,
            answer: "There's a Linux pre-release: v0.1-Linux-Beta-Pre-release-x64.\n\nIt's a GTK 4 + libadwaita desktop app needing Python 3.10+. Download the tarball or install-rNitro-linux.sh from the Linux page and run:\nbash install-rNitro-linux.sh\n\nIt installs to ~/.local/share/rnitro. Apple-only sensors (SMC, Low Power Mode) show as N/A.",
            terms: [("atrball", 3), ("buuntu", 3), ("dbeian", 3), ("debain", 3), ("debian", 3), ("debians", 3), ("debina", 3), ("dedora", 3), ("deiban", 3), ("does it work on linux", 8), ("edbian", 3), ("efdora", 3), ("fdeora", 3), ("fedoar", 3), ("fedora", 3), ("fedora support", 8), ("fedoras", 3), ("fedorasupport", 8), ("fedroa", 3), ("feodra", 3), ("gtk", 2), ("ilbadwaita", 3), ("ilnux", 2), ("kinux", 2), ("lbiadwaita", 3), ("liabdwaita", 3), ("libadawita", 3), ("libadwaita", 3), ("libadwaitas", 3), ("libawdaita", 3), ("libdawaita", 3), ("linux", 2), ("linux version", 8), ("linuxs", 3), ("linuxversion", 8), ("linxu", 2), ("liunx", 2), ("lniux", 2), ("oinux", 2), ("rarball", 3), ("sebian", 3), ("tabrall", 3), ("tarabll", 3), ("tarball", 3), ("tarballs", 3), ("tarblal", 3), ("traball", 3), ("ubnutu", 3), ("ubuntu", 3), ("ubuntu support", 8), ("ubuntus", 3), ("ubuntusupport", 8), ("ubunut", 3), ("ubutnu", 3), ("uubntu", 3), ("ybuntu", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.memory",
            product: "rnitro",
            label: "Does it monitor RAM?",
            priority: 55,
            answer: "Yes — used vs total memory in GB, a percentage, and macOS memory pressure.\n\nThe Advisor tab will tell you whether your current usage is above the RAM threshold you've set, and suggest checking Activity Monitor when it is.",
            terms: [("does it show mem", 8), ("does it show memory", 8), ("does it show ram", 8), ("emmory", 3), ("mem", 2), ("mem pressure", 8), ("mem usage", 7), ("memory", 3), ("memory pressure", 8), ("memory usage", 8), ("memoryusage", 7), ("memoyr", 3), ("mempressure", 7), ("memroy", 3), ("memusage", 7), ("meomry", 3), ("mmeory", 3), ("nemory", 3), ("ram", 2), ("ram pressure", 8), ("ram usage", 7), ("rampressure", 7), ("ramusage", 7), ("swap", 2), ("swaps", 2)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.network",
            product: "rnitro",
            label: "Does it show network speed?",
            priority: 50,
            answer: "Yes — live download and upload throughput in Mbps, sampled continuously.\n\nIt measures throughput on your active interface; it isn't a speed test, so numbers reflect what your Mac is actually transferring right now.",
            terms: [("abndwidth", 3), ("badnwidth", 3), ("bandiwdth", 3), ("bandwdith", 3), ("bandwidth", 3), ("bandwidth monitor", 8), ("bandwidths", 3), ("banwdidth", 3), ("bnadwidth", 3), ("ehternet", 3), ("entwork", 3), ("etehrnet", 3), ("ethenret", 3), ("etherent", 3), ("ethernet", 3), ("ethernets", 3), ("ethrenet", 3), ("mbp", 2), ("mbps", 2), ("netowrk", 3), ("netwokr", 3), ("network", 3), ("network speed", 8), ("networks", 3), ("networkspeed", 8), ("netwrok", 3), ("newtork", 3), ("ntework", 3), ("tehernet", 3), ("upload download speed", 8), ("upload get speed", 8), ("upload grab speed", 8), ("upload obtain speed", 8), ("wifi", 2), ("wifis", 2)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.overlay",
            product: "rnitro",
            label: "What is the game overlay / FPS HUD?",
            priority: 55,
            answer: "Press ⌥⇧O to toggle an overlay showing CPU%, GPU%, temperature and RAM on top of fullscreen games.\n\nFor true frame rates, use \"Launch App with FPS HUD\" from the right-click menu — that enables Apple's native Metal performance HUD for that game.",
            terms: [("agming", 3), ("faming", 3), ("fps", 2), ("fps counter", 7), ("fps hud", 7), ("fpscounter", 7), ("fpshud", 7), ("gaimng", 3), ("game overlay", 8), ("gameoverlay", 7), ("gamign", 3), ("gaming", 3), ("gamnig", 3), ("gmaing", 3), ("hud", 2), ("in game overlay", 8), ("oevrlay", 3), ("ovelray", 3), ("overaly", 3), ("overlay", 3), ("overlya", 3), ("ovrelay", 3), ("voerlay", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.requirements",
            product: "rnitro",
            label: "What are the system requirements?",
            priority: 60,
            answer: "rNitro needs macOS 14 (Sonoma) or later.\n\nIt uses SwiftUI APIs introduced in macOS 14, so Big Sur, Monterey, and Ventura can't run the current build. There's an info pack on the site describing the older-macOS situation.\n\nApple Silicon is the primary target; Intel builds exist but stopped receiving updates after v1.2.5-Beta.",
            terms: [("aonoma", 3), ("cmopatibility", 4), ("cmopatible", 3), ("comaptibility", 4), ("comaptible", 3), ("compaitbility", 4), ("compaitble", 3), ("compatibility", 4), ("compatible", 3), ("compatibles", 3), ("comptaibility", 4), ("comptaible", 3), ("copmatibility", 4), ("copmatible", 3), ("erquirements", 4), ("esquoia", 3), ("evntura", 3), ("minimum apple computer", 8), ("minimum imac", 8), ("minimum mac", 7), ("minimum macbook", 8), ("minimum macos", 8), ("minimum os x", 8), ("minimum osx", 7), ("minimumimac", 7), ("minimummac", 7), ("minimummacos", 8), ("minimumosx", 7), ("ocmpatibility", 4), ("ocmpatible", 3), ("osnoma", 3), ("reqiurements", 4), ("requierments", 4), ("requirement", 3), ("requirements", 4), ("requriements", 4), ("reuqirements", 4), ("rqeuirements", 4), ("seqouia", 3), ("sequioa", 3), ("sequoai", 3), ("sequoia", 3), ("sequoias", 3), ("seuqoia", 3), ("snooma", 3), ("sonmoa", 3), ("sonoam", 3), ("sonoma", 3), ("sonomas", 3), ("soonma", 3), ("spuported", 3), ("sqeuoia", 3), ("supoprted", 3), ("supporetd", 3), ("supported", 3), ("suppotred", 3), ("supproted", 3), ("system requirements", 8), ("uspported", 3), ("ventrua", 3), ("ventuar", 3), ("ventura", 3), ("venturas", 3), ("venutra", 3), ("vetnura", 3), ("vnetura", 3), ("what apple computer do i need", 8), ("what imac do i need", 8), ("what mac do i need", 8), ("what macbook do i need", 8), ("what macos do i need", 8), ("what os x do i need", 8), ("what osx do i need", 8), ("will it run on my apple computer", 8), ("will it run on my imac", 8), ("will it run on my mac", 8), ("will it run on my macbook", 8), ("will it run on my macos", 8), ("will it run on my os x", 8), ("will it run on my osx", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.safety",
            product: "rnitro",
            label: "Is rNitro safe to run?",
            priority: 55,
            answer: "The installers verify their own SHA-256 checksum before running, and refuse to continue if it doesn't match.\n\nThe full app source is included inline in the shell installers, so you can read everything before executing. rNitro is also on GitHub.\n\nNo telemetry, no account, no data collection.",
            terms: [("can i trust it", 8), ("cirus", 2), ("elgit", 2), ("firus", 2), ("frust", 2), ("is it a virus", 8), ("is it malware", 8), ("is it safe", 7), ("ivrus", 2), ("kegit", 2), ("legit", 2), ("legits", 3), ("legti", 2), ("leigt", 2), ("lgeit", 2), ("oegit", 2), ("rrust", 2), ("rtust", 2), ("rtustworthy", 3), ("safe", 2), ("safes", 2), ("trsut", 2), ("trsutworthy", 3), ("trust", 2), ("trustowrthy", 3), ("trusts", 3), ("trustworthy", 3), ("truswtorthy", 3), ("truts", 2), ("trutsworthy", 3), ("turst", 2), ("turstworthy", 3), ("virsu", 2), ("viru", 2), ("virus", 2), ("viurs", 2), ("vrius", 2)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.tabs",
            product: "rnitro",
            label: "What are the tabs in the app?",
            priority: 55,
            answer: "Click the menu bar icon to open the popover:\n\n• Monitor — live stats and detail views\n• Advisor — asks about YOUR Mac using live readings, sets alert thresholds\n• Chat — AI chat, including chopsticksAI and bring-your-own-key providers\n• Cleaner — reclaim disk space\n• Lab — experimental toys (Beta builds)\n• Settings — appearance, menu bar items, alerts",
            terms: [("celaner", 3), ("claener", 3), ("cleaenr", 3), ("cleaner", 3), ("cleaners", 3), ("cleanre", 3), ("clenaer", 3), ("lab", 2), ("lceaner", 3), ("mnoitor", 3), ("mointor", 3), ("moniotr", 3), ("monitor", 3), ("monitors", 3), ("monitro", 3), ("montior", 3), ("omnitor", 3), ("oppover", 3), ("poopver", 3), ("popoevr", 3), ("popover", 3), ("popovers", 3), ("popovre", 3), ("popvoer", 3), ("ppoover", 3), ("tab", 2), ("tabs", 2), ("what are the tabs", 8), ("what is the cleaner tab", 8), ("what is the lab tab", 8), ("what is the monitor tab", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.temperature",
            product: "rnitro",
            label: "How accurate is the temperature?",
            priority: 65,
            answer: "rNitro reads real sensor data from your Mac's SMC — the same controller iStat Menus, TG Pro, and Macs Fan Control use.\n\nIf the SMC can't be reached or your chip's sensor keys aren't recognised, it falls back to macOS's own thermal state (Nominal / Fair / Serious / Critical), smoothed using live CPU load so the gauge never goes blank.\n\nThese are informational readings, not a substitute for hardware diagnostics.",
            terms: [("aensor", 3), ("celisus", 3), ("celsisu", 3), ("celsiu", 3), ("celsius", 3), ("celsuis", 3), ("ceslius", 3), ("clesius", 3), ("degeres", 3), ("degree", 3), ("degrees", 3), ("degrese", 3), ("dergees", 3), ("dgerees", 3), ("eclsius", 3), ("edgrees", 3), ("esnsor", 3), ("etmperature", 3), ("heat", 2), ("heats", 2), ("hot", 2), ("how accurate is the celsius", 8), ("how accurate is the degrees", 8), ("how accurate is the heat", 8), ("how accurate is the hot", 8), ("how accurate is the temp", 8), ("how accurate is the temperature", 8), ("how accurate is the thermal", 8), ("htermal", 3), ("is the celsius reading real", 8), ("is the degrees reading real", 8), ("is the heat reading real", 8), ("is the hot reading real", 8), ("is the temp reading real", 8), ("is the temperature reading real", 8), ("is the thermal reading real", 8), ("segrees", 3), ("senosr", 3), ("sensor", 3), ("sensors", 3), ("sensro", 3), ("sesnor", 3), ("smc", 2), ("snesor", 3), ("tehrmal", 3), ("temeprature", 3), ("temp", 2), ("tempearture", 3), ("temperature", 3), ("temperatures", 4), ("tempreature", 3), ("temps", 2), ("tepmerature", 3), ("themral", 3), ("theraml", 3), ("thermal", 3), ("thermals", 3), ("thermla", 3), ("thremal", 3), ("tmeperature", 3), ("where does the celsius come from", 8), ("where does the degrees come from", 8), ("where does the heat come from", 8), ("where does the hot come from", 8), ("where does the temp come from", 8), ("where does the temperature come from", 8), ("where does the thermal come from", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.thresholds",
            product: "rnitro",
            label: "How do I set alerts and thresholds?",
            priority: 50,
            answer: "Advisor tab → ⚙. You can set:\n\n• Temperature warning and critical levels\n• CPU, RAM, and GPU percentage limits\n• Low-battery percentage\n• Proactive alerts on or off\n• macOS notification banners for critical temperatures\n\nAlerts have a 90-second cooldown per type so they don't spam you.",
            terms: [("abnner", 3), ("aelrt", 2), ("alert", 2), ("alert me when", 8), ("alerts", 3), ("aletr", 2), ("alret", 2), ("awrning", 3), ("banenr", 3), ("banner", 3), ("banners", 3), ("bannre", 3), ("bnaner", 3), ("custom threshold", 8), ("ganner", 3), ("htreshold", 3), ("laert", 2), ("noitfication", 4), ("notfiication", 4), ("notifciation", 4), ("notification", 4), ("notification when celsius", 8), ("notification when degrees", 8), ("notification when heat", 8), ("notification when hot", 8), ("notification when temp", 8), ("notification when temperature", 8), ("notification when thermal", 8), ("notifications", 4), ("notiifcation", 4), ("ntoification", 4), ("ontification", 4), ("qlert", 2), ("set a warning", 8), ("thershold", 3), ("threhsold", 3), ("threshold", 3), ("thresholds", 3), ("thresohld", 3), ("thrsehold", 3), ("trheshold", 3), ("vanner", 3), ("wanring", 3), ("warinng", 3), ("warnign", 3), ("warning", 3), ("warnnig", 3), ("wlert", 2), ("wraning", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.uninstall",
            product: "rnitro",
            label: "How do I uninstall rNitro?",
            priority: 60,
            answer: "macOS: quit rNitro from the menu bar, then delete rNitro.app from ~/Applications (or /Applications).\n\nTo remove settings too:\ndefaults delete com.chopsticks.rnitro\n\nLinux: rm -rf ~/.local/share/rnitro ~/.local/bin/rnitro ~/.local/share/applications/rnitro.desktop\n\nWindows: right-click the tray icon → Exit, then delete the folder you unzipped.",
            terms: [("deelte", 3), ("deleet", 3), ("delete", 3), ("delete macbar", 8), ("delete nitro", 8), ("delete r nitro", 8), ("delete rnitro", 8), ("delete rnitro app", 8), ("deletemacbar", 8), ("deletenitro", 7), ("deleternitro", 8), ("deletes", 3), ("deltee", 3), ("dleete", 3), ("edlete", 3), ("eemove", 3), ("ermove", 3), ("get rid of", 5), ("get rid of rnitro", 8), ("how do i delete", 8), ("how do i delete rnitro", 8), ("how do i get rid of", 8), ("how do i get rid of rnitro", 8), ("how do i remove", 8), ("how do i remove macbar", 8), ("how do i remove nitro", 8), ("how do i remove r nitro", 8), ("how do i remove rnitro", 8), ("how do i remove rnitro app", 8), ("how do i uninstall", 8), ("how do i uninstall rnitro", 8), ("nuinstall", 3), ("remoev", 3), ("remove", 3), ("remove rnitro", 8), ("removernitro", 8), ("removes", 3), ("remvoe", 3), ("reomve", 3), ("rmeove", 3), ("selete", 3), ("uinnstall", 3), ("uninsatll", 3), ("uninstall", 3), ("uninstall rnitro", 8), ("uninstalls", 3), ("unintsall", 3), ("unisntall", 3), ("unnistall", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.update",
            product: "rnitro",
            label: "How do updates work?",
            priority: 55,
            answer: "rNitro checks for updates when it launches and can fetch the latest build in-app.\n\nYou can also just re-run the Terminal install command — it always resolves whatever version.json lists as current, so it upgrades you in place.\n\nOld releases are kept on the Archives page.",
            terms: [("bewer", 2), ("check for updates", 8), ("enwer", 2), ("hewer", 2), ("how do i update", 8), ("how do updates work", 8), ("is there a new version", 8), ("neewr", 2), ("newer", 2), ("newers", 3), ("newre", 2), ("nweer", 2), ("pudate", 3), ("pugrade", 3), ("udpate", 3), ("ugprade", 3), ("upadte", 3), ("updaet", 3), ("update", 3), ("updates", 3), ("updtae", 3), ("upgarde", 3), ("upgrade", 3), ("upgrades", 3), ("upgraed", 3), ("upgrdae", 3), ("uprgade", 3), ("ypdate", 3)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.version",
            product: "rnitro",
            label: "What version is current?",
            priority: 55,
            answer: "The current macOS build is v1.4.0-Final.\n\nOther platforms:\n• CLI — v0.2-cli\n• Linux — v0.1 Beta pre-release\n• Windows — v6.0.2 (deprecated)\n\nThe live numbers always come from chopstickshq.com/rnitro/version.json.",
            terms: [("biuld", 2), ("buidl", 2), ("build", 2), ("builds", 3), ("bulid", 2), ("cahngelog", 7), ("chagnelog", 7), ("chaneglog", 7), ("changelog", 7), ("changelogs", 7), ("changleog", 7), ("chnagelog", 7), ("current release", 8), ("erlease", 3), ("evrsion", 3), ("guild", 2), ("hcangelog", 7), ("latest version", 8), ("latestversion", 8), ("reelase", 3), ("relaese", 3), ("releaes", 3), ("release", 3), ("releases", 3), ("relesae", 3), ("rleease", 3), ("ubild", 2), ("verison", 3), ("versino", 3), ("version", 3), ("versions", 3), ("versoin", 3), ("vesrion", 3), ("vresion", 3), ("vuild", 2), ("what version", 8), ("whats new", 7), ("whatsnew", 7), ("whatversion", 7)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.what",
            product: "rnitro",
            label: "What is rNitro?",
            priority: 70,
            answer: "rNitro is a free, open-source system monitor that lives in your Mac's menu bar.\n\nIt shows live CPU usage, temperature, memory, GPU, battery, and network — plus per-core breakdowns, a built-in benchmark, a game overlay, and an optional Bitcoin price readout.\n\nFree, no account, no telemetry. macOS 14+ (Sonoma or later).",
            terms: [("amcbar", 3), ("bitro", 2), ("enitro", 3), ("hitro", 2), ("intro", 2), ("mabcar", 3), ("macabr", 3), ("macbar", 3), ("macbars", 3), ("macbra", 3), ("mcabar", 3), ("nacbar", 3), ("nirto", 2), ("nitor", 2), ("nitro", 2), ("nitros", 3), ("nritro", 3), ("ntiro", 2), ("r nitro", 5), ("rintro", 3), ("rnirto", 3), ("rnitor", 3), ("rnitro", 3), ("rnitro app", 5), ("rnitroapp", 3), ("rnitros", 3), ("rntiro", 3), ("tell me about macbar", 8), ("tell me about nitro", 8), ("tell me about r nitro", 8), ("tell me about rnitro", 8), ("tell me about rnitro app", 8), ("what does macbar do", 8), ("what does nitro do", 8), ("what does r nitro do", 8), ("what does rnitro app do", 8), ("what does rnitro do", 8), ("what is macbar", 8), ("what is nitro", 8), ("what is r nitro", 8), ("what is rnitro", 8), ("what is rnitro app", 8)]
        ),
        ChopsticksAIIntent(
            id: "rnitro.windows",
            product: "rnitro",
            label: "Is there a Windows version?",
            priority: 60,
            answer: "Windows is no longer actively developed, but the last build stays available: v6.0.2-Windows-x64, shipped as a portable ZIP.\n\nUnzip it anywhere and run rNitro.exe — it lives in the system tray. Needs 64-bit Windows 10 or 11 and the .NET 8 Desktop Runtime. Windows 8.1 and earlier aren't supported.\n\nRun as administrator if you want CPU temperatures; Windows hides thermal sensors from unelevated apps.",
            terms: [("does it work on windows", 8), ("exe", 2), ("iwndows", 3), ("msi", 2), ("pc version", 7), ("pcversion", 7), ("tray", 2), ("widnows", 3), ("win10", 2), ("win11", 2), ("windosw", 3), ("window", 3), ("windows", 3), ("windows 11 support", 8), ("windows version", 8), ("windwos", 3), ("winodws", 3), ("wnidows", 3)]
        ),
        ChopsticksAIIntent(
            id: "shaders.what",
            product: "shaders",
            label: "What are Chopsticks Shaders?",
            priority: 60,
            answer: "Chopsticks Shaders is an Iris shader pack for Minecraft, with volumetric lighting derived from Noble.\n\nIt's licensed GPL-3.0 because of that lineage. Available from chopstickshq.com/shaders/.",
            terms: [("hsaderpack", 3), ("hsaders", 3), ("iri", 2), ("iris", 2), ("minecraft shaders", 8), ("sahderpack", 3), ("sahders", 3), ("shadeprack", 3), ("shader", 3), ("shader pack", 7), ("shaderpack", 7), ("shaderpacks", 3), ("shaders", 3), ("shadesr", 3), ("shadrepack", 3), ("shadres", 3), ("shaedrpack", 3), ("shaedrs", 3), ("shdaerpack", 3), ("shdaers", 3), ("what are the shaders", 8)]
        ),
        ChopsticksAIIntent(
            id: "trouble.checksum",
            product: "general",
            label: "The installer says checksum mismatch",
            priority: 55,
            answer: "That's the installer protecting you — it downloaded a file whose SHA-256 doesn't match what version.json publishes, so it refused to install.\n\nUsually it's a truncated or cached download. Try again; if it keeps failing, the mirror you hit may be stale. Report it at github.com/ilikemacos/rNitro/issues/new and include both hashes it printed.",
            terms: [("cehcksum", 3), ("chceksum", 3), ("checksum", 3), ("checksum mismatch", 8), ("checksums", 3), ("checkusm", 3), ("checskum", 3), ("chekcsum", 3), ("hash does not match", 8), ("hcecksum", 3), ("imsmatch", 3), ("inetgrity", 3), ("integirty", 3), ("integrity", 3), ("integrity check failed", 8), ("intergity", 3), ("intgerity", 3), ("itnegrity", 3), ("mimsatch", 3), ("misamtch", 3), ("mismacth", 3), ("mismatch", 3), ("mismatchs", 3), ("mismtach", 3), ("msimatch", 3), ("nitegrity", 3), ("sha256", 3)]
        ),
        ChopsticksAIIntent(
            id: "trouble.download.blocked",
            product: "general",
            label: "The download won't start",
            priority: 50,
            answer: "Every download shows a terms dialog first — you have to press \"I Agree & download\" for the file to start.\n\nIf nothing happens after that, try the Terminal install instead, or grab the file straight from GitHub Releases.",
            terms: [("cant download", 8), ("cant get", 7), ("cant grab", 7), ("cant obtain", 7), ("cantdownload", 8), ("cantget", 7), ("cantgrab", 7), ("cantobtain", 7), ("donwloadfail", 4), ("dowlnoadfail", 4), ("downlaodfail", 4), ("download button does nothing", 8), ("download not working", 8), ("downloadfail", 4), ("downloadfails", 4), ("downoladfail", 4), ("dwonloadfail", 4), ("get button does nothing", 8), ("get not working", 8), ("grab button does nothing", 8), ("grab not working", 8), ("obtain button does nothing", 8), ("obtain not working", 8), ("odwnloadfail", 4)]
        ),
        ChopsticksAIIntent(
            id: "trouble.high.cpu",
            product: "general",
            label: "The app itself is using CPU",
            priority: 50,
            answer: "rNitro is native Swift, not Electron — the app bundle is around 3.5 MB and idles low.\n\nIf it's using more than you'd expect, lower the refresh rate in Settings, turn off the Bitcoin ticker, and close the popover when you're not reading it — the live panel refreshes several times a second while open.",
            terms: [("app is heavy", 8), ("battery drain from the app", 8), ("charge drain from the app", 8), ("ehavy", 2), ("ersource", 3), ("geavy", 2), ("haevy", 2), ("heavy", 2), ("heayv", 2), ("hevay", 2), ("high chip usage from the app", 8), ("high cpu usage from the app", 8), ("high processor usage from the app", 8), ("high silicon usage from the app", 8), ("juice drain from the app", 8), ("power drain from the app", 8), ("reosurce", 3), ("resoruce", 3), ("resoucre", 3), ("resource", 3), ("resources", 3), ("resuorce", 3), ("rseource", 3), ("using too much chip", 8), ("using too much cpu", 8), ("using too much processor", 8), ("using too much silicon", 8), ("yeavy", 2)]
        ),
        ChopsticksAIIntent(
            id: "trouble.no.temperature",
            product: "general",
            label: "Temperature shows N/A or looks wrong",
            priority: 55,
            answer: "If the SMC sensor keys for your chip aren't recognised, rNitro falls back to macOS's thermal state and interpolates from CPU load — so the number stays plausible but isn't a direct reading.\n\nOn Windows, temperatures need administrator rights; Windows hides thermal sensors from unelevated processes.\n\nOn Linux, Apple-only sensors always show N/A.",
            terms: [("balnk", 2), ("blakn", 2), ("blank", 2), ("blanks", 3), ("blnak", 2), ("celsius is wrong", 8), ("celsius not showing", 8), ("celsius says na", 8), ("celsius shows na", 8), ("degrees is wrong", 8), ("degrees not showing", 8), ("degrees says na", 8), ("degrees shows na", 8), ("glank", 2), ("heat is wrong", 8), ("heat not showing", 8), ("heat says na", 8), ("heat shows na", 8), ("hot is wrong", 8), ("hot not showing", 8), ("hot says na", 7), ("hot shows na", 8), ("imssing", 3), ("lbank", 2), ("misisng", 3), ("missign", 3), ("missing", 3), ("missnig", 3), ("msising", 3), ("nissing", 3), ("no sensor data", 8), ("shows na", 7), ("showsna", 7), ("temp is wrong", 8), ("temp not showing", 8), ("temp says na", 8), ("temp shows na", 8), ("temperature is wrong", 8), ("temperature not showing", 8), ("temperature says na", 8), ("temperature shows na", 8), ("thermal is wrong", 8), ("thermal not showing", 8), ("thermal says na", 8), ("thermal shows na", 8), ("vlank", 2), ("zero", 2), ("zeros", 2)]
        ),
        ChopsticksAIIntent(
            id: "trouble.wont.launch",
            product: "general",
            label: "The app won't launch",
            priority: 60,
            answer: "Try in this order:\n\n1. If macOS blocked it, right-click → Open → Open again\n2. Clear the quarantine flag: xattr -cr ~/Applications/rNitro.app\n3. Confirm you're on macOS 14 or later — older versions can't run the current build\n4. Re-run the Terminal installer to get a clean copy\n\nStill stuck? Open an issue at github.com/ilikemacos/rNitro/issues/new with your macOS version and Mac model.",
            terms: [("alunch", 3), ("app crashes on launch", 8), ("app wont open", 8), ("carsh", 2), ("carshing", 3), ("crahs", 2), ("crahsing", 3), ("crash", 2), ("crashing", 3), ("crashnig", 3), ("crashs", 3), ("crasihng", 3), ("crsah", 2), ("crsahing", 3), ("drash", 2), ("dreeze", 3), ("fereze", 3), ("freeez", 3), ("freeze", 3), ("freezes", 3), ("frezee", 3), ("hang", 2), ("hangs", 2), ("kaunch", 3), ("lanuch", 3), ("laucnh", 3), ("launch", 3), ("launchs", 3), ("launhc", 3), ("luanch", 3), ("nothing happens when i click", 8), ("rcash", 2), ("rcashing", 3), ("rfeeze", 3), ("rreeze", 3), ("wont start", 7), ("wontstart", 7), ("xrash", 2)]
        ),
        ChopsticksAIIntent(
            id: "vault.what",
            product: "vault",
            label: "What is the vault?",
            priority: 55,
            answer: "The vault at chopstickshq.com/vault/ is a password-gated generator for Fathom Pro unlock keys.\n\nEach Generate mints a new random oi-pl key entirely in your browser. These are unlock tokens for Fathom Pro only — they are not cloud API keys and carry no credit.",
            terms: [("avult", 2), ("cault", 2), ("fault", 2), ("valut", 2), ("vault", 2), ("vault key generator", 8), ("vault page", 7), ("vaultpage", 7), ("vaults", 3), ("vautl", 2), ("vualt", 2), ("what is the vault", 8)]
        ),
    ]
}
