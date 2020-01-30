//
//  All Satisfy.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes a single Boolean value that indicates whether all received elements pass a given predicate.
    public struct AllSatisfy<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Bool
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        /// A closure that evaluates each received element.
        ///
        ///  Return `true` to continue, or `false` to cancel the upstream and finish.
        public let predicate: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let allSatisfySubscriber = InternalSink(downstream: subscriber, predicate: predicate)
            
            subscriber.receive(subscription: allSatisfySubscriber)
            allSatisfySubscriber.request(.unlimited)
            upstream.subscribe(allSatisfySubscriber)
        }
    }
}

extension PKPublishers.AllSatisfy {
    
    // MARK: ALL SATISFY SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let predicate: (Upstream.Output) -> Bool
        
        init(downstream: Downstream, predicate: @escaping (Upstream.Output) -> Bool) {
            self.predicate = predicate
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            let output = self.predicate(input)
            downstream?.receive(input: output)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
