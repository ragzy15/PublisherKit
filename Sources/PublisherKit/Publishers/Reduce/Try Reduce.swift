//
//  Try Reduce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

import Foundation

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
            let tryReduceSubscriber = InternalSink(downstream: subscriber, initial: initial, nextPartialResult: nextPartialResult)
            upstream.subscribe(tryReduceSubscriber)
        }
    }
}

extension Publishers.TryReduce {
    
    // MARK: TRY REDUCE SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let nextPartialResult: (Output, Upstream.Output) throws -> Output
        private var output: Output
        
        init(downstream: Downstream, initial: Output, nextPartialResult: @escaping (Output, Upstream.Output) throws -> Output) {
            self.output = initial
            self.nextPartialResult = nextPartialResult
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isOver else { return .none }
            
            do {
                output = try nextPartialResult(output, input)
                _ = downstream?.receive(output)
            } catch {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isOver else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
