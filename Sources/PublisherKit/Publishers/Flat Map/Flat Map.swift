//
//  Flat Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that transforms elements from an upstream publisher into a publisher of that element’s type.
    public struct FlatMap<Upstream: Publisher, NewPublisher: Publisher>: Publisher where Upstream.Failure == NewPublisher.Failure {
        
        public typealias Output = NewPublisher.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The maximum number of publishers produced by this method.
        public let maxPublishers: Subscribers.Demand
        
        /// A closure that takes an element as a parameter and returns a publisher
        public let transform: (Upstream.Output) -> NewPublisher
        
        public init(upstream: Upstream, maxPublishers: Subscribers.Demand, transform: @escaping (Upstream.Output) -> NewPublisher) {
            self.upstream = upstream
            self.maxPublishers = maxPublishers
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let flatMapSubscriber = InternalSink(downstream: subscriber, transform: transform)
            upstream.subscribe(flatMapSubscriber)
        }
    }
}

extension Publishers.FlatMap {
    
    // MARK: FLATMAP SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Output) -> NewPublisher
        
        private lazy var subscriber = Subscribers.ClosureOperatorSink<Downstream, NewPublisher.Output, NewPublisher.Failure>(downstream: downstream!, receiveCompletion: { (completion, downstream) in
            if let error = completion.getError() {
                downstream?.receive(completion: .failure(error))
            }
        }) { (input, downstream) in
            _ = downstream?.receive(input)
        }
        
        init(downstream: Downstream, transform: @escaping (Upstream.Output) -> NewPublisher) {
            self.transform = transform
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            
            let publisher = transform(input)
            
            downstream?.receive(subscription: subscriber)
            publisher.subscribe(subscriber)
            
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
