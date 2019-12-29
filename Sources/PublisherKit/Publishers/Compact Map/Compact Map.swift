//
//  Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKPublishers {
    
    /// A publisher that republishes all non-`nil` results of calling a closure with each received element.
    struct CompactMap<Upstream: NKPublisher, Output>: NKPublisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                
                let newOutput = self.transform(output)
                
                if let value = newOutput {
                    _ = subscriber.receive(value)
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}

extension NKPublishers.CompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) -> T?) -> NKPublishers.CompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T? = { output in
            if let newOutput = self.transform(output) {
                return transform(newOutput)
            } else {
                return nil
            }
        }
        
        return NKPublishers.CompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> NKPublishers.CompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T? = { output in
            if let newOutput = self.transform(output) {
                return transform(newOutput)
            } else {
                return nil
            }
        }
        
        return NKPublishers.CompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}
