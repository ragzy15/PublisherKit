//
//  Combine Latest3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct CombineLatest3<A: PKPublisher, B: PKPublisher, C: PKPublisher>: PKPublisher where A.Failure == B.Failure, B.Failure == C.Failure {

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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Sub = InternalSink<S, A.Output, B.Output, C.Output, Failure>
            
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

extension PKPublishers.CombineLatest3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    
    public static func == (lhs: PKPublishers.CombineLatest3<A, B, C>, rhs: PKPublishers.CombineLatest3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}
