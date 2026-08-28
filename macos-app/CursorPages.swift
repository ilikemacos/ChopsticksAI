import AppKit
import SwiftUI

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Cursor.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Cursor.muted)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Cursor.bg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Cursor.hairline).frame(height: 1)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(Cursor.accentFg)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Cursor.accent))
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .foregroundStyle(Cursor.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Cursor.hover))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Cursor.border))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyPane: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle().fill(Cursor.hover).frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Cursor.soft)
            }
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Cursor.text)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Cursor.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, icon: "plus", action: action)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Cursor.bg)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Cursor.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Cursor.muted)
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: 720, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Cursor.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Cursor.hairline)
        )
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Cursor.text)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Cursor.muted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

struct AutomationsView: View {
    @ObservedObject var store: AppStore
    @State private var selectedId: String?

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                title: "Automations",
                subtitle: "Run agents on a schedule or automatically in response to events.",
                trailing: AnyView(PrimaryButton(title: "New Automation", icon: "plus") {
                    store.addAutomation()
                    selectedId = store.automations.first?.id
                })
            )

            if store.automations.isEmpty {
                EmptyPane(
                    icon: "arrow.triangle.2.circlepath",
                    title: "No Automations Yet",
                    message: "Run agents on a schedule or automatically in response to events. Billed at plan rates.",
                    actionTitle: "New Automation"
                ) {
                    store.addAutomation()
                    selectedId = store.automations.first?.id
                }
            } else {
                HStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(store.automations) { item in
                                Button {
                                    selectedId = item.id
                                } label: {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(item.enabled ? Cursor.green : Cursor.muted)
                                            .frame(width: 7, height: 7)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(size: 12.5, weight: .medium))
                                                .foregroundStyle(Cursor.text)
                                                .lineLimit(1)
                                            Text(item.trigger)
                                                .font(.system(size: 11))
                                                .foregroundStyle(Cursor.muted)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(selectedId == item.id ? Cursor.selected : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                    }
                    .frame(width: 260)
                    .background(Cursor.sidebar)
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(Cursor.hairline).frame(width: 1)
                    }

                    if let id = selectedId, let idx = store.automations.firstIndex(where: { $0.id == id }) {
                        automationEditor(idx: idx)
                    } else {
                        EmptyPane(icon: "slider.horizontal.3", title: "Select an automation", message: "Pick one from the list or create a new automation.")
                    }
                }
            }
        }
        .background(Cursor.bg)
        .onAppear {
            if selectedId == nil { selectedId = store.automations.first?.id }
        }
    }

    private func automationEditor(idx: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsCard(title: "Name") {
                    TextField("Automation name", text: Binding(
                        get: { store.automations[idx].name },
                        set: { store.automations[idx].name = $0; store.saveAutomations() }
                    ))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Cursor.text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                }

                SettingsCard(title: "Trigger", subtitle: "When this automation should run") {
                    TextField("e.g. Schedule · Daily 9:00 or On PR opened", text: Binding(
                        get: { store.automations[idx].trigger },
                        set: { store.automations[idx].trigger = $0; store.saveAutomations() }
                    ))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Cursor.text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                }

                SettingsCard(title: "Repository") {
                    TextField("owner/repo or local name", text: Binding(
                        get: { store.automations[idx].repo },
                        set: { store.automations[idx].repo = $0; store.saveAutomations() }
                    ))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Cursor.text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                }

                SettingsCard(title: "Instructions") {
                    TextEditor(text: Binding(
                        get: { store.automations[idx].instructions },
                        set: { store.automations[idx].instructions = $0; store.saveAutomations() }
                    ))
                    .font(.system(size: 13))
                    .foregroundStyle(Cursor.text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                }

                SettingsCard(title: "Status") {
                    SettingsToggleRow(
                        title: "Enabled",
                        subtitle: "When off, this automation will not run.",
                        isOn: Binding(
                            get: { store.automations[idx].enabled },
                            set: { store.automations[idx].enabled = $0; store.saveAutomations() }
                        )
                    )
                }

                GhostButton(title: "Delete Automation", icon: "trash") {
                    let id = store.automations[idx].id
                    store.deleteAutomation(id)
                    selectedId = store.automations.first?.id
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Cursor.bg)
    }
}

