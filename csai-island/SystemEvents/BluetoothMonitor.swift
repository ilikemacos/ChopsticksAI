import Foundation
import IOBluetooth
import AppKit

final class BluetoothMonitor: NSObject {
    private var connectNote: IOBluetoothUserNotification?

    func start() {
        connectNote = IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(connected(_:device:)))
    }

    @objc private func connected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        _ = device.register(forDisconnectNotification: self, selector: #selector(disconnected(_:device:)))
        announce(device, connected: true)
    }

    @objc private func disconnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        announce(device, connected: false)
    }

    private func announce(_ device: IOBluetoothDevice, connected: Bool) {
        let name = device.name ?? "Bluetooth device"
        let audio = device.deviceClassMajor == kBluetoothDeviceClassMajorAudio
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .bluetooth,
                    ttl: 3.2,
                    payload: .text(
                        title: connected ? "Connected" : "Disconnected",
                        detail: name,
                        symbol: audio ? "airpodspro" : "wave.3.right"
                    )
                )
            )
        }
    }
}
