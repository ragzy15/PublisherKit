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
            
            let mapErrorSubscriber = Inner(downstream: subscriber, operation: transform)
            upstream.subscribe(mapErrorSubscriber)
        }
    }
}

extension Publishers.MapError {
    
    // MARK: MAPERROR SINK
    private final class Inner<Downstream: Subscriber, Failure>: OperatorSubscriber<Downstream, Upstream, (Upstream.Failure) -> Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            .success(input)
        }
        
         override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { operation($0) }
            downstream?.receive(completion: completion)
        }
    }
}
