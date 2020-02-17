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
    
    class InternalBase<Downstream: Subscriber, Input, Failure: Error>: Subscriptions.InternalBase<Downstream, Input, Failure>, Subscriber {
        
        final var status: SubscriptionStatus = .awaiting
        
        private let lock = Lock()
        
        final func getLock() -> Lock {
            lock
        }
        
        final func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            onSubscription(subscription)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            super.request(demand)
            lock.unlock()
        }
        
        func onSubscription(_ subscription: Subscription) {
            status = .subscribed(to: subscription)
            lock.unlock()
            downstream?.receive(subscription: self)
            subscription.request(.unlimited)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            end {
                onCompletion(completion)
            }
        }
        
        func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            /* abstract method */
            nil
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            switch operate(on: input) {
            case .success(let output):
                _ = downstream?.receive(output)
                
            case .failure(let error):
                lock.lock()
                end {
                    downstream?.receive(completion: .failure(error))
                }
                
            case .none: break
            }
            
            return demand
        }
        
        override var description: String {
            "Inner"
        }
        
        override var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream ?? "nil"),
                ("status", status)
            ]
            
            return Mirror(self, children: children)
        }
        
        override func cancel() {
            lock.lock()
            switch status {
            case .subscribed(let subscription):
                status = .terminated
                lock.unlock()
                subscription.cancel()
                
            case .multipleSubscription(let subscriptions):
                status = .terminated
                lock.unlock()
                subscriptions.forEach { (subscription) in
                    subscription.cancel()
                }
                
            default: lock.unlock()
            }
            
            downstream = nil
        }
        
        override func end(completion: () -> Void) {
            status = .terminated
            lock.unlock()
            completion()
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
        
        private final var receiveValue: ((Input, Downstream?) -> Void)?
        
        private final var receiveCompletion: ((Subscribers.Completion<Failure>, Downstream?) -> Void)?
        
        init(downstream: Downstream,
             receiveCompletion: ((Subscribers.Completion<Failure>, Downstream?) -> Void)?,
             receiveValue: ((Input, Downstream?) -> Void)?) {
            
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            receiveValue?(input, downstream)
            return nil
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            receiveCompletion?(completion, downstream)
        }
        
        override func end(completion: () -> Void) {
            super.end(completion: completion)
            receiveValue = nil
            receiveCompletion = nil
        }
        
        override func cancel() {
            super.cancel()
            receiveValue = nil
            receiveCompletion = nil
        }
    }
    
    class InternalCombine<Downstream: Subscriber>: Subscriptions.InternalBase<Downstream, Downstream.Input, Downstream.Failure>, Subscriber {
        
        final var subscriptions: [Subscription] = []
        
        final private(set) var isTerminated = false
        
        var allSubscriptionsHaveTerminated: Bool { false } /* abstract property to be used by Merge and Combine Latest publishers */
        
        private let lock = Lock()
        
        final func getLock() -> Lock {
            lock
        }
        
        final var awaitingSubscription: Bool {
            subscriptions.isEmpty
        }
        
        final var isSubscribed: Bool {
            !awaitingSubscription && !isTerminated
        }
        
        func checkAndSend() {
        }
        
        final func receive(subscription: Subscription) {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return }
            lock.unlock()
            downstream?.receive(subscription: self)
            subscriptions.append(subscription)
            subscription.request(.unlimited)
        }
        
        final func receive(_ input: Downstream.Input) -> Subscribers.Demand {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return .none }
            lock.unlock()
            _ = downstream?.receive(input)
            return demand
        }
        
        final override func receive(completion: Subscribers.Completion<Downstream.Failure>) {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return }
            onCompletion(completion)
        }
        
        /* Used by Merge and Combine Latest Publishers, as they only pass completion after all upstream publishers have terminated, unlike Zip publisher */
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            switch completion {
            case .finished:
                guard allSubscriptionsHaveTerminated else {
                    lock.unlock()
                    return
                }
                
                end {
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end {
                    downstream?.receive(completion: .failure(error))
                }
            }
        }
        
        final func receive(completion: Subscribers.Completion<Downstream.Failure>, downstream: InternalCombine?) {
            receive(completion: completion)
        }
        
        final func receive(input: Downstream.Input, downstream: InternalCombine?) {
            _ = receive(input)
        }
        
        final override func end(completion: () -> Void) {
            isTerminated = true
            lock.unlock()
            
            completion()
            subscriptions = []
        }
        
        final override func cancel() {
            lock.lock()
            isTerminated = true
            lock.unlock()
            
            super.cancel()
            
            subscriptions.forEach { (subscription) in
                subscription.cancel()
            }
            
            subscriptions = []
        }
        
        override var description: String {
            "Internal Combine"
        }
        
        override var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
    
    final class InternalSubject<DownstreamSubject: Subject>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable {
        
        typealias Input = DownstreamSubject.Output
        
        typealias Failure = DownstreamSubject.Failure
        
        private var subject: DownstreamSubject?
        
        private var status: SubscriptionStatus = .awaiting
        
        private var demand: Subscribers.Demand = .none
        
        private let lock = Lock()
        
        init(subject: DownstreamSubject) {
            self.subject = subject
        }
        
        final func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case let .subscribed(subscription) = status else { lock.unlock(); return }
            self.demand = demand
            lock.unlock()
            subscription.request(demand)
        }
        
        final func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            subject?.send(subscription: self)
        }
        
        final func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            subject?.send(input)
            return demand
        }
        
        final func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            
            end {
                subject?.send(completion: completion)
            }
        }
        
        final func end(completion: () -> Void) {
            status = .terminated
            lock.unlock()
            completion()
            subject = nil
        }
        
        final func cancel() {
            lock.lock()
            guard case let .subscribed(subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
            subject = nil
        }
        
        var description: String {
            "Internal Subject"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
