import Foundation
import Intents

final class FocusMonitor {
    private var last: Bool?

    func start() {
        INFocusStatusCenter.default.requestAuthorization { _ in
            self.publish()
        }
        Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.publish()
        }.tolerance = 2
    }

    private func publish() {
        let on = INFocusStatusCenter.default.focusStatus.isFocused == true
        if last == on { return }
        last = on
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .focus,
                    ttl: 2.8,
                    payload: .text(
                        title: on ? "Focus on" : "Focus off",
                        detail: "Do Not Disturb",
                        symbol: on ? "moon.fill" : "moon"
                    )
                )
            )
        }
    }
}
