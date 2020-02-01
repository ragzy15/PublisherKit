//
//  Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    struct Map<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapSubscriber = InternalSink(downstream: subscriber, transform: transform)
            upstream.subscribe(mapSubscriber)
        }
    }
}

extension PKPublishers.Map {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> PKPublishers.Map<Upstream, T> {
        
        let newTransform: (Upstream.Output) -> T = { output in
            let newOutput = self.transform(output)
            return transform(newOutput)
        }
        
        return PKPublishers.Map<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> PKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = self.transform(output)
            return try transform(newOutput)
        }
        
        return PKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}

extension PKPublishers.Map {
    
    // MARK: MAP SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Output) -> Output
        
        init(downstream: Downstream, transform: @escaping (Upstream.Output) -> Output) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            let output = transform(input)
            _ = downstream?.receive(output)
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
