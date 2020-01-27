//
//  Map KeyPath.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that publishes the value of a key path.
    struct MapKeyPath<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath: KeyPath<Upstream.Output, Output>
        
        public init(upstream: Upstream, keyPath: KeyPath<Upstream.Output, Output>) {
            self.upstream = upstream
            self.keyPath = keyPath
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                
                let newOutput = output[keyPath: self.keyPath]
                _ = subscriber.receive(newOutput)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
