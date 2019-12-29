//
//  Flat Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {

    public struct FlatMap<Upstream: NKPublisher, NewPublisher: NKPublisher>: NKPublisher where Upstream.Failure == NewPublisher.Failure {

        public typealias Output = NewPublisher.Output

        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream

        public let maxPublishers: NKSubscribers.Demand

        public let transform: (Upstream.Output) -> NewPublisher

        public init(upstream: Upstream, maxPublishers: NKSubscribers.Demand, transform: @escaping (Upstream.Output) -> NewPublisher) {
            self.upstream = upstream
            self.maxPublishers = maxPublishers
            self.transform = transform
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Upstream>(downstream: subscriber) { (output) in
                let newPublisher = self.transform(output)
                
                let newUpstreamSubscriber = NKSubscribers.OperatorSink<S, Output, Failure>(downstream: subscriber, receiveCompletion: { (completion) in
                    
                }) { (newOutput) in
                    _ = subscriber.receive(newOutput)
                }
                
                subscriber.receive(subscription: newUpstreamSubscriber)
                newUpstreamSubscriber.request(self.maxPublishers)
                newPublisher.subscribe(newUpstreamSubscriber)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(maxPublishers)
            upstream.subscribe(upstreamSubscriber)
            
        }
    }
}
