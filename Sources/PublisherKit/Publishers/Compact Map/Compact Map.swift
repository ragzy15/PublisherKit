//
//  Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

extension Publishers {
    
    /// A publisher that republishes all non-`nil` results of calling a closure with each received element.
    public  struct CompactMap<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let compactMapSubscriber = Inner(downstream: subscriber, operation: transform)
            upstream.subscribe(compactMapSubscriber)
        }
    }
}

extension Publishers.CompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) -> T?) -> Publishers.CompactMap<Upstream, T> {
        Publishers.CompactMap(upstream: upstream, transform: { self.transform($0).flatMap(transform) })
    }
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> Publishers.CompactMap<Upstream, T> {
        Publishers.CompactMap(upstream: upstream, transform: { self.transform($0).map(transform) })
    }
}

extension Publishers.CompactMap {
    
    // MARK: COMPACTMAP SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) -> Output?> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> CompletionResult<Output, Failure>? {
            if let value = operation(input) {
                return .send(value)
            } else {
                return nil
            }
        }
        
        override var description: String {
            "CompactMap"
        }
    }
}
