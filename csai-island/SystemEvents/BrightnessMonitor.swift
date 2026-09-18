import Foundation
import CoreGraphics
import IOKit

/// Brightness via DisplayServices when present; otherwise IODisplay. macOS does not
/// publish a supported public brightness-changed notification for all hardware.
final class BrightnessMonitor {
    private var timer: Timer?
    private var last: Float = -1
    private typealias GetBright = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private var getBright: GetBright?

    func start() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY),
           let sym = dlsym(handle, "DisplayServicesGetBrightness") {
            getBright = unsafeBitCast(sym, to: GetBright.self)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.sample()
        }
        timer?.tolerance = 0.25
    }

    private func sample() {
        var value: Float = 0
        let display = CGMainDisplayID()
        var ok = false
        if let getBright {
            var v: Float = 0
            if getBright(display, &v) == 0 {
                value = v
                ok = true
            }
        }
        if !ok { return }
        if last < 0 { last = value; return }
        if abs(value - last) < 0.03 { return }
        last = value
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .brightness,
                    ttl: 2.0,
                    payload: .meter(title: "Brightness", value: Double(value), symbol: "sun.max.fill")
                )
            )
        }
    }
}
