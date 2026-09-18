import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    private var panel: IslandPanelController?
    private let menuBar = MenuBarController()
    private let hotKey = HotKeyService()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)
        menuBar.start()
        EventHub.shared.start()
        hotKey.start()
        panel = IslandPanelController()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                Task { @MainActor in IslandStateManager.shared.escape() }
            }
            return event
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    @objc func screenChanged() {
        panel?.reposition(animated: true)
    }

    @objc func openAI() {
        Task { @MainActor in
            IslandStateManager.shared.openAI()
            NotificationCenter.default.post(name: .islandNeedsLayout, object: nil)
        }
    }

    @objc func toggleIsland() {
        AppSettings.shared.islandEnabled.toggle()
        AppSettings.shared.persist()
        panel?.reposition(animated: true)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsRootView())
            let win = NSWindow(contentViewController: host)
            win.title = "cs.AI Island"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.setContentSize(NSSize(width: 540, height: 440))
            win.center()
            settingsWindow = win
        }
        NSApp.setActivationPolicy(.regular)
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
