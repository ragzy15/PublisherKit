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
        
        /// The publisher from which this publisher receives elements.
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
            
            let duplicatesSubscriber = InternalSink(downstream: subscriber, predicate: predicate)
            upstream.subscribe(duplicatesSubscriber)
        }
    }
}

extension PKPublishers.RemoveDuplicates {
    
    // MARK: REMOVE DUPLICATES SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let predicate: (Output, Output) -> Bool
        private var previousValue: Output?
        
        init(downstream: Downstream, predicate: @escaping (Output, Output) -> Bool) {
            self.predicate = predicate
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            if let previousValue = previousValue, predicate(previousValue, input) {
                return demand
            }
            
            previousValue = input
            _ = downstream?.receive(input)
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
