import Network
import Foundation

public typealias ConnectionStatus = NWPath.Status

/// Swift wrapper over Apple NWPathMonitor from Network framework
public class NetworkMonitor {
    static public let shared = NetworkMonitor()
    
    /// ConnectionStatus (NWPath.Status) for current path
    public private(set) var status: ConnectionStatus = .unsatisfied
    
    /// Bool value indicating on is network connection established and ready to use
    public private(set) var isNetworkReachable: Bool = false
    
    private let monitor: NWPathMonitor
    @AtomicProperty private var observers = Set<NetworkToken>()
    
    private init() {
        self.monitor = NWPathMonitor()
        self.monitor.start(queue: DispatchQueue.global(qos: .utility))
    }
    
    /// Start monitoring of network changes
    public func startMonitoring() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            
            let isSatisfied = path.status == .satisfied
            let isValidPath = !path.usesInterfaceType(.other) || !path.usesInterfaceType(.loopback)
            let isNetworkReachable = isSatisfied && isValidPath
            
            if self?.isNetworkReachable != isNetworkReachable {
                self?.notify(isNetworkReachable: isNetworkReachable)
            }
            
            self?.isNetworkReachable = isNetworkReachable
        }
    }
    
    public func observeNetworkChanges(
        skipInitial: Bool = false,
        actions: @escaping (_ isNetworkReachable: Bool) -> Void
    ) -> NetworkToken {
        let wrapper = NetworkToken(for: actions)
        _observers.mutate {
            $0.insert(wrapper)
        }
        
        if !skipInitial {
            actions(self.isNetworkReachable)
        }
        
        return wrapper
    }
    
    public func removeObserver(for token: NetworkToken?) {
        guard let token = token else { return }
        
        _observers.mutate {
            $0.remove(token)
        }
    }
    
    // MARK: Private Methods
    
    private func notify(isNetworkReachable: Bool) {
        _observers.wrappedValue.forEach { observer in
            observer.actions(isNetworkReachable)
        }
    }
}

public class NetworkToken: NSObject {
    var actions: (Bool) -> Void
    
    init(for actions: @escaping (Bool) -> Void) {
        self.actions = actions
    }
}
