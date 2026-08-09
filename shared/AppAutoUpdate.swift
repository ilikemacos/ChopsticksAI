import AppKit
import Combine
import CryptoKit
import Foundation

struct AppUpdateConfig {
    let manifestURL: URL
    let downloadBase: URL
    let bundleName: String
    let productName: String
    let defaultsPrefix: String

    // Bumped key so older installs that defaulted auto-install on don't keep
    // deleting the app before the staging-path fix.
    var autoInstallKey: String { "\(defaultsPrefix).autoInstallUpdates.v2" }
    var snoozeKey: String { "\(defaultsPrefix).updateSnoozeUntil" }
}

final class AppAutoUpdate: ObservableObject {
    static let shared = AppAutoUpdate()

    @Published private(set) var updateAvailable: String?
    @Published var autoInstall: Bool {
        didSet { UserDefaults.standard.set(autoInstall, forKey: config?.autoInstallKey ?? "") }
    }

    private var config: AppUpdateConfig?
    private var checking = false
    private var installing = false

    private init() {
        autoInstall = false
    }

    func configure(_ config: AppUpdateConfig) {
        self.config = config
        if UserDefaults.standard.object(forKey: config.autoInstallKey) != nil {
            autoInstall = UserDefaults.standard.bool(forKey: config.autoInstallKey)
        } else {
            // Opt-in: auto-install used to delete the app when the temp
            // staging folder was cleaned up before the replace finished.
            autoInstall = false
            UserDefaults.standard.set(false, forKey: config.autoInstallKey)
        }
    }

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    func checkOnLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.check(manual: false)
        }
    }

    func checkManually() {
        check(manual: true)
    }

    private func check(manual: Bool) {
        guard let config, !checking, !installing else { return }
        if !manual, isSnoozed() { return }

        checking = true
        fetchManifest(config: config) { [weak self] manifest in
            guard let self else { return }
            self.checking = false
            guard let manifest else {
                if manual { self.showAlert("Could Not Check for Updates", "Could not reach chopstickshq.com. Check your connection and try again.") }
                return
            }
            let remote = manifest.latest
            guard Self.isNewer(remote, than: self.currentVersion) else {
                self.updateAvailable = nil
                if manual {
                    self.showAlert("You're Up to Date", "\(config.productName) v\(Self.display(remote)) is the newest build.")
                }
                return
            }
            self.updateAvailable = remote
            if self.autoInstall, !manual {
                self.install(version: remote, manifest: manifest)
            } else {
                self.offerUpdate(version: remote, manifest: manifest, manual: manual)
            }
        }
    }

    private func offerUpdate(version: String, manifest: ReleaseManifest, manual: Bool) {
        guard let config else { return }
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "\(config.productName) v\(Self.display(version)) is available (you have v\(Self.display(currentVersion)))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update Now")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            install(version: version, manifest: manifest)
        } else if !manual {
            snooze(hours: 24)
        }
    }

    private func install(version: String, manifest: ReleaseManifest) {
        guard let config, !installing else { return }
        guard let zipName = manifest.stableZip else {
            showAlert("Update Failed", "The release manifest did not include a download file.")
            return
        }

        installing = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result = self.performInstall(config: config, version: version, zipName: zipName, expectedSha: manifest.stableSha)
            DispatchQueue.main.async {
                self.installing = false
                switch result {
                case .success:
                    break
                case .failure(let msg):
                    self.showAlert("Update Failed", msg)
                }
            }
        }
    }

    private enum InstallOutcome {
        case success
        case failure(String)
    }

    private func performInstall(config: AppUpdateConfig, version: String, zipName: String, expectedSha: String?) -> InstallOutcome {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("chq-update-\(UUID().uuidString)", isDirectory: true)
        let zipFile = tmp.appendingPathComponent(zipName)
        let extractDir = tmp.appendingPathComponent("extract", isDirectory: true)

        defer { try? fm.removeItem(at: tmp) }

        do {
            try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        } catch {
            return .failure("Could not create a temp folder: \(error.localizedDescription)")
        }

        let downloadURL = config.downloadBase.appendingPathComponent(zipName)
        let sem = DispatchSemaphore(value: 0)
        var dlError: Error?
        var req = URLRequest(url: downloadURL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 120
        URLSession.shared.downloadTask(with: req) { tempURL, resp, err in
            defer { sem.signal() }
            guard err == nil, let tempURL else { dlError = err ?? URLError(.badServerResponse); return }
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 0 || status == 200 else {
                dlError = URLError(.badServerResponse)
                return
            }
            do {
                if fm.fileExists(atPath: zipFile.path) { try fm.removeItem(at: zipFile) }
                try fm.moveItem(at: tempURL, to: zipFile)
            } catch { dlError = error }
        }.resume()
        sem.wait()
        if let dlError {
            return .failure("Download failed: \(dlError.localizedDescription)")
        }

        if let want = expectedSha?.lowercased(), want.count == 64 {
            guard let got = Self.sha256Hex(zipFile)?.lowercased(), got == want else {
                return .failure("Checksum mismatch — refusing to install. Try again from chopstickshq.com.")
            }
        }

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzip.arguments = ["-x", "-k", zipFile.path, extractDir.path]
        do {
            try unzip.run()
            unzip.waitUntilExit()
        } catch {
            return .failure("Could not unzip the update.")
        }
        guard unzip.terminationStatus == 0 else { return .failure("Could not unzip the update.") }

        guard let staged = Self.findApp(named: config.bundleName, under: extractDir) else {
            return .failure("\(config.bundleName) was not found inside the update archive.")
        }

        // Copy out of `tmp` before defer deletes it — otherwise the replace
        // script runs after cleanup and `rm -rf` leaves no app behind.
        let stagedKeep = fm.temporaryDirectory
            .appendingPathComponent("chq-keep-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent(config.bundleName, isDirectory: true)
        do {
            try fm.createDirectory(at: stagedKeep.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: stagedKeep.path) { try fm.removeItem(at: stagedKeep) }
            try fm.copyItem(at: staged, to: stagedKeep)
        } catch {
            return .failure("Could not stage the update: \(error.localizedDescription)")
        }

        let dest = Self.installDestination(bundleName: config.bundleName)
        guard Self.isAllowedDestination(dest) else {
            try? fm.removeItem(at: stagedKeep.deletingLastPathComponent())
            return .failure("Refusing to install outside ~/Applications.")
        }

        return Self.scheduleReplace(
            staged: stagedKeep,
            stagedParent: stagedKeep.deletingLastPathComponent(),
            dest: dest,
            productName: config.productName,
            version: version
        )
    }

    private static func scheduleReplace(
        staged: URL,
        stagedParent: URL,
        dest: URL,
        productName: String,
        version: String
    ) -> InstallOutcome {
        // Never codesign here — ad-hoc resign can prompt for the login keychain
        // password. Clear quarantine only, then reopen.
        let script = """
        #!/bin/bash
        set -e
        sleep 1
        mkdir -p '\(shellQuote(dest.deletingLastPathComponent().path))'
        rm -rf '\(shellQuote(dest.path))'
        ditto '\(shellQuote(staged.path))' '\(shellQuote(dest.path))'
        xattr -cr '\(shellQuote(dest.path))' 2>/dev/null || true
        open '\(shellQuote(dest.path))'
        rm -rf '\(shellQuote(stagedParent.path))'
        """
        let scriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("chq-update-\(UUID().uuidString).sh")
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        } catch {
            try? FileManager.default.removeItem(at: stagedParent)
            return .failure("Could not prepare the update helper.")
        }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Installing Update"
            alert.informativeText = "\(productName) will restart to apply v\(display(version))."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Restart")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() != .alertFirstButtonReturn {
                try? FileManager.default.removeItem(at: stagedParent)
                try? FileManager.default.removeItem(at: scriptURL)
                return
            }

            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/bash")
            proc.arguments = [scriptURL.path]
            try? proc.run()
            NSApp.terminate(nil)
        }
        return .success
    }

    /// Always install under ~/Applications so updates never ask for an admin password.
    private static func installDestination(bundleName: String) -> URL {
        let homeApps = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
        let running = Bundle.main.bundleURL
        if running.path.hasPrefix(homeApps.path) { return running }
        return homeApps.appendingPathComponent(bundleName, isDirectory: true)
    }

    private static func isAllowedDestination(_ url: URL) -> Bool {
        let homeApps = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true).path
        let p = url.path
        return p.hasPrefix(homeApps) && !p.contains("AppTranslocation")
    }

    private static func findApp(named bundleName: String, under root: URL) -> URL? {
        let fm = FileManager.default
        if root.lastPathComponent == bundleName, (try? root.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            return root
        }
        guard let items = try? fm.subpathsOfDirectory(atPath: root.path) else { return nil }
        for item in items where item.hasSuffix(bundleName) {
            let url = root.appendingPathComponent(item)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue { return url }
        }
        return nil
    }

    private static func sha256Hex(_ file: URL) -> String? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func shellQuote(_ path: String) -> String {
        path.replacingOccurrences(of: "'", with: "'\\''")
    }

    private struct ReleaseManifest: Decodable {
        let latest: String
        let releases: Releases?

        struct Releases: Decodable {
            let stable: Stable?
        }

        struct Stable: Decodable {
            let zip: String
            let sha256: String?
        }

        var stableZip: String? { releases?.stable?.zip }
        var stableSha: String? { releases?.stable?.sha256 }
    }

    private func fetchManifest(config: AppUpdateConfig, completion: @escaping (ReleaseManifest?) -> Void) {
        var req = URLRequest(url: config.manifestURL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 12
        URLSession.shared.dataTask(with: req) { data, _, _ in
            let manifest: ReleaseManifest? = {
                guard let data else { return nil }
                return try? JSONDecoder().decode(ReleaseManifest.self, from: data)
            }()
            // AppKit (NSAlert) and @Published must run on the main thread.
            DispatchQueue.main.async {
                completion(manifest)
            }
        }.resume()
    }

    static func isNewer(_ remote: String, than current: String) -> Bool {
        if remote == current { return false }
        let rn = versionNumbers(remote), cn = versionNumbers(current)
        let count = max(rn.count, cn.count)
        for i in 0..<count {
            let r = i < rn.count ? rn[i] : 0
            let c = i < cn.count ? cn[i] : 0
            if r != c { return r > c }
        }
        return remote.localizedCaseInsensitiveCompare(current) == .orderedDescending
    }

    static func versionNumbers(_ v: String) -> [Int] {
        var s = v.trimmingCharacters(in: .whitespaces)
        if s.lowercased().hasPrefix("v") { s.removeFirst() }
        var nums: [Int] = []
        var cur = ""
        for ch in s {
            if ch.isNumber { cur.append(ch) }
            else if !cur.isEmpty {
                if let n = Int(cur) { nums.append(n) }
                cur = ""
            }
        }
        if !cur.isEmpty, let n = Int(cur) { nums.append(n) }
        return nums
    }

    static func display(_ version: String) -> String {
        version.hasPrefix("v") ? String(version.dropFirst()) : version
    }

    private func isSnoozed() -> Bool {
        guard let config else { return false }
        let until = UserDefaults.standard.double(forKey: config.snoozeKey)
        guard until > 0 else { return false }
        return Date().timeIntervalSince1970 < until
    }

    private func snooze(hours: Double) {
        guard let config else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970 + hours * 3600, forKey: config.snoozeKey)
    }

    private func showAlert(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}
