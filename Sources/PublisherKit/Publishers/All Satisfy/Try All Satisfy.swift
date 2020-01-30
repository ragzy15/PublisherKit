//
//  Try All Satisfy.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes a single Boolean value that indicates whether all received elements pass a given error-throwing predicate.
    public struct TryAllSatisfy<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Bool
        
        public typealias Failure = Error
        
        public let upstream: Upstream
        
        /// A closure that evaluates each received element.
        ///
        /// Return `true` to continue, or `false` to cancel the upstream and complete. The closure may throw, in which case the publisher cancels the upstream publisher and fails with the thrown error.
        public let predicate: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryAllSatisfySubscriber = InternalSink(downstream: subscriber, predicate: predicate)
            
            subscriber.receive(subscription: tryAllSatisfySubscriber)
            tryAllSatisfySubscriber.request(.unlimited)
            upstream.receive(subscriber: tryAllSatisfySubscriber)
        }
    }
}

extension PKPublishers.TryAllSatisfy {
    
    // MARK: TRY ALLSATISFY SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let predicate: (Upstream.Output) throws -> Bool
        
        init(downstream: Downstream, predicate: @escaping (Upstream.Output) throws -> Bool) {
            self.predicate = predicate
            super.init(downstream: downstream)
        }
        
        override func receive(input: Upstream.Output) {
            guard receive(input) != .none else { return }
            
            do {
                let output = try self.predicate(input)
                downstream?.receive(input: output)
            } catch {
                downstream?.receive(completion: .failure(error))
            }
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
