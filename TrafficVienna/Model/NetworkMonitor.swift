import Combine
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "at.wellbe.TrafficVienna.network-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = isConnected
            }
        }
        monitor.start(queue: queue)
        isConnected = monitor.currentPath.status == .satisfied
    }

    deinit {
        monitor.cancel()
    }
}
