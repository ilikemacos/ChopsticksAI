import Foundation
import AppKit

@MainActor
final class ChatController: ObservableObject {
    @Published var turns: [ChatTurn] = []
    @Published var draft: String = ""
    @Published var streamingText: String = ""
    @Published var isGenerating = false
    @Published var error: String?
    @Published var lastPrompt: String = ""

    private let service: AIService
    private let store = ConversationStore()

    init(service: AIService = CSAIService()) {
        self.service = service
        turns = store.load()
    }

    func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }
        draft = ""
        error = nil
        lastPrompt = text
        turns.append(ChatTurn(role: "user", text: text))
        persist()
        Task { await generate() }
    }

    func stop() {
        service.cancel()
        isGenerating = false
        if !streamingText.isEmpty {
            turns.append(ChatTurn(role: "assistant", text: streamingText))
            streamingText = ""
            persist()
        }
    }

    func regenerate() {
        guard !isGenerating else { return }
        if turns.last?.role == "assistant" { turns.removeLast() }
        guard turns.contains(where: { $0.role == "user" }) else { return }
        Task { await generate() }
    }

    func clear() {
        stop()
        turns = []
        streamingText = ""
        error = nil
        store.clear()
    }

    func copyLast() {
        let text = turns.last(where: { $0.role == "assistant" })?.text ?? streamingText
        guard !text.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func generate() async {
        isGenerating = true
        streamingText = ""
        error = nil
        do {
            let reply = try await service.complete(
                messages: turns,
                streaming: AppSettings.shared.streaming
            ) { [weak self] delta in
                Task { @MainActor in
                    self?.streamingText = delta
                }
            }
            turns.append(ChatTurn(role: "assistant", text: reply))
            streamingText = ""
            persist()
        } catch {
            if (error as? AIServiceError) != .cancelled {
                self.error = error.localizedDescription
            }
        }
        isGenerating = false
    }

    private func persist() { store.save(turns) }
}
