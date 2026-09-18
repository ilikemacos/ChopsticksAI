import SwiftUI
import AppKit

struct ExpandedIslandContent: View {
    @ObservedObject var mgr = IslandStateManager.shared

    var body: some View {
        Group {
            if mgr.aiOpen || mgr.kind == .ai {
                AIExpandedView()
            } else if case .music(let info) = mgr.active?.payload {
                expandedMusic(info)
            } else {
                CompactIslandContent()
                    .padding(.vertical, 8)
            }
        }
    }

    private func expandedMusic(_ info: NowPlayingInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Group {
                    if let art = info.artwork {
                        Image(nsImage: art).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Color.white.opacity(0.08)
                            Image(systemName: "music.note")
                        }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.title).font(.system(size: 15, weight: .semibold, design: .rounded)).lineLimit(2)
                    Text(info.artist).font(.system(size: 12, design: .rounded)).opacity(0.65)
                }
                Spacer()
            }
            GeometryReader { g in
                let p = info.duration > 0 ? info.elapsed / info.duration : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(height: 3)
                    Capsule().fill(Color.white).frame(width: g.size.width * CGFloat(min(1, max(0, p))), height: 3)
                }
            }
            .frame(height: 8)
            HStack {
                Spacer()
                Button { NowPlayingMonitor.shared.send(MediaCommand.previous) } label: { Image(systemName: "backward.fill").font(.title3) }
                Button { NowPlayingMonitor.shared.send(MediaCommand.playPause) } label: {
                    Image(systemName: info.isPlaying ? "pause.fill" : "play.fill").font(.title2)
                }
                Button { NowPlayingMonitor.shared.send(MediaCommand.next) } label: { Image(systemName: "forward.fill").font(.title3) }
                Spacer()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .padding(.vertical, 4)
    }
}

struct AIExpandedView: View {
    @ObservedObject var mgr = IslandStateManager.shared
    @ObservedObject var chat = IslandStateManager.shared.chat
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkle")
                Text("cs.AI")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                if chat.isGenerating { PulseDot() }
                Spacer()
                Button(action: { mgr.closeAI() }) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .foregroundStyle(.white)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
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
                Button("Copy", action: chat.copyLast)
                Button("Regenerate", action: chat.regenerate)
                Button("Clear", action: chat.clear)
                Spacer()
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .foregroundStyle(.white)
        .onAppear { focused = true }
    }
}
