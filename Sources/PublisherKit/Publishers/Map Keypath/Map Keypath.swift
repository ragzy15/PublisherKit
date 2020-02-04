//
//  Map KeyPath.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension Publishers {
    
    /// A publisher that publishes the value of a key path.
    struct MapKeyPath<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath: KeyPath<Upstream.Output, Output>
        
        public init(upstream: Upstream, keyPath: KeyPath<Upstream.Output, Output>) {
            self.upstream = upstream
            self.keyPath = keyPath
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapKeypathSubscriber = InternalSink(downstream: subscriber, keyPath: keyPath)
            upstream.subscribe(mapKeypathSubscriber)
        }
    }
}

extension Publishers.MapKeyPath {
    
    // MARK: MAPKEYPATH SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let keyPath: KeyPath<Upstream.Output, Output>
        
        init(downstream: Downstream, keyPath: KeyPath<Upstream.Output, Output>) {
            self.keyPath = keyPath
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            
            let output = input[keyPath: keyPath]
            
            _ = downstream?.receive(output)
            
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
