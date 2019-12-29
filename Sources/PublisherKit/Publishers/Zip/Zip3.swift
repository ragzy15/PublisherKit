//
//  Zip3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher created by applying the zip function to three upstream publishers.
    public struct Zip3<A: NKPublisher, B: NKPublisher, C: NKPublisher>: NKPublisher where A.Failure == B.Failure, B.Failure == C.Failure {

        public typealias Output = (A.Output, B.Output, C.Output)

        public typealias Failure = A.Failure

        public let a: A

        public let b: B

        public let c: C

        public init(_ a: A, _ b: B, _ c: C) {
            self.a = a
            self.b = b
            self.c = c
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Sub = ZipSink3<S, A.Output, B.Output, C.Output, Failure>
            
            let upstreamSubscriber = Sub(downstream: subscriber)

            let aUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, A>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(a: output)
            }

            let bUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, B>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(b: output)
            }

            let cUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, C>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(c: output)
            }
            
            upstreamSubscriber.receive(subscription: aUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: bUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: cUpstreamSubscriber)
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            upstreamSubscriber.request(.unlimited)
            aUpstreamSubscriber.request(.unlimited)
            bUpstreamSubscriber.request(.unlimited)
            cUpstreamSubscriber.request(.unlimited)
            
            c.subscribe(cUpstreamSubscriber)
            b.subscribe(bUpstreamSubscriber)
            a.subscribe(aUpstreamSubscriber)
        }
    }
}

extension NKPublishers.Zip3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    
    public static func == (lhs: NKPublishers.Zip3<A, B, C>, rhs: NKPublishers.Zip3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}
