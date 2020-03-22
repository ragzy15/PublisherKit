//
//  Just.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that emits an output to each subscriber just once, and then finishes.
    ///
    /// A `Just` publisher can be used to start a chain of publishers. A `Just` publisher is also useful when replacing a value with `Catch` publisher.
    public struct Just<Output>: Publisher {
        
        public typealias Failure = Never
        
        public let output: Output
        
        /// Initializes the publisher that publishes the specified output just once.
        ///
        /// - Parameter output: The element that the publisher publishes.
        public init(_ output: Output) {
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            subscriber.receive(subscription: Inner(downstream: subscriber, output: output))
        }
    }
}

extension Publishers.Just: Equatable where Output: Equatable { }

extension Publishers.Just {
    
    // MARK: JUST SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
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
            "Just"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, unlabeledChildren: [output])
        }
    }
}
