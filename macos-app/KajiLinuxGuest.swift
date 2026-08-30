import AppKit
import Foundation
import Virtualization

/// Headless Alpine Linux guest for Kaji `run_command`. No desktop, no guest browser, no NIC.
/// Web stays in WebKit. Scratch dir: ~/Downloads/Kaji-scratch (virtiofs tag `kaji`).
enum KajiLinuxGuest {
    private static let alpineMinor = "3.21.3"
    private static let alpineSeries = "v3.21"
    private static let queue = DispatchQueue(label: "com.chopstickshq.kaji.linux")
    private static let lock = NSLock()
    private static var machine: VZVirtualMachine?
    private static var writeHandle: FileHandle?
    private static var readBuffer = Data()
    private static var waiter: ((String) -> Void)?
    private static var booted = false
    private static var assetsReady = false

    static func run(command raw: String) async -> [String: Any] {
        let command = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if command.isEmpty {
            return ["ok": false, "error": "empty command"]
        }
        if command.count > 4000 {
            return ["ok": false, "error": "command too long"]
        }
        if command.contains("KAJI_END") {
            return ["ok": false, "error": "command not allowed"]
        }
        let allowed = await MainActor.run { confirm(command) }
        guard allowed else {
            return ["ok": false, "error": "user cancelled command"]
        }
        do {
            try await ensureBooted()
            let output = try await exec(command)
            return [
                "ok": true,
                "guest": "alpine",
                "cwd": scratchURL.path,
                "output": String(output.prefix(24_000)),
            ]
        } catch {
            return ["ok": false, "error": String(describing: error)]
        }
    }

    @MainActor
    private static func confirm(_ command: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Kaji wants to run a command in the Linux sandbox"
        alert.informativeText = "Headless Alpine (no network, no desktop). Scratch folder:\n~/Downloads/Kaji-scratch\n\n\(command)"
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Don’t run")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static var cacheURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("chopsticksAI/kaji-alpine", isDirectory: true)
    }

    private static var scratchURL: URL {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        return downloads.appendingPathComponent("Kaji-scratch", isDirectory: true)
    }

    private static var arch: String {
        #if arch(arm64)
        return "aarch64"
        #else
        return "x86_64"
        #endif
    }

