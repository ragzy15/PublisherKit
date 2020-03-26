//
//  Retry.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that attempts to recreate its subscription to a failed upstream publisher.
    public struct Retry<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The maximum number of retry attempts to perform.
        ///
        /// If `nil`, this publisher attempts to reconnect with the upstream publisher an unlimited number of times.
        public let retries: Int?
        
        private let demand: Subscribers.Demand
        
        /// Creates a publisher that attempts to recreate its subscription to a failed upstream publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher from which this publisher receives its elements.
        ///   - retries: The maximum number of retry attempts to perform. If `nil`, this publisher attempts to reconnect with the upstream publisher an unlimited number of times.
        public init(upstream: Upstream, retries: Int?) {
            self.upstream = upstream
            self.retries = retries
            
            if let retries = retries {
                demand = .max(retries < 0 ? 0 : retries)
            } else {
                demand = .unlimited
            }
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber, upstream: upstream, retries: demand)
            inner.upstream.subscribe(inner)
            subscriber.receive(subscription: inner)
        }
    }
}

extension Publishers.Retry: Equatable where Upstream: Equatable { }

extension Publishers.Retry {
    
    // MARK: RETRY
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private let lock = Lock()
        private var retries: Subscribers.Demand
        private var isRetrying = false
        
        fileprivate let upstream: Upstream
        private var downstreamDemand: Subscribers.Demand = .none
        
        init(downstream: Downstream, upstream: Upstream, retries: Subscribers.Demand) {
            self.downstream = downstream
            self.upstream = upstream
            self.retries = retries
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            
            if isRetrying {
                lock.unlock()
                subscription.request(downstreamDemand)
            } else {
                lock.unlock()
            }
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            downstreamDemand -= 1
            lock.unlock()
            
            let demand = downstream?.receive(input) ?? .none
            
            lock.lock()
            downstreamDemand += demand
            lock.unlock()
            
            return downstreamDemand
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            
            switch completion {
            case .finished:
                lock.unlock()
                downstream?.receive(completion: .finished)
                
            case .failure(let error):
                if retries == .unlimited {
                    status = .awaiting
                    isRetrying = true
                    lock.unlock()
                    upstream.subscribe(self)
                } else if retries > .none {
                    retries -= 1
                    status = .awaiting
                    isRetrying = true
                    lock.unlock()
                    upstream.subscribe(self)
                } else {
                    isRetrying = false
                    lock.unlock()
                    downstream?.receive(completion: .failure(error))
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            downstreamDemand += demand
            lock.unlock()
            
            subscription.request(downstreamDemand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "ReplaceError"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
