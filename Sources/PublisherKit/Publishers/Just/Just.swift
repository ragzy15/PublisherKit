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

        /// The one element that the publisher emits.
        public let output: Output

        /// Initializes a publisher that emits the specified output just once.
        ///
        /// - Parameter output: The one element that the publisher emits.
        public init(_ output: Output) {
            self.output = output
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let justSubscriber = SameUpstreamOperatorSink<S, Self>(downstream: subscriber)
            
            subscriber.receive(subscription: justSubscriber)
            
            justSubscriber.receive(input: output)
            justSubscriber.receive(completion: .finished)
        }
    }
}
