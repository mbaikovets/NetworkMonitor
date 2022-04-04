import Network

@available(iOS 13.0, *)
public struct AsyncMonitor {
    static public let isNetworkReachable: AsyncStream<Bool> = AsyncStream { continuation in
        let monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { path in
            let isSatisfied = path.status == .satisfied
                && (!path.usesInterfaceType(.other) || !path.usesInterfaceType(.loopback))
            
            continuation.yield(isSatisfied)
        }
        
        continuation.onTermination = { @Sendable _ in
            monitor.cancel()
        }
        
        monitor.start(queue: DispatchQueue.global(qos: .utility))
    }
}
