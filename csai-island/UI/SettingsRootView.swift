import SwiftUI
import AppKit

struct SettingsRootView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var apiKey: String = KeychainCredentials.read()

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            appearance.tabItem { Label("Appearance", systemImage: "paintbrush") }
            ai.tabItem { Label("AI", systemImage: "sparkle") }
            events.tabItem { Label("Events", systemImage: "bell") }
        }
        .frame(width: 520, height: 420)
        .onDisappear { settings.persist(); KeychainCredentials.write(apiKey) }
    }

    private var general: some View {
        Form {
            Toggle("Enable Dynamic Island", isOn: $settings.islandEnabled)
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, v in LoginItemService.set(v) }
            Toggle("Expand on hover near notch", isOn: $settings.hoverToExpand)
            Picker("Island position", selection: $settings.position) {
                ForEach(IslandPosition.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
            Slider(value: $settings.animationIntensity, in: 0.5...1.6) { Text("Animation intensity") }
            Toggle("Automatically collapse HUD blips", isOn: $settings.autoCollapse)
            Slider(value: $settings.autoCollapseDelay, in: 1.2...8) { Text("Collapse delay") }
            Toggle("Keyboard shortcut (⌃⌥Space)", isOn: $settings.hotKeyEnabled)
        }
        .padding()
    }

    private var appearance: some View {
        Form {
            Picker("Appearance", selection: $settings.appearance) {
                Text("System").tag(IslandAppearance.system)
                Text("Dark").tag(IslandAppearance.dark)
                Text("Light").tag(IslandAppearance.light)
            }
            Slider(value: $settings.opacity, in: 0.55...1) { Text("Island opacity") }
            Slider(value: $settings.blurIntensity, in: 0.2...1) { Text("Blur intensity") }
            Slider(value: $settings.cornerRadius, in: 10...28) { Text("Corner radius") }
            Picker("Animation style", selection: $settings.animationStyle) {
                Text("Spring").tag(AnimationStyle.spring)
                Text("Snappy").tag(AnimationStyle.snappy)
                Text("Gentle").tag(AnimationStyle.gentle)
            }
        }
        .padding()
    }

    private var ai: some View {
        Form {
            Toggle("Enable cs.AI", isOn: $settings.aiEnabled)
            TextField("API endpoint", text: $settings.apiEndpoint)
            Picker("Default plate", selection: $settings.plate) {
                ForEach(PlateOption.allCases) { plate in
                    Label(plate.label, systemImage: plate.symbol).tag(plate)
                }
            }
            SecureField("API key (optional)", text: $apiKey)
                .help("Stored in Keychain. Public chopstickshq.com Flash does not require a key.")
            Toggle("Prefer streaming responses", isOn: $settings.streaming)
            Toggle("Keep conversation history", isOn: $settings.keepHistory)
            Text("Plates are Fast, Auto, Flash, and Core — no provider names in the island UI.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var events: some View {
        Form {
            Toggle("Music", isOn: $settings.eventMusic)
            Toggle("Volume", isOn: $settings.eventVolume)
            Toggle("Brightness", isOn: $settings.eventBrightness)
            Toggle("Battery", isOn: $settings.eventBattery)
            Toggle("Downloads", isOn: $settings.eventDownloads)
            Toggle("Notifications", isOn: $settings.eventNotifications)
            Toggle("Bluetooth", isOn: $settings.eventBluetooth)
            Toggle("Network / VPN", isOn: $settings.eventNetwork)
            Toggle("Screenshots", isOn: $settings.eventScreenshots)
            Toggle("Microphone / camera device events", isOn: $settings.eventCapture)
            Toggle("Focus", isOn: $settings.eventFocus)
        }
        .padding()
    }
}
