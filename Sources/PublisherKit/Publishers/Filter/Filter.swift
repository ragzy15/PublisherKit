//
//  Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that republishes all elements that match a provided closure.
    public struct Filter<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that indicates whether to republish an element.
        public let isIncluded: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, isIncluded: @escaping (Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.isIncluded = isIncluded
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let filterSubscriber = InternalSink(downstream: subscriber, isIncluded: isIncluded)
            upstream.subscribe(filterSubscriber)
        }
    }
}

extension PKPublishers.Filter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> PKPublishers.Filter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) -> Bool = { output in
            if self.isIncluded(output) {
                return isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.Filter(upstream: upstream, isIncluded: newIsIncluded)
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> PKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if self.isIncluded(output) {
                return try isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
}

extension PKPublishers.Filter {

    // MARK: FILTER SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamInternalSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let isIncluded: (Upstream.Output) -> Bool
        
        init(downstream: Downstream, isIncluded: @escaping (Upstream.Output) -> Bool) {
            self.isIncluded = isIncluded
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            if isIncluded(input) {
                _ = downstream?.receive(input)
            }
            
            return demand
        }
    }
}
