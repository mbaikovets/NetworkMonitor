import Network

public typealias ConnectionStatus = NWPath.Status

public class NetworkMonitor {
    static public let shared = NetworkMonitor()
    
    public private(set) var status: ConnectionStatus = .unsatisfied
    public private(set) var isNetworkReachable: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue.global(qos: .utility)
    
    private init() {
        self.monitor = NWPathMonitor()
        self.monitor.start(queue: queue)
    }
    
    public func startMonitoring() {
        self.monitor.pathUpdateHandler = { path in
            self.status = path.status
            
            let isSatisfied = path.status == .satisfied
            let isValidPath = !path.usesInterfaceType(.other) || !path.usesInterfaceType(.loopback)
            
            self.isNetworkReachable = isSatisfied && isValidPath
        }
    }
}
