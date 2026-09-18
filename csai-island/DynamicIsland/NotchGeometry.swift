import AppKit

struct NotchGeometry {
    var screen: NSScreen
    var hasNotch: Bool
    var menuBarHeight: CGFloat
    var centerX: CGFloat
    var topY: CGFloat
    var visibleFrame: NSRect

    static func current(settings: AppSettings) -> NotchGeometry {
        let mouse = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let preferred: NSScreen
        switch settings.position {
        case .activeDisplay:
            preferred = screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main ?? screens[0]
        case .notchCenter, .menuBarCenter:
            preferred = NSScreen.main ?? screens[0]
        }
        return NotchGeometry(screen: preferred)
    }

    init(screen: NSScreen) {
        self.screen = screen
        visibleFrame = screen.visibleFrame
        let frame = screen.frame
        menuBarHeight = max(24, frame.maxY - visibleFrame.maxY)
        hasNotch = Self.detectNotch(screen)
        centerX = frame.midX
        topY = frame.maxY
    }

    static func detectNotch(_ screen: NSScreen) -> Bool {
        if #available(macOS 12.0, *) {
            let aux = screen.auxiliaryTopLeftArea?.width ?? 0
            let auxR = screen.auxiliaryTopRightArea?.width ?? 0
            if aux > 0 || auxR > 0 { return true }
        }
        let name = screen.localizedName.lowercased()
        if name.contains("macbook") && (name.contains("pro") || name.contains("air")) {
            return screen.frame.width >= 1512
        }
        return false
    }

    func islandOrigin(size: CGSize, phase: IslandPhase) -> CGPoint {
        let yOffset: CGFloat = hasNotch ? (phase == .idle ? 2 : 5) : 6
        let x = centerX - size.width / 2
        let y = topY - size.height - yOffset
        return CGPoint(x: x, y: y)
    }

    @MainActor
    func size(for kind: IslandKind, phase: IslandPhase, ai: Bool, settings: AppSettings) -> CGSize {
        let mgr = IslandStateManager.shared
        let tab = mgr.selectedTab

        if phase == .extraExpanded {
            return CGSize(width: 500, height: 430)
        }

        if ai || kind == .ai || mgr.isExpandedSurface {
            switch phase {
            case .idle: return CGSize(width: 92, height: 32)
            case .compact: return CGSize(width: 176, height: 36)
            case .expanded:
                if tab == .ai { return CGSize(width: 460, height: 360) }
                if tab == .media { return CGSize(width: 440, height: 200) }
                if tab == .timers { return CGSize(width: 420, height: 240) }
                return CGSize(width: 420, height: 220)
            case .extraExpanded:
                return CGSize(width: 500, height: 430)
            }
        }

        switch phase {
        case .idle:
            return hasNotch ? CGSize(width: 30, height: 10) : CGSize(width: 36, height: 12)
        case .compact:
            switch kind {
            case .music: return CGSize(width: 360, height: 42)
            case .volume, .brightness: return CGSize(width: 232, height: 38)
            case .battery: return CGSize(width: 200, height: 38)
            default: return CGSize(width: 268, height: 38)
            }
        case .expanded:
            switch kind {
            case .music: return CGSize(width: 420, height: 148)
            default: return CGSize(width: 360, height: 120)
            }
        case .extraExpanded:
            return CGSize(width: 500, height: 430)
        }
    }
}
