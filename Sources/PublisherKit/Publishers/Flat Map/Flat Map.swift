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
            let inner = Inner(downstream: subscriber, maxPublishers: maxPublishers, transform: transform)
            subscriber.receive(subscription: inner)
            upstream.subscribe(inner)
        }
    }
}

extension Publishers.FlatMap {
    
    // Credits - broadwaylamb/OpenCombine
    
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where NewPublisher.Output == Downstream.Input, Upstream.Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private typealias Index = Int
        
        /// All requests to this subscription should be made with the `outerLock`
        /// acquired.
        private var outerSubscription: Subscription?
        
        // Must be recursive lock. Probably a bug in Combine.
        /// The lock for requesting from `outerSubscription`.
        private let outerLock = Lock()
        
        /// The lock for modifying the state. All mutable state here should be
        /// read and modified with this lock acquired.
        /// The only exception is the `downstreamRecursive` field, which is guarded
        /// by the `downstreamLock`.
        private let lock = Lock()
        
        /// All the calls to the downstream subscriber should be made with this lock
        /// acquired.
        private let downstreamLock = RecursiveLock()
        
        private let downstream: Downstream
        
        private var downstreamDemand = Subscribers.Demand.none
        
        /// This variable is set to `true` whenever we call `downstream.receive(_:)`,
        /// and then set back to `false`.
        private var downstreamRecursive = false
        
        private var innerRecursive = false
        
        private var subscriptions = [Index : Subscription]()
        private var nextInnerIndex: Index = 0
        private var pendingSubscriptions = 0
        
        private var buffer = [(Index, NewPublisher.Output)]()
        private let maxPublishers: Subscribers.Demand
        
        private let transform: (Input) -> NewPublisher
        
        private var cancelledOrCompleted = false
        private var outerFinished = false
        
        init(downstream: Downstream, maxPublishers: Subscribers.Demand, transform: @escaping (Input) -> NewPublisher) {
            self.downstream = downstream
            self.maxPublishers = maxPublishers
            self.transform = transform
        }
        
        // MARK: - Subscriber
        
        fileprivate func receive(subscription: Subscription) {
            lock.lock()
            guard outerSubscription == nil, !cancelledOrCompleted else {
                lock.unlock()
                subscription.cancel()
                return
            }
            outerSubscription = subscription
            lock.unlock()
            subscription.request(maxPublishers)
        }
        
