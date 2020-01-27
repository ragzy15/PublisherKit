//
//  Try Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that republishes all non-`nil` results of calling an error-throwing closure with each received element.
    struct TryCompactMap<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = PKSubscribers.SameFailureOperatorSink<S, Upstream.Output, Failure>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber) { (output) in
                
                do {
                    if let newOutput = try self.transform(output) {
                        _ = subscriber.receive(newOutput)
                    }
                } catch {
                    subscriber.receive(completion: .failure(error))
                }
            }
            
            let bridgeSubscriber = SameUpstreamOutputOperatorSink<Subscriber, Upstream>(downstream: upstreamSubscriber) { (completion) in
                
                let newCompletion = completion.mapError { $0 as Failure }
                upstreamSubscriber.receive(completion: newCompletion)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            bridgeSubscriber.request(.unlimited)
            upstream.receive(subscriber: bridgeSubscriber)
        }
    }
}

extension PKPublishers.TryCompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) throws -> T?) -> PKPublishers.TryCompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T? = { output in
            if let newOutput = try self.transform(output) {
                return try transform(newOutput)
            } else {
                return nil
            }
        }
        
        return PKPublishers.TryCompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}
