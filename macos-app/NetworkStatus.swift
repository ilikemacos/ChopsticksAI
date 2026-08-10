import Combine
import Foundation
import Network

enum ConnectionKind: String {
    case wifi
    case cellular
    case wired
    case other
    case offline

    var label: String {
        switch self {
        case .wifi: return "Wi‑Fi"
        case .cellular: return "Cellular"
        case .wired: return "Ethernet"
        case .other: return "Network"
        case .offline: return "Offline"
        }
    }
}

@MainActor
final class NetworkStatus: ObservableObject {
    static let shared = NetworkStatus()

    @Published private(set) var isOnline = true
    @Published private(set) var connection: ConnectionKind = .other

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.chopstickshq.chopsticksai.network")

    var statusLabel: String {
        guard isOnline else { return "Offline — no connection" }
        return "Online · \(connection.label)"
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            let kind: ConnectionKind
            if !online {
                kind = .offline
            } else if path.usesInterfaceType(.wifi) {
                kind = .wifi
            } else if path.usesInterfaceType(.cellular) {
                kind = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                kind = .wired
            } else {
                kind = .other
            }
            Task { @MainActor in
                self?.isOnline = online
                self?.connection = kind
            }
        }
        monitor.start(queue: queue)
    }
}
