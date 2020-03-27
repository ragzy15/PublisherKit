//
//  Prefix While.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that republishes elements while a predicate closure indicates publishing should continue.
    public struct PrefixWhile<Upstream> : Publisher where Upstream : Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that determines whether whether publishing should continue.
        public let predicate: (Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Publishers.PrefixWhile<Upstream>.Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, operation: predicate))
        }
    }
}

extension Publishers.PrefixWhile {
    
    // MARK: PREFIX WHILE SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> PartialCompletion<Output, Failure>? {
            operation(input) ? .continue(input) : .finished
        }
        
        override var description: String {
            "PrefixWhile"
        }
    }
}
