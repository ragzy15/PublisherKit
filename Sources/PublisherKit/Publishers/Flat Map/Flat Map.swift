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
            
            let flatMapSubscriber = Inner(downstream: subscriber, operation: transform)
            upstream.subscribe(flatMapSubscriber)
        }
    }
}

extension Publishers.FlatMap {
    
    // MARK: FLATMAP SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Output) -> NewPublisher> where Output == Downstream.Input, Failure == Downstream.Failure {
       
        private lazy var subscriber = Subscribers.InternalClosure<Downstream, NewPublisher.Output, NewPublisher.Failure>(downstream: downstream!, receiveCompletion: { (completion, downstream) in
            if let error = completion.getError() {
                downstream?.receive(completion: .failure(error))
            }
        }) { (input, downstream) in
            _ = downstream?.receive(input)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            let publisher = operation(input)
            
            downstream?.receive(subscription: subscriber)
            publisher.subscribe(subscriber)
            
            return nil
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "FlatMap"
        }
    }
}
