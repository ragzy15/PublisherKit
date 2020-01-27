//
//  Map KeyPath3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes the values of three key paths as a tuple.
    public struct MapKeyPath3<Upstream: PKPublisher, Output0, Output1, Output2>: PKPublisher {
        
        public typealias Output = (Output0, Output1, Output2)
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath0: KeyPath<Upstream.Output, Output0>
        
        /// The key path of a second property to publish.
        public let keyPath1: KeyPath<Upstream.Output, Output1>
        
        /// The key path of a third property to publish.
        public let keyPath2: KeyPath<Upstream.Output, Output2>
        
        public init(upstream: Upstream, keyPath0: KeyPath<Upstream.Output, Output0>, keyPath1: KeyPath<Upstream.Output, Output1>, keyPath2: KeyPath<Upstream.Output, Output2>) {
            self.upstream = upstream
            self.keyPath0 = keyPath0
            self.keyPath1 = keyPath1
            self.keyPath2 = keyPath2
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                
                let output0 = output[keyPath: self.keyPath0]
                let output1 = output[keyPath: self.keyPath1]
                let output2 = output[keyPath: self.keyPath2]
                
                _ = subscriber.receive((output0, output1, output2))
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
