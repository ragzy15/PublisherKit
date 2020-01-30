//
//  Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
    struct Catch<Upstream: PKPublisher, NewPublisher: PKPublisher>: PKPublisher where Upstream.Output == NewPublisher.Output {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = NewPublisher.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public let handler: (Upstream.Failure) -> NewPublisher
        
        /// Creates a publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - handler: A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public init(upstream: Upstream, handler: @escaping (Upstream.Failure) -> NewPublisher) {
            self.upstream = upstream
            self.handler = handler
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let catchSubscriber = InternalSink(downstream: subscriber, handler: handler)
            
            subscriber.receive(subscription: catchSubscriber)
            catchSubscriber.request(.unlimited)
            upstream.subscribe(catchSubscriber)
        }
    }
}

extension PKPublishers.Catch {
    
    // MARK: CATCH SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let handler: (Upstream.Failure) -> NewPublisher
        private lazy var subscriber = PKSubscribers.InternalSink<Downstream, Output, NewPublisher.Failure>(downstream: downstream!)
        
        init(downstream: Downstream, handler: @escaping (Upstream.Failure) -> NewPublisher) {
            self.handler = handler
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            guard let error = completion.getError() else {
                downstream?.receive(completion: .finished)
                return
            }
            
            guard let downstream = downstream else {
                return
            }
            
            let newPublisher = handler(error)
            
            downstream.receive(subscription: subscriber)
            subscriber.request(demand)
            newPublisher.subscribe(subscriber)
        }
    }
}
