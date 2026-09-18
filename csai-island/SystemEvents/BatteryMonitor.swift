import Foundation
import IOKit.ps

final class BatteryMonitor {
    private var loop: CFRunLoopSource?
    private var lastPercent = -1
    private var lastCharging: Bool?

    func start() {
        let ctx: IOPowerSourceCallbackType = { _ in
            BatteryMonitor.shared.sample()
        }
        if let src = IOPSNotificationCreateRunLoopSource(ctx, nil)?.takeRetainedValue() {
            loop = src
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .defaultMode)
        }
        sample()
    }

    static let shared = BatteryMonitor()

    func sample() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return }
        for src in list {
            guard let desc = IOPSGetPowerSourceDescription(info, src)?.takeUnretainedValue() as? [String: Any] else { continue }
            let percent = desc[kIOPSCurrentCapacityKey] as? Int ?? -1
            let charging = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
                || (desc[kIOPSIsChargingKey] as? Bool == true)
            if percent == lastPercent && charging == lastCharging { return }
            let first = lastPercent < 0
            lastPercent = percent
            lastCharging = charging
            if first { return }
            Task { @MainActor in
                IslandStateManager.shared.post(
                    IslandEvent(
                        kind: .battery,
                        ttl: 3.0,
                        payload: .battery(percent: percent, charging: charging)
                    )
                )
            }
            return
        }
    }
}
