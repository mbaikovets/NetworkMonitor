import Network
import Foundation

public typealias ConnectionStatus = NWPath.Status

/// Swift wrapper over Apple NWPathMonitor from Network framework.
public class NetworkMonitor {
    static public let shared = NetworkMonitor()
    
    /// ConnectionStatus (NWPath.Status) for current path.
    public private(set) var status: ConnectionStatus = .unsatisfied
    
    /// Bool value indicating on is network connection established and ready to use.
    public private(set) var isNetworkReachable: Bool = false
    
    private let monitor: NWPathMonitor
    @AtomicProperty private var observers = Set<NetworkToken>()
    
    private init() {
        self.monitor = NWPathMonitor()
        self.monitor.start(queue: DispatchQueue.global(qos: .utility))
    }
    
    /// Start monitoring of network changes. Required to call once before observing.
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
    
    /// Adds an entry to the network handler to receive updates that passed to the provided block.
    /// - Parameters:
    ///   - skipInitial: Bool value that determines if an observer gets current value or not.
    ///   - actions: The block that executes when receiving an update on connection status.
    /// - Returns: An opaque object that acts as a token to observation. NetworkMonitor strongly holds this value until you remove the observer.
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
    
    /// Removes observer specifying a token stored in the NetworkMonitor observers.
    /// - Parameter token: Optional token which related to the observer entrie stored in the NetworkMonitor observers.
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

/// An opaque object to act as the observer. NetworkMonitor strongly holds this values until you remove the observer registration.
public class NetworkToken: NSObject {
    var actions: (Bool) -> Void
    
    init(for actions: @escaping (Bool) -> Void) {
        self.actions = actions
    }
}
