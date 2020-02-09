//
//  OperatorSink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

typealias OperatorSubscriber<Downstream: Subscriber, Upstream: Publisher, Operator> = Subscribers.InternalOperators<Downstream, Upstream.Output, Upstream.Failure, Operator>

typealias InternalSubscriber<Downstream: Subscriber, Upstream: Publisher> = Subscribers.InternalBase<Downstream, Upstream.Output, Upstream.Failure>

extension Subscribers {
    
    class InternalBase<Downstream: Subscriber, Input, Failure: Error>: Subscriptions.Internal<Downstream, Input, Failure>, Subscriber {
        
        var status: SubscriptionStatus = .awaiting
        
        func receive(subscription: Subscription) {
            guard status == .awaiting else { return }
            onSubscription(subscription)
        }
        
        func onSubscription(_ subscription: Subscription) {
            downstream?.receive(subscription: self)
            status = .subscribed(to: subscription)
            subscription.request(.unlimited)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard status.isSubscribed else { return }
            
            end {
                onCompletion(completion)
            }
        }
        
        func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            /* abstract method */
            nil
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            guard status.isSubscribed else { return .none }
            
            switch operate(on: input) {
            case .success(let output):
                _ = downstream?.receive(output)
                
            case .failure(let error):
                end {
                    downstream?.receive(completion: .failure(error))
                }
                
            case .none: break
            }
            
            return demand
        }
        
        override func cancel() {
            super.cancel()
            
            switch status {
            case .subscribed(let subscription):
                subscription.cancel()
                status = .terminated
                downstream = nil
                
            case .multipleSubscription(let subscriptions):
                subscriptions.forEach { (subscription) in
                    subscription.cancel()
                }
                status = .terminated
                downstream = nil
                
            default: break
            }
        }
        
        override func end(completion: () -> Void) {
            status = .terminated
            super.end(completion: completion)
            downstream = nil
        }
    }
    
    class InternalOperators<Downstream: Subscriber, Input, Failure: Error, Operator>: InternalBase<Downstream, Input, Failure> {
        
        let operation: Operator
        
        init(downstream: Downstream, operation: Operator) {
            self.operation = operation
            super.init(downstream: downstream)
        }
    }
    
    class Inner<Downstream: Subscriber, Input, Failure>: InternalBase<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
    }
    
    class InternalClosure<Downstream: Subscriber, Input, Failure: Error>: InternalBase<Downstream, Input, Failure> {
        
        final let receiveValue: ((Input, Downstream?) -> Void)
        
        final let receiveCompletion: ((Subscribers.Completion<Failure>, Downstream?) -> Void)
        
        init(downstream: Downstream,
             receiveCompletion: @escaping (Subscribers.Completion<Failure>, Downstream?) -> Void,
             receiveValue: @escaping ((Input, Downstream?) -> Void)) {
            
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            receiveValue(input, downstream)
            return nil
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            receiveCompletion(completion, downstream)
        }
    }
    
    class InternalCombine<Downstream: Subscriber>: Subscriber, Subscription {
        
        typealias Input = Downstream.Input
        
        typealias Failure = Downstream.Failure
        
        private(set) final var downstream: Downstream?
        
        private(set) final var demand: Subscribers.Demand = .none
        
        final var subscriptions: [Subscription] = []
        
        final var isTerminated: Bool = false
        
        final var awaitingSubscription: Bool {
            subscriptions.isEmpty
        }
        
        final var isSubscribed: Bool {
            !awaitingSubscription && !isTerminated
        }
        
        init(downstream: Downstream) {
            self.downstream = downstream
        }
        
        func checkAndSend() {
        }
        
        func onCompletion(_ completion: Subscribers.Completion<Failure>) {
        }
        
        final func receive(subscription: Subscription) {
            guard !isTerminated else { return }
            downstream?.receive(subscription: self)
            subscriptions.append(subscription)
            subscription.request(.unlimited)
        }
        
        final func receive(_ input: Input) -> Subscribers.Demand {
            guard !isTerminated else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        final func receive(completion: Subscribers.Completion<Failure>) {
            guard !isTerminated else { return }
            onCompletion(completion)
        }
        
        final func receive(completion: Subscribers.Completion<Failure>, downstream: InternalCombine?) {
            receive(completion: completion)
        }
        
        final func receive(input: Input, downstream: InternalCombine?) {
            _ = receive(input)
        }
        
        final func end() {
            isTerminated = true
            subscriptions = []
            downstream = nil
        }
        
        final func request(_ demand: Subscribers.Demand) {
            self.demand = demand
        }
        
        final func cancel() {
            isTerminated = true
            subscriptions.forEach { (subscription) in
                subscription.cancel()
            }
            
            subscriptions = []
            downstream = nil
        }
    }
    
    final class InternalAnySubject<DownstreamSubject: Subject>: Subscriber, Subscription {
        
        typealias Input = DownstreamSubject.Output
        
        typealias Failure = DownstreamSubject.Failure
        
        private var subject: DownstreamSubject?
        
        private var status: SubscriptionStatus = .awaiting
        
        private var demand: Subscribers.Demand = .none
        
        init(subject: DownstreamSubject) {
            self.subject = subject
        }
        
        final func request(_ demand: Subscribers.Demand) {
            guard case let .subscribed(subscription) = status else { return }
            self.demand = demand
            subscription.request(demand)
        }
        
        final func receive(subscription: Subscription) {
            guard status == .awaiting else { return }
            status = .subscribed(to: subscription)
            subject?.send(subscription: self)
        }
        
        final func receive(_ input: Input) -> Subscribers.Demand {
            guard status.isSubscribed else { return .none }
            subject?.send(input)
            return demand
        }
        
        final func receive(completion: Subscribers.Completion<Failure>) {
            guard status.isSubscribed else { return }
            end {
                subject?.send(completion: completion)
            }
        }
        
        final func end(completion: () -> Void) {
            status = .terminated
            completion()
            subject = nil
        }
        
        final func cancel() {
           guard case let .subscribed(subscription) = status else { return }
            status = .terminated
            subscription.cancel()
            subject = nil
        }
    }
}
