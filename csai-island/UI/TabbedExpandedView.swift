import SwiftUI
import AppKit

struct TabbedExpandedView: View {
    @ObservedObject var mgr = IslandStateManager.shared
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 10) {
            tabBar
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .foregroundStyle(.white)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(IslandTab.allCases) { tab in
                tabButton(tab)
            }
            Spacer(minLength: 4)
            Button(action: { AppDelegate.shared?.openSettings() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 24)
            }
            .buttonStyle(.plain)
            .help("Settings")
            if mgr.selectedTab == .ai {
                Button(action: mgr.toggleExtraExpanded) {
                    Image(systemName: mgr.phase == .extraExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 24)
                }
                .buttonStyle(.plain)
                .help(mgr.phase == .extraExpanded ? "Compact height" : "Taller chat")
            }
            Button(action: mgr.collapseExpanded) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 28, height: 24)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
    }

    private func tabButton(_ tab: IslandTab) -> some View {
        Button {
            mgr.selectTab(tab)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 10, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                mgr.selectedTab == tab
                    ? Color.white.opacity(0.14)
                    : Color.white.opacity(0.04),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch mgr.selectedTab {
        case .ai: AIChatTabView()
        case .media: MediaTabView()
        case .stats: StatsTabView()
        case .timers: TimersTabView()
        }
    }
}

struct AIChatTabView: View {
    @ObservedObject var chat = IslandStateManager.shared.chat
    @ObservedObject var settings = AppSettings.shared
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                Text("cs.AI")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                if chat.isGenerating { PulseDot() }
                Spacer()
                Menu {
                    ForEach(PlateOption.allCases) { plate in
                        Button {
                            settings.plate = plate
                            settings.persist()
                        } label: {
                            Label(plate.label, systemImage: plate.symbol)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: settings.plate.symbol)
                        Text(settings.plate.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08), in: Capsule())
                }
                .menuStyle(.borderlessButton)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if chat.turns.isEmpty && chat.streamingText.isEmpty {
                            Text("Ask cs.AI anything. Flash is the default plate against HQ — no key required.")
                                .font(.system(size: 11.5, design: .rounded))
                                .opacity(0.55)
                                .padding(.vertical, 4)
                        }
                        ForEach(chat.turns) { turn in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(turn.role == "user" ? "You" : "cs.AI")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .opacity(0.45)
                                if turn.role == "assistant" {
                                    MarkdownBubble(text: turn.text)
                                } else {
                                    Text(turn.text)
                                        .font(.system(size: 12.5, design: .rounded))
                                }
                            }
                            .id(turn.id)
                        }
                        if !chat.streamingText.isEmpty {
                            MarkdownBubble(text: chat.streamingText).id("stream")
                        }
                        if let err = chat.error {
                            Text(err)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.orange)
                                .id("err")
                        }
                    }
                }
                .onChange(of: chat.streamingText) { _, _ in
                    proxy.scrollTo("stream", anchor: .bottom)
                }
                .onChange(of: chat.turns.count) { _, _ in
                    if let last = chat.turns.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Ask cs.AI anything…", text: $chat.draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .rounded))
                    .focused($focused)
                    .onSubmit { chat.send() }
                if chat.isGenerating {
                    Button("Stop", action: chat.stop)
                        .font(.system(size: 11, weight: .semibold))
                } else {
                    Button(action: chat.send) {
                        Image(systemName: "arrow.up.circle.fill").font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(chat.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                Button("Clipboard", action: chat.askClipboard)
                Button("Copy", action: chat.copyLast)
                Button("Regenerate", action: chat.regenerate)
                Button("Clear", action: chat.clear)
                Spacer()
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .buttonStyle(.plain)
            .opacity(0.75)
        }
        .onAppear { focused = true }
    }
}

struct MediaTabView: View {
    @ObservedObject private var music = NowPlayingMonitor.shared

    var body: some View {
        if let info = music.current {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    artwork(info.artwork)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .lineLimit(2)
                        Text(info.artist)
                            .font(.system(size: 12, design: .rounded))
                            .opacity(0.65)
                    }
                    Spacer()
                }
                GeometryReader { g in
                    let p = info.duration > 0 ? info.elapsed / info.duration : 0
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 3)
                        Capsule().fill(Color.white)
                            .frame(width: g.size.width * CGFloat(min(1, max(0, p))), height: 3)
                    }
                }
                .frame(height: 8)
                HStack {
                    Spacer()
                    mediaButton("backward.fill") { NowPlayingMonitor.shared.send(MediaCommand.previous) }
                    mediaButton(info.isPlaying ? "pause.fill" : "play.fill", large: true) {
                        NowPlayingMonitor.shared.send(MediaCommand.playPause)
                    }
                    mediaButton("forward.fill") { NowPlayingMonitor.shared.send(MediaCommand.next) }
                    Spacer()
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 28))
                    .opacity(0.35)
                Text("Nothing playing")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .opacity(0.55)
                Text("Start music in Music, Spotify, or another app.")
                    .font(.system(size: 10.5, design: .rounded))
                    .opacity(0.4)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func artwork(_ img: NSImage?) -> some View {
        Group {
            if let img {
                Image(nsImage: img).resizable().scaledToFill()
            } else {
                ZStack {
                    Color.white.opacity(0.08)
                    Image(systemName: "music.note")
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func mediaButton(_ symbol: String, large: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(large ? .title2 : .title3)
        }
        .buttonStyle(.plain)
    }
}

struct StatsTabView: View {
    @ObservedObject private var statsMon = StatsMonitor.shared

    var body: some View {
        let s = statsMon.stats
        VStack(alignment: .leading, spacing: 12) {
            statRow(title: "CPU", value: String(format: "%.0f%%", s.cpuPercent), progress: s.cpuPercent / 100, symbol: "cpu")
            statRow(
                title: "Memory",
                value: String(format: "%.1f / %.1f GB", s.memoryUsedGB, s.memoryTotalGB),
                progress: s.memoryPercent,
                symbol: "memorychip"
            )
            HStack(spacing: 8) {
                Image(systemName: s.networkOnline ? "wifi" : "wifi.slash")
                Text(s.networkOnline ? "Online" : "Offline")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                Text(s.networkLabel)
                    .font(.system(size: 11, design: .rounded))
                    .opacity(0.65)
            }
            Text("Updated every few seconds while the island is open.")
                .font(.system(size: 9.5, design: .rounded))
                .opacity(0.4)
        }
    }

    private func statRow(title: String, value: String, progress: Double, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbol)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                Text(value)
                    .font(.system(size: 11, design: .rounded))
                    .monospacedDigit()
                    .opacity(0.75)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(Color.white.opacity(0.85))
                        .frame(width: g.size.width * CGFloat(min(1, max(0, progress))))
                }
            }
            .frame(height: 4)
        }
    }
}

