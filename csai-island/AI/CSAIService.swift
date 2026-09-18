import Foundation

/// Live cs.AI provider. Endpoint and model come from Settings — not compiled secrets.
final class CSAIService: AIService {
    private var task: URLSessionDataTask?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func complete(
        messages: [ChatTurn],
        streaming: Bool,
        onDelta: @escaping (String) -> Void
    ) async throws -> String {
        let settings = AppSettings.shared
        guard settings.aiEnabled else { throw AIServiceError.disabled }
        guard let url = URL(string: settings.apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.hasPrefix("http") == true else {
            throw AIServiceError.invalidEndpoint
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 55
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if streaming {
            req.setValue("text/event-stream, application/json", forHTTPHeaderField: "Accept")
        }
        let key = KeychainCredentials.read().trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }

        let apiMessages: [[String: String]] = messages.suffix(16).map { turn in
            ["role": turn.role == "assistant" ? "assistant" : "user", "content": turn.text]
        }
        var payload: [String: Any] = [
            "messages": apiMessages,
            "tier": settings.plate.tierId,
            "mode": "agent",
            "client": "macos-island",
            "disableSearch": true,
        ]
        if streaming { payload["stream"] = true }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await withCheckedThrowingContinuation { cont in
            let task = session.dataTask(with: req) { data, resp, err in
                if let urlErr = err as? URLError, urlErr.code == .cancelled {
                    cont.resume(throwing: AIServiceError.cancelled)
                    return
                }
                if let err {
                    cont.resume(throwing: AIServiceError.network(err.localizedDescription))
                    return
                }
                let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
                let data = data ?? Data()
                if status == 0 {
                    cont.resume(throwing: AIServiceError.network("No response from cs.AI."))
                    return
                }
                if status >= 400 {
                    cont.resume(throwing: AIServiceError.http(status, StreamingResponseParser.errorMessage(from: data, status: status)))
                    return
                }
                guard let reply = StreamingResponseParser.extractReply(from: data), !reply.isEmpty else {
                    cont.resume(throwing: AIServiceError.empty)
                    return
                }
                DispatchQueue.main.async { onDelta(reply) }
                cont.resume(returning: reply)
            }
            self.task = task
            task.resume()
        }
    }
}