        fileprivate func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            let cancelledOrCompleted = self.cancelledOrCompleted
            lock.unlock()
            if cancelledOrCompleted {
                return .none
            }
            let NewPublisher = transform(input)
            lock.lock()
            let innerIndex = nextInnerIndex
            nextInnerIndex += 1
            pendingSubscriptions += 1
            lock.unlock()
            NewPublisher.subscribe(Side(index: innerIndex, inner: self))
            return .none
        }
        
        fileprivate func receive(completion: Subscribers.Completion<NewPublisher.Failure>) {
            outerSubscription = nil
            lock.lock()
            outerFinished = true
            switch completion {
            case .finished:
                releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: true)
                return
            case .failure:
                let wasAlreadyCancelledOrCompleted = cancelledOrCompleted
                cancelledOrCompleted = true
                for (_, subscription) in subscriptions {
                    subscription.cancel()
                }
                subscriptions = [:]
                lock.unlock()
                if wasAlreadyCancelledOrCompleted {
                    return
                }
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
            }
        }
        
        // MARK: - Subscription
        
        fileprivate func request(_ demand: Subscribers.Demand) {
            if downstreamRecursive {
                // downstreamRecursive being true means that downstreamLock
                // is already acquired.
                downstreamDemand += demand
                return
            }
            lock.lock()
            if cancelledOrCompleted {
                lock.unlock()
                return
            }
            if demand == .unlimited {
                downstreamDemand = .unlimited
                let buffer = self.buffer
                self.buffer = []
                let subscriptions = self.subscriptions
                lock.unlock()
                downstreamLock.lock()
                downstreamRecursive = true
                for (_, NewPublisherOutput) in buffer {
                    _ = downstream.receive(NewPublisherOutput)
                }
                downstreamRecursive = false
                downstreamLock.unlock()
                for (_, subscription) in subscriptions {
                    subscription.request(.unlimited)
                }
                lock.lock()
            } else {
                downstreamDemand += demand
                while !buffer.isEmpty && downstreamDemand > 0 {
                    // FIXME: This has quadratic complexity.
                    // This is what Combine does.
                    // Can we improve perfomance by using e. g. Deque instead of Array?
                    // Or array's cache locality makes this solution more efficient?
                    // Must benchmark before optimizing!
                    //
                    // https://www.cocoawithlove.com/blog/2016/09/22/deque.html
                    let (index, value) = buffer.removeFirst()
                    downstreamDemand -= 1
                    let subscription = subscriptions[index]
                    lock.unlock()
                    downstreamLock.lock()
                    downstreamRecursive = true
                    let additionalDemand = downstream.receive(value)
                    downstreamRecursive = false
                    downstreamLock.unlock()
                    if additionalDemand != .none {
                        lock.lock()
                        downstreamDemand += additionalDemand
                        lock.unlock()
                    }
                    if let subscription = subscription {
                        innerRecursive = true
                        subscription.request(.max(1))
                        innerRecursive = false
                    }
                    lock.lock()
                }
            }
            releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: outerFinished)
        }
        
        fileprivate func cancel() {
            lock.lock()
            cancelledOrCompleted = true
            let subscriptions = self.subscriptions
            self.subscriptions = [:]
            lock.unlock()
            for (_, subscription) in subscriptions {
                subscription.cancel()
            }
            // Combine doesn't acquire the lock here. Weird.
            outerSubscription?.cancel()
            outerSubscription = nil
        }
        
        // MARK: - Reflection
        
        fileprivate var description: String {
            "FlatMap"
        }
        
        fileprivate var customMirror: Mirror {
            Mirror(self, children: [])
        }
        
        fileprivate var playgroundDescription: Any { return description }
        
        // MARK: - Private
        
        private func receiveInner(subscription: Subscription, _ index: Index) {
            lock.lock()
            pendingSubscriptions -= 1
            subscriptions[index] = subscription
            
            let demand = downstreamDemand == .unlimited
                ? Subscribers.Demand.unlimited
                : .max(1)
            
            lock.unlock()
            subscription.request(demand)
        }
        
        private func receiveInner(_ input: NewPublisher.Output, _ index: Index) -> Subscribers.Demand {
            lock.lock()
            if downstreamDemand == .unlimited {
                lock.unlock()
                downstreamLock.lock()
                downstreamRecursive = true
                _ = downstream.receive(input)
                downstreamRecursive = false
                downstreamLock.unlock()
                return .none
            }
            if downstreamDemand == .none || innerRecursive {
                buffer.append((index, input))
                lock.unlock()
                return .none
            }
            downstreamDemand -= 1
            lock.unlock()
            downstreamLock.lock()
            downstreamRecursive = true
            let newDemand = downstream.receive(input)
            downstreamRecursive = false
            downstreamLock.unlock()
            if newDemand > 0 {
                lock.lock()
                downstreamDemand += newDemand
                lock.unlock()
            }
            return .max(1)
        }
        
        private func receiveInner(completion: Subscribers.Completion<NewPublisher.Failure>, _ index: Index) {
            switch completion {
            case .finished:
                lock.lock()
                subscriptions.removeValue(forKey: index)
                let downstreamCompleted = releaseLockThenSendCompletionDownstreamIfNeeded(
                    outerFinished: outerFinished
                )
                if !downstreamCompleted {
                    requestOneMorePublisher()
                }
            case .failure:
                lock.lock()
                if cancelledOrCompleted {
                    lock.unlock()
                    return
                }
                cancelledOrCompleted = true
                let subscriptions = self.subscriptions
                self.subscriptions = [:]
                lock.unlock()
                for (i, subscription) in subscriptions where i != index {
                    subscription.cancel()
                }
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
            }
        }
        
        private func requestOneMorePublisher() {
            if maxPublishers != .unlimited {
                outerLock.lock()
                outerSubscription?.request(.max(1))
                outerLock.unlock()
            }
        }
        
        /// - Precondition: `lock` is acquired
        /// - Postcondition: `lock` is released
        ///
        /// - Returns: `true` if a completion was sent downstream
        @discardableResult
        private func releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: Bool) -> Bool {
            #if DEBUG
            lock.assertOwner() // Sanity check
            #endif
            if !cancelledOrCompleted && outerFinished && buffer.isEmpty &&
                subscriptions.count + pendingSubscriptions == 0 {
                cancelledOrCompleted = true
                lock.unlock()
                downstreamLock.lock()
                downstream.receive(completion: .finished)
                downstreamLock.unlock()
                return true
            }
            
            lock.unlock()
            return false
        }
        
        // MARK: - Side
        
        private struct Side: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
            
            private let index: Index
            private let inner: Inner
            
            fileprivate let combineIdentifier = CombineIdentifier()
            
            fileprivate init(index: Index, inner: Inner) {
                self.index = index
                self.inner = inner
            }
            
            fileprivate func receive(subscription: Subscription) {
                inner.receiveInner(subscription: subscription, index)
            }
            
            fileprivate func receive(_ input: NewPublisher.Output) -> Subscribers.Demand {
                return inner.receiveInner(input, index)
            }
            
            fileprivate func receive(completion: Subscribers.Completion<NewPublisher.Failure>) {
                inner.receiveInner(completion: completion, index)
            }
            
            fileprivate var description: String {
                inner.description
            }
            
            fileprivate var customMirror: Mirror {
                inner.customMirror
            }
            
            fileprivate var playgroundDescription: Any {
                inner.playgroundDescription
            }
        }
        
    }
}
