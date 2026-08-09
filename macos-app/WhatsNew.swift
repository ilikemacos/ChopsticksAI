import SwiftUI
import AppKit

/// Shows changelog.json once after each version bump.
@MainActor
enum WhatsNew {
    private static let seenKey = "chopsticksAI.whatsNew.seenVersion"
    private static let changelogURL = URL(string: "https://chopstickshq.com/chopsticks-ai/changelog.json")!

    struct Entry: Decodable {
        let version: String
        let date: String?
        let title: String?
        let changes: [String]?
    }

    struct Payload: Decodable {
        let latest: String?
        let product: String?
        let entries: [Entry]?
    }

    static func presentIfNeeded() {
        Task { await checkAndPresent() }
    }

    static func presentManually() {
        Task { await fetchAndShow(force: true) }
    }

    private static func checkAndPresent() async {
        await fetchAndShow(force: false)
    }

    private static func fetchAndShow(force: Bool) async {
        let current = AppAutoUpdate.shared.currentVersion
        let seen = UserDefaults.standard.string(forKey: seenKey) ?? ""
        if !force, normalize(seen) == normalize(current), !seen.isEmpty {
            return
        }

        do {
            let (data, resp) = try await URLSession.shared.data(from: changelogURL)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            guard let entries = payload.entries, !entries.isEmpty else { return }

            let cv = normalize(current)
            let match = entries.first { e in
                let ev = normalize(e.version)
                return ev == cv || cv.hasPrefix(ev) || ev.hasPrefix(cv) || cv.contains(ev) || ev.contains(cv)
            } ?? entries.first
            guard let entry = match else { return }

            await MainActor.run {
                showAlert(entry: entry, product: payload.product ?? "cs.AI")
                UserDefaults.standard.set(current, forKey: seenKey)
            }
        } catch {
            // Offline / first install — skip quietly.
        }
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "cs.ai ", with: "")
            .replacingOccurrences(of: "v", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func showAlert(entry: Entry, product: String) {
        let alert = NSAlert()
        alert.messageText = "What’s new in \(entry.version)"
        let bullets = (entry.changes ?? []).map { "• \($0)" }.joined(separator: "\n")
        var info = entry.title ?? product
        if let date = entry.date, !date.isEmpty { info += " · \(date)" }
        if !bullets.isEmpty { info += "\n\n\(bullets)" }
        alert.informativeText = info
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
