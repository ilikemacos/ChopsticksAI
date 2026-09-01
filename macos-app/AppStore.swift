import AppKit
import Combine
import Foundation
import SwiftUI

private let compactKey = "chopsticksAI.compact"
private let sidebarExpandedKey = "chopsticksAI.sidebarExpanded"
private let railLabelsKey = "chopsticksAI.railLabels"
private let tierKey = "chopsticksAI.tier"
private let rulesKey = "chopsticksAI.userRules"
private let modesKey = "chopsticksAI.customModes"
private let autosKey = "chopsticksAI.automations"
private let reposKey = "chopsticksAI.repos"
private let privacyModeKey = "chopsticksAI.privacyMode"
private let offlineChatModeKey = "chopsticksAI.offlineChatMode"
private let languageKey = "chopsticksAI.language"
private let autoRunKey = "chopsticksAI.autoRun"
private let maxModeKey = "chopsticksAI.maxMode"
private let enableToolsKey = "chopsticksAI.enableTools"
private let webSearchKey = "chopsticksAI.webSearchEnabled"
private let confirmFileSaveKey = "chopsticksAI.confirmFileSave"
private let defaultWriteFolderKey = "chopsticksAI.defaultWriteFolder"
private let betaFilePreviewKey = "chopsticksAI.betaFilePreview"
private let plateStyleKey = "chopsticksAI.plateStyle"
private let unlockKeysKey = "chopsticksAI.fathomProUnlockKeys"
private let apiURL = URL(string: "https://chopstickshq.com/api/chopsticks-ai")!

struct CustomMode: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var instructions: String
    var tools: [String]
}

struct AutomationItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var trigger: String
    var repo: String
    var instructions: String
    var enabled: Bool
}

struct RepoItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var path: String
    var remote: String
}

struct UsageUpgrade: Identifiable, Equatable {
    let id: String
    let keysRequired: Int
    let limit: Int
    let contextLimit: Int
    let cooldownMs: Int
    let label: String
    let detail: String
    let unlocked: Bool
}

struct UsageSnapshot: Equatable {
    var used: Int = 0
    var limit: Int = 775_000
    var contextLimit: Int = 48_000
    var cooldownMs: Int = 5 * 60 * 60 * 1000
    var retryInMs: Int = 0
    var resetInMs: Int = 0
    var blocked: Bool = false
    var warningLevel: String?
    var warningMessage: String?
    var warningPercent: Int = 0
    var keysValid: Int = 0
    var tierLabel: String = "Free"
    var tierDetail: String = "775k tokens · 48k context · resets every 5h"
    var accountPlan: String?
    var upgrades: [UsageUpgrade] = [
        UsageUpgrade(id: "credits-2", keysRequired: 2, limit: 800_000, contextLimit: 64_000, cooldownMs: 9_000_000, label: "2 Fathom Pro APIs", detail: "800k tokens · 64k context · 2h 30m cooldown", unlocked: false),
        UsageUpgrade(id: "credits-5", keysRequired: 5, limit: 900_000, contextLimit: 96_000, cooldownMs: 7_200_000, label: "5 Fathom Pro APIs", detail: "900k tokens · 96k context · 2h cooldown", unlocked: false),
        UsageUpgrade(id: "credits-10", keysRequired: 10, limit: 1_000_000, contextLimit: 128_000, cooldownMs: 3_600_000, label: "10 Fathom Pro APIs", detail: "1m tokens · 128k context · 1h cooldown", unlocked: false),
    ]
    var budgetMode: String = "—"
    var error: String?
    var kajiAllowed: Bool = false

    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(1, Double(used) / Double(limit))
    }

    var nearLimit: Bool { !blocked && progress >= 0.8 }

    static func fmtTokens(_ n: Int) -> String {
        if n >= 1_000_000 {
            let v = Double(n) / 1_000_000
            return String(format: v.rounded() == v ? "%.0fm" : "%.1fm", v)
        }
        if n >= 1000 {
            let v = Double(n) / 1000
            return String(format: v.rounded() == v ? "%.0fk" : "%.1fk", v)
        }
        return String(n)
    }

    static func fmtCooldown(_ ms: Int) -> String {
        let total = max(0, ms / 1000)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        if m > 0 { return "\(m)m" }
        return "\(total)s"
    }

    static func fmtResetsAt(_ msFromNow: Int) -> String {
        guard msFromNow > 0 else { return "soon" }
        let date = Date().addingTimeInterval(Double(msFromNow) / 1000)
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: date)
    }
}

