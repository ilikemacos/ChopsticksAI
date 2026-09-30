import AppKit
import SwiftUI

final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class IslandPanelController: NSObject {
    private let panel: IslandPanel
    private var hosting: NSHostingView<IslandRootView>
    private var displayObs: Any?
    private var size: CGSize = CGSize(width: 36, height: 12)

    override init() {
        let root = IslandRootView()
        hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: size)
        panel = IslandPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 2)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovableByWindowBackground = false
        panel.contentView = hosting
        panel.animationBehavior = .utilityWindow
        reposition(animated: false)
        panel.orderFrontRegardless()

        displayObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reposition(animated: true) }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layout),
            name: .islandNeedsLayout,
            object: nil
        )
    }

    @objc func layout() {
        reposition(animated: true)
    }

    func reposition(animated: Bool) {
        let mgr = IslandStateManager.shared
        guard AppSettings.shared.islandEnabled else {
            panel.orderOut(nil)
            return
        }
        let geo = NotchGeometry.current(settings: AppSettings.shared)
        let next = geo.size(
            for: mgr.kind,
            phase: mgr.phase,
            ai: mgr.isExpandedSurface || mgr.aiOpen,
            settings: AppSettings.shared
        )
        size = next
        hosting.frame = NSRect(origin: .zero, size: next)
        let origin = geo.islandOrigin(size: next, phase: mgr.phase)
        let frame = NSRect(origin: origin, size: next)
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = AppSettings.shared.springResponse
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        if mgr.isExpandedSurface || mgr.aiOpen {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func applyMousePassthrough(idle: Bool) {
        panel.ignoresMouseEvents = idle && !IslandStateManager.shared.hover
    }
}

extension Notification.Name {
    static let islandNeedsLayout = Notification.Name("CSAIIsland.needsLayout")
}
