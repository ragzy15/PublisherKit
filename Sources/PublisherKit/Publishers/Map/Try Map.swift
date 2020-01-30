//
//  Try Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    struct TryMap<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryMapSubscriber = InternalSink(downstream: subscriber, transform: transform)
            
            subscriber.receive(subscription: tryMapSubscriber)
            tryMapSubscriber.request(.unlimited)
            upstream.receive(subscriber: tryMapSubscriber)
        }
    }
}

extension PKPublishers.TryMap {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> PKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = try self.transform(output)
            return transform(newOutput)
        }
        
        return PKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> PKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = try self.transform(output)
            return try transform(newOutput)
        }
        
        return PKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}

extension PKPublishers.TryMap {
    
    // MARK: TRY MAP SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Output) throws -> Output
        
        init(downstream: Downstream, transform: @escaping (Upstream.Output) throws -> Output) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(input: Upstream.Output) {
            guard receive(input) != .none else { return }
            
            do {
                let output = try transform(input)
                downstream?.receive(input: output)
                
            } catch {
                downstream?.receive(completion: .failure(error))
            }
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
