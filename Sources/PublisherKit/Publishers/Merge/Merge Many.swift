//
//  Merge Many.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    public struct MergeMany<Upstream>: NKPublisher where Upstream : NKPublisher {

        public typealias Output = Upstream.Output

        public typealias Failure = Upstream.Failure

        public let publishers: [Upstream]

        public init(_ upstream: Upstream...) {
            publishers = upstream
        }

        public init<S: Swift.Sequence>(_ upstream: S) where Upstream == S.Element {
            publishers = upstream.map { $0 }
        }

        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let upstreamSubscriber = SameUpstreamOperatorSink<S, Upstream>(downstream: subscriber)
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            publishers.forEach { (publisher) in
                publisher.subscribe(upstreamSubscriber)
            }
        }

        public func merge(with other: Upstream) -> NKPublishers.MergeMany<Upstream> {
            NKPublishers.MergeMany(publishers + [other])
        }
    }
}
