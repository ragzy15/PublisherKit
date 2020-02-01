//
//  Just.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    public struct Just<Output>: PKPublisher {
        
        public typealias Failure = Never
        
        public let output: Output
        
        /// Initializes a publisher that emits the specified output just once.
        ///
        /// - Parameter output: The one element that the publisher emits.
        public init(_ output: Output) {
            self.output = output
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let justSubscriber = InternalSink(downstream: subscriber)
            subscriber.receive(subscription: justSubscriber)
            justSubscriber.request(.max(1))
            
            justSubscriber.receive(input: output)
        }
    }
}

extension PKPublishers.Just {
    
    // MARK: JUST SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.OperatorSink<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        func receive(input: Output) {
            _ = downstream?.receive(input)
            end()
            downstream?.receive(completion: .finished)
        }
    }
}
