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
    @Published private(set) var apiUp: Bool?
    @Published private(set) var apiVersion = ""

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.chopstickshq.chopsticksai.network")

    var statusLabel: String {
        guard isOnline else { return "Offline — no connection" }
        return "Online · \(connection.label)"
    }

    var apiUptimeLabel: String {
        if CSAIEdition.current.isOffline { return "Offline edition — no live API" }
        switch apiUp {
        case true: return apiVersion.isEmpty ? "cs.AI API is up" : "cs.AI \(apiVersion) is up"
        case false: return "cs.AI API is down"
        default: return "Checking cs.AI API…"
        }
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
                if online { await self?.pingApi() }
                else { self?.apiUp = false }
            }
        }
        monitor.start(queue: queue)
        Task { await pingApi() }
    }

    func pingApi() async {
        guard !CSAIEdition.current.isOffline else {
            apiUp = nil
            return
        }
        var req = URLRequest(url: URL(string: "https://chopstickshq.com/api/chopsticks-ai")!)
        req.httpMethod = "GET"
        req.timeoutInterval = 8
        req.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let up = code == 200 && ((obj?["up"] as? Bool) == true || (obj?["ok"] as? Bool) == true)
            apiUp = up
            apiVersion = (obj?["version"] as? String) ?? ""
        } catch {
            apiUp = false
        }
    }
}
