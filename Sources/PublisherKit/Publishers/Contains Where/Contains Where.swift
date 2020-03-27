//
//  Contains Where.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 27/03/20.
//

extension Publishers {
    
    /// A publisher that emits a Boolean value upon receiving an element that satisfies the predicate closure.
    public struct ContainsWhere<Upstream: Publisher>: Publisher {
        
        public typealias Output = Bool
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that determines whether the publisher should consider an element as a match.
        public let predicate: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, operation: predicate))
        }
    }
    
    /// A publisher that emits a Boolean value upon receiving an element that satisfies the throwing predicate closure.
    public struct TryContainsWhere<Upstream: Publisher>: Publisher {
        
        public typealias Output = Bool
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The error-throwing closure that determines whether this publisher should emit a `true` element.
        public let predicate: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, operation: predicate))
        }
    }
}

extension Publishers.ContainsWhere {
    
    // MARK: CONTAINS WHERE SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> CompletionResult<Void, Downstream.Failure> {
            output = operation(input)
            return output == true ? .send : .finished
        }
        
        override var description: String {
            "ContainsWhere"
        }
    }
}

extension Publishers.TryContainsWhere {
    
    // MARK: TRY CONTAINS WHERE SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> CompletionResult<Void, Downstream.Failure> {
            do {
                output = try operation(input)
                return output == true ? .send : .finished
            } catch {
                return .failure(error)
            }
        }
        
        override var description: String {
            "TryContainsWhere"
        }
    }
}
