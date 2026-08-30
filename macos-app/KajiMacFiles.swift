import Foundation
import AppKit

enum KajiMacFiles {
    private static let maxRead = 80_000
    private static let maxWrite = 500_000
    private static let blocked: [String] = [
        "/.ssh/", "/Library/Keychains", "/Library/Mail/",
        "/private/var/", "/System/", "/usr/", "/bin/", "/sbin/",
    ]

    static func run(_ calls: [[String: Any]]) async -> [[String: Any]] {
        var out: [[String: Any]] = []
        for call in calls {
            let id = String(call["id"] as? String ?? "")
            let name = String(call["name"] as? String ?? "")
            let rawArgs = call["arguments"] as? String ?? "{}"
            let args = (try? JSONSerialization.jsonObject(with: Data(rawArgs.utf8))) as? [String: Any] ?? [:]
            let result: [String: Any]
            if name == "run_command" {
                result = await KajiLinuxGuest.run(command: args["command"] as? String ?? "")
            } else {
                result = execute(name: name, args: args)
            }
            let payload = (try? JSONSerialization.data(withJSONObject: result)) ?? Data("{}".utf8)
            out.append([
                "id": id,
                "name": name,
                "content": String(data: payload, encoding: .utf8) ?? "{}",
            ])
        }
        return out
    }

    private static func execute(name: String, args: [String: Any]) -> [String: Any] {
        switch name {
        case "list_dir":
            return listDir(args["path"] as? String ?? "~")
        case "read_file":
            return readFile(args["path"] as? String ?? "")
        case "write_mac_file":
            return writeFile(args["path"] as? String ?? "", content: args["content"] as? String ?? "")
        default:
            return ["ok": false, "error": "unknown tool"]
        }
    }

    private static func allowedRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return [home, desktop, docs, downloads].compactMap { $0?.standardizedFileURL }
    }

    private static func resolve(_ raw: String) -> URL? {
        let expanded = (raw as NSString).expandingTildeInPath
        guard !expanded.isEmpty else { return nil }
        let url = URL(fileURLWithPath: expanded).resolvingSymlinksInPath().standardizedFileURL
        let path = url.path
        if blocked.contains(where: { path.contains($0) }) { return nil }
        let roots = allowedRoots()
        guard roots.contains(where: { path == $0.path || path.hasPrefix($0.path + "/") }) else { return nil }
        return url
    }

    private static func listDir(_ raw: String) -> [String: Any] {
        guard let url = resolve(raw) else {
            return ["ok": false, "error": "path not allowed (use ~, Desktop, Documents, or Downloads)"]
        }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return ["ok": false, "error": "not a folder"]
        }
        guard let items = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles]) else {
            return ["ok": false, "error": "could not list"]
        }
        let listing = items.prefix(80).map { u -> String in
            let dir = (try? u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            return (dir ? "dir " : "file ") + u.lastPathComponent
        }
        return ["ok": true, "path": url.path, "entries": listing]
    }

    private static func readFile(_ raw: String) -> [String: Any] {
        guard let url = resolve(raw) else {
            return ["ok": false, "error": "path not allowed"]
        }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return ["ok": false, "error": "that is a folder — use list_dir"]
        }
        guard let data = try? Data(contentsOf: url) else {
            return ["ok": false, "error": "could not read"]
        }
        if data.count > maxRead {
            return ["ok": false, "error": "file larger than 80 KB"]
        }
        guard let text = String(data: data, encoding: .utf8) else {
            return ["ok": false, "error": "not a UTF-8 text file"]
        }
        return ["ok": true, "path": url.path, "content": text]
    }

    private static func confirmWrite(path: String, bytes: Int) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Kaji wants to write a file"
        alert.informativeText = "\(path)\n\(bytes) bytes"
        alert.addButton(withTitle: "Write")
        alert.addButton(withTitle: "Don’t write")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func writeFile(_ raw: String, content: String) -> [String: Any] {
        guard let url = resolve(raw) else {
            return ["ok": false, "error": "path not allowed"]
        }
        if content.utf8.count > maxWrite {
            return ["ok": false, "error": "content too large"]
        }
        guard confirmWrite(path: url.path, bytes: content.utf8.count) else {
            return ["ok": false, "error": "user cancelled write"]
        }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return ["ok": true, "path": url.path, "bytes": content.utf8.count]
        } catch {
            return ["ok": false, "error": String(describing: error)]
        }
    }
}
