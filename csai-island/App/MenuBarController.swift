import AppKit

final class MenuBarController {
    private var item: NSStatusItem?

    func start() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "capsule.portrait.fill", accessibilityDescription: "cs.AI Island")
        item.button?.image?.isTemplate = true
        let menu = NSMenu()
        let open = menu.addItem(withTitle: "Open cs.AI", action: #selector(AppDelegate.openAI), keyEquivalent: "")
        open.target = NSApp.delegate
        let toggle = menu.addItem(withTitle: "Toggle Island", action: #selector(AppDelegate.toggleIsland), keyEquivalent: "")
        toggle.target = NSApp.delegate
        menu.addItem(.separator())
        let settings = menu.addItem(withTitle: "Settings…", action: #selector(AppDelegate.openSettings), keyEquivalent: ",")
        settings.target = NSApp.delegate
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit cs.AI Island", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        self.item = item
    }
}
