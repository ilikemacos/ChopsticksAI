import Foundation
import AppKit
import UniformTypeIdentifiers

struct PendingAttachment: Identifiable, Equatable {
    let id: String
    var name: String
    var mime: String
    var size: Int64
    var path: String?
    var url: String?
    var text: String?
    var uploading: Bool = false
    var progress: Double = 0
    var error: String?
}

enum AttachLimits {
    static let maxBatch: Int64 = 500 * 1024 * 1024 
    static let textPreview = 200_000
    static let bucket = "cs-ai-attachments"
}

@MainActor
final class AttachmentStore: ObservableObject {
    static let shared = AttachmentStore()

    @Published var items: [PendingAttachment] = []
    @Published var status = ""

    var batchBytes: Int64 { items.reduce(0) { $0 + $1.size } }
    var isUploading: Bool { items.contains { $0.uploading } }
    var ready: [PendingAttachment] { items.filter { $0.url != nil && $0.error == nil } }

    func clear() { items = []; status = "" }

    func remove(_ id: String) {
        items.removeAll { $0.id == id }
    }

    func pickFiles() {
        guard AuthStore.shared.isSignedIn else {
            status = "Sign in (Account) to attach files up to 500 MB."
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Attach"
        panel.message = "Choose files or images (up to 500 MB total)"
        guard panel.runModal() == .OK else { return }
        Task { await enqueue(urls: panel.urls) }
    }

    func enqueue(urls: [URL]) async {
        guard AuthStore.shared.isSignedIn else {
            status = "Sign in (Account) to attach files up to 500 MB."
            return
        }
        var add: Int64 = 0
        for url in urls {
            guard let vals = try? url.resourceValues(forKeys: [.fileSizeKey]),
                  let sz = vals.fileSize else { continue }
            add += Int64(sz)
        }
        if batchBytes + add > AttachLimits.maxBatch {
            status = "Batch would exceed 500 MB — remove some files."
            return
        }

        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { continue }
            let size = Int64(data.count)
            guard size > 0, size <= AttachLimits.maxBatch else { continue }
            let name = url.lastPathComponent
            let mime = Self.mime(for: url) ?? "application/octet-stream"
            let item = PendingAttachment(
                id: UUID().uuidString,
                name: name,
                mime: mime,
                size: size,
                uploading: true
            )
            items.append(item)
            let text = Self.textPreview(data: data, name: name, mime: mime)
            let itemId = item.id
            do {
                guard let session = AuthStore.shared.session else {
                    throw NSError(domain: "cs.AI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
                }
                let up = try await StorageUpload.upload(
                    data: data,
                    fileName: name,
                    mime: mime,
                    userId: session.user.id,
                    accessToken: session.accessToken
                ) { [weak self] p in
                    Task { @MainActor in
                        guard let self else { return }
                        if let i = self.items.firstIndex(where: { $0.id == itemId }) {
                            self.items[i].progress = p
                        }
                    }
                }
                if let i = items.firstIndex(where: { $0.id == itemId }) {
                    items[i].uploading = false
                    items[i].progress = 1
                    items[i].path = up.path
                    items[i].url = up.signedURL
                    items[i].text = text
                }
            } catch {
                if let i = items.firstIndex(where: { $0.id == itemId }) {
                    items[i].uploading = false
                    items[i].error = error.localizedDescription
                }
            }
        }
        status = items.contains(where: { $0.error != nil })
            ? "Some uploads failed"
            : (items.isEmpty ? "" : "\(items.count) attachment(s) ready")
    }

    private static func mime(for url: URL) -> String? {
        if #available(macOS 11.0, *) {
            if let t = UTType(filenameExtension: url.pathExtension) {
                return t.preferredMIMEType
            }
        }
        return nil
    }

    private static func textPreview(data: Data, name: String, mime: String) -> String? {
        let lower = name.lowercased()
        let texty = mime.hasPrefix("text/") ||
            lower.hasSuffix(".txt") || lower.hasSuffix(".md") || lower.hasSuffix(".json") ||
            lower.hasSuffix(".js") || lower.hasSuffix(".ts") || lower.hasSuffix(".py") ||
            lower.hasSuffix(".swift") || lower.hasSuffix(".html") || lower.hasSuffix(".css") ||
            lower.hasSuffix(".csv") || lower.hasSuffix(".yml") || lower.hasSuffix(".yaml") ||
            lower.hasSuffix(".sh") || lower.hasSuffix(".toml")
        guard texty, data.count <= 512 * 1024 else { return nil }
        guard let s = String(data: data, encoding: .utf8) else { return nil }
        return String(s.prefix(AttachLimits.textPreview))
    }
}

enum StorageUpload {
    struct Result {
        let path: String
        let signedURL: String
    }

