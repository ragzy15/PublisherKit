//
//  Prefix Until Output.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 28/03/20.
//

extension Publishers {
    
    public struct PrefixUntilOutput<Upstream, Other> : Publisher where Upstream : Publisher, Other : Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// Another publisher, whose first output causes this publisher to finish.
        public let other: Other
        
        public init(upstream: Upstream, other: Other) {
            self.upstream = upstream
            self.other = other
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber)
            
            let termination = Inner.Termination(inner: inner)
            inner.termination = termination
            other.subscribe(termination)
            
            let prefix = Inner.Prefix(inner: inner)
            inner.prefix = prefix
            upstream.subscribe(prefix)
            
            subscriber.receive(subscription: inner)
        }
    }
}

extension Publishers.PrefixUntilOutput {
    
    // MARK: PREFIX UNTIL OUTPUT SINK
    private final class Inner<Downstream: Subscriber>: Subscription where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        
        private var upstreamPrefixSubscription: Subscription?
        private var upstreamTerminationSubscription: Subscription?
        
        fileprivate var prefix: Prefix?
        fileprivate var termination: Termination?
        
        init(downstream: Downstream) {
            self.downstream = downstream
        }
        
        func request(_ demand: Subscribers.Demand) {
            upstreamPrefixSubscription?.request(demand)
        }
        
        func cancel() {
            upstreamPrefixSubscription?.cancel()
            upstreamTerminationSubscription?.cancel()
            terminal(cancelled: true)
        }
        
        private func terminal(cancelled: Bool) {
            
            if !cancelled {
                upstreamTerminationSubscription?.cancel()
            }
            
            upstreamTerminationSubscription = nil
            upstreamPrefixSubscription = nil
            
            termination = nil
            prefix = nil
        }
        
        private func prefixReceive(subscription: Subscription) {
            upstreamPrefixSubscription = subscription
        }
        
        private func prefixReceive(_ input: Upstream.Output) -> Subscribers.Demand {
            downstream.receive(input)
        }
        
        private func prefixReceive(completion: Subscribers.Completion<Upstream.Failure>) {
            terminal(cancelled: false)
            downstream.receive(completion: completion)
        }
        
        private func terminationReceive(subscription: Subscription) {
            upstreamTerminationSubscription = subscription
            subscription.request(.max(1))
        }
        
        private func terminationReceive(_ input: Other.Output) -> Subscribers.Demand {
            cancel()
            downstream.receive(completion: .finished)
            return .none
        }
        
        fileprivate struct Prefix: Subscriber {
            
            private let inner: Inner
            let combineIdentifier = CombineIdentifier()
            
            init(inner: Inner) {
                self.inner = inner
            }
            
            func receive(subscription: Subscription) {
                inner.prefixReceive(subscription: subscription)
            }
            
            func receive(_ input: Upstream.Output) -> Subscribers.Demand {
                inner.prefixReceive(input)
            }
            
            func receive(completion: Subscribers.Completion<Upstream.Failure>) {
                inner.prefixReceive(completion: completion)
            }
        }
        
        fileprivate struct Termination: Subscriber {
            
            private let inner: Inner
            let combineIdentifier = CombineIdentifier()
            
            init(inner: Inner) {
                self.inner = inner
            }
            
            func receive(subscription: Subscription) {
                inner.terminationReceive(subscription: subscription)
            }
            
            func receive(_ input: Other.Output) -> Subscribers.Demand {
                inner.terminationReceive(input)
            }
            
            func receive(completion: Subscribers.Completion<Other.Failure>) {
                // NOT IN USE
            }
        }
    }
}
