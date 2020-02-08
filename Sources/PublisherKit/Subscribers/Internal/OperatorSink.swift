//
//  OperatorSink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

typealias UpstreamOperatorSink<Downstream: Subscriber, Upstream: Publisher> = Subscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure>

typealias UpstreamInternalSink<Downstream: Subscriber, Upstream: Publisher> = Subscribers.InternalSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure

extension Subscribers {
    
    class OperatorSink<Downstream: Subscriber, Input, Failure: Error>: SubscriptionSink, Subscriber {
        
        var downstream: Downstream?
        
        init(downstream: Downstream) {
            self.downstream = downstream
            super.init()
        }
        
        func receive(subscription: Subscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
            downstream?.receive(subscription: self)
            subscription.request(.unlimited)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            return demand
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
        }
    }
    
    class InternalSink<Downstream: Subscriber, Input, Failure>: OperatorSink<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {
        
        override func receive(_ input: Input) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
    
    class FinalOperatorSink<Downstream: Subscriber, Input, Failure: Error>: OperatorSink<Downstream, Input, Failure> {
        
        final let receiveValue: ((Input, Downstream?) -> Void)
        
        final let receiveCompletion: ((Subscribers.Completion<Failure>, Downstream?) -> Void)
        
        init(downstream: Downstream,
             receiveCompletion: @escaping (Subscribers.Completion<Failure>, Downstream?) -> Void,
             receiveValue: @escaping ((Input, Downstream?) -> Void)) {
            
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(input, downstream)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion(completion, downstream)
        }
    }
}
