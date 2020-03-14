//
//  Optional.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Optional {
    
    public var pkPublisher: PKPublisher {
        PKPublisher(self)
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
            if let output = output {
                subscriber.receive(subscription: Inner(downstream: subscriber, output: output))
            } else {
                subscriber.receive(subscription: Subscriptions.empty)
                subscriber.receive(completion: .finished)
            }
        }
    }
}

extension Optional.PKPublisher: Equatable where Wrapped: Equatable { }

extension Optional.PKPublisher {
    
    // MARK: OPTIONAL SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.InternalBase<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let output: Output
        
        init(downstream: Downstream, output: Output) {
            self.output = output
            super.init(downstream: downstream)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            guard let downstream = downstream else { return }
            _ = downstream.receive(output)
            downstream.receive(completion: .finished)
        }
        
        override func cancel() {
            downstream = nil
        }
        
        override var description: String {
            "Optional"
        }
        
        override var customMirror: Mirror {
            Mirror(self, unlabeledChildren: [output])
        }
    }
}
