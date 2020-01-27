//
//  Try Remove Duplicates.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes only elements that don’t match the previous element, as evaluated by a provided error-throwing closure.
    public struct TryRemoveDuplicates<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        public let upstream: Upstream
        
        /// An error-throwing closure to evaluate whether two elements are equivalent, for purposes of filtering.
        public let predicate: (Output, Output) throws -> Bool
        
        /// Creates a publisher that publishes only elements that don’t match the previous element, as evaluated by a provided error-throwing closure.
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        /// - Parameter predicate: An error-throwing closure to evaluate whether two elements are equivalent, for purposes of filtering. Return `true` from this closure to indicate that the second element is a duplicate of the first. If this closure throws an error, the publisher terminates with the thrown error.
        public init(upstream: Upstream, predicate: @escaping (Output, Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = SameUpstreamFailureOperatorSink<S, Self>
            
            var previousValue: Output? = nil
            
            let upstreamSubscriber = Subscriber(downstream: subscriber) { (output) in
                
                do {
                    if let previousValue = previousValue, try self.predicate(previousValue, output) {
                        return
                    }
                    
                    previousValue = output
                    _ = subscriber.receive(output)
                    
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
