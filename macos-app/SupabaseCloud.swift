import Combine
import Foundation

enum SupabasePublic {
    static let url = URL(string: "https://bohvvkpvnnqigfdcuhnp.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvaHZ2a3B2bm5xaWdmZGN1aG5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1Njk3NjEsImV4cCI6MjEwMTE0NTc2MX0.oVanbpY_NPRGG9B4YIHNx1cYbnZddpDCMpYDsumtl2s"
    static let sessionKey = "chopsticksAI.supabase.session"
}

struct CloudUser: Codable, Equatable {
    var id: String
    var email: String?
}

struct CloudAuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Int
    var user: CloudUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

struct CloudChat: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var client: String?
    var tier: String?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, client, tier
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CloudMessage: Codable, Equatable {
    var role: String
    var content: String
    var sources: [[String: String]]
    var seq: Int
}

@MainActor
final class AuthStore: ObservableObject {
    static let shared = AuthStore()

    @Published private(set) var session: CloudAuthSession?
    @Published private(set) var userId: String?
    @Published var statusMessage = ""
    @Published var busy = false

    var isSignedIn: Bool { session != nil }
    var email: String { session?.user.email ?? "" }

    private init() {
        restore()
        userId = session?.user.id
    }

    func restore() {
        if let data = KeychainStore.read(account: SupabasePublic.sessionKey),
           let s = try? JSONDecoder().decode(CloudAuthSession.self, from: data) {
            session = s
            userId = s.user.id
            return
        }
        guard let data = UserDefaults.standard.data(forKey: SupabasePublic.sessionKey),
              let s = try? JSONDecoder().decode(CloudAuthSession.self, from: data)
        else { return }
        session = s
        userId = s.user.id
        persist()
        UserDefaults.standard.removeObject(forKey: SupabasePublic.sessionKey)
    }

    private func persist() {
        if let session, let data = try? JSONEncoder().encode(session) {
            KeychainStore.write(account: SupabasePublic.sessionKey, data: data)
        } else {
            KeychainStore.delete(account: SupabasePublic.sessionKey)
        }
    }

    func signUp(email: String, password: String) async throws {
        busy = true
        defer { busy = false }
        if session != nil {
            await signOut()
        }
        let body: [String: Any] = ["email": email, "password": password]
        let obj = try await authRequest("/auth/v1/signup", method: "POST", body: body, authed: false)
        if let access = obj["access_token"] as? String {
            try applyTokenResponse(obj, access: access)
            statusMessage = "Account created."
        } else if obj["user"] != nil {
            statusMessage = "Check your email to confirm, then sign in."
        } else if let nested = obj["session"] as? [String: Any], let access = nested["access_token"] as? String {
            try applyTokenResponse(nested, access: access, userOverride: obj["user"] as? [String: Any])
            statusMessage = "Account created."
        } else {
            throw URLError(.userAuthenticationRequired)
        }
    }

    func signIn(email: String, password: String) async throws {
        busy = true
        defer { busy = false }
        let body: [String: Any] = ["email": email, "password": password]
        let obj = try await authRequest("/auth/v1/token?grant_type=password", method: "POST", body: body, authed: false)
        guard let access = obj["access_token"] as? String else {
            throw URLError(.userAuthenticationRequired)
        }
        try applyTokenResponse(obj, access: access)
        statusMessage = "Signed in."
    }

    func signOut() async {
        busy = true
        defer { busy = false }
        _ = try? await authRequest("/auth/v1/logout", method: "POST", body: [:], authed: true)
        session = nil
        userId = nil
        persist()
        statusMessage = "Signed out."
    }

    func ensureFreshToken() async throws -> String {
        guard let s = session else { throw URLError(.userAuthenticationRequired) }
        let expMs = Double(s.expiresAt) * 1000
        if expMs > Date().timeIntervalSince1970 * 1000 + 60_000 {
            return s.accessToken
        }
        let obj = try await authRequest(
            "/auth/v1/token?grant_type=refresh_token",
            method: "POST",
            body: ["refresh_token": s.refreshToken],
            authed: false
        )
        guard let access = obj["access_token"] as? String else {
            session = nil
            userId = nil
            persist()
            throw URLError(.userAuthenticationRequired)
        }
        try applyTokenResponse(obj, access: access)
        return session!.accessToken
    }

    private func applyTokenResponse(_ obj: [String: Any], access: String, userOverride: [String: Any]? = nil) throws {
        guard let refresh = obj["refresh_token"] as? String else {
            throw URLError(.badServerResponse)
        }
        let expiresIn = obj["expires_in"] as? Int ?? 3600
        let expiresAt = obj["expires_at"] as? Int ?? Int(Date().timeIntervalSince1970) + expiresIn
        let userObj = userOverride ?? (obj["user"] as? [String: Any])
        guard let uid = userObj?["id"] as? String else {
            throw URLError(.badServerResponse)
        }
        let email = userObj?["email"] as? String
        session = CloudAuthSession(
            accessToken: access,
            refreshToken: refresh,
            expiresAt: expiresAt,
            user: CloudUser(id: uid, email: email)
        )
        userId = uid
        persist()
    }

