import Foundation

@MainActor
final class EventHub {
    static let shared = EventHub()
    let volume = VolumeMonitor()
    let brightness = BrightnessMonitor()
    let battery = BatteryMonitor.shared
    let bluetooth = BluetoothMonitor()
    let network = NetworkMonitor()
    let downloads = DownloadMonitor()
    let screenshots = ScreenshotMonitor()
    let focus = FocusMonitor()
    let capture = CaptureIndicatorMonitor()
    let notifications = NotificationBridge()
    let music = NowPlayingMonitor.shared
    let stats = StatsMonitor.shared

    func start() {
        volume.start()
        brightness.start()
        battery.start()
        bluetooth.start()
        network.start()
        downloads.start()
        screenshots.start()
        focus.start()
        capture.start()
        notifications.start()
        music.start()
        stats.start()
    }
}
