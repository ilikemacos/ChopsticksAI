import Foundation
import Combine

@MainActor
final class KajiCommandGate: ObservableObject {
    static let shared = KajiCommandGate()
    @Published private(set) var pending: String?
    private var continuation: CheckedContinuation<Bool, Never>?

    func request(_ command: String) async -> Bool {
        if continuation != nil {
            continuation?.resume(returning: false)
            continuation = nil
        }
        pending = command
        return await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    func answer(_ run: Bool) {
        pending = nil
        continuation?.resume(returning: run)
        continuation = nil
    }

    func cancelPending() {
        guard continuation != nil || pending != nil else { return }
        answer(false)
    }
}
