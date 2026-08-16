import AppKit
import SwiftUI

private let apiURL = URL(string: "https://chopstickshq.com/api/chopsticks-ai")!

private let starters = [
    "What is ChopsticksAI?",
    "How do I install rNitro?",
    "macOS says it can't be opened",
    "How do I unlock Fathom Pro?",
    "Explain how SSDs work",
    "Write me a haiku about Mondays",
]

private let effortTiers: [(id: String, label: String)] = [
    ("low", "Low"),
    ("medium", "Medium"),
    ("high", "High"),
    ("xhigh", "Xhigh"),
    ("xhighplus", "Xhigh+"),
    ("insane", "Insane"),
    ("chopsticks", "Chopsticks"),
    ("chopcode", "ChopCode"),
    ("stickercoderplus", "StickerCoder+"),
]

struct SearchSource: Equatable, Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let url: String
    let snippet: String?
}

struct ChatFile: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    let name: String
    let content: String
    let language: String
}

struct ChatLine: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    let role: String
    let text: String
    var sources: [SearchSource] = []
    var files: [ChatFile] = []
}

struct ChatFolder: Identifiable, Equatable, Codable {
    var id: String = UUID().uuidString
    var name: String
}

struct UsageStats: Equatable {
    var contextUsed: Int?
    var contextLimit: Int?
    var budgetUsed: Int?
    var budgetLimit: Int?
    var searched: Bool = false

    var hasAny: Bool {
        searched
            || (contextUsed != nil && (contextLimit ?? 0) > 0)
            || (budgetUsed != nil && (budgetLimit ?? 0) > 0)
    }

    var contextProgress: Double {
        guard let u = contextUsed, let l = contextLimit, l > 0 else { return 0 }
        return min(1, Double(u) / Double(l))
    }

    var allowanceProgress: Double {
        guard let u = budgetUsed, let l = budgetLimit, l > 0 else { return 0 }
        return min(1, Double(u) / Double(l))
    }

    var label: String {
        var parts: [String] = []
        if searched { parts.append("Web search") }
        if let u = contextUsed, let l = contextLimit, l > 0 {
            parts.append("Context \(Self.fmt(u))/\(Self.fmt(l))")
        }
        if let u = budgetUsed, let l = budgetLimit, l > 0 {
            parts.append("Allowance \(Self.fmt(u))/\(Self.fmt(l))")
        }
        return parts.joined(separator: " · ")
    }

    static func fmt(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fm", Double(n) / 1_000_000).replacingOccurrences(of: ".0m", with: "m") }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000).replacingOccurrences(of: ".0k", with: "k") }
        return String(n)
    }
}

struct ChatUsageBar: View {
    let stats: UsageStats
    var webSearchEnabled: Bool = true
    var resetInMs: Int = 0

    private var rowCount: Int {
        var n = 0
        if stats.searched || !webSearchEnabled { n += 1 }
        if stats.contextUsed != nil && (stats.contextLimit ?? 0) > 0 { n += 1 }
        if stats.budgetUsed != nil && (stats.budgetLimit ?? 0) > 0 { n += 1 }
        return n
    }

    var body: some View {
        VStack(spacing: rowCount > 2 ? 6 : 8) {
            searchStatusRow
                .transition(.move(edge: .top).combined(with: .opacity))

            if let used = stats.contextUsed, let limit = stats.contextLimit, limit > 0 {
                meter(
                    title: "Context",
                    used: used,
                    limit: limit,
                    progress: stats.contextProgress,
                    fill: Cursor.blue.opacity(0.85)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }

            if let used = stats.budgetUsed, let limit = stats.budgetLimit, limit > 0 {
                meter(
                    title: "Allowance",
                    used: used,
                    limit: limit,
                    progress: stats.allowanceProgress,
                    fill: allowanceColor(stats.allowanceProgress)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                if resetInMs > 0 {
                    Text("Resets at \(UsageSnapshot.fmtResetsAt(resetInMs))")
                        .font(.system(size: 10))
                        .foregroundStyle(Cursor.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: stats)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: webSearchEnabled)
    }

    @ViewBuilder
    private var searchStatusRow: some View {
        if stats.searched {
            HStack(spacing: 5) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .symbolEffect(.pulse, options: .repeating.speed(0.35))
                Text("Web search used")
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(Cursor.chromium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Cursor.chromium.opacity(0.12)))
        } else if !webSearchEnabled {
            HStack(spacing: 5) {
                Image(systemName: "globe")
                    .font(.system(size: 9, weight: .semibold))
                    .overlay {
                        Rectangle()
                            .fill(Cursor.muted.opacity(0.85))
                            .frame(width: 14, height: 1.2)
                            .rotationEffect(.degrees(-35))
                    }
                Text("Web search off")
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(Cursor.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Cursor.hover))
        }
    }

    private func allowanceColor(_ ratio: Double) -> Color {
        if ratio >= 0.95 { return Color.red.opacity(0.85) }
        if ratio >= 0.8 { return Color.orange.opacity(0.9) }
        return Cursor.soft.opacity(0.9)
    }

    private func meter(title: String, used: Int, limit: Int, progress: Double, fill: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Cursor.muted)
                Spacer()
                Text("\(UsageStats.fmt(used)) / \(UsageStats.fmt(limit))")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Cursor.soft)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Cursor.hover)
                    Capsule()
                        .fill(fill)
                        .frame(width: max(4, geo.size.width * progress))
                }
            }
            .frame(height: 6)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: progress)
        }
    }
}

struct ChatSession: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var remoteId: String?
    var title: String
    var folderId: String?
    var lines: [ChatLine]
}

