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
    
    private var observers = NSMapTable<AnyObject, ActionWrapper>(
        keyOptions: [.weakMemory],
        valueOptions: [.weakMemory]
    )
    
    private let monitor: NWPathMonitor
    
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
    
    public func addObserver(
        _ object: AnyObject,
        skipFirst: Bool = false,
        closure: @escaping (_ isNetworkReachable: Bool) -> Void
    ) {
        let wrapper = ActionWrapper(closure)
        let reference = "observer\(UUID().uuidString)".replacingOccurrences(of: "-", with: "")
        observers.setObject(wrapper, forKey: object)

        // Giving the closure back to the object that is observing
        // Allows ClosureWrapper to die at the same time as observing object
        objc_setAssociatedObject(object, reference, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if !skipFirst {
            closure(self.isNetworkReachable)
        }
    }
    
    // MARK: Private Methods
    
    private func notify(isNetworkReachable: Bool) {
        let enumerator = observers.objectEnumerator()
        while let wrapper = enumerator?.nextObject() {
            (wrapper as? ActionWrapper)?.closure(isNetworkReachable)
        }
    }
}

fileprivate class ActionWrapper {
    var closure: (Bool) -> Void
    
    public init(_ closure: @escaping (Bool) -> Void) {
        self.closure = closure
    }
}
