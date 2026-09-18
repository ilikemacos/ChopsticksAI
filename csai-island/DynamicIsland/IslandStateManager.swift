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
    @Published var selectedTab: IslandTab = .ai
    @Published var hudPulse = false

    let chat = ChatController()
    let settings = AppSettings.shared

    private var collapseItem: DispatchWorkItem?
    private var tick: Timer?
    private var pulseReset: DispatchWorkItem?

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

    var isExpandedSurface: Bool {
        phase == .expanded || phase == .extraExpanded
    }

    func post(_ event: IslandEvent) {
        guard settings.islandEnabled, settings.enabled(for: event.kind) else { return }
        events.removeAll { $0.kind == event.kind && !event.sticky }
        events.append(event)
        if event.kind == .ai { aiOpen = true }
        if !userPinned && !aiOpen {
            flashHUD(for: event)
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

    func syncTimerEvent() {
        guard let next = TimerStore.shared.timers.min(by: { $0.remaining < $1.remaining }) else {
            events.removeAll { $0.kind == .timer }
            if !userPinned && !aiOpen && kind == .idle { phase = .idle }
            return
        }
        if let idx = events.lastIndex(where: { $0.kind == .timer }) {
            events[idx].payload = .timer(label: next.label, remaining: next.remaining)
        } else {
            events.append(
                IslandEvent(kind: .timer, sticky: true, ttl: nil, payload: .timer(label: next.label, remaining: next.remaining))
            )
            if !userPinned && !aiOpen { phase = .compact }
        }
    }

    func openAI() {
        openExpanded(tab: .ai)
    }

    func openExpanded(tab: IslandTab) {
        guard tab == .ai ? settings.aiEnabled : true else { return }
        selectedTab = tab
        userPinned = true
        phase = .expanded
        if tab == .ai {
            aiOpen = true
            post(IslandEvent(kind: .ai, sticky: true, ttl: nil, payload: .none))
        } else {
            aiOpen = false
            events.removeAll { $0.kind == .ai }
        }
        collapseItem?.cancel()
        layout()
    }

    func selectTab(_ tab: IslandTab) {
        selectedTab = tab
        if tab == .ai {
            aiOpen = true
            if !events.contains(where: { $0.kind == .ai }) {
                events.append(IslandEvent(kind: .ai, sticky: true, ttl: nil, payload: .none))
            }
        } else {
            aiOpen = false
        }
        layout()
    }

    func closeAI() {
        aiOpen = false
        events.removeAll { $0.kind == .ai }
        userPinned = false
        if isExpandedSurface {
            phase = .idle
        }
        collapseSoon()
    }

    func collapseExpanded() {
        if aiOpen { closeAI() }
        userPinned = false
        phase = active == nil ? .idle : .compact
        collapseSoon()
        layout()
    }

    func toggleExpand() {
        if isExpandedSurface {
            collapseExpanded()
            return
        }
        if aiOpen {
            closeAI()
            return
        }
        userPinned = true
        if kind == .idle { openAI() }
        else {
            phase = .expanded
            selectedTab = tabForKind(kind)
            collapseItem?.cancel()
            layout()
        }
    }

    func toggleExtraExpanded() {
        guard isExpandedSurface else { return }
        phase = phase == .extraExpanded ? .expanded : .extraExpanded
        layout()
    }

    func collapseSoon() {
        scheduleCollapse(after: 0.35)
    }

    func onHover(_ on: Bool) {
        hover = on
        if on {
            collapseItem?.cancel()
            if settings.hoverToExpand, phase == .idle, active != nil {
                phase = .compact
                layout()
            }
        } else if !userPinned && !aiOpen {
            scheduleCollapse(after: 1.1)
        }
    }

    func escape() {
        if chat.isGenerating { chat.stop(); return }
        if isExpandedSurface || aiOpen { collapseExpanded(); return }
        userPinned = false
        phase = .idle
        layout()
    }

    private func tabForKind(_ kind: IslandKind) -> IslandTab {
        switch kind {
        case .music: return .media
        case .timer: return .timers
        case .volume, .brightness, .battery, .network: return .stats
        default: return .ai
        }
    }

    private func flashHUD(for event: IslandEvent) {
        phase = .compact
        hudPulse = true
        pulseReset?.cancel()
        let reset = DispatchWorkItem { [weak self] in self?.hudPulse = false }
        pulseReset = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: reset)
        scheduleCollapse(after: event.sticky ? nil : hudDuration(for: event.kind))
        layout()
    }

    private func hudDuration(for kind: IslandKind) -> TimeInterval {
        switch kind {
        case .volume, .brightness: return 2.2
        case .battery: return 2.8
        case .music: return 4.0
        default: return settings.autoCollapseDelay
        }
    }

    private func rank(_ kind: IslandKind) -> Int {
        settings.priority.firstIndex(of: kind) ?? 50
    }

    private func prune() {
        let now = Date()
        TimerStore.shared.tick(0.35)
        events.removeAll { ev in
            if ev.sticky || ev.kind == .ai || ev.kind == .timer { return false }
            if let exp = ev.expiresAt { return exp < now }
            return false
        }
        if !userPinned && !aiOpen && !hover && !isExpandedSurface {
            if active == nil { phase = .idle }
        }
    }

    private func scheduleCollapse(after delay: Double?) {
        collapseItem?.cancel()
        guard settings.autoCollapse, !userPinned, !aiOpen, !isExpandedSurface else { return }
        guard let delay else { return }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.userPinned, !self.aiOpen, !self.hover, !self.isExpandedSurface else { return }
                self.phase = self.active == nil ? .idle : .idle
                self.layout()
            }
        }
        collapseItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func layout() {
        NotificationCenter.default.post(name: .islandNeedsLayout, object: nil)
    }
}
