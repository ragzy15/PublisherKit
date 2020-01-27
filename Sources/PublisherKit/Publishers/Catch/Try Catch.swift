//
//  Try Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher or optionally producing a new error.
    struct TryCatch<Upstream: PKPublisher, NewPublisher: PKPublisher>: PKPublisher where Upstream.Output == NewPublisher.Output {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public let handler: (Upstream.Failure) throws -> NewPublisher
        
        /// Creates a publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - handler: A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public init(upstream: Upstream, handler: @escaping (Upstream.Failure) throws -> NewPublisher) {
            self.upstream = upstream
            self.handler = handler
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where NewPublisher.Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = PKSubscribers.SameOutputOperatorSink<S, NewPublisher.Output, Failure>

            let newUpstreamSubscriber = Subscriber(downstream: subscriber) { (completion) in
                
                subscriber.receive(completion: completion)
            }
            
            let bridgeSubscriber = SameUpstreamOutputOperatorSink<Subscriber, NewPublisher>(downstream: newUpstreamSubscriber) { (completion) in
                
                let newCompletion = completion.mapError { $0 as Failure }
                newUpstreamSubscriber.receive(completion: newCompletion)
            }
            
            let upstreamSubscriber = SameUpstreamOutputOperatorSink<S, Upstream>(downstream: subscriber) { (completion) in
                
                guard let error = completion.getError() else {
                    subscriber.receive(completion: .finished)
                    return
                }
                
                do {
                    let newPublisher = try self.handler(error)
                    
                    subscriber.receive(subscription: newUpstreamSubscriber)
                    newUpstreamSubscriber.request(.unlimited)
                    newPublisher.subscribe(bridgeSubscriber)
                    
                } catch let catchError {
                    subscriber.receive(completion: .failure(catchError as Failure))
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.receive(subscriber: upstreamSubscriber)
        }
    }
}
