//
//  Just.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// /// A publisher that emits an output to each subscriber just once, and then finishes.
    ///
    /// A `Just` publisher can be used to start a chain of publishers. A `Just` publisher is also useful when replacing a value with `Catch` publisher.
    ///
    public struct Just<Output>: PKPublisher {
        
        public typealias Failure = Never
        
        public let output: Output
        
        /// Initializes the publisher that publishes the specified output just once.
        ///
        /// - Parameter output: The element that the publisher publishes.
        public init(_ output: Output) {
            self.output = output
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let justSubscriber = InternalSink(downstream: subscriber)
            
            subscriber.receive(subscription: justSubscriber)
            
            justSubscriber.receive(input: output)
            justSubscriber.receive(completion: .finished)
        }
    }
}

extension PKPublishers.Just {
    
    // MARK: JUST SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.Sinkable<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(_ input: Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
