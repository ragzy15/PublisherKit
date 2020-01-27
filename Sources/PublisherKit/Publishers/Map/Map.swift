//
//  Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    struct Map<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                
                let newOutput = self.transform(output)
                _ = subscriber.receive(newOutput)
                
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}

extension PKPublishers.Map {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> PKPublishers.Map<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T = { output in
            let newOutput = self.transform(output)
            return transform(newOutput)
        }
        
        return PKPublishers.Map<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> PKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = self.transform(output)
            return try transform(newOutput)
        }
        
        return PKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}
