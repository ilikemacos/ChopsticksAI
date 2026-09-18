import Foundation
import AppKit

enum IslandPayload: Equatable {
    case none
    case music(NowPlayingInfo)
    case meter(title: String, value: Double, symbol: String)
    case battery(percent: Int, charging: Bool)
    case text(title: String, detail: String, symbol: String)
    case download(name: String, progress: Double?)
    case timer(label: String, remaining: TimeInterval)
    case alert(title: String, detail: String)
}

struct NowPlayingInfo: Equatable {
    var title: String
    var artist: String
    var isPlaying: Bool
    var elapsed: TimeInterval
    var duration: TimeInterval
    var artwork: NSImage?

    static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.isPlaying == rhs.isPlaying
            && abs(lhs.elapsed - rhs.elapsed) < 0.4
            && abs(lhs.duration - rhs.duration) < 0.4
            && lhs.artwork?.tiffRepresentation == rhs.artwork?.tiffRepresentation
    }
}

struct IslandEvent: Identifiable, Equatable {
    let id: UUID
    var kind: IslandKind
    var sticky: Bool
    var expiresAt: Date?
    var payload: IslandPayload
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: IslandKind,
        sticky: Bool = false,
        ttl: TimeInterval? = 3.2,
        payload: IslandPayload
    ) {
        self.id = id
        self.kind = kind
        self.sticky = sticky
        self.expiresAt = ttl.map { Date().addingTimeInterval($0) }
        self.payload = payload
        self.createdAt = Date()
    }
}
