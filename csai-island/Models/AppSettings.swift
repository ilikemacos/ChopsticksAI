import Foundation
import SwiftUI

enum IslandAppearance: String, CaseIterable, Identifiable {
    case system, dark, light
    var id: String { rawValue }
}

enum AnimationStyle: String, CaseIterable, Identifiable {
    case spring, snappy, gentle
    var id: String { rawValue }
}

enum IslandPosition: String, CaseIterable, Identifiable {
    case notchCenter, menuBarCenter, activeDisplay
    var id: String { rawValue }
    var label: String {
        switch self {
        case .notchCenter: return "Notch / menu bar center"
        case .menuBarCenter: return "Menu bar center"
        case .activeDisplay: return "Follow active display"
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let d = UserDefaults.standard

    @Published var islandEnabled: Bool
    @Published var launchAtLogin: Bool
    @Published var position: IslandPosition
    @Published var animationIntensity: Double
    @Published var autoCollapse: Bool
    @Published var autoCollapseDelay: Double
    @Published var appearance: IslandAppearance
    @Published var opacity: Double
    @Published var blurIntensity: Double
    @Published var cornerRadius: Double
    @Published var animationStyle: AnimationStyle

    @Published var aiEnabled: Bool
    @Published var apiEndpoint: String
    @Published var model: String
    @Published var streaming: Bool
    @Published var keepHistory: Bool
    @Published var hotKeyEnabled: Bool

    @Published var eventMusic: Bool
    @Published var eventVolume: Bool
    @Published var eventBrightness: Bool
    @Published var eventBattery: Bool
    @Published var eventDownloads: Bool
    @Published var eventNotifications: Bool
    @Published var eventBluetooth: Bool
    @Published var eventNetwork: Bool
    @Published var eventScreenshots: Bool
    @Published var eventCapture: Bool
    @Published var eventFocus: Bool

    /// Highest first. Editable so new kinds can be inserted without rewriting the manager.
    @Published var priority: [IslandKind]

    private init() {
        islandEnabled = d.object(forKey: "island.enabled") as? Bool ?? true
        launchAtLogin = d.bool(forKey: "island.login")
        position = IslandPosition(rawValue: d.string(forKey: "island.position") ?? "") ?? .notchCenter
        animationIntensity = d.object(forKey: "island.intensity") as? Double ?? 1.0
        autoCollapse = d.object(forKey: "island.autocollapse") as? Bool ?? true
        autoCollapseDelay = d.object(forKey: "island.autocollapse.delay") as? Double ?? 3.4
        appearance = IslandAppearance(rawValue: d.string(forKey: "island.appearance") ?? "") ?? .dark
        opacity = d.object(forKey: "island.opacity") as? Double ?? 0.92
        blurIntensity = d.object(forKey: "island.blur") as? Double ?? 0.85
        cornerRadius = d.object(forKey: "island.radius") as? Double ?? 22
        animationStyle = AnimationStyle(rawValue: d.string(forKey: "island.anim") ?? "") ?? .spring
        aiEnabled = d.object(forKey: "ai.enabled") as? Bool ?? true
        apiEndpoint = d.string(forKey: "ai.endpoint") ?? "https://chopstickshq.com/api/chopsticks-ai"
        model = d.string(forKey: "ai.model") ?? "csai4flash"
        streaming = d.object(forKey: "ai.streaming") as? Bool ?? true
        keepHistory = d.object(forKey: "ai.history") as? Bool ?? true
        hotKeyEnabled = d.object(forKey: "ai.hotkey") as? Bool ?? true
        eventMusic = d.object(forKey: "ev.music") as? Bool ?? true
        eventVolume = d.object(forKey: "ev.volume") as? Bool ?? true
        eventBrightness = d.object(forKey: "ev.brightness") as? Bool ?? true
        eventBattery = d.object(forKey: "ev.battery") as? Bool ?? true
        eventDownloads = d.object(forKey: "ev.downloads") as? Bool ?? true
        eventNotifications = d.object(forKey: "ev.notifications") as? Bool ?? true
        eventBluetooth = d.object(forKey: "ev.bluetooth") as? Bool ?? true
        eventNetwork = d.object(forKey: "ev.network") as? Bool ?? true
        eventScreenshots = d.object(forKey: "ev.screenshots") as? Bool ?? true
        eventCapture = d.object(forKey: "ev.capture") as? Bool ?? true
        eventFocus = d.object(forKey: "ev.focus") as? Bool ?? true
        if let raw = d.array(forKey: "island.priority") as? [String] {
            let mapped = raw.compactMap(IslandKind.init(rawValue:))
            priority = mapped.isEmpty ? Self.defaultPriority : mapped
        } else {
            priority = Self.defaultPriority
        }
    }

    static let defaultPriority: [IslandKind] = [
        .ai, .systemAlert, .capture, .music, .download, .timer,
        .notification, .volume, .brightness, .battery, .bluetooth,
        .network, .screenshot, .focus, .idle,
    ]

    func persist() {
        d.set(islandEnabled, forKey: "island.enabled")
        d.set(launchAtLogin, forKey: "island.login")
        d.set(position.rawValue, forKey: "island.position")
        d.set(animationIntensity, forKey: "island.intensity")
        d.set(autoCollapse, forKey: "island.autocollapse")
        d.set(autoCollapseDelay, forKey: "island.autocollapse.delay")
        d.set(appearance.rawValue, forKey: "island.appearance")
        d.set(opacity, forKey: "island.opacity")
        d.set(blurIntensity, forKey: "island.blur")
        d.set(cornerRadius, forKey: "island.radius")
        d.set(animationStyle.rawValue, forKey: "island.anim")
        d.set(aiEnabled, forKey: "ai.enabled")
        d.set(apiEndpoint, forKey: "ai.endpoint")
        d.set(model, forKey: "ai.model")
        d.set(streaming, forKey: "ai.streaming")
        d.set(keepHistory, forKey: "ai.history")
        d.set(hotKeyEnabled, forKey: "ai.hotkey")
        d.set(eventMusic, forKey: "ev.music")
        d.set(eventVolume, forKey: "ev.volume")
        d.set(eventBrightness, forKey: "ev.brightness")
        d.set(eventBattery, forKey: "ev.battery")
        d.set(eventDownloads, forKey: "ev.downloads")
        d.set(eventNotifications, forKey: "ev.notifications")
        d.set(eventBluetooth, forKey: "ev.bluetooth")
        d.set(eventNetwork, forKey: "ev.network")
        d.set(eventScreenshots, forKey: "ev.screenshots")
        d.set(eventCapture, forKey: "ev.capture")
        d.set(eventFocus, forKey: "ev.focus")
        d.set(priority.map(\.rawValue), forKey: "island.priority")
    }

    func enabled(for kind: IslandKind) -> Bool {
        switch kind {
        case .idle, .ai, .systemAlert, .timer: return true
        case .music: return eventMusic
        case .volume: return eventVolume
        case .brightness: return eventBrightness
        case .battery: return eventBattery
        case .download: return eventDownloads
        case .notification: return eventNotifications
        case .bluetooth: return eventBluetooth
        case .network: return eventNetwork
        case .screenshot: return eventScreenshots
        case .capture: return eventCapture
        case .focus: return eventFocus
        }
    }

    var springResponse: Double {
        let base: Double
        switch animationStyle {
        case .spring: base = 0.42
        case .snappy: base = 0.28
        case .gentle: base = 0.58
        }
        return max(0.18, base / max(0.5, animationIntensity))
    }

    var springDamping: Double {
        switch animationStyle {
        case .spring: return 0.78
        case .snappy: return 0.92
        case .gentle: return 0.88
        }
    }
}
