//
//  Try Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKPublishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher or optionally producing a new error.
    struct TryCatch<Upstream: NKPublisher, NewPublisher: NKPublisher>: NKPublisher where Upstream.Output == NewPublisher.Output {
        
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
        
        public func receive<S: NKSubscriber>(subscriber: S) where NewPublisher.Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = NKSubscribers.OperatorSink<S, NewPublisher.Output, Failure>
            
            let upstreamSubscriber = SameUpstreamOutputOperatorSink<S, Upstream>(downstream: subscriber) { (completion) in
                
                switch completion {
                    
                case .finished:
                    subscriber.receive(completion: .finished)
                    
                case .failure(let error):
                    
                    do {
                        let newPublisher = try self.handler(error)
                        
                        let newUpstreamSubscriber = Subscriber(downstream: subscriber, receiveCompletion: { (completion) in
                            subscriber.receive(completion: completion)
                        }) { (output) in
                            _ = subscriber.receive(output)
                        }
                        
                        let bridgeSubscriber = NKSubscribers.OperatorSink<Subscriber, NewPublisher.Output, NewPublisher.Failure>(downstream: newUpstreamSubscriber, receiveCompletion: { (completion) in
                            
                            let newCompletion = completion.mapError { $0 as Failure }
                            newUpstreamSubscriber.receive(completion: newCompletion)
                            
                        }) { (output) in
                            _ = newUpstreamSubscriber.receive(output)
                        }
                        
                        subscriber.receive(subscription: newUpstreamSubscriber)
                        newUpstreamSubscriber.request(.unlimited)
                        newPublisher.subscribe(bridgeSubscriber)
                        
                    } catch let error {
                        subscriber.receive(completion: .failure(error as Failure))
                    }
                }
                
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.receive(subscriber: upstreamSubscriber)
            
        }
    }
}