    static func upload(
        data: Data,
        fileName: String,
        mime: String,
        userId: String,
        accessToken: String,
        onProgress: @escaping (Double) -> Void
    ) async throws -> Result {
        let safe = fileName.replacingOccurrences(of: #"[^\w.\-()+ ]+"#, with: "_", options: .regularExpression)
        let path = "\(userId)/\(String(Int(Date().timeIntervalSince1970), radix: 36))-\(safe.prefix(180))"
        if data.count > 5 * 1024 * 1024 {
            try await tusUpload(data: data, path: path, mime: mime, token: accessToken, onProgress: onProgress)
        } else {
            guard let url = storageObjectURL(path: path) else {
                throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Bad upload URL"])
            }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue(SupabasePublic.anonKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            req.setValue(mime, forHTTPHeaderField: "Content-Type")
            req.setValue("true", forHTTPHeaderField: "x-upsert")
            req.httpBody = data
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
            }
            onProgress(1)
        }

        let signed = try await sign(path: path, token: accessToken)
        return Result(path: path, signedURL: signed)
    }

    private static func storageObjectURL(path: String) -> URL? {
        let enc = path.split(separator: "/").map {
            String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0)
        }.joined(separator: "/")
        return URL(string: "\(SupabasePublic.url.absoluteString)/storage/v1/object/\(AttachLimits.bucket)/\(enc)")
    }

    private static func sign(path: String, token: String) async throws -> String {
        let enc = path.split(separator: "/").map {
            String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0)
        }.joined(separator: "/")
        guard let url = URL(string: "\(SupabasePublic.url.absoluteString)/storage/v1/object/sign/\(AttachLimits.bucket)/\(enc)") else {
            throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Bad sign URL"])
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabasePublic.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["expiresIn": 86400])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let signed = obj["signedURL"] as? String
        else {
            throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not sign URL"])
        }
        if signed.hasPrefix("http") { return signed }
        return SupabasePublic.url.appendingPathComponent("storage/v1").absoluteString
            + (signed.hasPrefix("/") ? signed : "/\(signed)")
    }

    
    private static func tusUpload(
        data: Data,
        path: String,
        mime: String,
        token: String,
        onProgress: @escaping (Double) -> Void
    ) async throws {
        guard let endpoint = URL(string: "\(SupabasePublic.url.absoluteString)/storage/v1/upload/resumable") else {
            throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Bad TUS endpoint"])
        }
        func b64(_ s: String) -> String {
            Data(s.utf8).base64EncodedString()
        }
        let meta = [
            "bucketName \(b64(AttachLimits.bucket))",
            "objectName \(b64(path))",
            "contentType \(b64(mime))",
            "cacheControl \(b64("3600"))",
        ].joined(separator: ",")

        var create = URLRequest(url: endpoint)
        create.httpMethod = "POST"
        create.setValue("1.0.0", forHTTPHeaderField: "Tus-Resumable")
        create.setValue(String(data.count), forHTTPHeaderField: "Upload-Length")
        create.setValue(meta, forHTTPHeaderField: "Upload-Metadata")
        create.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        create.setValue(SupabasePublic.anonKey, forHTTPHeaderField: "apikey")
        create.setValue("true", forHTTPHeaderField: "x-upsert")
        create.setValue("0", forHTTPHeaderField: "Content-Length")

        let (_, createResp) = try await URLSession.shared.data(for: create)
        guard let http = createResp as? HTTPURLResponse,
              let loc = http.value(forHTTPHeaderField: "Location") ?? http.value(forHTTPHeaderField: "location")
        else {
            throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "TUS create failed"])
        }
        let uploadURL: URL
        if let abs = URL(string: loc), abs.scheme != nil {
            uploadURL = abs
        } else if let rel = URL(string: loc, relativeTo: SupabasePublic.url)?.absoluteURL {
            uploadURL = rel
        } else {
            throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "TUS location invalid"])
        }

        let chunk = 6 * 1024 * 1024
        var offset = 0
        while offset < data.count {
            let end = min(offset + chunk, data.count)
            let slice = data.subdata(in: offset..<end)
            var patch = URLRequest(url: uploadURL)
            patch.httpMethod = "PATCH"
            patch.setValue("1.0.0", forHTTPHeaderField: "Tus-Resumable")
            patch.setValue(String(offset), forHTTPHeaderField: "Upload-Offset")
            patch.setValue("application/offset+octet-stream", forHTTPHeaderField: "Content-Type")
            patch.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            patch.setValue(SupabasePublic.anonKey, forHTTPHeaderField: "apikey")
            patch.httpBody = slice
            let (_, patchResp) = try await URLSession.shared.data(for: patch)
            guard let phttp = patchResp as? HTTPURLResponse, (200...299).contains(phttp.statusCode) else {
                throw NSError(domain: "cs.AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "TUS patch failed"])
            }
            offset = end
            onProgress(Double(offset) / Double(data.count))
        }
    }
}
