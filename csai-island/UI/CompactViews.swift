import SwiftUI
import AppKit

struct CompactIslandContent: View {
    @ObservedObject var mgr = IslandStateManager.shared

    var body: some View {
        Group {
            if mgr.aiOpen {
                compactAI
            } else {
                switch mgr.active?.payload {
                case .music(let info): compactMusic(info)
                case .meter(let title, let value, let symbol): compactMeter(title, value, symbol)
                case .battery(let p, let c): compactBattery(p, c)
                case .text(let t, let d, let s): compactText(t, d, s)
                case .download(let n, let p): compactDownload(n, p)
                case .timer(let l, let r): compactTimer(l, r)
                case .alert(let t, let d): compactText(t, d, "exclamationmark.triangle.fill")
                default: idleDot
                }
            }
        }
        .foregroundStyle(.white)
    }

    private var idleDot: some View {
        Circle()
            .fill(Color.white.opacity(0.55))
            .frame(width: 7, height: 7)
    }

    private var compactAI: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
            Text("cs.AI")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            if mgr.chat.isGenerating { PulseDot() }
        }
    }

    private func compactMusic(_ info: NowPlayingInfo) -> some View {
        HStack(spacing: 8) {
            artwork(info.artwork)
            VStack(alignment: .leading, spacing: 1) {
                Text(info.title)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(info.artist)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.65)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button { NowPlayingMonitor.shared.send(MediaCommand.previous) } label: {
                Image(systemName: "backward.fill")
            }.buttonStyle(.plain)
            Button { NowPlayingMonitor.shared.send(MediaCommand.playPause) } label: {
                Image(systemName: info.isPlaying ? "pause.fill" : "play.fill")
            }.buttonStyle(.plain)
            Button { NowPlayingMonitor.shared.send(MediaCommand.next) } label: {
                Image(systemName: "forward.fill")
            }.buttonStyle(.plain)
        }
    }

    private func compactMeter(_ title: String, _ value: Double, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(Color.white.opacity(0.85)).frame(width: g.size.width * CGFloat(min(1, max(0, value))))
                }
            }
            .frame(height: 4)
        }
    }

    private func compactBattery(_ p: Int, _ c: Bool) -> some View {
        compactText(c ? "Charging" : "Battery", "\(p)%", c ? "battery.100.bolt" : "battery.100")
    }

    private func compactText(_ t: String, _ d: String, _ s: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: s)
            Text(t).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1)
            Text(d).font(.system(size: 11, design: .rounded)).opacity(0.7).lineLimit(1)
        }
    }

    private func compactDownload(_ n: String, _ p: Double?) -> some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
            Text(n).font(.system(size: 11.5, weight: .medium, design: .rounded)).lineLimit(1)
            if let p { Text("\(Int(p * 100))%").opacity(0.6).font(.system(size: 10, design: .rounded)) }
        }
    }

    private func compactTimer(_ l: String, _ r: TimeInterval) -> some View {
        HStack {
            Image(systemName: "timer")
            Text(l)
            Text(Self.clock(r)).monospacedDigit()
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
    }

    private func artwork(_ img: NSImage?) -> some View {
        Group {
            if let img {
                Image(nsImage: img).resizable().scaledToFill()
            } else {
                Image(systemName: "music.note").opacity(0.7)
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture { mgr.openExpanded(tab: .media) }
    }

    private static func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct PulseDot: View {
    @State private var on = false
    var body: some View {
        Circle()
            .fill(Color.cyan.opacity(on ? 1 : 0.35))
            .frame(width: 7, height: 7)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { on = true }
            }
    }
}
