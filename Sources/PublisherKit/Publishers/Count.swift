//
//  Count.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that publishes the number of elements received from the upstream publisher.
    /// It publishes the value when upstream publisher has finished.
    public struct Count<Upstream: Publisher>: Publisher {
        
        public typealias Output = Int
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber))
        }
    }
}

extension Publishers.Count: Equatable where Upstream: Equatable { }

extension Publishers.Count {
    
    // MARK: COUNT SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, Void> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        init(downstream: Downstream) {
            super.init(downstream: downstream, initial: 0, reduce: ())
        }
        
        override func receive(newValue: Input) -> PartialCompletion<Void, Failure> {
            result = (result ?? 0) + 1
            return .continue
        }
        
        override var description: String {
            "Count"
        }
    }
}
