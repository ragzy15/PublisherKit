//
//  Sinkable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

typealias UpstreamSinkable<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.Sinkable<Downstream, Upstream.Output, Upstream.Failure>

typealias UpstreamInternalSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.InternalSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure

extension PKSubscribers {
    
    class Sinkable<Downstream: PKSubscriber, Input, Failure: Error>: SubscriptionSinkable, PKSubscriber {
        
        var downstream: Downstream?
        
        init(downstream: Downstream) {
            self.downstream = downstream
            super.init()
        }
        
        func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
        }
        
        func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            return demand
        }
        
        func receive(input: Input) {
            _ = receive(input)
        }
        
        func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
        }
    }
    
    class InternalSink<Downstream: PKSubscriber, Input, Failure>: Sinkable<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
    
    class FinalOperatorSink<Downstream: PKSubscriber, Input, Failure: Error>: Sinkable<Downstream, Input, Failure> {
        
        final let receiveValue: ((Input, Downstream?) -> Void)
        
        final let receiveCompletion: ((PKSubscribers.Completion<Failure>, Downstream?) -> Void)
        
        init(downstream: Downstream,
             receiveCompletion: @escaping (PKSubscribers.Completion<Failure>, Downstream?) -> Void,
             receiveValue: @escaping ((Input, Downstream?) -> Void)) {
            
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(input, downstream)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion(completion, downstream)
        }
    }
}
