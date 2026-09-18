import Foundation
import CoreAudio

final class VolumeMonitor {
    private var last: Float = -1
    private var device: AudioDeviceID = 0

    func start() {
        device = defaultOutput()
        emit()
        var addr = Self.volumeAddress
        AudioObjectAddPropertyListenerBlock(device, &addr, DispatchQueue.main) { [weak self] _, _ in
            self?.emit()
        }
        var defAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defAddr, DispatchQueue.main) { [weak self] _, _ in
            self?.device = self?.defaultOutput() ?? 0
            self?.emit()
        }
    }

    private static var volumeAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1
        )
    }

    private func defaultOutput() -> AudioDeviceID {
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &device)
        return device
    }

    private func emit() {
        var vol: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var addr = Self.volumeAddress
        let status = AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &vol)
        guard status == noErr else { return }
        if abs(vol - last) < 0.012 { return }
        last = vol
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .volume,
                    ttl: 2.2,
                    payload: .meter(
                        title: "Volume",
                        value: Double(vol),
                        symbol: vol < 0.01 ? "speaker.slash.fill" : "speaker.wave.2.fill"
                    )
                )
            )
        }
    }
}
