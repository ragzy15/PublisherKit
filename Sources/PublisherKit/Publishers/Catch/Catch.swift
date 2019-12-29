//
//  Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKPublishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
    struct Catch<Upstream: NKPublisher, NewPublisher: NKPublisher>: NKPublisher where Upstream.Output == NewPublisher.Output {
        
        public typealias Output = Upstream.Output

        public typealias Failure = NewPublisher.Failure

        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream

        /// A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public let handler: (Upstream.Failure) -> NewPublisher
        
        /// Creates a publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - handler: A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public init(upstream: Upstream, handler: @escaping (Upstream.Failure) -> NewPublisher) {
            self.upstream = upstream
            self.handler = handler
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where  Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamOutputOperatorSink<S, Upstream>(downstream: subscriber) { (completion) in
                
                switch completion {
                    
                case .finished:
                    subscriber.receive(completion: .finished)
                    
                case .failure(let error):
                    let newPublisher = self.handler(error)
                
                    let newUpstreamSubscriber = SameUpstreamFailureOperatorSink<S, NewPublisher>(downstream: subscriber) { (output) in
                        _ = subscriber.receive(output)
                    }
                    
                    subscriber.receive(subscription: newUpstreamSubscriber)
                    newUpstreamSubscriber.request(.unlimited)
                    newPublisher.subscribe(newUpstreamSubscriber)
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
