//
//  Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

import Foundation

public extension Publishers {
    
    /// A publisher that republishes all non-`nil` results of calling a closure with each received element.
    struct CompactMap<Upstream: Publisher, Output>: Publisher {
        
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
        
        let newTransform: (Upstream.Output) -> T? = { output in
            if let newOutput = self.transform(output) {
                return transform(newOutput)
            } else {
                return nil
            }
        }
        
        return Publishers.CompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> Publishers.CompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T? = { output in
            if let newOutput = self.transform(output) {
                return transform(newOutput)
            } else {
                return nil
            }
        }
        
        return Publishers.CompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}

extension Publishers.CompactMap {
    
    // MARK: COMPACTMAP SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Output) -> Output?> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            let output = operation(input)
            if let value = output {
                return .success(value)
            } else {
                return nil
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
    }
}
