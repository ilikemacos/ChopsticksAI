import SwiftUI
import AppKit

struct IslandRootView: View {
    @ObservedObject var mgr = IslandStateManager.shared
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        IslandChrome {
            Group {
                if mgr.phase == .expanded || mgr.aiOpen {
                    ExpandedIslandContent()
                } else {
                    CompactIslandContent()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if mgr.phase == .idle || mgr.phase == .compact {
                if mgr.kind == .idle || mgr.kind == .ai { mgr.openAI() }
                else { mgr.toggleExpand() }
            }
        }
        .onHover { mgr.onHover($0) }
        .onChange(of: mgr.phase) { _, _ in notifyLayout() }
        .onChange(of: mgr.aiOpen) { _, _ in notifyLayout() }
        .onChange(of: mgr.kind) { _, _ in notifyLayout() }
        .focusable()
        .onExitCommand { mgr.escape() }
        .opacity(mgr.phase == .idle && !mgr.hover ? 0.22 : 1)
        .animation(.spring(response: settings.springResponse, dampingFraction: settings.springDamping), value: mgr.phase)
        .animation(.spring(response: settings.springResponse, dampingFraction: settings.springDamping), value: mgr.aiOpen)
        .allowsHitTesting(settings.islandEnabled)
    }

    private func notifyLayout() {
        NotificationCenter.default.post(name: .islandNeedsLayout, object: nil)
    }
}
