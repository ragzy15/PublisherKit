//
//  Concatenate.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

extension Publisher {
    
    /// Prefixes a `Publisher`'s output with the specified sequence.
    /// - Parameter elements: The elements to publish before this publisher’s elements.
    /// - Returns: A publisher that prefixes the specified elements prior to this publisher’s elements.
    public func prepend(_ elements: Output...) -> Publishers.Concatenate<Publishers.Sequence<[Output], Failure>, Self> {
        prepend(elements)
    }
    
    /// Prefixes a `Publisher`'s output with the specified sequence.
    /// - Parameter elements: A sequence of elements to publish before this publisher’s elements.
    /// - Returns: A publisher that prefixes the sequence of elements prior to this publisher’s elements.
    public func prepend<S: Sequence>(_ elements: S) -> Publishers.Concatenate<Publishers.Sequence<S, Failure>, Self> where Output == S.Element {
        prepend(Publishers.Sequence(sequence: elements))
    }
    
    /// Prefixes this publisher’s output with the elements emitted by the given publisher.
    ///
    /// The resulting publisher doesn’t emit any elements until the prefixing publisher finishes.
    /// - Parameter publisher: The prefixing publisher.
    /// - Returns: A publisher that prefixes the prefixing publisher’s elements prior to this publisher’s elements.
    public func prepend<P: Publisher>(_ publisher: P) -> Publishers.Concatenate<P, Self> where Output == P.Output, Failure == P.Failure {
        Publishers.Concatenate(prefix: publisher, suffix: self)
    }
    
    /// Append a `Publisher`'s output with the specified sequence.
    public func append(_ elements: Output...) -> Publishers.Concatenate<Self, Publishers.Sequence<[Output], Failure>> {
        append(elements)
    }
    
    /// Appends a `Publisher`'s output with the specified sequence.
    public func append<S: Sequence>(_ elements: S) -> Publishers.Concatenate<Self, Publishers.Sequence<S, Failure>> where Output == S.Element {
        append(Publishers.Sequence(sequence: elements))
    }
    
    /// Appends this publisher’s output with the elements emitted by the given publisher.
    ///
    /// This operator produces no elements until this publisher finishes. It then produces this publisher’s elements, followed by the given publisher’s elements. If this publisher fails with an error, the prefixing publisher does not publish the provided publisher’s elements.
    /// - Parameter publisher: The appending publisher.
    /// - Returns: A publisher that appends the appending publisher’s elements after this publisher’s elements.
    public func append<P: Publisher>(_ publisher: P) -> Publishers.Concatenate<Self, P> where Output == P.Output, Failure == P.Failure {
        Publishers.Concatenate(prefix: self, suffix: publisher)
    }
}

extension Publishers {
    
    /// A publisher that emits all of one publisher’s elements before those from another publisher.
    public struct Concatenate<Prefix: Publisher, Suffix: Publisher>: Publisher where Prefix.Output == Suffix.Output, Prefix.Failure == Suffix.Failure {
        
        public typealias Output = Suffix.Output
        
        public typealias Failure = Suffix.Failure
        
        /// The publisher to republish, in its entirety, before republishing elements from `suffix`.
        public let prefix: Prefix
        
        /// The publisher to republish only after `prefix` finishes.
        public let suffix: Suffix
        
        public init(prefix: Prefix, suffix: Suffix) {
            self.prefix = prefix
            self.suffix = suffix
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber, suffix: suffix)
            subscriber.receive(subscription: inner)
            prefix.subscribe(inner)
        }
    }
}

extension Publishers.Concatenate: Equatable where Prefix: Equatable, Suffix: Equatable { }

extension Publishers.Concatenate {
    
    // MARK: CONCATENATE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Suffix.Output
        
        typealias Failure = Suffix.Failure
        
        private let downstream: Downstream
        private let suffix: Suffix
        
        private var hasPrefixFinished = false
        
        private var demand: Subscribers.Demand = .none
        
        private var upstreamSubscription: Subscription?
        
        private var maxSubscriptions = 2
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        init(downstream: Downstream, suffix: Suffix) {
            self.downstream = downstream
            self.suffix = suffix
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard upstreamSubscription == nil, maxSubscriptions > 0 else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            upstreamSubscription = subscription
            maxSubscriptions -= 1
            
            let demand = self.demand
            lock.unlock()
            
            if demand > .none {
                subscription.request(demand)
            }
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            demand -= 1
            lock.unlock()
            
            downstreamLock.lock()
            let additionalDemand = downstream.receive(input)
            downstreamLock.unlock()
            
            lock.lock()
            demand += additionalDemand
            lock.unlock()
            
            return additionalDemand
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            if hasPrefixFinished {
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
                return
            }
            
            switch completion {
            case .finished:
                hasPrefixFinished = true
                
                lock.lock()
                upstreamSubscription = nil
                lock.unlock()
                
                suffix.subscribe(self)
                
            case .failure(let error):
                downstreamLock.lock()
                downstream.receive(completion: .failure(error))
                downstreamLock.unlock()
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            self.demand += demand
            guard let upstreamSubscription = upstreamSubscription else { lock.unlock(); return }
            lock.unlock()
            
            upstreamSubscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard let upstreamSubscription = upstreamSubscription else { lock.unlock(); return }
            self.upstreamSubscription = nil
            lock.unlock()
            
            upstreamSubscription.cancel()
        }
        
        var description: String {
            "Concatenate"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream),
                ("upstreamSubscription", upstreamSubscription as Any),
                ("suffix", suffix),
                ("demand", demand)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
