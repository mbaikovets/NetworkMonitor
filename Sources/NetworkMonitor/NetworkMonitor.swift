import Network

public typealias ConnectionStatus = NWPath.Status

/// Swift wrapper over Apple NWPathMonitor from Network framework
public class NetworkMonitor {
    static public let shared = NetworkMonitor()
    
    /// ConnectionStatus (NWPath.Status) for current path
    public private(set) var status: ConnectionStatus = .unsatisfied
    
    /// Bool value indicating on is network connection established and ready to use
    public private(set) var isNetworkReachable: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue.global(qos: .utility)
    
    private init() {
        self.monitor = NWPathMonitor()
        self.monitor.start(queue: queue)
    }
    
    /// Start monitoring of network changes
    /// - Parameter callback: allows to perform custom actions on network changes
    public func startMonitoring(_ callback: @escaping (_ isNetworkReachable: Bool) -> Void) {
        self.monitor.pathUpdateHandler = { path in
            self.status = path.status
            
            let isSatisfied = path.status == .satisfied
            let isValidPath = !path.usesInterfaceType(.other) || !path.usesInterfaceType(.loopback)
            
            self.isNetworkReachable = isSatisfied && isValidPath
            callback(isSatisfied && isValidPath)
        }
    }
}
