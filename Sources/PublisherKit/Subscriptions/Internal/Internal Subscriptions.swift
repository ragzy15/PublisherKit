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
}
