//
//  Internal Subscriptions.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

extension Subscriptions {
    
    class InternalBase<Downstream: Subscriber, Input, Failure: Error>: Subscription, CustomStringConvertible, CustomReflectable {
        
        var demand: Subscribers.Demand = .none
        
        var downstream: Downstream?
        
        init(downstream: Downstream) {
            self.downstream = downstream
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
        }
        
        func receive(input: Input) {
            /* abstract method, override in publishers that do not have an upstream publisher to send input downstream. */
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
        }
        
        func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            /* abstract method */
        }
        
        func cancel() {
            downstream = nil
        }
        
        func end(completion: () -> Void) {
            
        }
        
        var description: String {
            "Internal Subscription"
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
    
    
    class Internal<Downstream: Subscriber, Input, Failure>: InternalBase<Downstream, Input, Failure> where Input == Downstream.Input, Failure == Downstream.Failure {
        
        private(set) var isTerminated = false
        
        private let lock = Lock()
        
        final func getLock() -> Lock {
            lock
        }
        
        override func request(_ demand: Subscribers.Demand) {
            lock.lock()
            self.demand = demand
            lock.unlock()
        }
        
        override func receive(input: Input) {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return }
            lock.unlock()
            _ = downstream?.receive(input)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return }
            
            end {
                onCompletion(completion)
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override func cancel() {
            lock.lock()
            isTerminated = true
            lock.unlock()
            super.cancel()
        }
        
        override func end(completion: () -> Void) {
            isTerminated = true
            lock.unlock()
            completion()
            downstream = nil
        }
        
        override var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream as Any),
                ("isTerminated", isTerminated)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
