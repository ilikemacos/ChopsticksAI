import Foundation

final class ScreenshotMonitor {
    private var sources: [DispatchSourceFileSystemObject] = []
    private var fds: [Int32] = []

    func start() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dirs = [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures"),
        ]
        for dir in dirs {
            let fd = open(dir.path, O_EVTONLY)
            guard fd >= 0 else { continue }
            fds.append(fd)
            let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
            src.setEventHandler { [weak self] in
                self?.scan(dir)
            }
            sources.append(src)
            src.resume()
        }
    }

    private func scan(_ dir: URL) {
        let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)) ?? []
        let now = Date()
        let shot = items.first { url in
            let name = url.lastPathComponent
            guard name.localizedCaseInsensitiveContains("screenshot") || name.hasPrefix("Screen Recording") else { return false }
            let m = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return now.timeIntervalSince(m) < 2.5
        }
        guard let shot else { return }
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .screenshot,
                    ttl: 3.4,
                    payload: .text(title: "Screenshot", detail: shot.lastPathComponent, symbol: "camera.viewfinder")
                )
            )
        }
    }
}
