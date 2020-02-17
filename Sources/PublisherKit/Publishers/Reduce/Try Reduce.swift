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
            let tryReduceSubscriber = Inner(downstream: subscriber, initial: initial, nextPartialResult: nextPartialResult)
            upstream.subscribe(tryReduceSubscriber)
        }
    }
}

extension Publishers.TryReduce {
    
    // MARK: TRY REDUCE SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Output, Upstream.Output) throws -> Output> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var output: Output
        
        init(downstream: Downstream, initial: Output, nextPartialResult: @escaping (Output, Upstream.Output) throws -> Output) {
            self.output = initial
            super.init(downstream: downstream, operation: nextPartialResult)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            Result {
                output = try operation(output, input)
                return output
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "TryReduce"
        }
    }
}
