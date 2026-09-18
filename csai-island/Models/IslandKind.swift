import Foundation

enum IslandKind: String, CaseIterable, Codable, Identifiable {
    case idle
    case ai
    case systemAlert
    case music
    case download
    case notification
    case volume
    case brightness
    case battery
    case bluetooth
    case network
    case screenshot
    case capture
    case focus
    case timer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idle: return "Idle"
        case .ai: return "cs.AI"
        case .systemAlert: return "Alert"
        case .music: return "Music"
        case .download: return "Downloads"
        case .notification: return "Notification"
        case .volume: return "Volume"
        case .brightness: return "Brightness"
        case .battery: return "Battery"
        case .bluetooth: return "Bluetooth"
        case .network: return "Network"
        case .screenshot: return "Screenshot"
        case .capture: return "Capture"
        case .focus: return "Focus"
        case .timer: return "Timer"
        }
    }

    var symbol: String {
        switch self {
        case .idle: return "circle.fill"
        case .ai: return "sparkle"
        case .systemAlert: return "exclamationmark.triangle.fill"
        case .music: return "music.note"
        case .download: return "arrow.down.circle.fill"
        case .notification: return "bell.fill"
        case .volume: return "speaker.wave.2.fill"
        case .brightness: return "sun.max.fill"
        case .battery: return "battery.100"
        case .bluetooth: return "airpodspro"
        case .network: return "network"
        case .screenshot: return "camera.viewfinder"
        case .capture: return "video.fill"
        case .focus: return "moon.fill"
        case .timer: return "timer"
        }
    }
}

enum IslandPhase: Equatable {
    case idle
    case compact
    case expanded
    /// Taller surface for cs.AI chat or rich tabs.
    case extraExpanded
}
