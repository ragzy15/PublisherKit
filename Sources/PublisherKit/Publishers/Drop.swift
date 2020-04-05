//
//  Drop.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {

    /// A publisher that omits a specified number of elements before republishing later elements.
    public struct Drop<Upstream: Publisher>: Publisher {

        public typealias Output = Upstream.Output

        public typealias Failure = Upstream.Failure

        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream

        /// The number of elements to drop.
        public let count: Int

        public init(upstream: Upstream, count: Int) {
            self.upstream = upstream
            self.count = count
        }

        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber, count: count)
            upstream.subscribe(inner)
            subscriber.receive(subscription: inner)
        }
    }
}

extension Publishers.Drop: Equatable where Upstream: Equatable { }

extension Publishers.Drop {

    // MARK: DROP SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {

        typealias Input = Upstream.Output

        typealias Failure = Upstream.Failure

        private var count: Int

        private var downstream: Downstream?

        private let lock = Lock()

        private var subscription: Subscription?
        
        private var pendingDemand: Subscribers.Demand = .none

        init(downstream: Downstream, count: Int) {
            self.count = count
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard self.subscription == nil else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            precondition(count >= 0, "count must not be negative.")
            
            self.subscription = subscription
            
            let demand = pendingDemand + count
            lock.unlock()
            
            if demand > .none {
                subscription.request(demand)
            }
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            guard subscription != nil else { return .none }
            
            if count > 0 {
                count -= 1
                return .none
            }
            
            return downstream?.receive(input) ?? .none
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            guard subscription != nil else { return }
            downstream?.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must not be negative.")
            lock.lock()
            guard let subscription = subscription else {
                pendingDemand += demand
                lock.unlock()
                return
            }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            subscription?.cancel()
            subscription = nil
            downstream = nil
        }

        var description: String {
            "Drop"
        }

        var playgroundDescription: Any {
            description
        }

        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
