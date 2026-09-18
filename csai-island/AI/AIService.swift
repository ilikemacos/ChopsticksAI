import Foundation

struct ChatTurn: Identifiable, Equatable, Codable {
    let id: UUID
    var role: String
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), role: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

enum AIServiceError: LocalizedError, Equatable {
    case disabled
    case invalidEndpoint
    case network(String)
    case empty
    case cancelled
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .disabled: return "cs.AI is turned off in Settings."
        case .invalidEndpoint: return "The cs.AI endpoint is not a valid URL."
        case .network(let s): return s
        case .empty: return "cs.AI returned an empty reply."
        case .cancelled: return "Stopped."
        case .http(let c, let s): return "cs.AI error \(c): \(s)"
        }
    }
}

protocol AIService: AnyObject {
    func complete(
        messages: [ChatTurn],
        streaming: Bool,
        onDelta: @escaping (String) -> Void
    ) async throws -> String
    func cancel()
}
