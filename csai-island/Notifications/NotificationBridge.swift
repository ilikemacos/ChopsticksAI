import Foundation
import UserNotifications

/// Other apps’ Notification Center banners cannot be intercepted with public APIs.
/// We present our own island notifications and listen for UN notifications delivered to this app.
final class NotificationBridge: NSObject, UNUserNotificationCenterDelegate {
    func start() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(custom),
            name: Notification.Name("com.chopstickshq.csai-island.event"),
            object: nil
        )
    }

    @objc private func custom(_ n: Notification) {
        let title = (n.userInfo?["title"] as? String) ?? "Notification"
        let detail = (n.userInfo?["body"] as? String) ?? ""
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(kind: .notification, ttl: 4.0, payload: .text(title: title, detail: detail, symbol: "bell.fill"))
            )
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let c = notification.request.content
        await MainActor.run {
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .notification,
                    ttl: 4.0,
                    payload: .text(title: c.title.isEmpty ? "Notification" : c.title, detail: c.body, symbol: "bell.fill")
                )
            )
        }
        return []
    }
}
