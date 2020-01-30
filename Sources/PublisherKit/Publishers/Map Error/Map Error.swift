//
//  Map Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that converts the failure from the upstream publisher into a new failure.
    struct MapError<Upstream: PKPublisher, Failure: Error>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Failure) -> Failure
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Failure) -> Failure) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapErrorSubscriber = InternalSink(downstream: subscriber, transform: transform)
            
            subscriber.receive(subscription: mapErrorSubscriber)
            mapErrorSubscriber.request(.unlimited)
            upstream.subscribe(mapErrorSubscriber)
        }
    }
}

extension PKPublishers.MapError {
    
    // MARK: MAPERROR SINK
    private final class InternalSink<Downstream: PKSubscriber, Failure>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Failure) -> Failure
        
        init(downstream: Downstream, transform: @escaping (Upstream.Failure) -> Failure) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { self.transform($0) }
            downstream?.receive(completion: completion)
        }
    }
}
