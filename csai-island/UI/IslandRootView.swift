import SwiftUI
import AppKit

struct IslandRootView: View {
    @ObservedObject var mgr = IslandStateManager.shared
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        IslandChrome {
            Group {
                if mgr.isExpandedSurface {
                    TabbedExpandedView()
                } else {
                    CompactIslandContent()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .onHover { mgr.onHover($0) }
        .onChange(of: mgr.phase) { _, _ in notifyLayout() }
        .onChange(of: mgr.selectedTab) { _, _ in notifyLayout() }
        .onChange(of: mgr.kind) { _, _ in notifyLayout() }
        .focusable()
        .onExitCommand { mgr.escape() }
        .opacity(idleOpacity)
        .scaleEffect(mgr.hudPulse ? 1.02 : 1, anchor: .top)
        .animation(.spring(response: settings.springResponse, dampingFraction: settings.springDamping), value: mgr.phase)
        .animation(.spring(response: settings.springResponse, dampingFraction: settings.springDamping), value: mgr.isExpandedSurface)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: mgr.hudPulse)
        .allowsHitTesting(settings.islandEnabled)
    }

    private var idleOpacity: Double {
        if mgr.isExpandedSurface { return 1 }
        if mgr.phase == .idle && !mgr.hover && mgr.active == nil { return 0.85 }
        if mgr.phase == .idle && !mgr.hover { return 0.95 }
        return 1
    }

    private func handleTap() {
        guard settings.islandEnabled else { return }
        if mgr.isExpandedSurface { return }
        switch mgr.kind {
        case .music:
            mgr.openExpanded(tab: .media)
        case .timer:
            mgr.openExpanded(tab: .timers)
        case .volume, .brightness, .battery, .network:
            mgr.openExpanded(tab: .stats)
        default:
            mgr.openAI()
        }
    }

    private func notifyLayout() {
        NotificationCenter.default.post(name: .islandNeedsLayout, object: nil)
    }
}
