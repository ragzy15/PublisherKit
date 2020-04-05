//
//  Switch To Latest.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 28/03/20.
//

extension Publishers {
    
    /// A publisher that “flattens” nested publishers.
    ///
    /// Given a publisher that publishes Publishers, the `SwitchToLatest` publisher produces a sequence of events from only the most recent one.
    /// For example, given the type `Publisher<Publisher<Data, NSError>, Never>`, calling `switchToLatest()` will result in the type `Publisher<Data, NSError>`. The downstream subscriber sees a continuous stream of values even though they may be coming from different upstream publishers.
    public struct SwitchToLatest<P: Publisher, Upstream: Publisher>: Publisher where P == Upstream.Output, P.Failure == Upstream.Failure {
        
        public typealias Output = P.Output
        
        public typealias Failure = P.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// Creates a publisher that “flattens” nested publishers.
        ///
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let outer = Outer(downstream: subscriber)
            subscriber.receive(subscription: outer)
            upstream.subscribe(outer)
        }
    }
}

extension Publishers.SwitchToLatest {
    
    // MARK: SWITCH TO LATEST SINK
    private final class Outer<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        
        private var outerSubscription: Subscription?
        private var innerSubscription: Subscription?
        
        private var innerIndex: Int = 0
        private var nextInnerIndex: Int = 1
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private var isCancelled = false
        private var isFinished = false
        
        private var hasSentCompletion = false
        private var awaitingInnerSubscription = false
        
        private var downstreamDemand: Subscribers.Demand = .none
        
        init(downstream: Downstream) {
            self.downstream = downstream
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard !isCancelled, !isFinished, outerSubscription == nil else {
                lock.unlock()
                subscription.cancel()
                return
            }
            outerSubscription = subscription
            lock.unlock()
            
            subscription.request(.unlimited)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard !isCancelled, !isFinished else { lock.unlock(); return .none }
            
            if let innerSubscription = innerSubscription  {
                self.innerSubscription = nil
                lock.unlock()
                
                innerSubscription.cancel()
                lock.lock()
            }
            
            let index = nextInnerIndex
            innerIndex = nextInnerIndex
            nextInnerIndex += 1
            
            awaitingInnerSubscription = true
            lock.unlock()
            
            input.subscribe(Side(self, index))
            
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard !isCancelled, !isFinished else { lock.unlock(); return }
            outerSubscription = nil
            
            switch completion {
            case .finished:
                guard !awaitingInnerSubscription, innerSubscription != nil else { lock.unlock(); return }
                
                hasSentCompletion = true
                isFinished = true
                lock.unlock()
                
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
                
            case .failure:
                let innerSubscription = self.innerSubscription
                self.innerSubscription = nil
                
                hasSentCompletion = true
                isFinished = true
                lock.unlock()
                
                innerSubscription?.cancel()
                
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must be greater than zero.")
            
            lock.lock()
            downstreamDemand += demand
            guard let innerSubscription = self.innerSubscription else { lock.unlock(); return }
            lock.unlock()
            
            innerSubscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            isCancelled = true
            
            let innerSubscription = self.innerSubscription
            self.innerSubscription = nil
            
            let outerSubscription = self.outerSubscription
            self.outerSubscription = nil
            lock.unlock()
            
            innerSubscription?.cancel()
            outerSubscription?.cancel()
        }
        
        func receiveInner(subscription: Subscription, _ index: Int) {
            lock.lock()
            guard !isCancelled, innerIndex == index, innerSubscription == nil else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            innerSubscription = subscription
            awaitingInnerSubscription = false
            
            let downstreamDemand = self.downstreamDemand
            lock.unlock()
            
            if downstreamDemand > .none {
                subscription.request(downstreamDemand)
            }
        }
        
        func receiveInner(_ input: P.Output, _ index: Int) -> Subscribers.Demand {
            lock.lock()
            guard !isCancelled, innerIndex == index else { lock.unlock(); return .none }
            downstreamDemand -= 1
            lock.unlock()
            
            downstreamLock.lock()
            let additionalDemand = downstream.receive(input)
            downstreamLock.unlock()
            
            if additionalDemand > .none {
                lock.lock()
                downstreamDemand += additionalDemand
                lock.unlock()
            }
            
            return additionalDemand
        }
        
        func receiveInner(completion: Subscribers.Completion<P.Failure>, _ index: Int) {
            lock.lock()
            guard !isCancelled, innerIndex == index else { lock.unlock(); return }
            
            precondition(!awaitingInnerSubscription, "Unexpected completion.")
            
            innerSubscription = nil
            
            switch completion {
            case .finished:
                guard !hasSentCompletion || !isFinished else { lock.unlock(); return }
                hasSentCompletion = true
                lock.unlock()
                
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
                
            case .failure:
                guard !hasSentCompletion else { lock.unlock(); return }
                isCancelled = true
                hasSentCompletion = true
                
                let outerSubscription = self.outerSubscription
                self.outerSubscription = nil
                
                lock.unlock()
                
                outerSubscription?.cancel()
                
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
            }
        }
        
        var description: String {
            "SwitchToLatest"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
        
        private struct Side: Subscriber {
            
            typealias Input = P.Output
            
            typealias Failure = P.Failure
            
            private let outer: Outer
            private let index: Int
            let combineIdentifier = CombineIdentifier()
            
            init(_ outer: Outer, _ index: Int) {
                self.outer = outer
                self.index = index
            }
            
            func receive(subscription: Subscription) {
                outer.receiveInner(subscription: subscription, index)
            }
            
            func receive(_ input: Input) -> Subscribers.Demand {
                outer.receiveInner(input, index)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                outer.receiveInner(completion: completion, index)
            }
        }
    }
}