struct ReposView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                title: "Repositories",
                subtitle: "Local repos available to agents and automations.",
                trailing: AnyView(PrimaryButton(title: "Add Repository", icon: "plus") {
                    store.pickRepoFolder()
                })
            )

            if store.repos.isEmpty {
                EmptyPane(
                    icon: "externaldrive",
                    title: "No repositories",
                    message: "Add a local folder so agents can work against a repo context.",
                    actionTitle: "Add Repository"
                ) {
                    store.pickRepoFolder()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.repos) { repo in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Cursor.hover)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "externaldrive.fill")
                                        .foregroundStyle(Cursor.soft)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(repo.name)
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .foregroundStyle(Cursor.text)
                                    Text(repo.path)
                                        .font(.system(size: 11.5, design: .monospaced))
                                        .foregroundStyle(Cursor.muted)
                                        .lineLimit(1)
                                    if !repo.remote.isEmpty {
                                        Text(repo.remote)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Cursor.soft)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                GhostButton(title: "Remove") {
                                    store.removeRepo(repo.id)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Cursor.panel)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Cursor.hairline)
                            )
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
                .background(Cursor.bg)
            }
        }
        .background(Cursor.bg)
    }
}

struct AccountView: View {
    @ObservedObject var auth = AuthStore.shared
    @ObservedObject var store: AppStore
    var onSignedIn: (() -> Void)?
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var error = ""

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                title: "Account",
                subtitle: "Email and password via chopstickshq.com — sync chats across Lab and macOS."
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if auth.isSignedIn {
                        SettingsCard(title: "Signed in", subtitle: auth.email) {
                            Text("Chats sync to your account after each reply.")
                                .font(.system(size: 12.5))
                                .foregroundStyle(Cursor.muted)
                            HStack {
                                PrimaryButton(title: "Reload cloud chats", icon: "arrow.clockwise") {
                                    onSignedIn?()
                                }
                                GhostButton(title: "Sign out") {
                                    Task { await auth.signOut() }
                                }
                            }
                            if !auth.statusMessage.isEmpty {
                                Text(auth.statusMessage)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Cursor.soft)
                            }
                        }
                    } else {
                        SettingsCard(title: "Sign in or create account", subtitle: "Email + password.") {
                            TextField("Email", text: $email)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Cursor.text)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                            SecureField("Password (min 6)", text: $password)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Cursor.text)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                            TextField("6-digit email code (after first step)", text: $code)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Cursor.text)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                            if !error.isEmpty {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.red.opacity(0.85))
                            }
                            if !auth.statusMessage.isEmpty {
                                Text(auth.statusMessage)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Cursor.green)
                            }
                            HStack {
                                PrimaryButton(title: auth.busy ? "Working…" : "Sign in") {
                                    Task { await signIn() }
                                }
                                GhostButton(title: "Create account") {
                                    Task { await signUp() }
                                }
                            }
                        }
                    }

                    SettingsCard(title: "Privacy", subtitle: "Cloud sync") {
                        Text("Auth runs on chopstickshq.com — the app never talks to Supabase Auth directly. Chats sync when signed in.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Cursor.muted)
                        Link("Privacy policy", destination: URL(string: "https://chopstickshq.com/chopsticks-ai/privacy.html")!)
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.blue)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Cursor.bg)
        }
        .background(Cursor.bg)
    }

    private func signIn() async {
        error = ""
        do {
            let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let digits = code.trimmingCharacters(in: .whitespacesAndNewlines)
            if digits.count == 6 {
                let token = UserDefaults.standard.string(forKey: "chopsticksAI.pendingLoginToken") ?? ""
                try await auth.signIn(email: trimmed, password: password, code: digits, loginToken: token)
            } else {
                try await auth.signIn(email: trimmed, password: password)
            }
            if auth.isSignedIn { onSignedIn?() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func signUp() async {
        error = ""
        do {
            let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let digits = code.trimmingCharacters(in: .whitespacesAndNewlines)
            if digits.count == 6 {
                let token = UserDefaults.standard.string(forKey: "chopsticksAI.pendingSignupToken") ?? ""
                try await auth.signUp(email: trimmed, password: password, code: digits, signupToken: token)
            } else {
                try await auth.signUp(email: trimmed, password: password)
            }
            if auth.isSignedIn { onSignedIn?() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct UsageView: View {
    @ObservedObject var store: AppStore
    @State private var redeemError: String?
    @State private var cooldownEndsAt: Date?

    private var barColor: Color {
        if store.usage.blocked { return Color.orange.opacity(0.85) }
        if store.usage.warningLevel == "critical" { return Color.red.opacity(0.8) }
        if store.usage.nearLimit { return Color.orange.opacity(0.85) }
        return Cursor.blue
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                title: "Usage",
                subtitle: "Allowance resets every 5 hours. Redeem Fathom Pro keys for higher limits.",
                trailing: AnyView(
                    GhostButton(title: store.usageBusy ? "Refreshing…" : "Refresh", icon: "arrow.clockwise") {
                        Task { await store.refreshUsage() }
                    }
                )
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    usageCard
                    upgradesCard
                    redeemCard
                    keysCard
                    Text("Credits come from Fathom Pro oi-pl unlock keys (scavenger / vault) — not OpenRouter sk-or keys. The live model still runs on Chopsticks HQ’s server key.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Cursor.muted)
                        .frame(maxWidth: 720, alignment: .leading)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Cursor.bg)
        }
        .background(Cursor.bg)
        .task { await store.refreshUsage() }
        .onChange(of: store.usage.blocked) { _, blocked in
            if blocked, store.usage.retryInMs > 0 {
                cooldownEndsAt = Date().addingTimeInterval(Double(store.usage.retryInMs) / 1000)
            } else {
                cooldownEndsAt = nil
            }
        }
        .onChange(of: store.usage.retryInMs) { _, ms in
            if store.usage.blocked, ms > 0 {
                cooldownEndsAt = Date().addingTimeInterval(Double(ms) / 1000)
            }
        }
    }

    private var usageCard: some View {
        SettingsCard(title: "Current plan", subtitle: store.usage.tierDetail) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.usage.tierLabel)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Cursor.text)
                    if let plan = store.usage.accountPlan {
                        Text(plan)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Cursor.green)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(UsageSnapshot.fmtTokens(store.usage.used)) / \(UsageSnapshot.fmtTokens(store.usage.limit))")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Cursor.soft)
                    Text("Context \(UsageSnapshot.fmtTokens(store.usage.contextLimit))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Cursor.muted)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Cursor.hover)
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(4, geo.size.width * store.usage.progress))
                }
            }
            .frame(height: 8)

            if store.usage.blocked {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let leftMs: Int = {
                        if let end = cooldownEndsAt {
                            return max(0, Int(end.timeIntervalSinceNow * 1000))
                        }
                        return store.usage.retryInMs
                    }()
                    Text("Cooling down — \(UsageSnapshot.fmtCooldown(leftMs)) left.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.orange.opacity(0.9))
                }
            } else if let msg = store.usage.warningMessage {
                Text(msg)
                    .font(.system(size: 12.5))
                    .foregroundStyle(store.usage.warningLevel == "critical" ? Color.red.opacity(0.85) : Color.orange.opacity(0.9))
            } else if store.usage.resetInMs > 0 {
                TimelineView(.periodic(from: .now, by: 30)) { _ in
                    Text("Resets at \(UsageSnapshot.fmtResetsAt(store.usage.resetInMs)) · \(UsageSnapshot.fmtCooldown(store.usage.resetInMs)) left")
                        .font(.system(size: 12))
                        .foregroundStyle(Cursor.muted)
                }
            } else {
                Text("Cooldown after limit: \(UsageSnapshot.fmtCooldown(store.usage.cooldownMs)) · \(store.usage.keysValid) valid key\(store.usage.keysValid == 1 ? "" : "s") redeemed")
                    .font(.system(size: 12))
                    .foregroundStyle(Cursor.muted)
            }

            if let err = store.usage.error ?? redeemError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.red.opacity(0.85))
            }
        }
    }

    private var upgradesCard: some View {
        SettingsCard(title: "Upgrades", subtitle: "Redeem Fathom Pro API keys as credits.") {
            ForEach(store.usage.upgrades) { up in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: up.unlocked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(up.unlocked ? Cursor.green : Cursor.muted)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(up.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Cursor.text)
                        Text(up.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(Cursor.muted)
                        Text("\(up.keysRequired) keys · \(UsageSnapshot.fmtTokens(up.limit)) tokens · \(UsageSnapshot.fmtTokens(up.contextLimit)) context")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Cursor.soft)
                    }
                    Spacer()
                    Text(up.unlocked ? "Active" : "Locked")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(up.unlocked ? Cursor.green : Cursor.muted)
                }
                if up.id != store.usage.upgrades.last?.id {
                    Divider().overlay(Cursor.hairline)
                }
            }
        }
    }

    private var redeemCard: some View {
        SettingsCard(title: "Redeem Fathom Pro API key", subtitle: "Paste an oi-pl key from the site scavenger (10‑minute cooldown) or vault.") {
            TextField("oi-pl-…………-…………-…………", text: $store.keyDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(Cursor.text)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                .onSubmit { redeem() }

            HStack {
                PrimaryButton(title: "Redeem key", icon: "plus") { redeem() }
                GhostButton(title: "Get a key") {
                    if let url = URL(string: "https://chopstickshq.com/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Spacer()
            }
        }
    }

    private var keysCard: some View {
        SettingsCard(title: "Redeemed keys", subtitle: "\(store.unlockKeys.count) stored locally · validated on each request") {
            if store.unlockKeys.isEmpty {
                Text("No keys yet. Find the scavenger on chopstickshq.com (Small lab.) — 10 minute cooldown between finds.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Cursor.muted)
            } else {
                ForEach(store.unlockKeys, id: \.self) { key in
                    HStack {
                        Text(maskKey(key))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Cursor.soft)
                            .lineLimit(1)
                        Spacer()
                        Button("Remove") {
                            store.removeUnlockKey(key)
                            Task { await store.refreshUsage() }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Cursor.muted)
                    }
                    if key != store.unlockKeys.last {
                        Divider().overlay(Cursor.hairline)
                    }
                }
            }
        }
    }

    private func redeem() {
        if let err = store.redeemKeyDraft() {
            redeemError = err
            return
        }
        redeemError = nil
        Task { await store.refreshUsage() }
    }

    private func maskKey(_ key: String) -> String {
        let k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard k.count > 18 else { return k }
        return String(k.prefix(12)) + "…" + String(k.suffix(8))
    }
}

struct MozillaSearchHit: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let url: String
    let snippet: String
    let via: String
}

struct MozillaSearchView: View {
    @State private var query = ""
    @State private var busy = false
    @State private var status = "Same Chromium engine cs.AI uses before every answer."
    @State private var results: [MozillaSearchHit] = []
    @FocusState private var focused: Bool

    private let apiURL = URL(string: "https://chopstickshq.com/api/chopsticks-ai")!

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                title: "Search",
                subtitle: "Chromium engine · Google · DuckDuckGo",
                trailing: AnyView(
                    GhostButton(title: busy ? "Searching…" : "Search", icon: "magnifyingglass") {
                        Task { await runSearch() }
                    }
                )
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    searchCard
                    resultsCard
                }
                .padding(22)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Cursor.bg)
        }
        .background(Cursor.bg)
        .onAppear { focused = true }
    }

    private var searchCard: some View {
        SettingsCard(title: "Chromium engine", subtitle: "No API key. Results from Google and DuckDuckGo; chopsticks queries prioritize chopstickshq.com.") {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Cursor.mozilla)
                TextField("Search the web…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Cursor.text)
                    .focused($focused)
                    .onSubmit { Task { await runSearch() } }
                Button {
                    Task { await runSearch() }
                } label: {
                    Text(busy ? "…" : "Search")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.88))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Cursor.mozilla))
                }
                .buttonStyle(.plain)
                .disabled(busy || query.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Cursor.composer))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Cursor.border))

            Text(status)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(Cursor.muted)
        }
    }

    @ViewBuilder
    private var resultsCard: some View {
        if results.isEmpty {
            EmptyView()
        } else {
            SettingsCard(title: "Results", subtitle: "\(results.count) hit\(results.count == 1 ? "" : "s")") {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(results) { hit in
                        Button {
                            if let url = URL(string: hit.url), !hit.url.isEmpty {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(hit.title)
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .foregroundStyle(Cursor.blue)
                                        .multilineTextAlignment(.leading)
                                    Text(hit.via)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Cursor.mozilla)
                                }
                                if !hit.url.isEmpty {
                                    Text(hit.url)
                                        .font(.system(size: 10.5, design: .monospaced))
                                        .foregroundStyle(Cursor.muted)
                                        .lineLimit(1)
                                }
                                if !hit.snippet.isEmpty {
                                    Text(hit.snippet)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Cursor.soft)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        if hit.id != results.last?.id {
                            Divider().overlay(Cursor.hairline)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 3 else {
            status = "Enter at least 3 characters."
            return
        }
        busy = true
        status = "Searching Chromium engine…"
        defer { busy = false }

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 20
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "action": "search",
            "q": q,
            "max": 8,
        ])

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
                  let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                status = "Search failed — try again shortly."
                results = []
                return
            }
            let raw = obj["sources"] as? [[String: Any]] ?? []
            results = raw.map { row in
                MozillaSearchHit(
                    title: row["title"] as? String ?? q,
                    url: row["url"] as? String ?? "",
                    snippet: row["snippet"] as? String ?? "",
                    via: row["via"] as? String ?? "Mozilla"
                )
            }
            if results.isEmpty {
                status = "No results for “\(q)”."
            } else {
                let engine = obj["engine"] as? String ?? "mozilla"
                status = "\(results.count) result\(results.count == 1 ? "" : "s") · \(engine)"
            }
        } catch {
            status = "Network error — check your connection."
            results = []
        }
    }
}