    private func authRequest(_ path: String, method: String, body: [String: Any], authed: Bool) async throws -> [String: Any] {
        guard let url = URL(string: SupabasePublic.url.absoluteString + path) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(SupabasePublic.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authed, let token = session?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            req.setValue("Bearer \(SupabasePublic.anonKey)", forHTTPHeaderField: "Authorization")
        }
        if method != "GET" {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard (200..<300).contains(http.statusCode) else {
            let msg = obj["error_description"] as? String
                ?? obj["msg"] as? String
                ?? obj["message"] as? String
                ?? obj["error"] as? String
                ?? "Request failed (\(http.statusCode))"
            throw NSError(domain: "SupabaseAuth", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return obj
    }
}

@MainActor
enum ChatCloud {
    static func listChats() async throws -> [CloudChat] {
        let token = try await AuthStore.shared.ensureFreshToken()
        let path = "chats?select=id,title,client,tier,created_at,updated_at&order=updated_at.desc&limit=50"
        let data = try await rest(path, method: "GET", token: token)
        return try JSONDecoder().decode([CloudChat].self, from: data)
    }

    static func createChat(title: String, tier: String?) async throws -> CloudChat {
        let token = try await AuthStore.shared.ensureFreshToken()
        guard let uid = AuthStore.shared.session?.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        var body: [String: Any] = [
            "user_id": uid,
            "title": title,
            "client": "macos",
        ]
        if let tier { body["tier"] = tier }
        let data = try await rest(
            "chats",
            method: "POST",
            token: token,
            body: body,
            prefer: "return=representation"
        )
        let rows = try JSONDecoder().decode([CloudChat].self, from: data)
        guard let first = rows.first else { throw URLError(.badServerResponse) }
        return first
    }

    static func updateChat(id: String, title: String?, tier: String?) async throws {
        let token = try await AuthStore.shared.ensureFreshToken()
        var body: [String: Any] = ["updated_at": isoNow()]
        if let title { body["title"] = title }
        if let tier { body["tier"] = tier }
        _ = try await rest(
            "chats?id=eq.\(id)",
            method: "PATCH",
            token: token,
            body: body
        )
    }

    static func deleteChat(id: String) async throws {
        let token = try await AuthStore.shared.ensureFreshToken()
        _ = try await rest("chats?id=eq.\(id)", method: "DELETE", token: token)
    }

    static func loadMessages(chatId: String) async throws -> [CloudMessage] {
        let token = try await AuthStore.shared.ensureFreshToken()
        let path = "chat_messages?chat_id=eq.\(chatId)&select=role,content,sources,seq&order=seq.asc"
        let data = try await rest(path, method: "GET", token: token)
        
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr.compactMap { row in
            guard let role = row["role"] as? String,
                  let content = row["content"] as? String,
                  let seq = row["seq"] as? Int
            else { return nil }
            var sources: [[String: String]] = []
            if let src = row["sources"] as? [[String: Any]] {
                sources = src.map { item in
                    var out: [String: String] = [:]
                    if let t = item["title"] as? String { out["title"] = t }
                    if let u = item["url"] as? String { out["url"] = u }
                    if let s = item["snippet"] as? String { out["snippet"] = s }
                    return out
                }
            }
            return CloudMessage(role: role, content: content, sources: sources, seq: seq)
        }
    }

    static func saveMessages(chatId: String, title: String, tier: String?, lines: [ChatLine]) async throws {
        let token = try await AuthStore.shared.ensureFreshToken()
        try await updateChat(id: chatId, title: title, tier: tier)
        _ = try await rest("chat_messages?chat_id=eq.\(chatId)", method: "DELETE", token: token)
        let rows: [[String: Any]] = lines.enumerated().map { idx, line in
            let sources: [[String: String]] = line.sources.map { s in
                var d = ["title": s.title]
                if !s.url.isEmpty { d["url"] = s.url }
                if let sn = s.snippet { d["snippet"] = sn }
                return d
            }
            return [
                "chat_id": chatId,
                "role": line.role == "user" ? "user" : "assistant",
                "content": String(line.text.prefix(100_000)),
                "sources": sources,
                "seq": idx,
            ]
        }
        guard !rows.isEmpty else { return }
        for start in stride(from: 0, to: rows.count, by: 40) {
            let end = min(start + 40, rows.count)
            let chunk = Array(rows[start..<end])
            _ = try await rest(
                "chat_messages",
                method: "POST",
                token: token,
                body: chunk,
                prefer: "return=minimal"
            )
        }
    }

    private static func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func rest(
        _ path: String,
        method: String,
        token: String,
        body: Any? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        let url = URL(string: SupabasePublic.url.absoluteString + "/rest/v1/" + path)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(SupabasePublic.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "REST error"
            throw NSError(domain: "ChatCloud", code: (resp as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return data
    }
}
