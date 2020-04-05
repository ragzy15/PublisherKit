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
            upstream.subscribe(Inner(downstream: subscriber, filter: predicate))
        }
    }
    
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
            upstream.subscribe(Inner(downstream: subscriber, filter: predicate))
        }
    }
}

extension Publishers.RemoveDuplicates {
    
    // MARK: REMOVE DUPLICATES SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Output, Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var previousInput: Output?
        
        override func receive(newValue: Input) -> PartialCompletion<Output?, Failure> {
            let previousInput = self.previousInput
            self.previousInput = newValue
            
            if let previousInput = previousInput, filter(previousInput, newValue) {
                return .continue(nil)
            }
            
            return .continue(newValue)
        }
        
        override var description: String {
            "RemoveDuplicates"
        }
    }
}

extension Publishers.TryRemoveDuplicates {
    
    // MARK: TRY REMOVE DUPLICATES SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Output, Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var previousInput: Output? = nil
        
        override func receive(newValue: Input) -> PartialCompletion<Output?, Downstream.Failure> {
            let previousInput = self.previousInput
            self.previousInput = newValue
            
            if let previousInput = previousInput {
                do {
                    return try filter(previousInput, newValue) ? .continue(nil) : .continue(newValue)
                } catch {
                    return .failure(error)
                }
            } else {
                return .continue(newValue)
            }
        }
        
        override var description: String {
            "TryRemoveDuplicates"
        }
    }
}
