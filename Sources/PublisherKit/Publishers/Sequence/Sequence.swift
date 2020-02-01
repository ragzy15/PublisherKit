//
//  Sequence.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Sequence {
    
    public var pkPublisher: PKPublishers.Sequence<Self, Never> {
        PKPublishers.Sequence(sequence: self)
    }
}

extension PKPublishers {
    
    /// A publisher that publishes a given sequence of elements.
    ///
    /// When the publisher exhausts the elements in the sequence, the next request causes the publisher to finish.
    public struct Sequence<Elements: Swift.Sequence, Failure: Error>: PKPublisher {
        
        public typealias Output = Elements.Element
        
        /// The sequence of elements to publish.
        public let sequence: Elements
        
        /// Creates a publisher for a sequence of elements.
        ///
        /// - Parameter sequence: The sequence of elements to publish.
        public init(sequence: Elements) {
            self.sequence = sequence
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let sequenceSubscriber = InternalSink(downstream: subscriber)
            
            subscriber.receive(subscription: sequenceSubscriber)
            
            for element in sequence {
                if sequenceSubscriber.isCancelled { break }
                sequenceSubscriber.receive(input: element)
            }
            
            sequenceSubscriber.receive(completion: .finished)
        }
    }
}

extension PKPublishers.Sequence {

    // MARK: SEQUENCE SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.InternalSink<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        func receive(input: Input) {
            guard !isCancelled else { return }
            _ = downstream?.receive(input)
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
        }
    }
}
