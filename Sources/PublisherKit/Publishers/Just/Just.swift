//
//  Just.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that emits an output to each subscriber just once, and then finishes.
    ///
    /// A `Just` publisher can be used to start a chain of publishers. A `Just` publisher is also useful when replacing a value with `Catch` publisher.
    public struct Just<Output>: Publisher {
        
        public typealias Failure = Never
        
        public let output: Output
        
        /// Initializes the publisher that publishes the specified output just once.
        ///
        /// - Parameter output: The element that the publisher publishes.
        public init(_ output: Output) {
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let justSubscriber = Inner(downstream: subscriber)
            
            subscriber.receive(subscription: justSubscriber)
            justSubscriber.request(.max(1))
            
            justSubscriber.receive(input: output)
            justSubscriber.receive(completion: .finished)
        }
    }
}

extension Publishers.Just: Equatable where Output: Equatable {
}

extension Publishers.Just {
    
    // MARK: JUST SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override var description: String {
            "Just"
        }
    }
}
