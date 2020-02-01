//
//  Try Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that republishes all elements that match a provided error-throwing closure.
    public struct TryFilter<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        public let upstream: Upstream
        
        /// A error-throwing closure that indicates whether to republish an element.
        public let isIncluded: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, isIncluded: @escaping (Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.isIncluded = isIncluded
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryFilterSubscriber = InternalSink(downstream: subscriber, isIncluded: isIncluded)
            upstream.receive(subscriber: tryFilterSubscriber)
        }
    }
}

extension PKPublishers.TryFilter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> PKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if try self.isIncluded(output) {
                return isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> PKPublishers.TryFilter<Upstream> {
        
        let newIsIncluded: (Upstream.Output) throws -> Bool = { output in
            if try self.isIncluded(output) {
                return try isIncluded(output)
            } else {
                return false
            }
        }
        
        return PKPublishers.TryFilter(upstream: upstream, isIncluded: newIsIncluded)
    }
}

extension PKPublishers.TryFilter {
    
    // MARK: TRY FILTER SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let isIncluded: (Upstream.Output) throws -> Bool
        
        init(downstream: Downstream, isIncluded: @escaping (Upstream.Output) throws -> Bool) {
            self.isIncluded = isIncluded
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            do {
                if try isIncluded(input) {
                    _ = downstream?.receive(input)
                }
            } catch {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