enum CSAIEdition: String {
    case online, offline

    static var current: CSAIEdition {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "CSAIEdition") as? String ?? "online")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return raw == "offline" ? .offline : .online
    }

    var isOffline: Bool { self == .offline }
}

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published var nav: AppNav = .agents
    @Published var settingsSection: SettingsSection = .general
    @Published var compact = UserDefaults.standard.bool(forKey: compactKey)
    
    @Published var sidebarExpanded: Bool = UserDefaults.standard.object(forKey: sidebarExpandedKey) as? Bool ?? true
    
    @Published var railLabels: Bool = UserDefaults.standard.object(forKey: railLabelsKey) as? Bool ?? true
    @Published var tier: String = AppStore.normalizeTier(UserDefaults.standard.string(forKey: tierKey) ?? "tamago")
    @Published var userRules: String = UserDefaults.standard.string(forKey: rulesKey) ?? ""
    @Published var privacyMode = UserDefaults.standard.bool(forKey: privacyModeKey)
    @Published var offlineChatMode = UserDefaults.standard.bool(forKey: offlineChatModeKey)
    @Published var language: String = UserDefaults.standard.string(forKey: languageKey) ?? "en"
    @Published var autoRun = UserDefaults.standard.object(forKey: autoRunKey) as? Bool ?? true
    @Published var maxMode = UserDefaults.standard.bool(forKey: maxModeKey)
    
    @Published var enableTools: Bool = UserDefaults.standard.object(forKey: enableToolsKey) as? Bool ?? true
    
    @Published var webSearchEnabled: Bool = UserDefaults.standard.object(forKey: webSearchKey) as? Bool ?? true
    
    @Published var confirmFileSave: Bool = UserDefaults.standard.object(forKey: confirmFileSaveKey) as? Bool ?? true
    
    @Published var defaultWriteFolder: String = UserDefaults.standard.string(forKey: defaultWriteFolderKey) ?? ""
    
    @Published var betaFilePreview: Bool = UserDefaults.standard.object(forKey: betaFilePreviewKey) as? Bool ?? true
    @Published var skyPlates: Bool = UserDefaults.standard.string(forKey: plateStyleKey) != "sushi"
    @Published var customModes: [CustomMode] = []
    @Published var automations: [AutomationItem] = []
    @Published var repos: [RepoItem] = []
    @Published var selectedModeId: String?
    @Published var unlockKeys: [String] = []
    @Published var keyDraft = ""
    @Published var usage = UsageSnapshot()
    @Published var usageBusy = false
    @Published var regionUnavailable: String?
    @Published var pendingBrowserURL = ""
    @Published var kajiActivity: [String] = []
    @Published var kajiOpenedURL = ""
    @Published var kajiLastWritePath: String?
    @Published var kajiLastCommand: String?
    @Published var kajiLastCommandOk: Bool?
    @Published var kajiLastCommandOutput: String?
    @Published var whatsNewBanner: String?

    private init() {
        customModes = Self.load(modesKey) ?? [
            CustomMode(name: "Ask", instructions: "Answer questions. Prefer concise explanations. Do not edit files unless asked.", tools: ["search", "read"]),
            CustomMode(name: "Agent", instructions: "Plan and implement changes end-to-end. Use tools when needed.", tools: ["search", "read", "edit", "terminal", "write_file"]),
            CustomMode(name: "Plan", instructions: "Produce a detailed plan before coding. Wait for approval.", tools: ["search", "read"]),
        ]
        automations = Self.load(autosKey) ?? []
        repos = Self.load(reposKey) ?? []
        unlockKeys = []
        if selectedModeId == nil { selectedModeId = customModes.first(where: { $0.name == "Agent" })?.id ?? customModes.first?.id }
        if CSAIEdition.current.isOffline {
            offlineChatMode = true
            UserDefaults.standard.set(true, forKey: offlineChatModeKey)
        } else {
            offlineChatMode = false
            UserDefaults.standard.set(false, forKey: offlineChatModeKey)
        }
    }

    func bootstrapAccountState() {
        reloadForAccount(userId: AuthStore.shared.userId)
    }

    func dismissWhatsNewBanner() {
        whatsNewBanner = nil
        WhatsNew.markSeen()
    }

    func applyKajiToolResults(_ executed: [[String: Any]]) -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var chips: [String] = []
        for item in executed {
            let name = String(item["name"] as? String ?? "")
            let raw = String(item["content"] as? String ?? "")
            let json = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] ?? [:]
            let ok = json["ok"] as? Bool ?? false
            let path = String(json["path"] as? String ?? "")
            let pretty: String = {
                if path.hasPrefix(home) { return "~" + path.dropFirst(home.count) }
                return path
            }()
            let short = URL(fileURLWithPath: path).lastPathComponent
            var chip = ""
            switch name {
            case "list_dir" where ok:
                chip = "Listed \(pretty.isEmpty ? "~" : pretty)"
            case "read_file" where ok:
                chip = "Read \(short)"
            case "write_mac_file" where ok:
                chip = "Wrote \(short)"
                kajiLastWritePath = path
            case "run_command":
                let cmd = String(json["command"] as? String ?? "")
                if !cmd.isEmpty { kajiLastCommand = cmd }
                kajiLastCommandOk = ok
                let out = String(json["output"] as? String ?? "")
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let err = String(json["error"] as? String ?? "")
                if ok {
                    kajiLastCommandOutput = out.isEmpty ? "(no output)" : String(out.prefix(180))
                } else if err.contains("cancelled") {
                    kajiLastCommandOutput = "Cancelled"
                } else {
                    kajiLastCommandOutput = err.isEmpty ? "Not run" : String(err.prefix(140))
                }
                chip = ok ? "Ran in Alpine sandbox" : "Command not run"
            default:
                break
            }
            if !chip.isEmpty {
                noteKajiActivity(chip)
                chips.append(chip)
            }
        }
        return chips
    }

    func noteKajiActivity(_ line: String) {
        kajiActivity = Array(([line] + kajiActivity).prefix(6))
    }

    func setCompact(_ on: Bool) {
        compact = on
        UserDefaults.standard.set(on, forKey: compactKey)
    }

    func setSidebarExpanded(_ on: Bool) {
        sidebarExpanded = on
        UserDefaults.standard.set(on, forKey: sidebarExpandedKey)
    }

    func toggleSidebar() {
        setSidebarExpanded(!sidebarExpanded)
    }

    func setRailLabels(_ on: Bool) {
        railLabels = on
        UserDefaults.standard.set(on, forKey: railLabelsKey)
    }

    func setSkyPlates(_ on: Bool) {
        skyPlates = on
        UserDefaults.standard.set(on ? "sky" : "sushi", forKey: plateStyleKey)
    }

    static func normalizeTier(_ raw: String) -> String {
        switch raw.lowercased().replacingOccurrences(of: " ", with: "") {
        case "low", "haiku", "fast": return "rice"
        case "medium", "high", "sonnet", "chopsticks", "standard": return "tamago"
        case "xhigh", "xhighplus", "xhigh+", "opus", "pro", "ultra": return "hibachi"
        case "insane", "wagyu", "fable": return "wagyua5"
        case "a1", "wagyu-a1", "wagyu1": return "wagyua1"
        case "a2", "wagyu-a2", "wagyu2": return "wagyua2"
        case "a3", "wagyu-a3", "wagyu3": return "wagyua3"
        case "a4", "wagyu-a4", "wagyu4": return "wagyua4"
        case "a5", "wagyu-a5", "wagyu5", "3.5-air", "cs.ai3.5-air", "csai3.5-air": return "wagyua5"
        case "3.1", "cs.ai3.1", "csai3.1": return "rice"
        case "3.3-fast", "3.3fast", "cs.ai3.3-fast": return "tamago"
        case "3.3-thinking", "3.3thinking", "cs.ai3.3-thinking": return "hibachi"
        case "airii", "air2": return "wagyua1"
        case "airiii", "air3": return "wagyua2"
        case "airvi", "air6": return "wagyua3"
        case "airv", "air5": return "wagyua4"
        case "cscode-pro", "cscodepro", "cscode": return "chopcode"
        case "kaji", "grok", "grokbot", "grok-bot": return "kaji"
        default: return raw
        }
    }

    func setTier(_ id: String, syncNav: Bool = true) {
        let next = Self.normalizeTier(id)
        if syncNav, next != "kaji", nav == .kaji {
            nav = .agents
        }
        tier = next
        UserDefaults.standard.set(next, forKey: tierKey)
    }

    func setUserRules(_ text: String) {
        userRules = text
        UserDefaults.standard.set(text, forKey: rulesKey)
    }

    func setPrivacyMode(_ on: Bool) {
        privacyMode = on
        UserDefaults.standard.set(on, forKey: privacyModeKey)
    }

    func setOfflineChatMode(_ on: Bool) {
        if CSAIEdition.current.isOffline {
            offlineChatMode = true
            UserDefaults.standard.set(true, forKey: offlineChatModeKey)
            return
        }
        offlineChatMode = false
        UserDefaults.standard.set(false, forKey: offlineChatModeKey)
        _ = on
    }

    var chatUsesOnlineModel: Bool {
        !offlineChatMode
    }

    static let supportedLanguages: [(code: String, label: String)] = [
        ("en", "English"),
        ("zh", "中文"),
        ("es", "Español"),
        ("de", "Deutsch"),
        ("ko", "한국어"),
        ("ja", "日本語"),
    ]

    func setLanguage(_ code: String) {
        language = code
        UserDefaults.standard.set(code, forKey: languageKey)
    }

    func setAutoRun(_ on: Bool) {
        autoRun = on
        UserDefaults.standard.set(on, forKey: autoRunKey)
    }

    func setMaxMode(_ on: Bool) {
        maxMode = on
        UserDefaults.standard.set(on, forKey: maxModeKey)
    }

    func setEnableTools(_ on: Bool) {
        enableTools = on
        UserDefaults.standard.set(on, forKey: enableToolsKey)
    }

    func setWebSearchEnabled(_ on: Bool) {
        webSearchEnabled = on
        UserDefaults.standard.set(on, forKey: webSearchKey)
    }

    func toggleWebSearch() {
        setWebSearchEnabled(!webSearchEnabled)
    }

    func setConfirmFileSave(_ on: Bool) {
        confirmFileSave = on
        UserDefaults.standard.set(on, forKey: confirmFileSaveKey)
    }

    func setDefaultWriteFolder(_ path: String) {
        defaultWriteFolder = path
        UserDefaults.standard.set(path, forKey: defaultWriteFolderKey)
    }

    func setBetaFilePreview(_ on: Bool) {
        betaFilePreview = on
        UserDefaults.standard.set(on, forKey: betaFilePreviewKey)
    }

    
    func resolvedWriteFolder() -> URL {
        let path = defaultWriteFolder.trimmingCharacters(in: .whitespacesAndNewlines)
        let url: URL
        if path.isEmpty {
            url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/cs.AI", isDirectory: true)
        } else {
            url = URL(fileURLWithPath: path, isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func saveModes() { Self.save(modesKey, customModes) }
    func saveAutomations() { Self.save(autosKey, automations) }
    func saveRepos() { Self.save(reposKey, repos) }

    func addMode() {
        let mode = CustomMode(name: "Custom Mode", instructions: "Describe how the agent should behave.", tools: ["search", "read", "edit"])
        customModes.append(mode)
        selectedModeId = mode.id
        saveModes()
    }

    func deleteMode(_ id: String) {
        customModes.removeAll { $0.id == id }
        if selectedModeId == id { selectedModeId = customModes.first?.id }
        saveModes()
    }

    func addAutomation() {
        automations.insert(
            AutomationItem(
                name: "New Automation",
                trigger: "Schedule · Daily 9:00",
                repo: repos.first?.name ?? "Select repo",
                instructions: "Describe what the agent should do when this runs.",
                enabled: true
            ),
            at: 0
        )
        saveAutomations()
    }

    func deleteAutomation(_ id: String) {
        automations.removeAll { $0.id == id }
        saveAutomations()
    }

    func addRepo(url: URL) {
        let name = url.lastPathComponent
        var remote = ""
        let gitConfig = url.appendingPathComponent(".git/config")
        if let text = try? String(contentsOf: gitConfig, encoding: .utf8) {
            for line in text.components(separatedBy: .newlines) {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("url = ") {
                    remote = String(t.dropFirst(6))
                    break
                }
            }
        }
        repos.insert(RepoItem(name: name, path: url.path, remote: remote), at: 0)
        saveRepos()
    }

    func removeRepo(_ id: String) {
        repos.removeAll { $0.id == id }
        saveRepos()
    }

    func pickRepoFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add Repository"
        panel.message = "Choose a local git repository"
        if panel.runModal() == .OK, let url = panel.url {
            addRepo(url: url)
        }
    }

    func saveUnlockKeys() {
        Self.saveUnlockKeys(unlockKeys, for: AuthStore.shared.userId)
    }

    func reloadForAccount(userId: String?) {
        unlockKeys = Self.loadUnlockKeys(for: userId)
        keyDraft = ""
        usage = UsageSnapshot()
    }

    private static func unlockStorageAccount(for userId: String?) -> String {
        if let userId, !userId.isEmpty { return "\(unlockKeysKey).\(userId)" }
        return "\(unlockKeysKey).guest"
    }

    private static func loadUnlockKeys(for userId: String? = nil) -> [String] {
        let key = unlockStorageAccount(for: userId)
        if let keys: [String] = load(key) { return keys }
        if userId == nil, let legacy: [String] = load(unlockKeysKey) {
            save(key, legacy)
            UserDefaults.standard.removeObject(forKey: unlockKeysKey)
            return legacy
        }
        return []
    }

    private static func saveUnlockKeys(_ keys: [String], for userId: String?) {
        save(unlockStorageAccount(for: userId), keys)
    }

    @discardableResult
    func redeemKeyDraft() -> String? {
        let raw = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "Paste a Fathom Pro oi-pl key." }
        if raw.lowercased().hasPrefix("sk-or-") || raw.lowercased().hasPrefix("sk-") {
            return "OpenRouter / provider keys are not accepted. Use a Fathom Pro oi-pl unlock key."
        }
        guard raw.lowercased().hasPrefix("oi-pl") else {
            return "That doesn’t look like a Fathom Pro API key (oi-pl…)."
        }
        let normalized = raw.lowercased()
        if unlockKeys.contains(where: { $0.lowercased() == normalized }) {
            return "That key is already redeemed."
        }
        unlockKeys.append(raw)
        keyDraft = ""
        saveUnlockKeys()
        return nil
    }

    func removeUnlockKey(_ key: String) {
        unlockKeys.removeAll { $0 == key }
        saveUnlockKeys()
    }

    static let regionUnavailableFallback =
        "cs.AI is currently unavailable in Brazil while we complete regional privacy, data-processing, and compliance requirements."

    static func regionUnavailableMessage(obj: [String: Any]?, status: Int?) -> String? {
        if (obj?["code"] as? String) == "region_unavailable" {
            let err = (obj?["error"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return err.isEmpty ? regionUnavailableFallback : err
        }
        if status == 451 {
            let err = (obj?["error"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return err.isEmpty ? regionUnavailableFallback : err
        }
        return nil
    }

    func noteRegionUnavailable(_ message: String) {
        regionUnavailable = message
        usage.error = message
    }

    func refreshUsage() async {
        usageBusy = true
        defer { usageBusy = false }
        usage.error = nil
        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 20
        var payload: [String: Any] = [
            "action": "usage",
            "unlockKeys": unlockKeys,
        ]
        if let token = try? await AuthStore.shared.ensureFreshToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let token = AuthStore.shared.session?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let http = resp as? HTTPURLResponse
            let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            if let msg = Self.regionUnavailableMessage(obj: obj, status: http?.statusCode) {
                noteRegionUnavailable(msg)
                return
            }
            guard let http, http.statusCode == 200, let obj else {
                usage.error = "Could not reach chopstickshq.com for usage."
                return
            }
            applyUsage(obj["usage"] as? [String: Any], budget: obj["budget"] as? [String: Any], mode: obj["budgetMode"] as? String)
        } catch {
            usage.error = "Network error loading usage."
        }
    }

    func applyUsage(_ u: [String: Any]?, budget: [String: Any]?, mode: String?) {
        var snap = usage
        snap.error = nil
        if let budget {
            snap.used = budget["used"] as? Int ?? snap.used
            snap.limit = budget["limit"] as? Int ?? snap.limit
        }
        guard let u else {
            usage = snap
            return
        }
        snap.used = u["used"] as? Int ?? snap.used
        snap.limit = u["limit"] as? Int ?? snap.limit
        snap.contextLimit = u["contextLimit"] as? Int ?? snap.contextLimit
        snap.cooldownMs = u["cooldownMs"] as? Int ?? snap.cooldownMs
        snap.resetInMs = u["resetInMs"] as? Int ?? snap.resetInMs
        snap.keysValid = u["keysValid"] as? Int ?? snap.keysValid
        if let tier = u["tier"] as? [String: Any] {
            snap.tierLabel = tier["label"] as? String ?? snap.tierLabel
            snap.tierDetail = tier["detail"] as? String ?? snap.tierDetail
            if let cl = tier["contextLimit"] as? Int { snap.contextLimit = cl }
        }
        if let account = u["account"] as? [String: Any] {
            snap.accountPlan = account["plan"] as? String
        }
        if let cool = u["cooldown"] as? [String: Any] {
            snap.blocked = (cool["blocked"] as? Bool) == true
            snap.retryInMs = cool["retryInMs"] as? Int ?? 0
        } else {
            snap.blocked = false
            snap.retryInMs = 0
        }
        if let warn = u["warning"] as? [String: Any] {
            snap.warningLevel = warn["level"] as? String
            snap.warningMessage = warn["message"] as? String
            snap.warningPercent = warn["percent"] as? Int ?? Int(snap.progress * 100)
        } else {
            snap.warningLevel = nil
            snap.warningMessage = nil
            snap.warningPercent = 0
        }
        if let arr = u["upgrades"] as? [[String: Any]] {
            snap.upgrades = arr.compactMap { item in
                guard let id = item["id"] as? String,
                      let keysRequired = item["keysRequired"] as? Int,
                      let limit = item["limit"] as? Int,
                      let label = item["label"] as? String,
                      let detail = item["detail"] as? String
                else { return nil }
                return UsageUpgrade(
                    id: id,
                    keysRequired: keysRequired,
                    limit: limit,
                    contextLimit: item["contextLimit"] as? Int ?? 0,
                    cooldownMs: item["cooldownMs"] as? Int ?? 0,
                    label: label,
                    detail: detail,
                    unlocked: (item["unlocked"] as? Bool) == true
                )
            }
        } else {
            snap.upgrades = snap.upgrades.map { up in
                UsageUpgrade(
                    id: up.id,
                    keysRequired: up.keysRequired,
                    limit: up.limit,
                    contextLimit: up.contextLimit,
                    cooldownMs: up.cooldownMs,
                    label: up.label,
                    detail: up.detail,
                    unlocked: snap.keysValid >= up.keysRequired
                )
            }
        }
        snap.budgetMode = mode ?? (u["budgetMode"] as? String) ?? snap.budgetMode
        if let kaji = u["kaji"] as? [String: Any] {
            snap.kajiAllowed = (kaji["allowed"] as? Bool) == true
        }
        usage = snap
    }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ key: String, _ value: T) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
