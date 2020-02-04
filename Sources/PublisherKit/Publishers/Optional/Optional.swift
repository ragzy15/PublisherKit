//
//  Optional.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Optional {
    
    public var pkPublisher: Optional<Wrapped>.PKPublisher {
        .init(self)
    }
}

extension Optional {
    
    /// A publisher that publishes an optional value to each subscriber exactly once, if the optional has a value.
    ///
    /// In contrast with `Just`, an `Optional` publisher may send no value before completion.
    public struct PKPublisher: PublisherKit.Publisher {
        
        public typealias Output = Wrapped
        
        public typealias Failure = Never
        
        /// The result to deliver to each subscriber.
        public let output: Wrapped?
        
        /// Creates a publisher to emit the optional value of a successful result, or fail with an error.
        ///
        /// - Parameter result: The result to deliver to each subscriber.
        public init(_ output: Output?) {
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let optionalSubscriber = InternalSink(downstream: subscriber)
            
            optionalSubscriber.request(.max(1))
            
            if let output = output {
                optionalSubscriber.receive(input: output)
            }
        }
    }
}

extension Optional.PKPublisher {
    
    // MARK: OPTIONAL SINK
    private final class InternalSink<Downstream: Subscriber>: Subscribers.OperatorSink<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        func receive(input: Output) {
            guard !isCancelled else { return }
            _ = downstream?.receive(input)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
        }
    }
}
