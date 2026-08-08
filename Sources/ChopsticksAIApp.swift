import SwiftUI

private let apiURL = URL(string: "https://chopstickshq.com/api/chopsticks-ai")!
private let compactKey = "chopsticksAI.compact"

private let starters = [
    "What is chopsticksAI?",
    "How do I install rNitro?",
    "macOS says it can't be opened",
    "How do I unlock Fathom Pro?",
    "Explain how SSDs work",
    "Write me a haiku about Mondays",
]

struct ChatLine: Identifiable, Equatable {
    let id = UUID()
    let role: String
    let text: String
}

struct UsageStats: Equatable {
    var contextUsed: Int?
    var contextLimit: Int?
    var budgetUsed: Int?
    var budgetLimit: Int?

    var label: String {
        var parts: [String] = []
        if let u = contextUsed, let l = contextLimit, l > 0 {
            parts.append("Context \(Self.fmt(u))/\(Self.fmt(l))")
        }
        if let u = budgetUsed, let l = budgetLimit, l > 0 {
            parts.append("Allowance \(Self.fmt(u))/\(Self.fmt(l))")
        }
        return parts.joined(separator: " · ")
    }

    private static func fmt(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fm", Double(n) / 1_000_000).replacingOccurrences(of: ".0m", with: "m") }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000).replacingOccurrences(of: ".0k", with: "k") }
        return String(n)
    }
}

@MainActor
final class ChatModel: ObservableObject {
    @Published var lines: [ChatLine] = []
    @Published var draft = ""
    @Published var busy = false
    @Published var usage = UsageStats()
    @Published var compact = UserDefaults.standard.bool(forKey: compactKey)

    func reset() {
        lines = [welcomeLine]
        draft = ""
        busy = false
    }

    func setCompact(_ on: Bool) {
        compact = on
        UserDefaults.standard.set(on, forKey: compactKey)
    }

    private var welcomeLine: ChatLine {
        ChatLine(
            role: "assistant",
            text: "Hi, I'm chopsticksAI.\n\nAsk me anything — general questions, code, writing, or anything about the Chopsticks apps. Type /compact for a tighter layout."
        )
    }

    func send(_ raw: String) async {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !busy else { return }

        let lower = text.lowercased()
        if lower == "/compact" || lower == "/compact on" {
            setCompact(true)
            lines.append(ChatLine(role: "assistant", text: "Compact mode on."))
            draft = ""
            return
        }
        if lower == "/compact off" {
            setCompact(false)
            lines.append(ChatLine(role: "assistant", text: "Compact mode off."))
            draft = ""
            return
        }

        busy = true
        lines.append(ChatLine(role: "user", text: text))
        draft = ""
        let (reply, stats) = await fetchReply(for: text)
        usage = stats
        lines.append(ChatLine(role: "assistant", text: reply))
        busy = false
    }

    private func history() -> [[String: String]] {
        lines.filter { $0.role == "user" || $0.role == "assistant" }
            .suffix(12)
            .map { ["role": $0.role, "content": $0.text] }
    }

    private func kbFallback(_ text: String) -> String? {
        let result = ChopsticksAI.ask(text)
        return result.confident ? result.answer : nil
    }

    private func parseUsage(_ obj: [String: Any]) -> UsageStats {
        var stats = UsageStats()
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

    private func fetchReply(for userText: String) async -> (String, UsageStats) {
        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["messages": history(), "tier": "ultra"])

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
                  let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let reply = obj["reply"] as? String,
                  !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return (kbFallback(userText) ?? offlineMessage, UsageStats())
            }
            let stats = parseUsage(obj)
            let mode = obj["mode"] as? String ?? "live"
            if mode != "live", let local = kbFallback(userText) {
                return (local, stats)
            }
            if mode == "error", let local = kbFallback(userText) {
                return (local, stats)
            }
            return (reply, stats)
        } catch {
            return (kbFallback(userText) ?? offlineMessage, UsageStats())
        }
    }

    private var offlineMessage: String {
        "I couldn't reach chopstickshq.com just now. Check your connection and try again."
    }
}

