import AppKit
import Foundation

final class MediaRemoteBridge {
    typealias InfoBlock = @convention(block) (NSDictionary?) -> Void
    typealias GetInfoFn = @convention(c) (DispatchQueue, InfoBlock) -> Void
    typealias SendFn = @convention(c) (UInt32, CFDictionary?) -> Bool
    typealias RegisterFn = @convention(c) (DispatchQueue) -> Void

    private var getNowPlaying: GetInfoFn?
    private var sendCommand: SendFn?
    private var token: NSObjectProtocol?

    func start(onChange: @escaping (NowPlayingInfo) -> Void) {
        if let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY) {
            if let s = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
                getNowPlaying = unsafeBitCast(s, to: GetInfoFn.self)
            }
            if let s = dlsym(handle, "MRMediaRemoteSendCommand") {
                sendCommand = unsafeBitCast(s, to: SendFn.self)
            }
            if let s = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
                let register = unsafeBitCast(s, to: RegisterFn.self)
                register(DispatchQueue.main)
            }
        }
        token = NotificationCenter.default.addObserver(
            forName: Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh(onChange: onChange)
        }
        refresh(onChange: onChange)
    }

    func command(_ id: UInt32) {
        if sendCommand?(id, nil) == true { return }
        let verb: String
        switch id {
        case 2: verb = "next track"
        case 1: verb = "previous track"
        default: verb = "playpause"
        }
        NSAppleScript(source: "tell application \"Music\" to \(verb)")?.executeAndReturnError(nil)
    }

    private func refresh(onChange: @escaping (NowPlayingInfo) -> Void) {
        if let getNowPlaying {
            getNowPlaying(DispatchQueue.main) { info in
                guard let info else { return }
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Now Playing"
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let elapsed = (info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? 0
                let duration = (info["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? 0
                let rate = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? 0
                var art: NSImage?
                if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    art = NSImage(data: data)
                }
                onChange(NowPlayingInfo(title: title, artist: artist, isPlaying: rate > 0.01, elapsed: elapsed, duration: duration, artwork: art))
            }
            return
        }
        scriptFallback(onChange: onChange)
    }

    private func scriptFallback(onChange: @escaping (NowPlayingInfo) -> Void) {
        let src = """
        tell application "System Events"
          if not (exists process "Music") then return "|||"
        end tell
        tell application "Music"
          if player state is stopped then return "|||"
          set t to name of current track
          set a to artist of current track
          set p to player state is playing
          return t & tab & a & tab & p
        end tell
        """
        var err: NSDictionary?
        guard let out = NSAppleScript(source: src)?.executeAndReturnError(&err).stringValue, out != "|||" else { return }
        let parts = out.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3 else { return }
        onChange(NowPlayingInfo(title: parts[0], artist: parts[1], isPlaying: parts[2].contains("true"), elapsed: 0, duration: 0, artwork: nil))
    }
}

enum MediaCommand {
    static let playPause: UInt32 = 0
    static let previous: UInt32 = 1
    static let next: UInt32 = 2
}

@MainActor
final class NowPlayingMonitor: ObservableObject {
    static let shared = NowPlayingMonitor()
    private let remote = MediaRemoteBridge()
    private var lastTitle = ""
    @Published private(set) var current: NowPlayingInfo?

    func start() {
        remote.start { [weak self] info in
            guard let self else { return }
            Task { @MainActor in
                self.current = info.title.isEmpty ? nil : info
                let mgr = IslandStateManager.shared
                mgr.update(kind: .music, payload: .music(info))
                if info.title != self.lastTitle, !info.title.isEmpty {
                    self.lastTitle = info.title
                    mgr.post(IslandEvent(kind: .music, sticky: info.isPlaying, ttl: info.isPlaying ? 8 : 3, payload: .music(info)))
                }
            }
        }
    }

    func send(_ command: UInt32) {
        remote.command(command)
    }
}