@MainActor
final class ChatModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var folders: [ChatFolder] = []
    @Published var expandedFolderIds: Set<String> = []
    @Published var activeSessionId: UUID?
    @Published var draft = ""
    @Published var busy = false
    @Published var usage = UsageStats()
    @Published var offlineMode = false
    @Published var showNewFolderPrompt = false
    @Published var newFolderName = ""
    @Published var renamingFolderId: String?
    @Published var dropTargetFolderId: String? = nil
    @Published var dropTargetUnfiled = false
    @Published var selectedSessionIds: Set<UUID> = []
    @Published var selectionAnchorId: UUID? = nil

    private var folderByRemoteId: [String: String] = [:]

    private struct ChatWorkspaceStore: Codable {
        var folders: [ChatFolder]
        var sessions: [ChatSession]
        var activeSessionId: UUID?
        var expandedFolderIds: [String]
        var folderByRemoteId: [String: String]
    }

    init() {
        loadWorkspace()
        ensureSession()
    }

    func sessions(in folderId: String?) -> [ChatSession] {
        sessions.filter { $0.folderId == folderId }
    }

    func sidebarSessionIds() -> [UUID] {
        if folders.isEmpty {
            return sessions.map(\.id)
        }
        var ids: [UUID] = []
        for folder in folders {
            ids.append(contentsOf: sessions(in: folder.id).map(\.id))
        }
        ids.append(contentsOf: sessions(in: nil).map(\.id))
        return ids
    }

    func sessionsToMove(primary: UUID) -> Set<UUID> {
        if selectedSessionIds.contains(primary), selectedSessionIds.count > 1 {
            return selectedSessionIds
        }
        return [primary]
    }

    static func parseDragIds(from raw: String) -> Set<UUID> {
        Set(
            raw.split(separator: ",")
                .compactMap { UUID(uuidString: String($0)) }
        )
    }

    func dragPayload(for session: ChatSession) -> String {
        sessionsToMove(primary: session.id)
            .map(\.uuidString)
            .sorted()
            .joined(separator: ",")
    }

    func handleSessionClick(_ id: UUID) {
        let shift = NSEvent.modifierFlags.contains(.shift)
        let command = NSEvent.modifierFlags.contains(.command)

        if shift {
            let anchor = selectionAnchorId ?? activeSessionId ?? id
            let order = sidebarSessionIds()
            guard let aIdx = order.firstIndex(of: anchor),
                  let bIdx = order.firstIndex(of: id) else {
                selectSession(id)
                return
            }
            let lo = min(aIdx, bIdx)
            let hi = max(aIdx, bIdx)
            selectedSessionIds = Set(order[lo...hi])
            activeSessionId = id
            selectionAnchorId = anchor
            draft = ""
            saveWorkspace()
        } else if command {
            if selectedSessionIds.contains(id) {
                selectedSessionIds.remove(id)
                if selectedSessionIds.isEmpty {
                    selectedSessionIds = [id]
                }
            } else {
                selectedSessionIds.insert(id)
            }
            activeSessionId = id
            selectionAnchorId = id
            draft = ""
            saveWorkspace()
        } else {
            selectSession(id)
        }
    }

    func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let folder = ChatFolder(name: trimmed)
        folders.insert(folder, at: 0)
        expandedFolderIds.insert(folder.id)
        saveWorkspace()
    }

    func renameFolder(id: String, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let idx = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[idx].name = trimmed
        saveWorkspace()
    }

    func deleteFolder(id: String) {
        folders.removeAll { $0.id == id }
        expandedFolderIds.remove(id)
        for idx in sessions.indices where sessions[idx].folderId == id {
            sessions[idx].folderId = nil
        }
        folderByRemoteId = folderByRemoteId.filter { $0.value != id }
        saveWorkspace()
    }

    func toggleFolder(_ id: String) {
        if expandedFolderIds.contains(id) {
            expandedFolderIds.remove(id)
        } else {
            expandedFolderIds.insert(id)
        }
        saveWorkspace()
    }

    func moveSession(_ sessionId: UUID, to folderId: String?) {
        moveSessions([sessionId], to: folderId)
    }

    func moveSessions(_ sessionIds: Set<UUID>, to folderId: String?) {
        guard !sessionIds.isEmpty else { return }
        for sessionId in sessionIds {
            guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { continue }
            sessions[idx].folderId = folderId
            if let remote = sessions[idx].remoteId, let folderId {
                folderByRemoteId[remote] = folderId
            } else if let remote = sessions[idx].remoteId {
                folderByRemoteId.removeValue(forKey: remote)
            }
        }
        if let folderId { expandedFolderIds.insert(folderId) }
        saveWorkspace()
    }

    private func workspaceKey() -> String {
        let uid = AuthStore.shared.userId ?? "guest"
        return "chopsticksAI.chatWorkspace.\(uid)"
    }

    private func loadWorkspace() {
        guard let data = UserDefaults.standard.data(forKey: workspaceKey()),
              let store = try? JSONDecoder().decode(ChatWorkspaceStore.self, from: data) else { return }
        folders = store.folders
        sessions = store.sessions
        activeSessionId = store.activeSessionId
        expandedFolderIds = Set(store.expandedFolderIds)
        folderByRemoteId = store.folderByRemoteId
    }

    func saveWorkspace() {
        let store = ChatWorkspaceStore(
            folders: folders,
            sessions: sessions,
            activeSessionId: activeSessionId,
            expandedFolderIds: Array(expandedFolderIds),
            folderByRemoteId: folderByRemoteId
        )
        if let data = try? JSONEncoder().encode(store) {
            UserDefaults.standard.set(data, forKey: workspaceKey())
        }
    }

    private func applyFolderMap() {
        for idx in sessions.indices {
            if let remote = sessions[idx].remoteId,
               let folderId = folderByRemoteId[remote] {
                sessions[idx].folderId = folderId
            }
        }
    }

    var activeSession: ChatSession? {
        guard let id = activeSessionId else { return nil }
        return sessions.first(where: { $0.id == id })
    }

    var lines: [ChatLine] {
        activeSession?.lines ?? []
    }

    func ensureSession() {
        if sessions.isEmpty {
            let s = ChatSession(remoteId: nil, title: "New Chat", folderId: nil, lines: [welcomeLine])
            sessions = [s]
            activeSessionId = s.id
        } else if activeSessionId == nil {
            activeSessionId = sessions.first?.id
        }
    }

    func newChat(in folderId: String? = nil) {
        let s = ChatSession(remoteId: nil, title: "New Chat", folderId: folderId, lines: [welcomeLine])
        sessions.insert(s, at: 0)
        activeSessionId = s.id
        selectedSessionIds = [s.id]
        selectionAnchorId = s.id
        draft = ""
        busy = false
        if let folderId { expandedFolderIds.insert(folderId) }
        saveWorkspace()
    }

    func newChat() {
        newChat(in: nil)
    }

    func resetForAccountSwitch() {
        usage = UsageStats()
        offlineMode = false
        folders = []
        expandedFolderIds = []
        folderByRemoteId = [:]
        loadWorkspace()
        if sessions.isEmpty {
            let s = ChatSession(remoteId: nil, title: "New Chat", folderId: nil, lines: [welcomeLine])
            sessions = [s]
            activeSessionId = s.id
            selectedSessionIds = [s.id]
            selectionAnchorId = s.id
        }
        draft = ""
        busy = false
        selectedSessionIds = []
        selectionAnchorId = activeSessionId
        if let id = activeSessionId { selectedSessionIds = [id] }
    }

    func selectSession(_ id: UUID) {
        activeSessionId = id
        selectedSessionIds = [id]
        selectionAnchorId = id
        draft = ""
        saveWorkspace()
    }

    func syncActiveToCloud() async {
        guard !AppStore.shared.privacyMode else { return }
        guard AuthStore.shared.isSignedIn,
              let id = activeSessionId,
              let idx = sessions.firstIndex(where: { $0.id == id })
        else { return }
        var session = sessions[idx]
        let meaningful = session.lines.filter { $0.role == "user" || ($0.role == "assistant" && $0.text != welcomeLine.text) }
        guard !meaningful.isEmpty else { return }
        do {
            if session.remoteId == nil {
                let created = try await ChatCloud.createChat(title: session.title, tier: AppStore.shared.tier)
                session.remoteId = created.id
                sessions[idx].remoteId = created.id
                if let folderId = session.folderId {
                    folderByRemoteId[created.id] = folderId
                }
            }
            guard let remote = session.remoteId else { return }
            try await ChatCloud.saveMessages(
                chatId: remote,
                title: session.title,
                tier: AppStore.shared.tier,
                lines: session.lines.filter { $0.role == "user" || $0.role == "assistant" }
            )
        } catch { }
        saveWorkspace()
    }

    func loadCloudChats() async {
        guard AuthStore.shared.isSignedIn else { return }
        let savedFolderMap = folderByRemoteId
        let savedFolders = folders
        do {
            let remote = try await ChatCloud.listChats()
            var loaded: [ChatSession] = []
            for chat in remote.prefix(20) {
                let msgs = try await ChatCloud.loadMessages(chatId: chat.id)
                let lines: [ChatLine] = msgs.map { m in
                    let sources = m.sources.compactMap { d -> SearchSource? in
                        guard let title = d["title"] else { return nil }
                        return SearchSource(title: title, url: d["url"] ?? "", snippet: d["snippet"])
                    }
                    return ChatLine(role: m.role, text: m.content, sources: sources)
                }
                loaded.append(ChatSession(
                    remoteId: chat.id,
                    title: chat.title,
                    folderId: savedFolderMap[chat.id],
                    lines: lines.isEmpty ? [welcomeLine] : lines
                ))
            }
            if !loaded.isEmpty {
                sessions = loaded
                activeSessionId = loaded.first?.id
                folders = savedFolders
                folderByRemoteId = savedFolderMap
                applyFolderMap()
            } else {
                resetForAccountSwitch()
            }
        } catch {
            resetForAccountSwitch()
        }
        saveWorkspace()
    }

    private var welcomeLine: ChatLine {
        ChatLine(
            role: "assistant",
            text: "Hi — I'm cs.AI 2.5.4.\n\nEmail + password sign-in via chopstickshq.com. Keyword KB + Chromium search. Ask anything. Pick StickerCoder+ for coding."
        )
    }

    private func mutateActive(_ block: (inout ChatSession) -> Void) {
        guard let id = activeSessionId,
              let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        block(&sessions[idx])
    }

    func send(_ raw: String) async {
        let store = AppStore.shared
        let attach = AttachmentStore.shared
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !busy else { return }
        if attach.isUploading { return }
        let ready = attach.ready
        guard !text.isEmpty || !ready.isEmpty else { return }
        ensureSession()

        let lower = text.lowercased()
        if lower == "/compact" || lower == "/compact on" {
            store.setCompact(true)
            mutateActive { $0.lines.append(ChatLine(role: "assistant", text: "Compact mode on.")) }
            draft = ""
            return
        }
        if lower == "/compact off" {
            store.setCompact(false)
            mutateActive { $0.lines.append(ChatLine(role: "assistant", text: "Compact mode off.")) }
            draft = ""
            return
        }
        if lower == "/search" {
            let hint = store.webSearchEnabled
                ? "Type `/search` followed by your question to force a web lookup, e.g.\n/search latest Python release notes"
                : "Web search is off in Settings, but `/search …` still forces a one-off lookup.\n/search latest Python release notes"
            mutateActive {
                $0.lines.append(ChatLine(role: "assistant", text: hint))
            }
            draft = ""
            return
        }

        let display: String = {
            if ready.isEmpty { return text }
            let names = ready.map(\.name).joined(separator: ", ")
            let base = text.isEmpty ? "(attachments)" : text
            return base + "\n\n[\(ready.count) attachment\(ready.count == 1 ? "" : "s"): \(names)]"
        }()
        let prompt = text.isEmpty ? "Please review the attached files." : text

        busy = true
        mutateActive { session in
            session.lines.append(ChatLine(role: "user", text: display))
            if session.title == "New Chat" {
                session.title = String(prompt.prefix(42))
            }
        }
        draft = ""
        let payloadAttach = ready.map { a -> [String: Any] in
            var d: [String: Any] = [
                "name": a.name,
                "mime": a.mime,
                "size": a.size,
                "url": a.url ?? "",
                "path": a.path ?? "",
            ]
            if let t = a.text, !t.isEmpty { d["text"] = t }
            return d
        }
        attach.clear()
        let result = await fetchReply(for: prompt, store: store, attachments: payloadAttach)
        usage = result.usage
        offlineMode = store.offlineChatMode || store.privacyMode || !NetworkStatus.shared.isOnline
        mutateActive {
            $0.lines.append(ChatLine(role: "assistant", text: result.text, sources: result.sources, files: result.files))
        }
        busy = false
        saveWorkspace()
        await syncActiveToCloud()
    }

    private struct ReplyResult {
        let text: String
        let usage: UsageStats
        let sources: [SearchSource]
        var files: [ChatFile] = []
        var offline: Bool = false
    }

    private func searchRequest(for text: String) -> (query: String, force: Bool) {
        if text.lowercased().hasPrefix("/search ") {
            return (String(text.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines), true)
        }
        return (text, false)
    }

    private func history() -> [[String: String]] {
        let msgs = lines.filter { $0.role == "user" || $0.role == "assistant" }
            .suffix(12)
            .map { ["role": $0.role, "content": $0.text] }

        let store = AppStore.shared
        var prefix: [[String: String]] = []
        if !store.userRules.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prefix.append(["role": "system", "content": "User rules:\n\(store.userRules)"])
        }
        if let mode = store.customModes.first(where: { $0.id == store.selectedModeId }) {
            prefix.append(["role": "system", "content": "Active custom mode (\(mode.name)):\n\(mode.instructions)"])
        }
        return prefix + msgs
    }

    private func apiMessages(forcingSearch query: String) -> [[String: String]] {
        var msgs = history()
        if let last = msgs.indices.last, msgs[last]["role"] == "user" {
            msgs[last]["content"] = query
        }
        return msgs
    }

    private func kbFallback(_ text: String) -> String? {
        let result = ChopsticksAI.ask(text)
        return result.confident ? result.answer : nil
    }

    private func parseSources(_ obj: [String: Any]) -> [SearchSource] {
        guard let arr = obj["sources"] as? [[String: Any]] else { return [] }
        return arr.compactMap { item in
            guard let title = item["title"] as? String else { return nil }
            let url = item["url"] as? String ?? ""
            let snippet = item["snippet"] as? String
            return SearchSource(title: title, url: url, snippet: snippet)
        }
    }

    private func parseUsage(_ obj: [String: Any]) -> UsageStats {
        var stats = UsageStats()
        stats.searched = (obj["searched"] as? Bool) == true
        if let cw = obj["contextWindow"] as? [String: Any] {
            stats.contextUsed = cw["used"] as? Int
            stats.contextLimit = cw["limit"] as? Int
        }
        if let b = obj["budget"] as? [String: Any] {
            stats.budgetUsed = b["used"] as? Int
            stats.budgetLimit = b["limit"] as? Int
        }
        return stats
    }

    private func usesLocalKB(store: AppStore) -> Bool {
        store.offlineChatMode || store.privacyMode
    }

    private func onlineFailureMessage() -> String {
        "The live model didn’t return an answer. Try a shorter question, or send again in a few seconds."
    }

    private func requestReply(payload: [String: Any], userText: String) async -> ReplyResult? {
        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if AuthStore.shared.isSignedIn {
            if let token = try? await AuthStore.shared.ensureFreshToken() {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if let token = AuthStore.shared.session?.accessToken {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        req.timeoutInterval = 75
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let http = resp as? HTTPURLResponse
            let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let reply = (obj?["reply"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let mode = obj?["mode"] as? String
            if mode == "error" {
                return nil
            }
            guard let obj, !reply.isEmpty else {
                if http?.statusCode == 403, obj?["mode"] as? String == "auth_required" {
                    return ReplyResult(
                        text: "Sign in is required for this effort level. Open Usage or sign in with your email.",
                        usage: UsageStats(),
                        sources: [],
                        offline: false
                    )
                }
                if http?.statusCode == 429 {
                    return ReplyResult(
                        text: reply.isEmpty ? "Too many requests — wait a minute and try again." : reply,
                        usage: obj.map { parseUsage($0) } ?? UsageStats(),
                        sources: [],
                        offline: false
                    )
                }
                return nil
            }
            let stats = parseUsage(obj)
            let sources = parseSources(obj)
            let files = parseFiles(obj, reply: reply)
            AppStore.shared.applyUsage(
                obj["usage"] as? [String: Any],
                budget: obj["budget"] as? [String: Any],
                mode: obj["budgetMode"] as? String
            )
            return ReplyResult(
                text: reply,
                usage: stats,
                sources: sources,
                files: files,
                offline: false
            )
        } catch {
            return nil
        }
    }

    private func noNetworkMessage() -> String {
        "No network connection detected. Connect to Wi‑Fi or turn on Offline mode in Settings → Chat to use local product help."
    }

    private func fetchReply(for userText: String, store: AppStore, attachments: [[String: Any]] = []) async -> ReplyResult {
        if usesLocalKB(store: store) {
            if let local = kbFallback(userText) {
                let tag = store.privacyMode
                    ? "(Privacy mode · local product help only.)"
                    : "(Offline mode · local product help only.)"
                return ReplyResult(
                    text: local + "\n\n" + tag,
                    usage: UsageStats(),
                    sources: [],
                    offline: true
                )
            }
            let hint = store.privacyMode
                ? "Privacy mode is on — cs.AI stays on this Mac and does not call the cloud API. Ask a product question or turn privacy off in Settings."
                : "Offline mode is on — cs.AI uses the local product KB only. Turn it off in Settings → Chat for live answers."
            return ReplyResult(
                text: hint,
                usage: UsageStats(),
                sources: [],
                offline: true
            )
        }

        guard NetworkStatus.shared.isOnline else {
            return ReplyResult(
                text: noNetworkMessage(),
                usage: UsageStats(),
                sources: [],
                offline: false
            )
        }

        let (query, forceSearch) = searchRequest(for: userText)
        var payload: [String: Any] = [
            "messages": apiMessages(forcingSearch: query),
            "tier": store.maxMode && store.tier == "high" ? "xhigh" : store.tier,
            "mode": "agent",
            "maxTokens": tierMaxTokens(store.tier),
            "unlockKeys": store.unlockKeys,
            "enableTools": store.enableTools,
        ]
        if !forceSearch && !store.webSearchEnabled {
            payload["disableSearch"] = true
        }
        payload["onlineMode"] = true
        if !attachments.isEmpty {
            payload["attachments"] = attachments
        }
        payload["language"] = store.language

        if let result = await requestReply(payload: payload, userText: userText) {
            return result
        }
        var lite = payload
        lite["tier"] = "medium"
        lite["maxTokens"] = tierMaxTokens("medium")
        lite["disableSearch"] = true
        if let result = await requestReply(payload: lite, userText: userText) {
            return result
        }
        if forceSearch {
            var full = payload
            full.removeValue(forKey: "disableSearch")
            if let result = await requestReply(payload: full, userText: userText) {
                return result
            }
        }
        if let local = kbFallback(userText) {
            return ReplyResult(
                text: local + "\n\n(Live model unavailable — local product help.)",
                usage: UsageStats(),
                sources: [],
                offline: true
            )
        }
        return ReplyResult(
            text: onlineFailureMessage(),
            usage: UsageStats(),
            sources: [],
            offline: false
        )
    }

    private func parseFiles(_ obj: [String: Any], reply: String) -> [ChatFile] {
        var out: [ChatFile] = []
        if let arr = obj["files"] as? [[String: Any]] {
            for item in arr {
                guard let name = item["name"] as? String, !name.isEmpty else { continue }
                let content = item["content"] as? String ?? ""
                let language = item["language"] as? String ?? "text"
                out.append(ChatFile(name: name, content: content, language: language))
            }
        }
        if out.isEmpty {
            out = Self.extractFencedFiles(from: reply)
        }
        return out
    }

    static func extractFencedFiles(from text: String) -> [ChatFile] {
        var out: [ChatFile] = []
        let parts = text.components(separatedBy: "```")
        guard parts.count > 1 else { return out }
        var i = 1
        while i < parts.count {
            let block = parts[i]
            i += 2
            var lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard !lines.isEmpty else { continue }
            let head = lines.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
            let body = lines.joined(separator: "\n").trimmingCharacters(in: CharacterSet.newlines)
            guard !body.isEmpty else { continue }
            let bits = head.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            var lang = "text"
            var name = ""
            if bits.count >= 2 {
                lang = bits[0].lowercased()
                name = bits.dropFirst().joined(separator: " ")
            } else if bits.count == 1, bits[0].contains(".") {
                name = bits[0]
                lang = (name as NSString).pathExtension.lowercased()
                if lang.isEmpty { lang = "text" }
            } else if bits.count == 1 {
                lang = bits[0].lowercased()
                name = "chopsticksai-file.\(lang == "text" ? "txt" : lang)"
            } else {
                name = "chopsticksai-file.txt"
            }
            name = (name as NSString).lastPathComponent
            out.append(ChatFile(name: name, content: body, language: lang))
        }
        return out
    }

    static func proseWithoutFences(_ text: String) -> String {
        let parts = text.components(separatedBy: "```")
        var prose: [String] = []
        for (idx, part) in parts.enumerated() where idx % 2 == 0 {
            let t = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { prose.append(t) }
        }
        return prose.joined(separator: "\n\n")
    }

    private func tierMaxTokens(_ tier: String) -> Int {
        switch tier {
        case "low": return 400
        case "medium": return 600
        case "high": return 1000
        case "xhigh": return 2000
        case "xhighplus": return 3000
        case "insane": return 4000
        case "chopsticks": return 800
        case "chopcode": return 4000
        case "stickercoderplus": return 6000
        default: return 1000
        }
    }
}

struct RootShell: View {
    @ObservedObject private var store = AppStore.shared
    @StateObject private var chat = ChatModel()
    @ObservedObject private var updater = AppAutoUpdate.shared
    @ObservedObject private var auth = AuthStore.shared

    private var secondaryWidth: CGFloat {
        guard store.sidebarExpanded, store.nav != .settings else { return 0 }
        if store.nav == .agents {
            return store.compact ? 180 : 220
        }
        return store.compact ? 168 : 200
    }

    var body: some View {
        HStack(spacing: 0) {
            iconRail
            secondarySidebar
            mainPane
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: store.sidebarExpanded)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: store.nav)
        .animation(.easeInOut(duration: 0.22), value: store.compact)
        .preferredColorScheme(.dark)
        .background(Cursor.bg)
        .frame(minWidth: 980, minHeight: 640)
        .onAppear {
            store.bootstrapAccountState()
            chat.ensureSession()
            if auth.isSignedIn {
                Task { await chat.loadCloudChats() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chopsticksAIReset)) { _ in
            store.nav = .agents
            chat.newChat()
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task {
                    store.reloadForAccount(userId: auth.userId)
                    chat.resetForAccountSwitch()
                    await chat.loadCloudChats()
                    await store.refreshUsage()
                }
            } else {
                store.reloadForAccount(userId: nil)
                chat.resetForAccountSwitch()
                Task { await store.refreshUsage() }
            }
        }
        .onChange(of: auth.userId) { oldId, newId in
            guard oldId != newId else { return }
            Task {
                store.reloadForAccount(userId: newId)
                chat.resetForAccountSwitch()
                if newId != nil {
                    await chat.loadCloudChats()
                }
                await store.refreshUsage()
            }
        }
    }

    

    private var iconRail: some View {
        VStack(alignment: store.railLabels ? .leading : .center, spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    store.toggleSidebar()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: store.sidebarExpanded ? "sidebar.left" : "sidebar.right")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 20)
                        .rotationEffect(.degrees(store.sidebarExpanded ? 0 : 180))
                    if store.railLabels {
                        Text(store.sidebarExpanded ? "Hide panel" : "Show panel")
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(Cursor.soft)
                .padding(.horizontal, store.railLabels ? 10 : 0)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: store.railLabels ? .leading : .center)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Cursor.hover.opacity(0.65))
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.sidebarExpanded)
            }
            .buttonStyle(.plain)
            .help(store.sidebarExpanded ? "Collapse sidebar" : "Expand sidebar")
            .padding(.bottom, 4)

            ForEach([AppNav.agents, .search, .cloudAgents, .automations, .repos, .marketplace, .usage, .account], id: \.id) { item in
                railButton(item)
            }
            Spacer()
            railButton(.settings)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, store.railLabels ? 8 : 8)
        .frame(width: store.railLabels ? 148 : 52)
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: store.railLabels)
        .background(Cursor.rail)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Cursor.hairline).frame(width: 1)
        }
    }

    private func railButton(_ item: AppNav) -> some View {
        let selected = store.nav == item
        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                store.nav = item
                if !store.sidebarExpanded, item != .settings {
                    store.setSidebarExpanded(true)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 20)
                if store.railLabels {
                    Text(item.title)
                        .font(.system(size: 12.5, weight: selected ? .semibold : .medium))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(selected ? Cursor.text : Cursor.muted)
            .padding(.horizontal, store.railLabels ? 10 : 0)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: store.railLabels ? .leading : .center)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selected ? Cursor.selected : Color.clear)
            )
            .scaleEffect(selected ? 1.02 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: store.nav)
        }
        .buttonStyle(.plain)
        .help(item.title)
    }

    

    @ViewBuilder
    private var secondarySidebar: some View {
        ZStack(alignment: .leading) {
            if store.nav == .settings {
                EmptyView()
            } else {
                Group {
                    if store.nav == .agents {
                        agentsSidebar
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(store.nav.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Cursor.text)
                                .padding(14)
                            Text(sidebarBlurb)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Cursor.muted)
                                .padding(.horizontal, 14)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Cursor.sidebar)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(Cursor.hairline).frame(width: 1)
                        }
                    }
                }
                .frame(width: secondaryWidth > 0 ? secondaryWidth : nil, alignment: .leading)
                .opacity(store.sidebarExpanded ? 1 : 0)
                .offset(x: store.sidebarExpanded ? 0 : -12)
            }
        }
        .frame(width: secondaryWidth, alignment: .leading)
        .clipped()
    }

    private var sidebarBlurb: String {
        switch store.nav {
        case .search: return "Chromium browser · Google search"
        case .cloudAgents: return "Remote agent runs"
        case .automations: return "Schedules & event triggers"
        case .repos: return "Local repositories"
        case .marketplace: return "Plugins & extensions"
        case .usage: return "Allowance & upgrades"
        case .account: return auth.isSignedIn ? auth.email : "Sign in to sync chats"
        default: return ""
        }
    }

    private var agentsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    chat.newChat()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("New Agent")
                            .font(.system(size: 12.5, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Cursor.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Cursor.hover))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Cursor.border))
                }
                .buttonStyle(.plain)

                Button {
                    chat.newFolderName = ""
                    chat.showNewFolderPrompt = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Cursor.text)
                        .frame(width: 34, height: 34)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Cursor.hover))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Cursor.border))
                }
                .buttonStyle(.plain)
                .help("New chat file")
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ScrollView {
                LazyVStack(spacing: 2) {
                    if chat.folders.isEmpty {
                        ForEach(chat.sessions) { session in
                            chatSessionRow(session)
                        }
                    } else {
                        ForEach(chat.folders) { folder in
                            chatFolderSection(folder)
                        }

                        if !chat.sessions(in: nil).isEmpty || chat.dropTargetUnfiled {
                            VStack(spacing: 2) {
                                Text("Unfiled")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Cursor.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)
                                ForEach(chat.sessions(in: nil)) { session in
                                    chatSessionRow(session)
                                }
                                if chat.sessions(in: nil).isEmpty {
                                    Text("Drop chats here to unfile")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Cursor.muted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(chat.dropTargetUnfiled ? Cursor.blue.opacity(0.12) : Color.clear)
                            )
                            .dropDestination(for: String.self) { items, _ in
                                handleChatDrop(items, to: nil)
                            } isTargeted: { targeted in
                                chat.dropTargetUnfiled = targeted
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .dropDestination(for: String.self) { items, _ in
                guard chat.folders.isEmpty else { return false }
                return handleChatDrop(items, to: nil)
            }

            Spacer(minLength: 0)

            if chat.selectedSessionIds.count > 1 {
                HStack(spacing: 8) {
                    Text("\(chat.selectedSessionIds.count) chats selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Cursor.text)
                    Spacer()
                    if !chat.folders.isEmpty {
                        Menu {
                            ForEach(chat.folders) { folder in
                                Button(folder.name) {
                                    chat.moveSessions(chat.selectedSessionIds, to: folder.id)
                                }
                            }
                            Divider()
                            Button("Unfiled") {
                                chat.moveSessions(chat.selectedSessionIds, to: nil)
                            }
                        } label: {
                            Text("Move")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Cursor.hover.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 8) {
                if let ver = updater.updateAvailable {
                    Button("Update v\(AppAutoUpdate.display(ver))") {
                        AppAutoUpdate.shared.checkManually()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Cursor.soft)
                }
                Button {
                    store.nav = .account
                } label: {
                    Label(auth.isSignedIn ? auth.email : "Sign in to sync", systemImage: "person.crop.circle")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Cursor.muted)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                Button {
                    store.nav = .settings
                    store.settingsSection = .customize
                } label: {
                    Label("Custom Modes", systemImage: "slider.horizontal.3")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Cursor.muted)
                }
                .buttonStyle(.plain)
                Text("cs.AI \(AppAutoUpdate.shared.currentVersion)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Cursor.muted)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Cursor.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Cursor.hairline).frame(width: 1)
        }
        .alert(renamingFolderTitle, isPresented: $chat.showNewFolderPrompt) {
            TextField("Name", text: $chat.newFolderName)
            Button(renamingFolderActionTitle) {
                if let id = chat.renamingFolderId {
                    chat.renameFolder(id: id, name: chat.newFolderName)
                    chat.renamingFolderId = nil
                } else {
                    chat.createFolder(name: chat.newFolderName)
                }
            }
            Button("Cancel", role: .cancel) {
                chat.renamingFolderId = nil
            }
        } message: {
            Text(renamingFolderMessage)
        }
    }

    private var renamingFolderTitle: String {
        chat.renamingFolderId == nil ? "New chat file" : "Rename chat file"
    }

    private var renamingFolderActionTitle: String {
        chat.renamingFolderId == nil ? "Create" : "Save"
    }

    private var renamingFolderMessage: String {
        chat.renamingFolderId == nil
            ? "Create a file to organize related chats."
            : "Rename this chat file."
    }

    @ViewBuilder
    private func chatFolderSection(_ folder: ChatFolder) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Button {
                    chat.toggleFolder(folder.id)
                } label: {
                    Image(systemName: chat.expandedFolderIds.contains(folder.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Cursor.muted)
                        .frame(width: 14)
                }
                .buttonStyle(.plain)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Cursor.blue)

                Text(folder.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Cursor.text)
                    .lineLimit(1)

                Spacer()

                Button {
                    chat.newChat(in: folder.id)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Cursor.soft)
                }
                .buttonStyle(.plain)
                .help("New chat in this file")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(chat.dropTargetFolderId == folder.id ? Cursor.blue.opacity(0.14) : Color.clear)
            )
            .dropDestination(for: String.self) { items, _ in
                handleChatDrop(items, to: folder.id)
            } isTargeted: { targeted in
                if targeted {
                    chat.dropTargetFolderId = folder.id
                } else if chat.dropTargetFolderId == folder.id {
                    chat.dropTargetFolderId = nil
                }
            }
            .contextMenu {
                Button("Rename") {
                    chat.renamingFolderId = folder.id
                    chat.newFolderName = folder.name
                    chat.showNewFolderPrompt = true
                }
                Button("Delete file", role: .destructive) {
                    chat.deleteFolder(id: folder.id)
                }
            }

            if chat.expandedFolderIds.contains(folder.id) {
                ForEach(chat.sessions(in: folder.id)) { session in
                    chatSessionRow(session)
                        .padding(.leading, 18)
                }
                if chat.sessions(in: folder.id).isEmpty {
                    Text(chat.dropTargetFolderId == folder.id ? "Drop chat here" : "No chats yet")
                        .font(.system(size: 11))
                        .foregroundStyle(chat.dropTargetFolderId == folder.id ? Cursor.blue : Cursor.muted)
                        .padding(.leading, 28)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(chat.dropTargetFolderId == folder.id ? Cursor.blue.opacity(0.1) : Color.clear)
                        )
                        .padding(.leading, 8)
                        .dropDestination(for: String.self) { items, _ in
                            handleChatDrop(items, to: folder.id)
                        } isTargeted: { targeted in
                            if targeted {
                                chat.dropTargetFolderId = folder.id
                            } else if chat.dropTargetFolderId == folder.id {
                                chat.dropTargetFolderId = nil
                            }
                        }
                }
            }
        }
        .dropDestination(for: String.self) { items, _ in
            handleChatDrop(items, to: folder.id)
        } isTargeted: { targeted in
            if targeted {
                chat.dropTargetFolderId = folder.id
            } else if chat.dropTargetFolderId == folder.id {
                chat.dropTargetFolderId = nil
            }
        }
    }

    private func handleChatDrop(_ items: [String], to folderId: String?) -> Bool {
        guard let raw = items.first else { return false }
        let ids = ChatModel.parseDragIds(from: raw)
        guard !ids.isEmpty else { return false }
        chat.moveSessions(ids, to: folderId)
        return true
    }

    private func sessionRowBackground(_ session: ChatSession) -> Color {
        if chat.activeSessionId == session.id {
            return Cursor.selected
        }
        if chat.selectedSessionIds.contains(session.id) {
            return Cursor.blue.opacity(0.18)
        }
        return Color.clear
    }

    @ViewBuilder
    private func chatSessionRow(_ session: ChatSession) -> some View {
        let moveIds = chat.sessionsToMove(primary: session.id)
        let anyFiled = moveIds.contains { id in
            chat.sessions.first(where: { $0.id == id })?.folderId != nil
        }
        Button {
            chat.handleSessionClick(session.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: chat.selectedSessionIds.contains(session.id) && chat.selectedSessionIds.count > 1
                      ? "checkmark.circle.fill" : "bubble.left")
                    .font(.system(size: 11))
                    .foregroundStyle(chat.selectedSessionIds.contains(session.id) ? Cursor.blue : Cursor.soft)
                Text(session.title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Cursor.text)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(sessionRowBackground(session))
            )
        }
        .buttonStyle(.plain)
        .draggable(chat.dragPayload(for: session)) {
            HStack(spacing: 6) {
                Image(systemName: moveIds.count > 1 ? "tray.full" : "bubble.left")
                Text(moveIds.count > 1 ? "\(moveIds.count) chats" : session.title)
                    .lineLimit(1)
            }
            .font(.system(size: 12))
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.panel))
        }
        .contextMenu {
            if !chat.folders.isEmpty {
                Menu(moveIds.count > 1 ? "Move \(moveIds.count) chats to file" : "Move to file") {
                    ForEach(chat.folders) { folder in
                        Button(folder.name) {
                            chat.moveSessions(moveIds, to: folder.id)
                        }
                    }
                }
            }
            if anyFiled {
                Button(moveIds.count > 1 ? "Remove \(moveIds.count) chats from file" : "Remove from file") {
                    chat.moveSessions(moveIds, to: nil)
                }
            }
        }
    }

    @ViewBuilder
    private var mainPane: some View {
        switch store.nav {
        case .agents:
            AgentChatView(model: chat, store: store, updater: updater)
        case .search:
            ChromiumBrowserView()
        case .cloudAgents:
            CloudAgentsView()
        case .automations:
            AutomationsView(store: store)
        case .repos:
            ReposView(store: store)
        case .marketplace:
            MarketplaceView()
        case .usage:
            UsageView(store: store)
        case .account:
            AccountView(store: store) {
                Task { await chat.loadCloudChats(); store.nav = .agents }
            }
        case .settings:
            SettingsView(store: store, updater: updater)
        }
    }
}

