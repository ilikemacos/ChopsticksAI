import SwiftUI

private let kajiStarters = [
    "What’s Chopsticks HQ?",
    "Open chopstickshq.com and tell me what’s new",
    "Explain rNitro like I’m five",
    "Be Grok about shipping without a VM",
]

struct KajiAppView: View {
    @ObservedObject var store: AppStore
    @StateObject private var model = ChatModel()
    @ObservedObject private var auth = AuthStore.shared
    @FocusState private var focused: Bool
    @State private var previousTier = "tamago"

    private var showEmpty: Bool { model.lines.count <= 1 && !model.busy }
    private var kajiUnlocked: Bool {
        if store.usage.kajiAllowed { return true }
        if store.usage.keysValid >= 5 { return true }
        if (store.usage.accountPlan ?? "").localizedCaseInsensitiveContains("founder") { return true }
        if auth.email.lowercased() == "mzx@lam.ws" { return true }
        return false
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                header
                ZStack(alignment: .bottom) {
                    kajiMessages
                    if showEmpty { empty }
                    if !kajiUnlocked { proGate }
                }
                composer
            }
            .frame(minWidth: 420)
            .background(Color.black)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Web computer")
                        .font(.system(size: 12, weight: .semibold))
                    Text("No VM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Cursor.muted)
                    Spacer()
                }
                .foregroundStyle(Cursor.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black)
                ChromiumBrowserView()
            }
            .frame(minWidth: 280)
        }
        .background(Color.black)
        .onAppear {
            previousTier = store.tier
            store.setTier("kaji")
            model.ensureSession()
            focused = true
            Task { await store.refreshUsage() }
        }
        .onDisappear {
            if store.tier == "kaji" { store.setTier(previousTier) }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 13, weight: .semibold))
            Text("Kaji")
                .font(.system(size: 13, weight: .semibold))
            Text("·")
                .foregroundStyle(Cursor.muted)
            Text("Think different. Ask Kaji.")
                .font(.system(size: 12))
                .foregroundStyle(Cursor.muted)
            Spacer()
            Text("Pro")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Cursor.chromium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Cursor.chromium.opacity(0.16)))
            Button {
                model.newChat()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Cursor.soft)
            }
            .buttonStyle(.plain)
            .help("New Kaji chat")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black)
        .overlay(alignment: .bottom) { Rectangle().fill(Cursor.hairline).frame(height: 1) }
    }

    private var empty: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 36)
            Image(systemName: "sparkle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Cursor.text)
            Text("Think different. Ask Kaji.")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Cursor.text)
            Text("Grok-style assistant. Trained on Chopsticks HQ. The web is the computer.")
                .font(.system(size: 13.5))
                .foregroundStyle(Cursor.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(kajiStarters, id: \.self) { s in
                    Button {
                        Task { await model.send(s) }
                    } label: {
                        Text(s)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Cursor.soft)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Cursor.panel))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Cursor.border))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.busy || !kajiUnlocked)
                }
            }
            .frame(maxWidth: 480)
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 120)
    }

    private var proGate: some View {
        Color.black.opacity(0.72)
            .overlay {
                VStack(spacing: 12) {
                    Text("Think different. Ask Kaji.")
                        .font(.system(size: 22, weight: .bold))
                    Text("Kaji is a Pro app — five Fathom Pro keys or founder. Sign in, redeem in Usage, then come back.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Cursor.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                    HStack {
                        Button("Sign in") { store.nav = .account }
                            .buttonStyle(.borderedProminent)
                        Button("Usage") { store.nav = .usage }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(28)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Cursor.panel))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Cursor.border))
            }
    }

    private var kajiMessages: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(model.lines) { line in
                    if !(showEmpty && line.role == "assistant") {
                        MessageRow(line: line, compact: store.compact)
                    }
                }
                if model.busy {
                    Text("Thinking…")
                        .font(.system(size: 13))
                        .foregroundStyle(Cursor.muted)
                }
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask Kaji", text: $model.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .lineLimit(1...8)
                .focused($focused)
                .disabled(!kajiUnlocked)
                .onKeyPress { press in
                    guard press.key == .return, !press.modifiers.contains(.shift) else { return .ignored }
                    Task { await model.send(model.draft) }
                    return .handled
                }
            Button {
                Task { await model.send(model.draft) }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.busy || !kajiUnlocked ? Cursor.muted : Color.white))
            }
            .buttonStyle(.plain)
            .disabled(model.busy || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !kajiUnlocked)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Cursor.composer))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Cursor.border))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.black)
    }
}
