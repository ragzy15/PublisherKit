//
//  Try Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

extension Publishers {
    
    /// A publisher that republishes all non-`nil` results of calling an error-throwing closure with each received element.
    public struct TryCompactMap<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryCompactMapSubscriber = Inner(downstream: subscriber, operation: transform)
            upstream.receive(subscriber: tryCompactMapSubscriber)
        }
    }
}

extension Publishers.TryCompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) throws -> T?) -> Publishers.TryCompactMap<Upstream, T> {
        Publishers.TryCompactMap(upstream: upstream, transform: { try self.transform($0).flatMap(transform) })
    }
}

extension Publishers.TryCompactMap {
    
    // MARK: TRY COMPACTMAP SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Output) throws -> Output?> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            do {
                if let output = try operation(input) {
                    return .success(output)
                } else {
                    return nil
                }
            } catch {
                return .failure(error)
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "TryCompactMap"
        }
    }
}
