//
//  Just.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    public struct Just<Output>: NKPublisher {

        public typealias Failure = Never

        /// The one element that the publisher emits.
        public let output: Output

        /// Initializes a publisher that emits the specified output just once.
        ///
        /// - Parameter output: The one element that the publisher emits.
        public init(_ output: Output) {
            self.output = output
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let justSubscriber = NKSubscribers.TopLevelSink<S, Self>(downstream: subscriber)
            
            subscriber.receive(subscription: justSubscriber)
            
            justSubscriber.receive(input: output)
            justSubscriber.receive(completion: .finished)
        }
    }
}
