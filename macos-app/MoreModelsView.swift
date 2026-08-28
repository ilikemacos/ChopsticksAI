import SwiftUI

struct MoreModelsView: View {
    @ObservedObject private var store = MoreModelsStore.shared
    @State private var showKeys = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(
                title: "More models",
                subtitle: "Paste your Groq, OpenRouter, or Claude key, then pick any model from their catalogs."
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsCard(title: "API keys", subtitle: "Stored in Keychain on this Mac. Sent only with your chat requests — not used as Chopsticks HQ’s key.") {
                        keyRow("OpenRouter", placeholder: "sk-or-v1-…", text: $store.openRouterKey)
                        Divider().overlay(Cursor.hairline)
                        keyRow("Groq", placeholder: "gsk_…", text: $store.groqKey)
                        Divider().overlay(Cursor.hairline)
                        keyRow("Claude (Anthropic)", placeholder: "sk-ant-…", text: $store.anthropicKey)
                        HStack {
                            GhostButton(title: store.busy ? "Loading…" : "Load catalogs") {
                                Task { await store.refresh() }
                            }
                            .disabled(store.busy)
                            Spacer()
                            Toggle("Show keys", isOn: $showKeys)
                                .toggleStyle(.switch)
                                .font(.system(size: 12))
                                .foregroundStyle(Cursor.muted)
                        }
                    }

                    if !store.selectedModelId.isEmpty {
                        SettingsCard(title: "Active model") {
                            HStack {
                                Text(store.selectedLabel)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Cursor.text)
                                    .lineLimit(2)
                                Spacer()
                                GhostButton(title: "Use plates instead") {
                                    store.clearSelection()
                                }
                            }
                            Text(store.selectedModelId)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundStyle(Cursor.muted)
                                .textSelection(.enabled)
                        }
                    }

                    SettingsCard(title: "Catalog", subtitle: store.status.isEmpty ? "Load catalogs after saving a key. OpenRouter lists every public model; Groq and Claude list every model your key can see." : store.status) {
                        HStack(spacing: 8) {
                            Picker("", selection: $store.provider) {
                                Text("All").tag("all")
                                Text("Groq").tag("groq")
                                Text("Claude").tag("claude")
                                Text("OpenRouter").tag("openrouter")
                            }
                            .pickerStyle(.segmented)
                            TextField("Filter id or name", text: $store.filter)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
                        }
                        Text("\(store.filtered.count) shown")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Cursor.muted)

                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(store.filtered) { model in
                                Button {
                                    store.select(model.id)
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(badge(model.provider))
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Cursor.blue)
                                            .frame(width: 72, alignment: .leading)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(model.name)
                                                .font(.system(size: 12.5, weight: .medium))
                                                .foregroundStyle(Cursor.text)
                                                .lineLimit(1)
                                            Text(model.id)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundStyle(Cursor.muted)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        if store.selectedModelId == model.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Cursor.green)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                Divider().overlay(Cursor.hairline)
                            }
                        }
                    }
                }
                .padding(22)
            }
        }
        .background(Cursor.bg)
        .onAppear {
            if store.models.isEmpty {
                Task { await store.refresh() }
            }
        }
        .onChange(of: store.openRouterKey) { _, _ in store.saveKeys() }
        .onChange(of: store.groqKey) { _, _ in store.saveKeys() }
        .onChange(of: store.anthropicKey) { _, _ in store.saveKeys() }
    }

    private func badge(_ provider: String) -> String {
        switch provider {
        case "groq": return "GROQ"
        case "claude": return "CLAUDE"
        default: return "OR"
        }
    }

    @ViewBuilder
    private func keyRow(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Cursor.text)
            Group {
                if showKeys {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12.5, design: .monospaced))
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Cursor.hover))
        }
    }
}
