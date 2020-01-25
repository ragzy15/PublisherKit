//
//  Retry.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
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
            
            if let time = retries {
                demand = .max(time)
            } else {
                demand = .unlimited
            }
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var retryDemand = demand
            
            var upstreamSubscriber: SameUpstreamOutputOperatorSink<S, Upstream>!
            
            upstreamSubscriber = .init(downstream: subscriber) { (completion) in
                switch completion {
                case .finished:
                    subscriber.receive(completion: .finished)
                    
                case .failure(let error):
                    Logger.default.log(error: error)
                    
                    if retryDemand == .none {
                        subscriber.receive(completion: .failure(error))
                    } else {
                        if retryDemand != .unlimited {
                            retryDemand -= 1
                        }
                        self.upstream.subscribe(upstreamSubscriber)
                    }
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
