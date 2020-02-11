//
//  Sequence.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Sequence {
    
    public var pkPublisher: Publishers.Sequence<Self, Never> {
        Publishers.Sequence(sequence: self)
    }
}

extension Publishers {
    
    /// A publisher that publishes a given sequence of elements.
    ///
    /// When the publisher exhausts the elements in the sequence, the next request causes the publisher to finish.
    public struct Sequence<Elements: Swift.Sequence, Failure: Error>: Publisher {
        
        public typealias Output = Elements.Element
        
        /// The sequence of elements to publish.
        public let sequence: Elements
        
        /// Creates a publisher for a sequence of elements.
        ///
        /// - Parameter sequence: The sequence of elements to publish.
        public init(sequence: Elements) {
            self.sequence = sequence
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let sequenceSubscriber = Inner(downstream: subscriber)
            
            subscriber.receive(subscription: sequenceSubscriber)
            sequenceSubscriber.request(.unlimited)
            
            for element in sequence {
                if !sequenceSubscriber.isTerminated { break }
                sequenceSubscriber.receive(input: element)
            }
            
            sequenceSubscriber.receive(completion: .finished)
        }
    }
}

extension Publishers.Sequence {

    // MARK: SEQUENCE SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Output) {
            guard !isTerminated else { return }
            _ = downstream?.receive(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Sequence"
        }
    }
}