struct TimersTabView: View {
    @ObservedObject private var store = TimerStore.shared
    @State private var label = ""
    @State private var minutes = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Label", text: $label)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .rounded))
                Stepper("\(minutes)m", value: $minutes, in: 1...120)
                    .font(.system(size: 11, design: .rounded))
                Button("Start") {
                    store.add(label: label, seconds: TimeInterval(minutes * 60))
                    label = ""
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            HStack(spacing: 8) {
                quickStart("1m", seconds: 60)
                quickStart("5m", seconds: 300)
                quickStart("10m", seconds: 600)
                quickStart("25m", seconds: 1500)
            }
            if store.timers.isEmpty {
                Text("No active timers. They appear as live HUD blips when running.")
                    .font(.system(size: 11, design: .rounded))
                    .opacity(0.5)
            } else {
                ForEach(store.timers) { timer in
                    HStack {
                        Image(systemName: "timer")
                        Text(timer.label)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(format(timer.remaining))
                            .monospacedDigit()
                            .font(.system(size: 12, design: .rounded))
                        Button {
                            store.remove(timer.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill").opacity(0.55)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func quickStart(_ title: String, seconds: TimeInterval) -> some View {
        Button(title) { store.add(label: title, seconds: seconds) }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08), in: Capsule())
            .buttonStyle(.plain)
    }

    private func format(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        if s >= 3600 { return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60) }
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
