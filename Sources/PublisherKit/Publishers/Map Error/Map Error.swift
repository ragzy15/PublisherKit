//
//  Map Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension Publishers {
    
    /// A publisher that converts the failure from the upstream publisher into a new failure.
    struct MapError<Upstream: Publisher, Failure: Error>: Publisher {
        
        public typealias Output = Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Failure) -> Failure
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Failure) -> Failure) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapErrorSubscriber = InternalSink(downstream: subscriber, transform: transform)
            upstream.subscribe(mapErrorSubscriber)
        }
    }
}

extension Publishers.MapError {
    
    // MARK: MAPERROR SINK
    private final class InternalSink<Downstream: Subscriber, Failure>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Failure) -> Failure
        
        init(downstream: Downstream, transform: @escaping (Upstream.Failure) -> Failure) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { self.transform($0) }
            downstream?.receive(completion: completion)
        }
    }
}
