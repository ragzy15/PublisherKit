//
//  Flat Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
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
            
            var upstreamSubscriber: SameUpstreamFailureOperatorSink<S, Upstream>!
            
            let newUpstreamSubscriber = SameUpstreamOutputOperatorSink<S, NewPublisher>(downstream: subscriber) { (completion) in
                if let error = completion.getError() {
                    subscriber.receive(completion: .failure(error))
                }
            }
            
            upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                let newPublisher = self.transform(output)
                newPublisher.subscribe(newUpstreamSubscriber)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(maxPublishers)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
