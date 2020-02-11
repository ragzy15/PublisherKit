//
//  Reduce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

import Foundation

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
            let reduceSubscriber = Inner(downstream: subscriber, initial: initial, nextPartialResult: nextPartialResult)
            upstream.subscribe(reduceSubscriber)
        }
    }
}

extension Publishers.Reduce {
    
    // MARK: REDUCE SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Output, Upstream.Output) -> Output> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var output: Output
        
        init(downstream: Downstream, initial: Output, nextPartialResult: @escaping (Output, Upstream.Output) -> Output) {
            self.output = initial
            super.init(downstream: downstream, operation: nextPartialResult)
        }
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            output = operation(output, input)
            return .success(output)
        }
        
       override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Reduce"
        }
    }
}
