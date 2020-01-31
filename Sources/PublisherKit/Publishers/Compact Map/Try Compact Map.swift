//
//  Try Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that republishes all non-`nil` results of calling an error-throwing closure with each received element.
    struct TryCompactMap<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryCompactMapSubscriber = InternalSink(downstream: subscriber, transform: transform)
            
            subscriber.receive(subscription: tryCompactMapSubscriber)
            tryCompactMapSubscriber.request(.unlimited)
            upstream.receive(subscriber: tryCompactMapSubscriber)
        }
    }
}

extension PKPublishers.TryCompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) throws -> T?) -> PKPublishers.TryCompactMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T? = { output in
            if let newOutput = try self.transform(output) {
                return try transform(newOutput)
            } else {
                return nil
            }
        }
        
        return PKPublishers.TryCompactMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}

extension PKPublishers.TryCompactMap {
    
    // MARK: TRY COMPACTMAP SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Output) throws -> Output?
        
        init(downstream: Downstream, transform: @escaping (Upstream.Output) throws -> Output?) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            do {
                guard let output = try transform(input) else {
                    return demand
                }
                downstream?.receive(input: output)
                
            } catch {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
