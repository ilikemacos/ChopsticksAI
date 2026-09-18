import Foundation
import Network
import SystemConfiguration

final class NetworkMonitor {
    private let path = NWPathMonitor()
    private var queue = DispatchQueue(label: "csai.island.net")
    private var store: SCDynamicStore?
    private var lastVPN = false
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        path.pathUpdateHandler = { [weak self] p in
            let ok = p.status == .satisfied
            let label = Self.interfaceLabel(p)
            Task { @MainActor in
                NetworkStatusBridge.shared.update(online: ok, label: label)
                IslandStateManager.shared.post(
                    IslandEvent(
                        kind: .network,
                        ttl: 2.8,
                        payload: .text(
                            title: ok ? "Online" : "Offline",
                            detail: label,
                            symbol: ok ? "wifi" : "wifi.slash"
                        )
                    )
                )
            }
            self?.checkVPN()
        }
        path.start(queue: queue)
        checkVPN()
    }

    private static func interfaceLabel(_ p: NWPath) -> String {
        if p.usesInterfaceType(.wifi) { return "Wi‑Fi" }
        if p.usesInterfaceType(.wiredEthernet) { return "Ethernet" }
        if p.usesInterfaceType(.cellular) { return "Cellular" }
        if p.usesInterfaceType(.other) { return "Other" }
        return "Network"
    }

    private func checkVPN() {
        guard let cf = SCDynamicStoreCopyProxies(nil) as? [String: Any] else { return }
        let scoped = cf["__SCOPED__"] as? [String: Any]
        let vpn = (cf["VPN"] != nil) || (scoped?.keys.contains(where: { $0.contains("utun") || $0.contains("ipsec") || $0.lowercased().contains("vpn") }) == true)
        if vpn == lastVPN { return }
        lastVPN = vpn
        Task { @MainActor in
            IslandStateManager.shared.post(
                IslandEvent(
                    kind: .network,
                    ttl: 3.0,
                    payload: .text(title: vpn ? "VPN on" : "VPN off", detail: "Tunnel", symbol: "lock.shield.fill")
                )
            )
        }
    }
}
