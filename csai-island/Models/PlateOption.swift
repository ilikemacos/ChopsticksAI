import Foundation

/// cs.AI plates exposed in the island UI — labels only, no provider names.
enum PlateOption: String, CaseIterable, Identifiable, Codable {
    case fast
    case auto
    case flash
    case core

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fast: return "Fast"
        case .auto: return "Auto"
        case .flash: return "Flash"
        case .core: return "Core"
        }
    }

    /// HQ tier id sent to chopstickshq.com/api/chopsticks-ai
    var tierId: String {
        switch self {
        case .fast: return "csaifast"
        case .auto: return "csaiauto"
        case .flash: return "csai47flash"
        case .core: return "csai46core"
        }
    }

    var symbol: String {
        switch self {
        case .fast: return "hare.fill"
        case .auto: return "wand.and.stars"
        case .flash: return "bolt.fill"
        case .core: return "cpu.fill"
        }
    }
}

enum IslandTab: String, CaseIterable, Identifiable {
    case ai
    case media
    case stats
    case timers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ai: return "cs.AI"
        case .media: return "Media"
        case .stats: return "Stats"
        case .timers: return "Timers"
        }
    }

    var symbol: String {
        switch self {
        case .ai: return "sparkle"
        case .media: return "music.note"
        case .stats: return "chart.bar.fill"
        case .timers: return "timer"
        }
    }
}
