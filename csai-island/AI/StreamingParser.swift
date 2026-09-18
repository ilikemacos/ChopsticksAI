import Foundation

/// Parses either OpenAI-style SSE or a single JSON `{ "reply": "..." }` body.
/// Marked as a configuration layer: the live HQ function currently returns JSON.
enum StreamingResponseParser {
    static func extractReply(from data: Data) -> String? {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let reply = obj["reply"] as? String, !reply.isEmpty { return reply }
            if let error = obj["error"] as? String, !error.isEmpty { return nil }
        }
        if let text = String(data: data, encoding: .utf8) {
            return parseSSE(text)
        }
        return nil
    }

    static func parseSSE(_ text: String) -> String? {
        var chunks: [String] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let s = String(line)
            guard s.hasPrefix("data:") else { continue }
            let payload = s.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { continue }
            if let data = payload.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let reply = obj["reply"] as? String { chunks.append(reply) }
                else if let choices = obj["choices"] as? [[String: Any]],
                        let delta = choices.first?["delta"] as? [String: Any],
                        let content = delta["content"] as? String {
                    chunks.append(content)
                }
            } else if !payload.isEmpty {
                chunks.append(payload)
            }
        }
        let joined = chunks.joined()
        return joined.isEmpty ? nil : joined
    }

    static func errorMessage(from data: Data, status: Int) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let err = obj["error"] as? String { return err }
            if let reply = obj["reply"] as? String { return reply }
        }
        return String(data: data, encoding: .utf8)?.prefix(240).description ?? "HTTP \(status)"
    }
}