struct ChatView: View {
    @StateObject private var model = ChatModel()
    @ObservedObject private var updater = AppAutoUpdate.shared
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messageList
            if model.lines.count <= 1, !model.compact { starterChips }
            Divider()
            inputBar
        }
        .frame(
            minWidth: model.compact ? 360 : 420,
            minHeight: model.compact ? 480 : 560
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { if model.lines.isEmpty { model.reset() } }
        .onReceive(NotificationCenter.default.publisher(for: .chopsticksAIReset)) { _ in
            model.reset()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: model.compact ? 2 : 4) {
            HStack {
                Text("chopsticksAI")
                    .font(.system(size: model.compact ? 15 : 18, weight: .semibold))
                Spacer()
                if let ver = updater.updateAvailable {
                    Button("Update v\(AppAutoUpdate.display(ver))") {
                        AppAutoUpdate.shared.checkManually()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
                }
                Button(model.compact ? "Compact" : "Comfort") {
                    model.setCompact(!model.compact)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
            }
            Text("LIVE · NO KEY · /compact")
                .font(.system(size: model.compact ? 9 : 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(1.1)
            if !model.usage.label.isEmpty {
                Text(model.usage.label)
                    .font(.system(size: model.compact ? 9 : 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, model.compact ? 12 : 18)
        .padding(.vertical, model.compact ? 10 : 14)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: model.compact ? 6 : 10) {
                    ForEach(model.lines) { line in
                        MessageBubble(line: line, compact: model.compact).id(line.id)
                    }
                    if model.busy {
                        Text("Thinking…")
                            .font(.system(size: model.compact ? 12 : 13))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, model.compact ? 10 : 14)
                    }
                }
                .padding(model.compact ? 10 : 16)
            }
            .onChange(of: model.lines.count) { _, _ in
                if let last = model.lines.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var starterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(starters, id: \.self) { s in
                    Button(s) { Task { await model.send(s) } }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 999)
                                .strokeBorder(Color.secondary.opacity(0.35))
                        )
                        .disabled(model.busy)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var inputBar: some View {
        HStack(spacing: model.compact ? 8 : 10) {
            TextField("Ask me anything…", text: $model.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($focused)
                .onSubmit { Task { await model.send(model.draft) } }
            Button("Ask") { Task { await model.send(model.draft) } }
                .disabled(model.busy || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(model.compact ? 10 : 14)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct MessageBubble: View {
    let line: ChatLine
    var compact: Bool = false
    private var isUser: Bool { line.role == "user" }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: compact ? 40 : 56) }
            Text(line.text)
                .font(.system(size: compact ? 12.5 : 13.5))
                .lineSpacing(compact ? 2 : 3)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, compact ? 10 : 12)
                .padding(.vertical, compact ? 7 : 9)
                .background(
                    RoundedRectangle(cornerRadius: compact ? 9 : 11)
                        .fill(isUser ? Color.primary : Color(nsColor: .controlBackgroundColor))
                )
                .foregroundStyle(isUser ? Color(nsColor: .windowBackgroundColor) : Color.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 9 : 11)
                        .strokeBorder(isUser ? Color.clear : Color.secondary.opacity(0.25))
                )
            if !isUser { Spacer(minLength: compact ? 40 : 56) }
        }
    }
}

extension Notification.Name {
    static let chopsticksAIReset = Notification.Name("chopsticksAIReset")
}

@main
struct ChopsticksAIApp: App {
    @ObservedObject private var updater = AppAutoUpdate.shared

    init() {
        AppAutoUpdate.shared.configure(AppUpdateConfig(
            manifestURL: URL(string: "https://chopstickshq.com/chopsticks-ai/macos-version.json")!,
            downloadBase: URL(string: "https://chopstickshq.com/chopsticks-ai")!,
            bundleName: "chopsticksAI.app",
            productName: "chopsticksAI",
            defaultsPrefix: "chopsticksAI"
        ))
    }

    var body: some Scene {
        WindowGroup {
            ChatView()
                .onAppear { AppAutoUpdate.shared.checkOnLaunch() }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New conversation") {
                    NotificationCenter.default.post(name: .chopsticksAIReset, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { AppAutoUpdate.shared.checkManually() }
                Toggle("Install Updates Automatically", isOn: $updater.autoInstall)
            }
        }
        .defaultSize(width: 480, height: 720)
    }
}
