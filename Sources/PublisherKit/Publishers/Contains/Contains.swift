//
//  Contains.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

extension Publishers {
    
    /// A publisher that emits a Boolean value when a specified element is received from its upstream publisher.
    public struct Contains<Upstream: Publisher>: Publisher where Upstream.Output: Equatable {
        
        public typealias Output = Bool
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The element to scan for in the upstream publisher.
        public let output: Upstream.Output
        
        public init(upstream: Upstream, output: Upstream.Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, output: output))
        }
    }
}

extension Publishers.Contains: Equatable where Upstream: Equatable { }

extension Publishers.Contains {
    
    // MARK: CONTAINS SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, Void> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let outputValue: Input
        
        init(downstream: Downstream, output: Input) {
            self.outputValue = output
            super.init(downstream: downstream, initial: false, reduce: ())
        }
        
        override func receive(newValue: Input) -> PartialCompletion<Void, Failure> {
            result = newValue == outputValue
            return result == true ? .finished : .continue
        }
        
        override var description: String {
            "Contains"
        }
    }
}