    private static func ensureAssets() throws {
        if assetsReady { return }
        let fm = FileManager.default
        try fm.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: scratchURL, withIntermediateDirectories: true)
        let kernelGz = cacheURL.appendingPathComponent("vmlinuz-virt")
        let kernelRaw = cacheURL.appendingPathComponent("vmlinuz")
        let tarball = cacheURL.appendingPathComponent("minirootfs.tar.gz")
        let initrd = cacheURL.appendingPathComponent("initramfs.cpio.gz")
        let base = "https://dl-cdn.alpinelinux.org/alpine/\(alpineSeries)/releases/\(arch)"
        if !fm.fileExists(atPath: kernelGz.path) {
            try download("\(base)/netboot/vmlinuz-virt", to: kernelGz)
        }
        if !fm.fileExists(atPath: kernelRaw.path) {
            try gunzipIfNeeded(kernelGz, to: kernelRaw)
        }
        if !fm.fileExists(atPath: tarball.path) {
            try download("\(base)/alpine-minirootfs-\(alpineMinor)-\(arch).tar.gz", to: tarball)
        }
        if !fm.fileExists(atPath: initrd.path) {
            try packInitramfs(tarball: tarball, dest: initrd)
        }
        assetsReady = true
    }

    private static func download(_ urlString: String, to dest: URL) throws {
        guard let url = URL(string: urlString) else { throw GuestError.badURL }
        let data = try Data(contentsOf: url)
        if data.count < 1000 { throw GuestError.downloadFailed }
        try data.write(to: dest, options: .atomic)
    }

    private static func gunzipIfNeeded(_ src: URL, to dest: URL) throws {
        let bytes = try Data(contentsOf: src)
        if bytes.count >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b {
            try runTool("/usr/bin/gzip", arguments: ["-dc", src.path], stdout: dest)
        } else {
            try FileManager.default.copyItem(at: src, to: dest)
        }
    }

    private static func packInitramfs(tarball: URL, dest: URL) throws {
        let root = cacheURL.appendingPathComponent("rootfs", isDirectory: true)
        try? FileManager.default.removeItem(at: root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try runTool("/usr/bin/tar", arguments: ["-xzf", tarball.path, "-C", root.path])
        let initScript = """
        #!/bin/busybox sh
        /bin/busybox --install -s >/dev/null 2>&1 || true
        mount -t proc none /proc 2>/dev/null || true
        mount -t sysfs none /sys 2>/dev/null || true
        mount -t devtmpfs none /dev 2>/dev/null || true
        mkdir -p /dev/pts /mnt/scratch /root
        mount -t devpts none /dev/pts 2>/dev/null || true
        mount -t virtiofs kaji /mnt/scratch 2>/dev/null || true
        cd /mnt/scratch 2>/dev/null || cd /root
        export HOME=/root PATH=/usr/sbin:/usr/bin:/sbin:/bin
        exec /bin/busybox sh
        """
        let initURL = root.appendingPathComponent("init")
        try initScript.write(to: initURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: initURL.path)
        try runTool("/bin/sh", arguments: [
            "-c",
            "cd \"$1\" && find . | cpio -o -H newc | gzip -n > \"$2\"",
            "pack",
            root.path,
            dest.path,
        ])
    }

    private static func runTool(_ path: String, arguments: [String], stdout: URL? = nil) throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = arguments
        if let stdout {
            FileManager.default.createFile(atPath: stdout.path, contents: nil)
            proc.standardOutput = try FileHandle(forWritingTo: stdout)
        }
        let err = Pipe()
        proc.standardError = err
        try proc.run()
        proc.waitUntilExit()
        if proc.terminationStatus != 0 {
            let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw GuestError.toolFailed(path, msg)
        }
    }

    private static func ensureBooted() async throws {
        try ensureAssets()
        if booted { return }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try startLocked()
                    waitForReady(timeout: 45) { err in
                        if let err { cont.resume(throwing: err) }
                        else { cont.resume() }
                    }
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
        booted = true
    }

    private static func startLocked() throws {
        if machine != nil { return }
        let kernel = cacheURL.appendingPathComponent("vmlinuz")
        let initrd = cacheURL.appendingPathComponent("initramfs.cpio.gz")
        let boot = VZLinuxBootLoader(kernelURL: kernel)
        boot.initialRamdiskURL = initrd
        boot.commandLine = "console=hvc0 quiet rdinit=/init"

        let config = VZVirtualMachineConfiguration()
        config.cpuCount = 1
        config.memorySize = 512 * 1024 * 1024
        config.bootLoader = boot

        let outPipe = Pipe()
        let inPipe = Pipe()
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        serial.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: inPipe.fileHandleForReading,
            fileHandleForWriting: outPipe.fileHandleForWriting
        )
        config.serialPorts = [serial]
        writeHandle = inPipe.fileHandleForWriting

        let fs = VZVirtioFileSystemDeviceConfiguration(tag: "kaji")
        fs.share = VZSingleDirectoryShare(
            directory: VZSharedDirectory(url: scratchURL, readOnly: false)
        )
        config.directorySharingDevices = [fs]
        // No network device — guest stays offline.

        try config.validate()
        let vm = VZVirtualMachine(configuration: config, queue: queue)
        machine = vm

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty { return }
            lock.lock()
            readBuffer.append(chunk)
                let text = String(data: readBuffer, encoding: .utf8) ?? ""
            if let cb = waiter, let range = text.range(of: "KAJI_END") {
                let before = String(text[..<range.lowerBound])
                readBuffer.removeAll(keepingCapacity: true)
                waiter = nil
                lock.unlock()
                cb(before)
            } else {
                lock.unlock()
            }
        }

        let sem = DispatchSemaphore(value: 0)
        var startError: Error?
        vm.start { result in
            switch result {
            case .failure(let err): startError = err
            case .success: break
            }
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 20)
        if let startError { throw startError }
    }

    private static func waitForReady(timeout: TimeInterval, done: @escaping (Error?) -> Void) {
        var finished = false
        func finish(_ err: Error?) {
            lock.lock()
            let already = finished
            finished = true
            waiter = nil
            lock.unlock()
            if !already { done(err) }
        }
        lock.lock()
        readBuffer.removeAll(keepingCapacity: true)
        waiter = { _ in finish(nil) }
        lock.unlock()
        func poke() { writeLine("echo KAJI_READY; echo KAJI_END") }
        poke()
        for i in 1...8 {
            queue.asyncAfter(deadline: .now() + Double(i) * 2) {
                lock.lock()
                let pending = waiter != nil
                lock.unlock()
                if pending { poke() }
            }
        }
        queue.asyncAfter(deadline: .now() + timeout) {
            finish(GuestError.bootTimeout)
        }
    }

    private static func exec(_ command: String) async throws -> String {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            queue.async {
                let b64 = Data(command.utf8).base64EncodedString()
                var finished = false
                func finish(_ result: Result<String, Error>) {
                    lock.lock()
                    let already = finished
                    finished = true
                    waiter = nil
                    lock.unlock()
                    if !already {
                        switch result {
                        case .success(let s): cont.resume(returning: s)
                        case .failure(let e): cont.resume(throwing: e)
                        }
                    }
                }
                lock.lock()
                readBuffer.removeAll(keepingCapacity: true)
                waiter = { payload in
                    var body = payload
                    if let start = body.range(of: "KAJI_BEGIN") {
                        body = String(body[start.upperBound...])
                    }
                    if let st = body.range(of: "KAJI_STATUS:") {
                        body = String(body[..<st.lowerBound])
                    }
                    finish(.success(body.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                lock.unlock()
                writeLine("echo KAJI_BEGIN; echo \(b64) | base64 -d | sh; echo KAJI_STATUS:$?; echo KAJI_END")
                queue.asyncAfter(deadline: .now() + 25) {
                    lock.lock()
                    let partial = String(data: readBuffer, encoding: .utf8) ?? ""
                    lock.unlock()
                    if partial.isEmpty {
                        finish(.failure(GuestError.commandTimeout))
                    } else {
                        finish(.success(partial))
                    }
                }
            }
        }
    }

    private static func writeLine(_ line: String) {
        guard let writeHandle else { return }
        var data = Data((line + "\n").utf8)
        try? writeHandle.write(contentsOf: data)
        data.removeAll()
    }

    private enum GuestError: LocalizedError {
        case badURL, downloadFailed, bootTimeout, commandTimeout
        case toolFailed(String, String)
        var errorDescription: String? {
            switch self {
            case .badURL: return "bad Alpine URL"
            case .downloadFailed: return "could not download Alpine image"
            case .bootTimeout: return "Linux sandbox did not boot"
            case .commandTimeout: return "command timed out (25s)"
            case .toolFailed(let p, let m): return "\(p) failed: \(m.prefix(200))"
            }
        }
    }
}
