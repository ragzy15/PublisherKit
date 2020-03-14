//
//  Sequence.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

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
            
            let sequenceSubscriber = Inner(downstream: subscriber, sequence: sequence)
            
            subscriber.receive(subscription: sequenceSubscriber)
            sequenceSubscriber.request(.unlimited)
            
            sequenceSubscriber.send()
        }
    }
}

extension Publishers.Sequence {
    
    // MARK: SEQUENCE SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let sequence: Elements
        
        init(downstream: Downstream, sequence: Elements) {
            self.sequence = sequence
            super.init(downstream: downstream)
        }
        
        func send() {
            for element in sequence {
                if isTerminated { break }
                receive(input: element)
            }
            
            receive(completion: .finished)
        }
        
        override var description: String {
            "\(sequence)"
        }
    }
}
