//
//  Internal Subscriptions.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

extension Subscriptions {
    
    class Internal<Downstream: Subscriber, Input, Failure: Error>: Subscription, CustomStringConvertible, CustomReflectable {
        
        private(set) var isTerminated = false
        
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
            guard !isTerminated else { return }
            
            end {
                onCompletion(completion)
            }
        }
        
        func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            /* abstract method */
        }
        
        func cancel() {
            isTerminated = true
            downstream = nil
        }
        
        func end(completion: () -> Void) {
            isTerminated = true
            completion()
            downstream = nil
        }
        
        var description: String {
            "Internal Subscription"
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream ?? "nil"),
                ("isTerminated", isTerminated)
            ]
            
            return Mirror(self, children: children)
        }
    }
    
    class InternalSubject<Output, Failure: Error>: Subscription {
        
        private var downstream: AnySubscriber<Output, Failure>?
        
        private(set) var isTerminated = false
        
        private(set) var _demand: Subscribers.Demand = .none
        
        init(downstream: AnySubscriber<Output, Failure>) {
            self.downstream = downstream
        }
        
        func request(_ demand: Subscribers.Demand) {
             guard !isTerminated, _demand >= .none else { return }
            _demand += demand
        }
        
        final func receive(_ input: Output) {
            guard !isTerminated, _demand > .none else { return }
            let newDemand = downstream?.receive(input)
            _demand = newDemand ?? .none
        }
        
        final func receive(completion: Subscribers.Completion<Failure>) {
            guard !isTerminated else { return }
            downstream?.receive(completion: completion)
            finish()
        }
        
        final func cancel() {
            finish()
        }
        
        @inlinable func finish() {
            isTerminated = true
            downstream = nil
        }
    }
}