struct CloudAgentsView: View {
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Cloud Agents", subtitle: "Run agents in the cloud across repos.")
            EmptyPane(
                icon: "cloud",
                title: "Cloud Agents",
                message: "Launch long-running agents that keep working across repositories. Connect chopstickshq.com for live runs.",
                actionTitle: "Open Dashboard"
            ) {
                if let url = URL(string: "https://chopstickshq.com/chopailab/") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

struct MarketplaceView: View {
    @ObservedObject var store = AppStore.shared

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Marketplace", subtitle: "Plugins and extensions for agents.")
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    pluginCard(name: "Chromium Browser", desc: "Built-in web browser + Google search — Browser rail.", installed: true)
                    kajiCard
                    pluginCard(name: "Product KB", desc: "Offline Chopsticks HQ knowledge base.", installed: true)
                    pluginCard(name: "MCP Bridge", desc: "Connect Model Context Protocol servers.", installed: false)
                    pluginCard(name: "GitHub", desc: "Repos, PRs, and issues context.", installed: false)
                }
                .padding(22)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .background(Cursor.bg)
        }
    }

    private func pluginCard(name: String, desc: String, installed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Cursor.text)
                Spacer()
                Text(installed ? "Installed" : "Available")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(installed ? Cursor.green : Cursor.muted)
            }
            Text(desc)
                .font(.system(size: 12.5))
                .foregroundStyle(Cursor.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            GhostButton(title: installed ? "Manage" : "Install") {}
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Cursor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Cursor.hairline))
    }

    @ViewBuilder
    private var kajiCard: some View {
        if CSAIEdition.current.isOffline {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Kaji")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Cursor.text)
                    Spacer()
                    Text("App")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Cursor.chromium)
                }
                Text("Think different. Ask Kaji. Alpha Grok-style Pro app — prone to wrong answers. The web is the computer — no VM.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Cursor.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                GhostButton(title: "Open") {
                    store.nav = .kaji
                    store.setTier("kaji")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Cursor.panel))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Cursor.hairline))
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var updater: AppAutoUpdate
    @ObservedObject private var network = NetworkStatus.shared

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(SettingsSection.allCases) { section in
                        Button {
                            store.settingsSection = section
                        } label: {
                            Text(section.title)
                                .font(.system(size: 12.5, weight: store.settingsSection == section ? .semibold : .regular))
                                .foregroundStyle(store.settingsSection == section ? Cursor.text : Cursor.soft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(store.settingsSection == section ? Cursor.selected : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
            .frame(width: 220)
            .background(Cursor.sidebar)
            .overlay(alignment: .trailing) {
                Rectangle().fill(Cursor.hairline).frame(width: 1)
            }

            settingsDetail
        }
        .background(Cursor.bg)
    }

    @ViewBuilder
    private var settingsDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.settingsSection.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Cursor.text)
                    .padding(.bottom, 4)

                switch store.settingsSection {
                case .general:
                    SettingsCard(title: "Application") {
                        SettingsToggleRow(
                            title: "Compact layout",
                            subtitle: "Tighter spacing in the Agents panel.",
                            isOn: Binding(get: { store.compact }, set: { store.setCompact($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Show sidebar",
                            subtitle: "Secondary Agents / page sidebar. Also toggled from the rail.",
                            isOn: Binding(
                                get: { store.sidebarExpanded },
                                set: { on in
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                        store.setSidebarExpanded(on)
                                    }
                                }
                            )
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Show nav labels",
                            subtitle: "Label each rail item with text (Agents, Search, Usage…). Turn off for icon-only.",
                            isOn: Binding(get: { store.railLabels }, set: { store.setRailLabels($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Install updates automatically",
                            subtitle: "Download and apply chopsticksAI updates when available.",
                            isOn: $updater.autoInstall
                        )
                        Divider().overlay(Cursor.hairline)
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Language")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Cursor.text)
                                Text("Replies from cs.AI use this language.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Cursor.muted)
                            }
                            Spacer()
                            Picker("", selection: Binding(get: { store.language }, set: { store.setLanguage($0) })) {
                                ForEach(AppStore.supportedLanguages, id: \.code) { lang in
                                    Text(lang.label).tag(lang.code)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }
                        Divider().overlay(Cursor.hairline)
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Version")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Cursor.text)
                                Text("cs.AI \(updater.currentVersion)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Cursor.muted)
                            }
                            Spacer()
                            GhostButton(title: "What’s New") {
                                WhatsNew.presentManually()
                            }
                            GhostButton(title: "Check for Updates") {
                                AppAutoUpdate.shared.checkManually()
                            }
                        }
                    }

                case .chat:
                    SettingsCard(title: "Chat mode", subtitle: CSAIEdition.current.isOffline
                                ? "cs.AI Offline — on-device knowledge base only."
                                : "cs.AI Online — live models. Does not use the local KB.") {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Connection")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Cursor.text)
                                Text(network.statusLabel)
                                    .font(.system(size: 12))
                                    .foregroundStyle(network.isOnline ? Cursor.green : Cursor.soft)
                            }
                            Spacer()
                            Image(systemName: network.isOnline ? "wifi" : "wifi.slash")
                                .foregroundStyle(network.isOnline ? Cursor.green : Cursor.soft)
                        }
                        Divider().overlay(Cursor.hairline)
                        Text(CSAIEdition.current.isOffline
                             ? "This is cs.AI Offline. Answers come only from the on-device knowledge base."
                             : "This is cs.AI Online. Live models via chopstickshq.com — it does not fall back to the local KB.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                    }

                case .appearance:
                    SettingsCard(title: "Theme", subtitle: "Agents Window uses Cursor-style dark chrome.") {
                        Text("Dark (Cursor)")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                    }

                case .agents:
                    SettingsCard(title: "Agent behavior") {
                        SettingsToggleRow(
                            title: "Auto-run",
                            subtitle: "Allow the agent to run tools without confirming every step.",
                            isOn: Binding(get: { store.autoRun }, set: { store.setAutoRun($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Max mode",
                            subtitle: "Prefer higher effort for complex tasks.",
                            isOn: Binding(get: { store.maxMode }, set: { store.setMaxMode($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "File creation tools",
                            subtitle: "Let the agent call write_file to produce downloadable files.",
                            isOn: Binding(get: { store.enableTools }, set: { store.setEnableTools($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Web search",
                            subtitle: "Automatic Chromium lookup on each question. Off = faster model-only replies; `/search …` still forces lookup.",
                            isOn: Binding(get: { store.webSearchEnabled }, set: { store.setWebSearchEnabled($0) })
                        )
                    }

                case .models:
                    SettingsCard(title: "Plate", subtitle: "Rice → Tamago → Hibachi → Wagyu. ChopCode and Kaji are Pro. Kaji is alpha and prone to wrong answers.") {
                        ForEach([
                            ("rice", "Rice"), ("tamago", "Tamago"), ("hibachi", "Hibachi"),
                            ("wagyua1", "Wagyu A1"), ("wagyua2", "Wagyu A2"), ("wagyua3", "Wagyu A3"),
                            ("wagyua4", "Wagyu A4"), ("wagyua5", "Wagyu A5"),
                            ("chopcode", "ChopCode"),
                            ("kaji", "Kaji"),
                            ("stickercoderplus", "StickerCoder+"),
                        ], id: \.0) { id, label in
                            Button {
                                store.setTier(id)
                            } label: {
                                HStack {
                                    Text(label)
                                        .foregroundStyle(Cursor.text)
                                    Spacer()
                                    if store.tier == id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Cursor.blue)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            if id != "stickercoderplus" { Divider().overlay(Cursor.hairline) }
                        }
                    }
                    SettingsCard(title: "More models") {
                        Text("Bring your Groq, OpenRouter, or Claude API key and pick from their full catalogs.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                        GhostButton(title: "Open More models") {
                            store.nav = .moreModels
                        }
                    }

                case .rules:
                    SettingsCard(title: "User Rules", subtitle: "Rules that guide agent behavior across chats.") {
                        TextEditor(text: Binding(
                            get: { store.userRules },
                            set: { store.setUserRules($0) }
                        ))
                        .font(.system(size: 13))
                        .foregroundStyle(Cursor.text)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                    }
                    SettingsCard(title: "Custom Modes", subtitle: "Named agent modes with instructions and tools.") {
                        PrimaryButton(title: "Manage Custom Modes", icon: "slider.horizontal.3") {
                            store.settingsSection = .customize
                        }
                    }

                case .customize:
                    CustomizeModesView(store: store)

                case .plugins:
                    SettingsCard(title: "Plugins", subtitle: "Installed agent plugins.") {
                        Text("Web Search · Product KB")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                        GhostButton(title: "Open Marketplace") {
                            store.nav = .marketplace
                        }
                    }

                case .mcp:
                    SettingsCard(title: "Built-in tools") {
                        SettingsToggleRow(
                            title: "write_file",
                            subtitle: "Model tool-calls create files you can save from chat.",
                            isOn: Binding(get: { store.enableTools }, set: { store.setEnableTools($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Confirm before saving",
                            subtitle: "Show a save panel for each file. Off writes to the default folder.",
                            isOn: Binding(get: { store.confirmFileSave }, set: { store.setConfirmFileSave($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Default write folder")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Cursor.text)
                            Text(store.defaultWriteFolder.isEmpty
                                 ? "~/Downloads/cs.AI"
                                 : store.defaultWriteFolder)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Cursor.muted)
                                .lineLimit(2)
                            HStack {
                                GhostButton(title: "Choose…") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    panel.canCreateDirectories = true
                                    panel.begin { resp in
                                        guard resp == .OK, let url = panel.url else { return }
                                        store.setDefaultWriteFolder(url.path)
                                    }
                                }
                                if !store.defaultWriteFolder.isEmpty {
                                    GhostButton(title: "Reset") {
                                        store.setDefaultWriteFolder("")
                                    }
                                }
                            }
                        }
                    }
                    SettingsCard(title: "MCP servers", subtitle: "External Model Context Protocol servers.") {
                        Text("No MCP servers configured yet.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.muted)
                        Text("Custom MCP config lands in a later build — write_file works today.")
                            .font(.system(size: 12))
                            .foregroundStyle(Cursor.muted)
                    }

                case .indexing:
                    SettingsCard(title: "Indexing & Docs", subtitle: "Code intelligence for local repositories.") {
                        Text(store.repos.isEmpty
                              ? "Add a repository to enable indexing."
                              : "\(store.repos.count) repo(s) ready for indexing.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                        GhostButton(title: "Manage Repositories") {
                            store.nav = .repos
                        }
                    }

                case .hooks:
                    SettingsCard(title: "Hooks", subtitle: "Run scripts around agent lifecycle events.") {
                        Text("No hooks configured.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.muted)
                    }

                case .cloudAgents:
                    SettingsCard(title: "Cloud Agents") {
                        Text("Use the Cloud Agents pane to launch remote runs.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                        GhostButton(title: "Open Cloud Agents") {
                            store.nav = .cloudAgents
                        }
                    }

                case .network:
                    SettingsCard(title: "Network") {
                        SettingsToggleRow(
                            title: "Web search",
                            subtitle: "In-app WebKit browser (not Chromium). Turn off to skip lookups and save time.",
                            isOn: Binding(get: { store.webSearchEnabled }, set: { store.setWebSearchEnabled($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        Text("API endpoint")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Cursor.muted)
                        Text("https://chopstickshq.com/api/chopsticks-ai")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundStyle(Cursor.text)
                            .textSelection(.enabled)
                    }

                case .beta:
                    SettingsCard(title: "Beta features") {
                        SettingsToggleRow(
                            title: "Inline file previews",
                            subtitle: "Show a code preview inside file cards in chat.",
                            isOn: Binding(get: { store.betaFilePreview }, set: { store.setBetaFilePreview($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        SettingsToggleRow(
                            title: "Nav labels",
                            subtitle: "Text labels on the left rail (same as General).",
                            isOn: Binding(get: { store.railLabels }, set: { store.setRailLabels($0) })
                        )
                        Divider().overlay(Cursor.hairline)
                        Text("You're on the cs.AI Agents Window build with tool-call file creation.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                    }

                case .privacy:
                    SettingsCard(title: "Privacy Mode") {
                        if CSAIEdition.current.isOffline {
                            SettingsToggleRow(
                                title: "Privacy Mode",
                                subtitle: "Skip cloud API calls and chat sync; answers come from the local product KB only.",
                                isOn: Binding(get: { store.privacyMode }, set: { store.setPrivacyMode($0) })
                            )
                        } else {
                            Text("Privacy Mode is Offline-only. Online always uses live models (signed in).")
                                .font(.system(size: 12.5))
                                .foregroundStyle(Cursor.muted)
                        }
                        Divider().overlay(Cursor.hairline)
                        Link("Privacy policy", destination: URL(string: "https://chopstickshq.com/chopsticks-ai/privacy.html")!)
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.blue)
                    }

                case .planUsage:
                    SettingsCard(title: "Plan & Usage", subtitle: "Open the Usage tab for allowance, cooldown, and Fathom Pro upgrades.") {
                        Text("Free via chopstickshq.com — upgrades use Fathom Pro oi-pl keys, not OpenRouter.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.soft)
                        HStack {
                            PrimaryButton(title: "Open Usage", icon: "chart.bar") {
                                store.nav = .usage
                            }
                            GhostButton(title: "Open chopAI Lab") {
                                if let url = URL(string: "https://chopstickshq.com/chopailab/") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Cursor.bg)
    }
}

struct CustomizeModesView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Custom Modes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Cursor.text)
                Spacer()
                PrimaryButton(title: "New Mode", icon: "plus") {
                    store.addMode()
                }
            }

            ForEach($store.customModes) { $mode in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Mode name", text: $mode.name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Cursor.text)
                            .onChange(of: mode.name) { _, _ in store.saveModes() }
                        Spacer()
                        Button {
                            store.selectedModeId = mode.id
                        } label: {
                            Text(store.selectedModeId == mode.id ? "Active" : "Use")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(store.selectedModeId == mode.id ? Cursor.green : Cursor.soft)
                        }
                        .buttonStyle(.plain)
                        Button {
                            store.deleteMode(mode.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(Cursor.muted)
                        }
                        .buttonStyle(.plain)
                    }
                    TextEditor(text: $mode.instructions)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Cursor.text)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 72)
                        .onChange(of: mode.instructions) { _, _ in store.saveModes() }
                    Text("Tools: \(mode.tools.joined(separator: ", "))")
                        .font(.system(size: 11))
                        .foregroundStyle(Cursor.muted)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Cursor.hover))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Cursor.border))
            }
        }
        .padding(16)
        .frame(maxWidth: 720, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Cursor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Cursor.hairline))
    }
}