struct AgentChatView: View {
    @ObservedObject var model: ChatModel
    @ObservedObject var store: AppStore
    @ObservedObject var updater: AppAutoUpdate
    @ObservedObject private var network = NetworkStatus.shared
    @ObservedObject private var attachments = AttachmentStore.shared
    @FocusState private var focused: Bool

    private var showEmpty: Bool { model.lines.count <= 1 && !model.busy }

    private var modeLabel: String {
        store.customModes.first(where: { $0.id == store.selectedModeId })?.name ?? "Agent"
    }

    private var effortLabel: String {
        effortTiers.first(where: { $0.id == store.tier })?.label ?? "High"
    }

    private var composerPlaceholder: String {
        if store.webSearchEnabled {
            return "Plan, search, build, or attach files…"
        }
        return "Plan, build, or attach files… (/search forces lookup)"
    }

    private var emptyTagline: String {
        store.webSearchEnabled ? "Plan, search, build anything" : "Plan and build — web search is off"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack(alignment: .bottom) {
                messageList
                if showEmpty { emptyState }
            }
            composer
        }
        .background(Cursor.bg)
        .onAppear { focused = true }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Cursor.soft)
            Text("Agent")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Cursor.text)
            Text(modeLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Cursor.muted)
            Text("·")
                .foregroundStyle(Cursor.muted)
            Text(effortLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Cursor.muted)
            if !store.webSearchEnabled {
                Text("Search off")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Cursor.muted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Cursor.hover))
                    .transition(.scale.combined(with: .opacity))
            }
            if store.offlineChatMode || store.privacyMode {
                Text(store.privacyMode ? "Privacy" : "Offline")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Cursor.soft)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Cursor.hover))
            } else if network.isOnline {
                Text("Online")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Cursor.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Cursor.hover))
            } else {
                Text("No network")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Cursor.soft)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Cursor.hover))
            }
            Spacer()
            Button {
                model.newChat()
                focused = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Cursor.muted)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("New Agent")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Cursor.bg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Cursor.hairline).frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 48)
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Cursor.hover).frame(width: 52, height: 52)
                    Image(systemName: "sparkle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Cursor.text)
                }
                Text("ChopsticksAI")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Cursor.text)
                Text(emptyTagline)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Cursor.muted)
                    .animation(.easeInOut(duration: 0.22), value: store.webSearchEnabled)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(starters, id: \.self) { s in
                    Button {
                        Task { await model.send(s) }
                    } label: {
                        Text(s)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Cursor.soft)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Cursor.panel))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Cursor.border))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.busy)
                }
            }
            .frame(maxWidth: 460)
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 140)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: store.compact ? 16 : 22) {
                    ForEach(model.lines) { line in
                        if !(showEmpty && line.role == "assistant") {
                            MessageRow(line: line, compact: store.compact).id(line.id)
                        }
                    }
                    if model.busy {
                        HStack(spacing: 10) {
                            ProgressView().controlSize(.small).tint(Cursor.soft)
                            Text("Thinking…")
                                .font(.system(size: 12.5))
                                .foregroundStyle(Cursor.muted)
                        }
                        .padding(.leading, 36)
                    }
                    Color.clear.frame(height: 12).id("bottom")
                }
                .padding(.horizontal, store.compact ? 18 : 32)
                .padding(.vertical, store.compact ? 16 : 24)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: model.lines.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: model.busy) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if model.usage.hasAny || !store.webSearchEnabled {
                ChatUsageBar(stats: model.usage, webSearchEnabled: store.webSearchEnabled, resetInMs: store.usage.resetInMs)
            }
            if !attachments.status.isEmpty {
                Text(attachments.status)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Cursor.chromium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            if !attachments.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(attachments.items) { a in
                            HStack(spacing: 6) {
                                Text(a.uploading
                                      ? "\(a.name) · \(Int(a.progress * 100))%"
                                      : (a.error != nil ? "\(a.name) · failed" : a.name))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Cursor.soft)
                                    .lineLimit(1)
                                Button {
                                    attachments.remove(a.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Cursor.muted)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Cursor.hover))
                            .overlay(Capsule().strokeBorder(Cursor.border))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                TextField(composerPlaceholder, text: $model.draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Cursor.text)
                    .lineLimit(1...10)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                    .onSubmit { Task { await model.send(model.draft) } }

                HStack(spacing: 6) {
                    Button {
                        attachments.pickFiles()
                    } label: {
                        chip(icon: "paperclip", title: "Attach")
                    }
                    .buttonStyle(.plain)
                    .help("Attach files or images (up to 500 MB, sign in)")

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            store.toggleWebSearch()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: store.webSearchEnabled ? "globe" : "globe")
                                .font(.system(size: 10, weight: .medium))
                            Text(store.webSearchEnabled ? "Search" : "Search off")
                                .font(.system(size: 11.5, weight: .medium))
                        }
                        .foregroundStyle(store.webSearchEnabled ? Cursor.chromium : Cursor.muted)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(
                                store.webSearchEnabled ? Cursor.chromium.opacity(0.14) : Cursor.hover
                            )
                        )
                        .overlay(Capsule().strokeBorder(
                            store.webSearchEnabled ? Cursor.chromium.opacity(0.35) : Cursor.border
                        ))
                    }
                    .buttonStyle(.plain)
                    .help(store.webSearchEnabled
                          ? "Automatic Chromium web search on each question. Click to turn off."
                          : "Web search is off. Click to re-enable, or use /search … for one-off lookups.")

                    Menu {
                        ForEach(store.customModes) { mode in
                            Button {
                                store.selectedModeId = mode.id
                            } label: {
                                if mode.id == store.selectedModeId {
                                    Label(mode.name, systemImage: "checkmark")
                                } else {
                                    Text(mode.name)
                                }
                            }
                        }
                        Divider()
                        Button("Manage Custom Modes…") {
                            store.nav = .settings
                            store.settingsSection = .customize
                        }
                    } label: {
                        chip(icon: "cpu", title: modeLabel)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Menu {
                        ForEach(effortTiers, id: \.id) { t in
                            Button {
                                store.setTier(t.id)
                            } label: {
                                if t.id == store.tier {
                                    Label(t.label, systemImage: "checkmark")
                                } else {
                                    Text(t.label)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(effortLabel)
                                .font(.system(size: 11.5, weight: .medium))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundStyle(Cursor.soft)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Cursor.hover))
                        .overlay(Capsule().strokeBorder(Cursor.border))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    if let repo = store.repos.first {
                        chip(icon: "externaldrive", title: repo.name)
                    }

                    Spacer(minLength: 8)

                    Button {
                        Task { await model.send(model.draft) }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(sendEnabled ? Cursor.accentFg : Cursor.muted)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(sendEnabled ? Cursor.accent : Cursor.hover))
                    }
                    .buttonStyle(.plain)
                    .disabled(!sendEnabled)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Cursor.composer))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Cursor.border))
            .shadow(color: .black.opacity(0.35), radius: 18, y: 6)
            .padding(.horizontal, store.compact ? 14 : 22)
            .padding(.bottom, 14)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 6)
        .background(Cursor.bg)
    }

    private func chip(icon: String, title: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(Cursor.soft)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Cursor.hover))
        .overlay(Capsule().strokeBorder(Cursor.border))
    }

    private var sendEnabled: Bool {
        !model.busy && !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct MessageRow: View {
    let line: ChatLine
    var compact: Bool = false
    @ObservedObject private var store = AppStore.shared
    private var isUser: Bool { line.role == "user" }

    private var displayFiles: [ChatFile] {
        if !line.files.isEmpty { return line.files }
        return ChatModel.extractFencedFiles(from: line.text)
    }

    private var assistantProse: String {
        if displayFiles.isEmpty { return line.text }
        let prose = ChatModel.proseWithoutFences(line.text)
        return prose.isEmpty ? line.text : prose
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUser ? Cursor.hover : Color.white.opacity(0.12))
                    .frame(width: 24, height: 24)
                if isUser {
                    Text("Y")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Cursor.soft)
                } else {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Cursor.text)
                }
            }

            VStack(alignment: .leading, spacing: compact ? 6 : 8) {
                Text(isUser ? "You" : "ChopsticksAI")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Cursor.muted)

                if isUser {
                    Text(line.text)
                        .font(.system(size: compact ? 13 : 13.5))
                        .foregroundStyle(Cursor.text)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Cursor.userBubble))
                } else {
                    if !assistantProse.isEmpty {
                        Text(assistantProse)
                            .font(.system(size: compact ? 13 : 13.5))
                            .foregroundStyle(Cursor.text)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !displayFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(displayFiles) { file in
                                FileCardView(file: file, compact: compact, showPreview: store.betaFilePreview)
                            }
                        }
                    }
                }

                if !isUser, !line.sources.isEmpty {
                    SourcesView(sources: line.sources, compact: compact)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FileCardView: View {
    let file: ChatFile
    var compact: Bool = false
    var showPreview: Bool = true
    @ObservedObject private var store = AppStore.shared
    @State private var status = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Cursor.soft)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.system(size: compact ? 12 : 12.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Cursor.text)
                        .lineLimit(1)
                    Text(file.language)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Cursor.muted)
                }
                Spacer()
                GhostButton(title: "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(file.content, forType: .string)
                    status = "Copied"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { status = "" }
                }
                GhostButton(title: "Save") {
                    saveFile()
                }
            }
            if showPreview {
                ScrollView {
                    Text(file.content)
                        .font(.system(size: compact ? 11 : 11.5, design: .monospaced))
                        .foregroundStyle(Cursor.soft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: compact ? 120 : 180)
            }
            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 11))
                    .foregroundStyle(Cursor.muted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Cursor.panel))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Cursor.hairline))
    }

    private func saveFile() {
        if store.confirmFileSave {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = file.name
            panel.canCreateDirectories = true
            panel.begin { resp in
                guard resp == .OK, let url = panel.url else { return }
                write(to: url)
            }
        } else {
            let safeName = sanitizeFileName(file.name)
            let url = store.resolvedWriteFolder().appendingPathComponent(safeName)
            write(to: url)
        }
    }

    private func sanitizeFileName(_ raw: String) -> String {
        var name = raw.replacingOccurrences(of: "\\", with: "/")
        name = name.split(separator: "/").last.map(String.init) ?? "file.txt"
        name = name.replacingOccurrences(of: "\0", with: "")
        name = name.replacingOccurrences(of: "..", with: "")
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-+() "))
        name = String(name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
        name = name.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if name.isEmpty { name = "file.txt" }
        return String(name.prefix(180))
    }

    private func write(to url: URL) {
        do {
            try file.content.write(to: url, atomically: true, encoding: .utf8)
            status = "Saved \(url.lastPathComponent)"
        } catch {
            status = "Save failed"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { status = "" }
    }
}

struct SourcesView: View {
    let sources: [SearchSource]
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Sources")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Cursor.muted)
            ForEach(sources) { source in
                if let link = URL(string: source.url), !source.url.isEmpty {
                    Link(source.title, destination: link)
                        .font(.system(size: compact ? 11.5 : 12))
                        .foregroundStyle(Cursor.soft)
                        .lineLimit(2)
                } else {
                    Text(source.title)
                        .font(.system(size: compact ? 11.5 : 12))
                        .foregroundStyle(Cursor.muted)
                        .lineLimit(2)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Cursor.panel))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Cursor.hairline))
    }
}

