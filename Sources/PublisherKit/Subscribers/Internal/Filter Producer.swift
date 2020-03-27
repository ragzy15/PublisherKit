//
//  Filter Producer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

class FilterProducer<Downstream: Subscriber, Output, Input, Failure: Error, Operator>: CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Downstream.Input == Output {
    
    private var status: SubscriptionStatus = .awaiting
    private let lock = Lock()
    
    var downstream: Downstream?
    private var requestReceived = false
    
    let operation: Operator
    
    init(downstream: Downstream, operation: Operator) {
        self.downstream = downstream
        self.operation = operation
    }
    
    func receive(input: Input) -> PartialCompletion<Output, Downstream.Failure>? {
        fatalError("receive(_:) not overrided.")
    }
    
    var description: String {
        "Inner"
    }
    
    var playgroundDescription: Any {
        description
    }
    
    var customMirror: Mirror {
        lock.lock()
        defer { lock.unlock() }
        
        let children: [Mirror.Child] = [
            ("downstream", downstream as Any),
        ]
        
        return Mirror(self, children: children)
    }
}

extension FilterProducer: Subscriber {
    
    func receive(subscription: Subscription) {
        lock.lock()
        guard status == .awaiting else { lock.unlock(); return }
        status = .subscribed(to: subscription)
        lock.unlock()
        
        downstream?.receive(subscription: self)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        lock.lock()
        guard case .subscribed(let subscription) = status else { lock.unlock(); return .none }
        lock.unlock()
        
        switch receive(input: input) {
            
        case .continue(let output):
            return downstream?.receive(output) ?? .none
            
        case .finished:
            lock.lock()
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
            downstream?.receive(completion: .finished)
            
        case .failure(let error):
            lock.lock()
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
            downstream?.receive(completion: .failure(error))
            
        case .none:
            return .max(1)
        }
        
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        guard status.isSubscribed else { lock.unlock(); return }
        status = .terminated
        lock.unlock()
        
        switch completion {
        case .finished:
            downstream?.receive(completion: .finished)
            
        case .failure(let error):
            downstream?.receive(completion: .failure(error as! Downstream.Failure))
        }
    }
}

extension FilterProducer: Subscription {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard case .subscribed(let subscription) = status else { lock.unlock(); return }
        lock.unlock()
        
        subscription.request(demand)
    }
    
    func cancel() {
        lock.lock()
        guard case .subscribed(let subscription) = status else {
            lock.unlock()
            return
        }
        
        status = .terminated
        lock.unlock()
        subscription.cancel()
    }
}
