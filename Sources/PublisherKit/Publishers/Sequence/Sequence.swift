//
//  Sequence.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension Sequence {
    
    public var nkPublisher: NKPublishers.Sequence<Self, Never> {
        NKPublishers.Sequence(sequence: self)
    }
}

extension NKPublishers {

    /// A publisher that publishes a given sequence of elements.
    ///
    /// When the publisher exhausts the elements in the sequence, the next request causes the publisher to finish.
    public struct Sequence<Elements: Swift.Sequence, Failure: Error>: NKPublisher {

        public typealias Output = Elements.Element

        /// The sequence of elements to publish.
        public let sequence: Elements

        /// Creates a publisher for a sequence of elements.
        ///
        /// - Parameter sequence: The sequence of elements to publish.
        public init(sequence: Elements) {
            self.sequence = sequence
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let sequenceSubscriber = NKSubscribers.TopLevelSink<S, Self>(downstream: subscriber)
            
            subscriber.receive(subscription: sequenceSubscriber)
            
            for element in sequence {
                if sequenceSubscriber.isCancelled { return }
                sequenceSubscriber.receive(input: element)
            }
            
            subscriber.receive(completion: .finished)
        }
    }
}
