//
//  OperatorSink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

typealias UpstreamOperatorSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure>

typealias UpstreamInternalSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.InternalSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure

extension PKSubscribers {
    
    class SubscriptionSink<Downstream: PKSubscriber, Input, Failure: Error>: PKSubscription {
        
        private(set) var isCancelled = false
        
        private(set) var isEnded = false
        
        var isOver: Bool {
            isEnded || isCancelled
        }
        
        var demand: PKSubscribers.Demand = .unlimited
        
        var downstream: Downstream?
        
        init(downstream: Downstream) {
            self.downstream = downstream
        }
        
        func request(_ demand: PKSubscribers.Demand) {
            self.demand = demand
        }
        
        func receive(input: Input) { }
        
        func receive(completion: PKSubscribers.Completion<Failure>) { }
        
        func cancel() {
            isCancelled = true
        }
        
        func end() {
            isEnded = true
        }
    }
    
    class OperatorSink<Downstream: PKSubscriber, Input, Failure: Error>: SubscriptionSink<Downstream, Input, Failure>, PKSubscriber {
        
        
        var subscription: PKSubscription?
        
        override init(downstream: Downstream) {
            super.init(downstream: downstream)
            sendSubscription()
        }
        
        func sendSubscription() {
            downstream?.receive(subscription: self)
            request(.unlimited)
        }
        
        override func request(_ demand: PKSubscribers.Demand) {
            super.request(demand)
        }
        
        func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
        }
        
        func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
        }
        
        override func cancel() {
            super.cancel()
            subscription?.cancel()
            subscription = nil
        }
        
        override func end() {
            super.end()
            subscription = nil
        }
    }
    
    class InternalSink<Downstream: PKSubscriber, Input, Failure>: OperatorSink<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {

        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }

        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
    
    class ClosureOperatorSink<Downstream: PKSubscriber, Input, Failure: Error>: OperatorSink<Downstream, Input, Failure> {
        
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
