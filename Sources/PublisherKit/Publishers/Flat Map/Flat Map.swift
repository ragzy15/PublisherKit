//
//  Flat Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that transforms elements from an upstream publisher into a publisher of that element’s type.
    public struct FlatMap<Upstream: Publisher, NewPublisher: Publisher>: Publisher where Upstream.Failure == NewPublisher.Failure {
        
        public typealias Output = NewPublisher.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The maximum number of publishers produced by this method.
        public let maxPublishers: Subscribers.Demand
        
        /// A closure that takes an element as a parameter and returns a publisher
        public let transform: (Upstream.Output) -> NewPublisher
        
        public init(upstream: Upstream, maxPublishers: Subscribers.Demand, transform: @escaping (Upstream.Output) -> NewPublisher) {
            self.upstream = upstream
            self.maxPublishers = maxPublishers
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let flatMapSubscriber = Inner(downstream: subscriber, maxPublishers: maxPublishers, operation: transform)
            upstream.subscribe(flatMapSubscriber)
        }
    }
}

extension Publishers.FlatMap {
    
    // MARK: FLATMAP SINK
    private final class Inner<Downstream: Subscriber, NewPublisher: Publisher>: OperatorSubscriber<Downstream, Upstream, (Upstream.Output) -> NewPublisher> where NewPublisher.Output == Downstream.Input, Failure == Downstream.Failure, NewPublisher.Failure == Failure {
        
        private let maxPublishers: Subscribers.Demand
        
        private var innerStatus: SubscriptionStatus = .awaiting
        private var innerSubscriptions: [Int: Subscription] = [:]
        
        private var currentIndex = 0
        private var pendingSubscriptions = 0
        
        private let downstreamLock = RecursiveLock()
        
        init(downstream: Downstream, maxPublishers: Subscribers.Demand, operation: @escaping (Upstream.Output) -> NewPublisher) {
            self.maxPublishers = maxPublishers
            super.init(downstream: downstream, operation: operation)
        }
        
        override final func onSubscription(_ subscription: Subscription) {
            status = .subscribed(to: subscription)
            getLock().unlock()
            
            downstreamLock.lock()
            downstream?.receive(subscription: self)
            downstreamLock.unlock()
            
            subscription.request(maxPublishers)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            super.request(self.demand + demand)
        }
        
        override final func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            let publisher = operation(input)
            
            getLock().lock()
            currentIndex += 1
            pendingSubscriptions += 1
            getLock().unlock()
            
            let subscriber = MapInner(outer: self, index: currentIndex)
            publisher.subscribe(subscriber)
            
            return nil
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return }
            status = .terminated
            
            switch completion {
            case .finished:
                sendCompletionIfPossible()
                
            case .failure(let error):
                cancelInnerSubscriptions()
                end {
                    downstreamLock.lock()
                    downstream?.receive(completion: .failure(error))
                    downstreamLock.unlock()
                }
            }
        }
        
        override func cancel() {
            switch status {
            case .subscribed(let subscription):
                status = .terminated
                cancelInnerSubscriptions()
                subscription.cancel()
                
            default: break
            }
            
            super.cancel()
        }
        
        func receiveInner(subscription: Subscription, for index: Int) {
            getLock().lock()
            
            pendingSubscriptions -= 1
            innerSubscriptions[index] = subscription
            
            getLock().unlock()
            
            subscription.request(demand == .unlimited ? .unlimited : .max(1))
        }
        
        func receiveInner(input: NewPublisher.Output, for index: Int) -> Subscribers.Demand {
            getLock().lock()
            
            guard demand != .unlimited else {
                getLock().unlock()
                downstreamLock.lock()
                _ = downstream?.receive(input)
                downstreamLock.unlock()
                return .unlimited
            }
            
            guard demand != .none else { getLock().unlock(); return .none }
            
            demand -= 1
            
            getLock().unlock()
            
            downstreamLock.lock()
            let newDemand = downstream?.receive(input) ?? .none
            downstreamLock.unlock()
            
            if newDemand > .none {
                getLock().lock()
                demand += newDemand
                getLock().unlock()
            }
            
            return .max(1)
        }
        
        func receiveInner(completion: Subscribers.Completion<NewPublisher.Failure>, for index: Int) {
            getLock().lock()
            innerSubscriptions.removeValue(forKey: index)
            
            switch completion {
            case .finished:
                sendCompletionIfPossible()
                
            case .failure(let error):
                cancelInnerSubscriptions()
                
                end {
                    downstreamLock.lock()
                    downstream?.receive(completion: .failure(error))
                    downstreamLock.unlock()
                }
            }
        }
        
        func cancelInnerSubscriptions() {
            innerSubscriptions.forEach { (_, innerSubscription) in
                innerSubscription.cancel()
            }
            
            innerSubscriptions = [:]
        }
        
        func sendCompletionIfPossible() {
            guard status.isTerminated, innerSubscriptions.count + pendingSubscriptions == 0 else {
                getLock().unlock()
                return
            }
            
            end {
                downstreamLock.lock()
                downstream?.receive(completion: .finished)
                downstreamLock.unlock()
            }
        }
        
        override var description: String {
            "FlatMap"
        }
        
        private final class MapInner: Subscriber {
            
            typealias Input = NewPublisher.Output
            
            typealias Failure = NewPublisher.Failure
            
            private let outer: Inner
            private let index: Int
            
            init(outer: Inner, index: Int) {
                self.outer = outer
                self.index = index
            }
            
            func receive(subscription: Subscription) {
                outer.receiveInner(subscription: subscription, for: index)
            }
            
            func receive(_ input: NewPublisher.Output) -> Subscribers.Demand {
                outer.receiveInner(input: input, for: index)
            }
            
            func receive(completion: Subscribers.Completion<NewPublisher.Failure>) {
                outer.receiveInner(completion: completion, for: index)
            }
        }
    }
}
