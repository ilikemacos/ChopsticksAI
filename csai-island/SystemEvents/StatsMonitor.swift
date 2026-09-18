import Foundation
import Darwin

struct SystemStats: Equatable {
    var cpuPercent: Double
    var memoryUsedGB: Double
    var memoryTotalGB: Double
    var networkOnline: Bool
    var networkLabel: String

    static let empty = SystemStats(
        cpuPercent: 0,
        memoryUsedGB: 0,
        memoryTotalGB: 0,
        networkOnline: true,
        networkLabel: "—"
    )

    var memoryPercent: Double {
        guard memoryTotalGB > 0 else { return 0 }
        return min(1, max(0, memoryUsedGB / memoryTotalGB))
    }
}

@MainActor
final class StatsMonitor: ObservableObject {
    static let shared = StatsMonitor()

    @Published private(set) var stats = SystemStats.empty

    private var timer: Timer?
    private var lastCPU: (user: Double, system: Double, idle: Double)?
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer?.tolerance = 0.4
    }

    func refresh() {
        stats = SystemStats(
            cpuPercent: sampleCPU(),
            memoryUsedGB: sampleMemoryUsedGB(),
            memoryTotalGB: sampleMemoryTotalGB(),
            networkOnline: NetworkStatusBridge.shared.isOnline,
            networkLabel: NetworkStatusBridge.shared.label
        )
    }

    private func sampleCPU() -> Double {
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        var load = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return stats.cpuPercent }

        let user = Double(load.cpu_ticks.0)
        let system = Double(load.cpu_ticks.1)
        let idle = Double(load.cpu_ticks.2)
        defer { lastCPU = (user, system, idle) }

        guard let prev = lastCPU else { return 0 }
        let dUser = user - prev.user
        let dSystem = system - prev.system
        let dIdle = idle - prev.idle
        let total = dUser + dSystem + dIdle
        guard total > 0 else { return stats.cpuPercent }
        return min(100, max(0, ((dUser + dSystem) / total) * 100))
    }

    private func sampleMemoryUsedGB() -> Double {
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        var vmStats = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return stats.memoryUsedGB }
        let pageSize = Double(vm_kernel_page_size)
        let usedPages = Double(vmStats.active_count + vmStats.wire_count + vmStats.compressor_page_count)
        return (usedPages * pageSize) / 1_073_741_824
    }

    private func sampleMemoryTotalGB() -> Double {
        Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
    }
}

/// Lightweight bridge so StatsMonitor does not duplicate NWPathMonitor wiring.
@MainActor
final class NetworkStatusBridge: ObservableObject {
    static let shared = NetworkStatusBridge()

    @Published private(set) var isOnline = true
    @Published private(set) var label = "Network"

    private init() {}

    func update(online: Bool, label: String) {
        isOnline = online
        self.label = label
        StatsMonitor.shared.refresh()
    }
}
