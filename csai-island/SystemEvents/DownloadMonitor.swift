import Foundation

final class DownloadMonitor {
    private var source: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1
    private var known = Set<String>()

    func start() {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
        fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        known = snapshot(url)
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        src.setEventHandler { [weak self] in
            self?.changed(url)
        }
        src.setCancelHandler { [weak self] in
            if let fd = self?.fd, fd >= 0 { close(fd) }
        }
        source = src
        src.resume()
    }

    private func snapshot(_ url: URL) -> Set<String> {
        let items = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
        return Set(items.filter { !$0.hasPrefix(".") })
    }

    private func changed(_ url: URL) {
        let now = snapshot(url)
        let added = now.subtracting(known)
        known = now
        guard let name = added.sorted().first else { return }
        if name.hasSuffix(".download") || name.hasSuffix(".crdownload") || name.hasSuffix(".part") {
            Task { @MainActor in
                IslandStateManager.shared.post(
                    IslandEvent(kind: .download, ttl: 4.0, payload: .download(name: name, progress: nil))
                )
            }
            return
        }
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(kind: .download, ttl: 3.2, payload: .download(name: name, progress: 1))
            )
        }
    }
}
