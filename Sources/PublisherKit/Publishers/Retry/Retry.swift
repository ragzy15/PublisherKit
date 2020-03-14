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
            
            let retrySubscriber = Inner(downstream: subscriber, demand: demand)
            subscriber.receive(subscription: retrySubscriber)
            
            retrySubscriber.retrySubscription = {
                self.upstream.subscribe(retrySubscriber)
            }
            
            upstream.subscribe(retrySubscriber)
        }
    }
}

extension Publishers.Retry: Equatable where Upstream: Equatable {
    
}

extension Publishers.Retry {
    
    // MARK: RETRY
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        var retrySubscription: (() -> Void)?
        
        let _demand: Subscribers.Demand
        
        init(downstream: Downstream, demand: Subscribers.Demand) {
            _demand = demand
            super.init(downstream: downstream)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            super.request(_demand)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Output, Failure>? {
            .success(input)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return }
            
            guard let error = completion.getError() else {
                end {
                    downstream?.receive(completion: completion)
                }
                return
            }
            
            Logger.default.log(error: error)
            
            guard demand != .none else {
                end {
                    downstream?.receive(completion: .failure(error))
                }
                return
            }
            
            demand -= 1
            status = .awaiting
            retrySubscription?()
        }
        
        override func end(completion: () -> Void) {
            super.end(completion: completion)
            retrySubscription = nil
        }
        
        override func cancel() {
            super.cancel()
            retrySubscription = nil
        }
        
        override var description: String {
            "Retry"
        }
    }
}
