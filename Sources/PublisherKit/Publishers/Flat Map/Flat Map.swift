//
//  Flat Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    public struct FlatMap<Upstream: PKPublisher, NewPublisher: PKPublisher>: PKPublisher where Upstream.Failure == NewPublisher.Failure {
        
        public typealias Output = NewPublisher.Output
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        public let maxPublishers: PKSubscribers.Demand
        
        public let transform: (Upstream.Output) -> NewPublisher
        
        public init(upstream: Upstream, maxPublishers: PKSubscribers.Demand, transform: @escaping (Upstream.Output) -> NewPublisher) {
            self.upstream = upstream
            self.maxPublishers = maxPublishers
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let flatMapSubscriber = InternalSink(downstream: subscriber, transform: transform)
            
            subscriber.receive(subscription: flatMapSubscriber)
            flatMapSubscriber.request(maxPublishers)
            upstream.subscribe(flatMapSubscriber)
        }
    }
}

extension PKPublishers.FlatMap {
    
    // MARK: FLATMAP SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let transform: (Upstream.Output) -> NewPublisher
        
        private lazy var subscriber = PKSubscribers.FinalOperatorSink<Downstream, NewPublisher.Output, NewPublisher.Failure>(downstream: downstream!, receiveCompletion: { (completion, downstream) in
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
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            let publisher = transform(input)
            
            downstream?.receive(subscription: subscriber)
            publisher.subscribe(subscriber)
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
