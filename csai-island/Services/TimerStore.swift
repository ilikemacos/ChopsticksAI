import Foundation

struct IslandTimer: Identifiable, Equatable {
    let id: UUID
    var label: String
    var remaining: TimeInterval
    var total: TimeInterval

    init(id: UUID = UUID(), label: String, seconds: TimeInterval) {
        self.id = id
        self.label = label
        self.remaining = seconds
        self.total = seconds
    }
}

@MainActor
final class TimerStore: ObservableObject {
    static let shared = TimerStore()

    @Published private(set) var timers: [IslandTimer] = []

    private init() {}

    func add(label: String, seconds: TimeInterval) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Timer" : trimmed
        let timer = IslandTimer(label: name, seconds: max(1, seconds))
        timers.append(timer)
        IslandStateManager.shared.syncTimerEvent()
    }

    func remove(_ id: UUID) {
        timers.removeAll { $0.id == id }
        IslandStateManager.shared.syncTimerEvent()
    }

    func tick(_ delta: TimeInterval) {
        guard !timers.isEmpty else { return }
        var finished: [IslandTimer] = []
        timers = timers.compactMap { timer in
            var next = timer
            next.remaining -= delta
            if next.remaining <= 0 {
                finished.append(timer)
                return nil
            }
            return next
        }
        for timer in finished {
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .systemAlert,
                    ttl: 4.5,
                    payload: .alert(title: "Timer done", detail: timer.label)
                )
            )
        }
        IslandStateManager.shared.syncTimerEvent()
    }
}
