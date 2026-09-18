import Foundation

enum Debounce {
    static func later(_ delay: TimeInterval, id: String = "default", action: @escaping () -> Void) {
        let key = "csai.debounce." + id
        DispatchQueue.main.async {
            objcHold.removeValue(forKey: key)
            let work = DispatchWorkItem(block: action)
            objcHold[key] = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }
}

private var objcHold: [String: DispatchWorkItem] = [:]
