import Foundation
import SwiftUI

struct RemoteModel: Identifiable, Equatable, Codable {
    var id: String
    var name: String
    var provider: String
    var context: Int?
}

@MainActor
final class MoreModelsStore: ObservableObject {
    static let shared = MoreModelsStore()

    private static let orAccount = "moreModels.openrouter"
    private static let groqAccount = "moreModels.groq"
    private static let claudeAccount = "moreModels.anthropic"
    private static let selectedKey = "chopsticksAI.moreModels.selected"

    @Published var openRouterKey = ""
    @Published var groqKey = ""
    @Published var anthropicKey = ""
    @Published var selectedModelId = ""
    @Published var filter = ""
    @Published var provider: String = "all"
    @Published var models: [RemoteModel] = []
    @Published var counts: (groq: Int, claude: Int, openrouter: Int) = (0, 0, 0)
    @Published var status = ""
    @Published var busy = false

    private init() {
        openRouterKey = Self.readKey(Self.orAccount)
        groqKey = Self.readKey(Self.groqAccount)
        anthropicKey = Self.readKey(Self.claudeAccount)
        selectedModelId = UserDefaults.standard.string(forKey: Self.selectedKey) ?? ""
    }

    var selectedLabel: String {
        if selectedModelId.isEmpty { return "" }
        if let m = models.first(where: { $0.id == selectedModelId }) {
            return m.name.isEmpty ? m.id : m.name
        }
        return selectedModelId
    }

    var filtered: [RemoteModel] {
        let q = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return models.filter { m in
            if provider != "all", m.provider != provider { return false }
            if q.isEmpty { return true }
            return m.id.lowercased().contains(q) || m.name.lowercased().contains(q)
        }
    }

    func saveKeys() {
        Self.writeKey(Self.orAccount, openRouterKey)
        Self.writeKey(Self.groqAccount, groqKey)
        Self.writeKey(Self.claudeAccount, anthropicKey)
    }

    func select(_ id: String) {
        selectedModelId = id
        UserDefaults.standard.set(id, forKey: Self.selectedKey)
    }

    func clearSelection() {
        select("")
    }

    func applyKeysToPayload(_ payload: inout [String: Any]) {
        let or = openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let g = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if or.hasPrefix("sk-or-") { payload["openRouterKey"] = or }
        if g.hasPrefix("gsk_") { payload["groqKey"] = g }
        if a.hasPrefix("sk-ant-") { payload["anthropicKey"] = a }
        let model = selectedModelId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !model.isEmpty { payload["model"] = model }
    }

    func refresh() async {
        busy = true
        status = "Loading models…"
        defer { busy = false }
        saveKeys()
        var req = URLRequest(url: URL(string: "https://chopstickshq.com/api/chopsticks-ai")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        var body: [String: Any] = ["action": "listModels"]
        applyKeysToPayload(&body)
        body.removeValue(forKey: "model")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let arr = obj?["models"] as? [[String: Any]] ?? []
            models = arr.compactMap { item in
                guard let id = item["id"] as? String, !id.isEmpty else { return nil }
                return RemoteModel(
                    id: id,
                    name: item["name"] as? String ?? id,
                    provider: item["provider"] as? String ?? "openrouter",
                    context: item["context"] as? Int
                )
            }
            if let c = obj?["counts"] as? [String: Any] {
                counts = (
                    c["groq"] as? Int ?? 0,
                    c["claude"] as? Int ?? 0,
                    c["openrouter"] as? Int ?? 0
                )
            }
            status = "\(models.count) models · Groq \(counts.groq) · Claude \(counts.claude) · OpenRouter \(counts.openrouter)"
        } catch {
            status = "Could not load models. Check the keys and try again."
        }
    }

    private static func readKey(_ account: String) -> String {
        guard let data = KeychainStore.read(account: account),
              let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }

    private static func writeKey(_ account: String, _ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainStore.delete(account: account)
        } else if let data = trimmed.data(using: .utf8) {
            KeychainStore.write(account: account, data: data)
        }
    }
}
