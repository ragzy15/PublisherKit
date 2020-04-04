//
//  Filter Producer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

class FilterProducer<Downstream: Subscriber, Output, Input, Failure: Error, Filter>: CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Downstream.Input == Output {
    
    private enum State {
        case awaitingSubscription
        case subscribed(to: Subscription)
        case terminated
    }
    
    private var state: State = .awaitingSubscription
    private let lock = Lock()
    
    private let downstream: Downstream
    
    let filter: Filter
    
    init(downstream: Downstream, filter: Filter) {
        self.downstream = downstream
        self.filter = filter
    }
    
    func receive(newValue: Input) -> PartialCompletion<Output?, Downstream.Failure> {
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
            ("downstream", downstream),
        ]
        
        return Mirror(self, children: children)
    }
}

extension FilterProducer: Subscriber {
    
    func receive(subscription: Subscription) {
        lock.lock()
        guard case .awaitingSubscription = state else {
            lock.unlock()
            subscription.cancel()
            return
        }
        
        state = .subscribed(to: subscription)
        lock.unlock()
        
        downstream.receive(subscription: self)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        lock.lock()
        guard case .subscribed(let subscription) = state else { lock.unlock(); return .none }
        lock.unlock()
        
        switch receive(newValue: input) {
            
        case .continue(let output):
            if let output = output {
                return downstream.receive(output)
            } else {
                return .max(1)
            }
            
        case .finished:
            lock.lock()
            state = .terminated
            lock.unlock()
            
            subscription.cancel()
            downstream.receive(completion: .finished)
            
        case .failure(let error):
            lock.lock()
            state = .terminated
            lock.unlock()
            
            subscription.cancel()
            downstream.receive(completion: .failure(error))
        }
        
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        guard case .subscribed = state else { lock.unlock(); return }
        state = .terminated
        lock.unlock()
        
        switch completion {
        case .finished:
            downstream.receive(completion: .finished)
            
        case .failure(let error):
            downstream.receive(completion: .failure(error as! Downstream.Failure))
        }
    }
}

extension FilterProducer: Subscription {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard case .subscribed(let subscription) = state else { lock.unlock(); return }
        lock.unlock()
        
        subscription.request(demand)
    }
    
    func cancel() {
        lock.lock()
        guard case .subscribed(let subscription) = state else {
            lock.unlock()
            return
        }
        
        state = .terminated
        lock.unlock()
        subscription.cancel()
    }
}
