import Foundation
import Combine

@MainActor
final class IslandStateManager: ObservableObject {
    static let shared = IslandStateManager()

    @Published private(set) var events: [IslandEvent] = []
    @Published var phase: IslandPhase = .idle
    @Published var userPinned = false
    @Published var hover = false
    @Published var aiOpen = false

    let chat = ChatController()
    let settings = AppSettings.shared

    private var collapseItem: DispatchWorkItem?
    private var tick: Timer?

    private init() {
        tick = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.prune() }
        }
    }

    var active: IslandEvent? {
        if aiOpen {
            return events.first(where: { $0.kind == .ai })
                ?? IslandEvent(kind: .ai, sticky: true, ttl: nil, payload: .none)
        }
        let ranked = events
            .filter { settings.enabled(for: $0.kind) }
            .sorted { a, b in
                rank(a.kind) < rank(b.kind)
                    || (rank(a.kind) == rank(b.kind) && a.createdAt > b.createdAt)
            }
        return ranked.first
    }

    var kind: IslandKind { active?.kind ?? .idle }

    func post(_ event: IslandEvent) {
        guard settings.islandEnabled, settings.enabled(for: event.kind) else { return }
        events.removeAll { $0.kind == event.kind && !event.sticky }
        events.append(event)
        if event.kind == .ai { aiOpen = true }
        if !userPinned && !aiOpen {
            phase = event.kind == .music ? .compact : .compact
            scheduleCollapse(after: event.sticky ? nil : settings.autoCollapseDelay)
        }
        objectWillChange.send()
    }

    func update(kind: IslandKind, payload: IslandPayload) {
        if let idx = events.lastIndex(where: { $0.kind == kind }) {
            events[idx].payload = payload
        } else {
            post(IslandEvent(kind: kind, ttl: settings.autoCollapseDelay, payload: payload))
        }
    }

    func openAI() {
        guard settings.aiEnabled else { return }
        aiOpen = true
        userPinned = true
        phase = .expanded
        post(IslandEvent(kind: .ai, sticky: true, ttl: nil, payload: .none))
        collapseItem?.cancel()
    }

    func closeAI() {
        aiOpen = false
        events.removeAll { $0.kind == .ai }
        userPinned = false
        collapseSoon()
    }

    func toggleExpand() {
        if aiOpen {
            closeAI()
            return
        }
        if phase == .expanded {
            userPinned = false
            phase = active == nil ? .idle : .compact
            collapseSoon()
        } else {
            userPinned = true
            if kind == .idle { openAI() }
            else { phase = .expanded }
            collapseItem?.cancel()
        }
    }

    func collapseSoon() {
        scheduleCollapse(after: 0.35)
    }

    func onHover(_ on: Bool) {
        hover = on
        if on, phase == .idle, active != nil { phase = .compact }
        if on { collapseItem?.cancel() }
        else if !userPinned && !aiOpen { scheduleCollapse(after: 1.1) }
    }

    func escape() {
        if chat.isGenerating { chat.stop(); return }
        if aiOpen { closeAI(); return }
        userPinned = false
        phase = .idle
    }

    private func rank(_ kind: IslandKind) -> Int {
        settings.priority.firstIndex(of: kind) ?? 50
    }

    private func prune() {
        let now = Date()
        events.removeAll { ev in
            if ev.sticky || ev.kind == .ai { return false }
            if let exp = ev.expiresAt { return exp < now }
            return false
        }
        if !userPinned && !aiOpen && !hover && (active == nil || phase != .expanded) {
            if active == nil { phase = .idle }
        }
        if let idx = events.firstIndex(where: { $0.kind == .timer }) {
            if case .timer(let label, let remaining) = events[idx].payload {
                let next = remaining - 0.35
                if next <= 0 {
                    events.remove(at: idx)
                    post(IslandEvent(kind: .systemAlert, ttl: 4, payload: .alert(title: "Timer", detail: "\(label) is done")))
                } else {
                    events[idx].payload = .timer(label: label, remaining: next)
                }
            }
        }
    }

    private func scheduleCollapse(after delay: Double?) {
        collapseItem?.cancel()
        guard settings.autoCollapse, !userPinned, !aiOpen else { return }
        guard let delay else { return }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.userPinned, !self.aiOpen, !self.hover else { return }
                self.phase = self.active == nil ? .idle : .idle
            }
        }
        collapseItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
}
