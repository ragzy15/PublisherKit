//
//  Remove Duplicates.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

extension Publishers {
    
    /// A publisher that publishes only elements that don’t match the previous element.
    public struct RemoveDuplicates<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure to evaluate whether two elements are equivalent, for purposes of filtering.
        public let predicate: (Output, Output) -> Bool
        
        /// Creates a publisher that publishes only elements that don’t match the previous element, as evaluated by a provided closure.
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        /// - Parameter predicate: A closure to evaluate whether two elements are equivalent, for purposes of filtering. Return `true` from this closure to indicate that the second element is a duplicate of the first.
        public init(upstream: Upstream, predicate: @escaping (Output, Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let duplicatesSubscriber = Inner(downstream: subscriber, operation: predicate)
            subscriber.receive(subscription: duplicatesSubscriber)
            upstream.subscribe(duplicatesSubscriber)
        }
    }
}

extension Publishers.RemoveDuplicates {
    
    // MARK: REMOVE DUPLICATES SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Output, Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var previousValue: Output?
        
        override func operate(on input: Upstream.Output) -> Result<Output, Failure>? {
            if let previousValue = previousValue, operation(previousValue, input) {
                return nil
            }
            
            previousValue = input
            return .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "RemoveDuplicates"
        }
    }
}
