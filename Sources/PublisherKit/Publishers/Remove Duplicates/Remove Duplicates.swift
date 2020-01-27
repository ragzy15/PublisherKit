//
//  Remove Duplicates.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes only elements that don’t match the previous element.
    public struct RemoveDuplicates<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        /// A closure to evaluate whether two elements are equivalent, for purposes of filtering.
        public let predicate: (Output, Output) -> Bool
        
        /// Creates a publisher that publishes only elements that don’t match the previous element, as evaluated by a provided closure.
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        /// - Parameter predicate: A closure to evaluate whether two elements are equivalent, for purposes of filtering. Return `true` from this closure to indicate that the second element is a duplicate of the first.
        public init(upstream: Upstream, predicate: @escaping (Output, Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var previousValue: Output? = nil
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                
                if let previousValue = previousValue {
                    let isEqual = self.predicate(previousValue, output)
                    if isEqual {
                        return
                    }
                }
                
                previousValue = output
                _ = subscriber.receive(output)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