extension Notification.Name {
    static let chopsticksAIReset = Notification.Name("chopsticksAIReset")
}

@main
struct ChopsticksAIApp: App {
    @ObservedObject private var updater = AppAutoUpdate.shared
    @ObservedObject private var onboarding = OnboardingPresenter.shared

    init() {
        AppAutoUpdate.shared.configure(AppUpdateConfig(
            manifestURL: URL(string: "https://chopstickshq.com/chopsticks-ai/version.json")!,
            downloadBase: URL(string: "https://chopstickshq.com/chopsticks-ai")!,
            bundleName: "chopsticksAI.app",
            productName: "cs.AI",
            defaultsPrefix: "chopsticksAI"
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootShell()
                .sheet(isPresented: $onboarding.isPresented) {
                    OnboardingView(presenter: onboarding)
                }
                .onAppear {
                    AppAutoUpdate.shared.checkOnLaunch()
                    Onboarding.presentIfNeeded(on: onboarding)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if Onboarding.isCompleted {
                            WhatsNew.presentIfNeeded()
                        }
                    }
                }
                .onChange(of: onboarding.isPresented) { _, showing in
                    if !showing && Onboarding.isCompleted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            WhatsNew.presentIfNeeded()
                        }
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Agent") {
                    NotificationCenter.default.post(name: .chopsticksAIReset, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { AppAutoUpdate.shared.checkManually() }
                Toggle("Install Updates Automatically", isOn: $updater.autoInstall)
            }
        }
        .defaultSize(width: 1180, height: 780)
    }
}
