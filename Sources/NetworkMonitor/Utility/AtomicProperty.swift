import Foundation

@propertyWrapper
class AtomicProperty<Value> {
    private var value: Value
    private let queue = DispatchQueue(
        label: "networkmonitor.atomicproperty\(String(describing: Value.self))"
    )
    
    var wrappedValue: Value {
        get {
            queue.sync {
                value
            }
        }
        set {
            queue.sync {
                value = newValue
            }
        }
    }
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    func mutate(_ mutation: (inout Value) -> Void) {
        queue.sync {
            mutation(&value)
        }
    }
}
