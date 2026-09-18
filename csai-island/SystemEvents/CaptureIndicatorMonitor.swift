import AVFoundation
import Foundation

/// macOS does not expose a supported “camera in use by another app” API for menu extras.
/// We observe AVCaptureDevice.wasConnected/disconnected and local session running as the closest public signal.
final class CaptureIndicatorMonitor {
    private var camObs: NSObjectProtocol?
    private var micObs: NSObjectProtocol?

    func start() {
        camObs = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasConnected,
            object: nil,
            queue: .main
        ) { note in
            CaptureIndicatorMonitor.announce(note.object as? AVCaptureDevice, kind: "Camera")
        }
        micObs = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasDisconnected,
            object: nil,
            queue: .main
        ) { note in
            CaptureIndicatorMonitor.announce(note.object as? AVCaptureDevice, kind: "Device")
        }
    }

    private static func announce(_ device: AVCaptureDevice?, kind: String) {
        let name = device?.localizedName ?? kind
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .capture,
                    ttl: 3.0,
                    payload: .text(title: kind, detail: name, symbol: device?.hasMediaType(.video) == true ? "video.fill" : "mic.fill")
                )
            )
        }
    }
}
