//
//  Reduce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

extension Publishers {
    
    /// A publisher that applies a closure to all received elements and produces an accumulated value when the upstream publisher finishes.
    public struct Reduce<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The initial value provided on the first invocation of the closure.
        public let initial: Output
        
        /// A closure that takes the previously-accumulated value and the next element from the upstream publisher to produce a new value.
        public let nextPartialResult: (Output, Upstream.Output) -> Output
        
        public init(upstream: Upstream, initial: Output, nextPartialResult: @escaping (Output, Upstream.Output) -> Output) {
            self.upstream = upstream
            self.initial = initial
            self.nextPartialResult = nextPartialResult
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, initial: initial, reduce: nextPartialResult))
        }
    }
}

extension Publishers.Reduce {
    
    // MARK: REDUCE SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Output, Upstream.Output) -> Output> where Downstream.Input == Output, Downstream.Failure == Failure {
        
        override func receive(newValue: Input) -> PartialCompletion<Void, Failure> {
            result = reduce(result!, newValue)
            return .continue
        }
        override var description: String {
            "Reduce"
        }
    }
}
