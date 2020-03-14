//
//  Try Remove Duplicates.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

extension Publishers {
    
    /// A publisher that publishes only elements that don’t match the previous element, as evaluated by a provided error-throwing closure.
    public struct TryRemoveDuplicates<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// An error-throwing closure to evaluate whether two elements are equivalent, for purposes of filtering.
        public let predicate: (Output, Output) throws -> Bool
        
        /// Creates a publisher that publishes only elements that don’t match the previous element, as evaluated by a provided error-throwing closure.
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        /// - Parameter predicate: An error-throwing closure to evaluate whether two elements are equivalent, for purposes of filtering. Return `true` from this closure to indicate that the second element is a duplicate of the first. If this closure throws an error, the publisher terminates with the thrown error.
        public init(upstream: Upstream, predicate: @escaping (Output, Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryDuplicatesSubscriber = Inner(downstream: subscriber, operation: predicate)
            subscriber.receive(subscription: tryDuplicatesSubscriber)
            upstream.subscribe(tryDuplicatesSubscriber)
        }
    }
}

extension Publishers.TryRemoveDuplicates {
    
    // MARK: TRY REMOVE DUPLICATES SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Output, Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var previousValue: Output? = nil
        
        override func operate(on input: Upstream.Output) -> Result<Output, Downstream.Failure>? {
            do {
                if let previousValue = previousValue, try operation(previousValue, input) {
                    return nil
                }
                
                previousValue = input
                return .success(input)
                
            } catch {
                return .failure(error)
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "TryRemoveDuplicates"
        }
    }
}
