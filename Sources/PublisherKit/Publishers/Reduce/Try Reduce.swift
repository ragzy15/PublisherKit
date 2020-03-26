//
//  Try Reduce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

extension Publishers {
    
    /// A publisher that applies an error-throwing closure to all received elements and produces an accumulated value when the upstream publisher finishes.
    public struct TryReduce<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The initial value provided on the first invocation of the closure.
        public let initial: Output
        
        /// An error-throwing closure that takes the previously-accumulated value and the next element from the upstream to produce a new value.
        ///
        /// If this closure throws an error, the publisher fails and passes the error to its subscriber.
        public let nextPartialResult: (Output, Upstream.Output) throws -> Output
        
        public init(upstream: Upstream, initial: Output, nextPartialResult: @escaping (Output, Upstream.Output) throws -> Output) {
            self.upstream = upstream
            self.initial = initial
            self.nextPartialResult = nextPartialResult
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, initial: initial, operation: nextPartialResult))
        }
    }
}

extension Publishers.TryReduce {
    
    // MARK: TRY REDUCE SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Output, Upstream.Output) throws -> Output> where Downstream.Input == Output, Downstream.Failure == Failure {
        
        override func receive(input: Input) -> CompletionResult<Void, Downstream.Failure> {
            do {
                output = try operation(output!, input)
                return .send
            } catch {
                return .failure(error)
            }
        }
        
        override var description: String {
            "TryReduce"
        }
    }
}
