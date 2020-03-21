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
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let output: Output
        private var downstream: Downstream?
        
        init(downstream: Downstream, output: Output) {
            self.downstream = downstream
            self.output = output
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "Demand must not be zero.")
            
            guard let downstream = downstream else { return }
            self.downstream = nil
            
            _ = downstream.receive(output)
            downstream.receive(completion: .finished)
        }
        
        func cancel() {
            downstream = nil
        }
        
        var description: String {
            "Optional"
        }
        
        var customMirror: Mirror {
            Mirror(self, unlabeledChildren: [output])
        }
    }
}
