//
//  Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKPublishers {
    
    struct Map<Upstream: NKPublisher, Output>: NKPublisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
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

extension NKPublishers.Map {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> NKPublishers.Map<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T = { output in
            let newOutput = self.transform(output)
            return transform(newOutput)
        }
        
        return NKPublishers.Map<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> NKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = self.transform(output)
            return try transform(newOutput)
        }
        
        return NKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}
