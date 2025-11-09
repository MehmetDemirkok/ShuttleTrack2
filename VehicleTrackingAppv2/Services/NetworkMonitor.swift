import Foundation
import Network
import Combine

/// Network durumu izleme servisi
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Mobil Veri"
            case .ethernet: return "Ethernet"
            case .unknown: return "Bilinmiyor"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    /// Network durumunu izlemeye başla
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else {
                    self.connectionType = .unknown
                }
                
                print("📡 Network durumu: \(self.isConnected ? "Bağlı" : "Bağlı Değil") - \(self.connectionType.displayName)")
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// Network durumunu kontrol et (senkron)
    func checkConnection() -> Bool {
        return isConnected
    }
    
    deinit {
        monitor.cancel()
    }
}

