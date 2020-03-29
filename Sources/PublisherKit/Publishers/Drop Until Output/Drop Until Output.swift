//
//  Drop Until Output.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

extension Publisher {
    
    /// Ignores elements from the upstream publisher until it receives an element from a second publisher.
    ///
    /// This publisher requests a single value from the upstream publisher, and it ignores (drops) all elements from that publisher until the upstream publisher produces a value. After the `other` publisher produces an element, this publisher cancels its subscription to the `other` publisher, and allows events from the `upstream` publisher to pass through.
    /// After this publisher receives a subscription from the upstream publisher, it passes through backpressure requests from downstream to the upstream publisher. If the upstream publisher acts on those requests before the other publisher produces an item, this publisher drops the elements it receives from the upstream publisher.
    ///
    /// - Parameter publisher: A publisher to monitor for its first emitted element.
    /// - Returns: A publisher that drops elements from the upstream publisher until the `other` publisher produces a value.
    public func drop<P: Publisher>(untilOutputFrom publisher: P) -> Publishers.DropUntilOutput<Self, P> where Failure == P.Failure {
        Publishers.DropUntilOutput(upstream: self, other: publisher)
    }
}

extension Publishers {
    
    /// A publisher that ignores elements from the upstream publisher until it receives an element from second publisher.
    public struct DropUntilOutput<Upstream: Publisher, Other: Publisher> : Publisher where Upstream.Failure == Other.Failure {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// A publisher to monitor for its first emitted element.
        public let other: Other
        
        /// Creates a publisher that ignores elements from the upstream publisher until it receives an element from another publisher.
        ///
        /// - Parameters:
        ///   - upstream: A publisher to drop elements from while waiting for another publisher to emit elements.
        ///   - other: A publisher to monitor for its first emitted element.
        public init(upstream: Upstream, other: Other) {
            self.upstream = upstream
            self.other = other
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber)
            subscriber.receive(subscription: inner)
            other.subscribe(Inner.OtherSubscriber(inner: inner))
            upstream.subscribe(inner)
        }
    }
}

extension Publishers.DropUntilOutput: Equatable where Upstream: Equatable, Other: Equatable { }

extension Publishers.DropUntilOutput {
    
    // MARK: DROP UNTIL OUTPUT SINK
    fileprivate final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        
        private var pendingDemand: Subscribers.Demand = .none
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private var upstreamSubscription: Subscription?
        private var otherSubscription: Subscription?
        
        private var otherFinished = false
        private var cancelled = false
        private var triggered = false
        
        init(downstream: Downstream) {
            self.downstream = downstream
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard !cancelled, upstreamSubscription == nil else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            upstreamSubscription = subscription
            
            guard pendingDemand > .none else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(pendingDemand)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard triggered || !cancelled else {
                pendingDemand -= 1
                lock.unlock()
                return .none
            }
            lock.unlock()
            
            downstreamLock.lock()
            let demand = downstream.receive(input)
            downstreamLock.unlock()
            
            return demand
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard !cancelled else { lock.unlock(); return }
            cancelled = true
            lock.unlock()
            
            downstreamLock.lock()
            downstream.receive(completion: completion)
            downstreamLock.unlock()
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            pendingDemand += demand
            guard let upstreamSubscription = self.upstreamSubscription else { lock.unlock(); return }
            lock.unlock()
            
            upstreamSubscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            let upstreamSubscription = self.upstreamSubscription
            let otherSubscription = self.otherSubscription
            
            self.upstreamSubscription = nil
            self.otherSubscription = nil
            
            cancelled = true
            lock.unlock()
            
            upstreamSubscription?.cancel()
            otherSubscription?.cancel()
        }
        
        private func receiveOther(subscription: Subscription) {
            guard otherSubscription == nil else {
                subscription.cancel()
                return
            }
            
            otherSubscription = subscription
            
            subscription.request(.max(1))
        }
        
        private func receiveOther(_ input: Other.Output) -> Subscribers.Demand {
            lock.lock()
            triggered = true
            otherSubscription = nil
            lock.unlock()
            
            return .none
        }
        
        private func receiveOther(completion: Subscribers.Completion<Other.Failure>) {
            lock.lock()
            guard !triggered else {
                otherSubscription = nil
                lock.unlock()
                return
            }
            
            otherFinished = true
            guard let upstreamSubscription = self.upstreamSubscription else { lock.unlock(); return }
            self.upstreamSubscription = nil
            lock.unlock()
            
            upstreamSubscription.cancel()
            
            downstreamLock.lock()
            downstream.receive(completion: completion)
            downstreamLock.unlock()
        }
        
        var description: String {
            "DropUntilOutput"
        }
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
        
        fileprivate struct OtherSubscriber: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
            
            private let inner: Inner
            
            var combineIdentifier: CombineIdentifier {
                inner.combineIdentifier
            }
            
            init(inner: Inner) {
                self.inner = inner
            }
            
            func receive(subscription: Subscription) {
                inner.receiveOther(subscription: subscription)
            }
            
            func receive(_ input: Other.Output) -> Subscribers.Demand {
                inner.receiveOther(input)
            }
            
            func receive(completion: Subscribers.Completion<Other.Failure>) {
                inner.receiveOther(completion: completion)
            }
            
            var description: String {
                inner.description
            }
            
            var playgroundDescription: Any {
                inner.playgroundDescription
            }
            
            var customMirror: Mirror {
                inner.customMirror
            }
        }
    }
}
