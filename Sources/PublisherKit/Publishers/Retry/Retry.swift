//
//  Retry.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that attempts to recreate its subscription to a failed upstream publisher.
    public struct Retry<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The maximum number of retry attempts to perform.
        ///
        /// If `nil`, this publisher attempts to reconnect with the upstream publisher an unlimited number of times.
        public let retries: Int?
        
        private let demand: PKSubscribers.Demand
        
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let retrySubscriber = InternalSink(downstream: subscriber)
            
            retrySubscriber.retrySubscription = {
                self.upstream.subscribe(retrySubscriber)
            }
            
            subscriber.receive(subscription: retrySubscriber)
            retrySubscriber.request(demand)
            upstream.subscribe(retrySubscriber)
        }
    }
}

extension PKPublishers.Retry {
    
    // MARK: RETRY
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamInternalSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        var retrySubscription: (() -> Void)?
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            guard let error = completion.getError() else {
                downstream?.receive(completion: .finished)
                return
            }
            
            Logger.default.log(error: error)
            
            guard demand != .none else {
                end()
                downstream?.receive(completion: .failure(error))
                return
            }
            
            updateDemand()
            retrySubscription?()
        }
    }
}
